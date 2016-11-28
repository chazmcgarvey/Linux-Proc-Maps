package Linux::Proc::Maps;
# ABSTRACT: Read and write /proc/[pid]/maps files
# KEYWORDS: linux proc procfs

use 5.008;
use warnings;
use strict;

our $VERSION = '999.999'; # VERSION

use Carp qw(croak);
use Exporter qw(import);
use namespace::clean -except => [qw(import)];

our @EXPORT_OK = qw(read_maps write_maps parse_maps_single_line format_maps_single_line);

=head1 SYNOPSIS

    use Linux::Proc::Maps qw(read_maps);

    # by pid:
    my $vm_regions = read_maps(pid => $$);

    # by pid with explicit procfs mount:
    my $vm_regions = read_maps(mnt => '/proc', pid => 123);

    # by file:
    my $vm_regions = read_maps(file => '/proc/456/maps');

=head1 DESCRIPTION

This module reads and writes F</proc/[pid]/maps> files that contain listed mapped memory regions.

=func read_maps

Read and parse a maps file, returning an arrayref of regions (each represented as a hashref). See
L</parse_maps_single_line> to see the format of the hashrefs.

    my $regions = read_maps(%args);

Arguments:

=for :list
* C<file> - Path to maps file
* C<pid> - Process ID (one of C<file> or C<pid> is required)
* C<mnt> - Absolute path where L<proc(5)> is mounted (optional, default: C</proc>)

=cut

sub read_maps {
    my %args = @_ == 1 ? (pid => $_[0]) : @_;

    my $file = $args{file};

    if (!$file and my $pid = $args{pid}) {
        if ($pid =~ /^\d+$/) {
            require File::Spec::Functions;
            my $procfs = $args{mnt} || $ENV{PERL_LINUX_PROC_MAPS_MOUNT} ||
                         File::Spec::Functions::catdir(File::Spec::Functions::rootdir(), 'proc');
            $file = File::Spec::Functions::catfile($procfs, $pid, 'maps');
        }
        else {
            $file = $args{pid};
        }
    }

    $file or croak 'Filename or PID required';
    open(my $fh, '<:encoding(UTF-8)', $file) or croak "Open failed ($file): $!";

    my @regions;

    while (my $line = <$fh>) {
        chomp $line;

        my $region = parse_maps_single_line($line);
        next if !$region;

        push @regions, $region;
    }

    return \@regions;
}

=func write_maps

Returns a string with the contents of a maps file from the memory regions passed.

    my $file_content = write_maps(\@regions, %args);

This is the opposite of L</read_maps>.

Arguments:

=for :list
* C<fh> - Write maps to this open file handle (optional)
* C<file> - Open this filepath and write maps to that file (optional)

=cut

sub write_maps {
    my $regions = shift or croak 'Regions required';
    my %args = @_;

    ref $regions eq 'ARRAY' or croak 'Regions must be an arrayref';

    my $out = '';

    for my $region (@$regions) {
        $out .= format_maps_single_line($region);
    }

    # maybe print out the memory regions to a filehandle
    my $fh = $args{fh};
    if (!$fh and my $file = $args{file}) {
        open($fh, '>:encoding(UTF-8)', $file) or croak "Open failed ($file): $!";
    }
    print $fh $out if $fh;

    return $out;
}

=func parse_maps_single_line

Parse and return a single line from a maps file into a region represented as a hashref.

    my $region = parse_maps_single_line($line);

For example,

    # address         perms offset  dev   inode   pathname
    08048000-08056000 r-xp 00000000 03:0c 64593   /usr/sbin/gpm

becomes:

    {
        address_start   => 134512640,
        address_end     => 134569984,
        read            => 1,
        write           => '',
        execute         => 1,
        shared          => '',
        offset          => 0,
        device          => '03:0c'
        inode           => '64593',
        pathname        => '/usr/sbin/gpm',
    }

=cut

sub parse_maps_single_line {
    my $line = shift or croak 'Line from a maps file required';

    chomp $line;

    my ($addr1, $addr2, $read, $write, $exec, $shared, $offset, $device, $inode, $pathname) = $line =~ m{
        ^
        ([[:xdigit:]]+)-([[:xdigit:]]+)
        \s+ ([r-])([w-])([x-])([sp])
        \s+ ([[:xdigit:]]+)
        \s+ ([[:xdigit:]]+:[[:xdigit:]]+)
        \s+ (\d+)
        (?: \s+ (.*))?
    }x;

    return if !$addr1;

    no warnings 'portable';     # for hex() on 64-bit perls

    return {
        address_start   => hex($addr1),
        address_end     => hex($addr2),
        read            => 'r' eq $read,
        write           => 'w' eq $write,
        execute         => 'x' eq $exec,
        shared          => 's' eq $shared,
        offset          => hex($offset),
        device          => $device,
        inode           => $inode,
        pathname        => $pathname || '',
    };
}

=func format_maps_single_line

Return a single line for a maps file from a region represented as a hashref.

    my $line = format_maps_single_line(\%region);

This is the opposite of L</parse_maps_single_line>.

=cut

sub format_maps_single_line {
    my $region = shift or croak 'Region required';

    my @args = @{$region}{qw(address_start address_end read write execute shared offset device inode)};
    $args[2] = $args[2] ? 'r' : '-';
    $args[3] = $args[3] ? 'w' : '-';
    $args[4] = $args[4] ? 'x' : '-';
    $args[5] = $args[5] ? 's' : 'p';

    return sprintf("%-72s %s\n", sprintf("%x-%x %s%s%s%s %08x %s %d", @args), $region->{pathname});
}

=head1 SEE ALSO

L<proc(5)> describes the file format.

=head1 CAVEATS

Integer overloading may occur if you try to parse memory regions from address spaces larger than
your current architecture (or perl) supports. This is currently not fatal, though you will get
warnings from perl that you probably shouldn't ignore.

=cut

1;
