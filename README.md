# NAME

Linux::Proc::Maps - Read and write /proc/\[pid\]/maps files

# VERSION

version 0.001

# SYNOPSIS

    use Linux::Proc::Maps qw(read_maps);

    # by pid:
    my $vm_regions = read_maps(pid => $$);

    # by pid with explicit procfs mount:
    my $vm_regions = read_maps(mnt => '/proc', pid => 123);

    # by file:
    my $vm_regions = read_maps(file => '/proc/456/maps');

# DESCRIPTION

This module reads and writes `/proc/[pid]/maps` files that contain listed mapped memory regions.

# METHODS

## read\_maps %args

Read and parse a maps file, returning an arrayref of regions (each represented as a hashref). See
["parse\_maps\_single\_line"](#parse_maps_single_line) to see the format of the hashrefs.

Arguments:

- `file` - Path to maps file
- `pid` - Process ID (one of `file` or `pid` is required)
- `mnt` - Absolute path where [proc(5)](http://man.he.net/man5/proc) is mounted (optional, default: `/proc`)

## write\_maps \\@regions, %args

Returns a string with the contents of a maps file from the memory regions passed.

This is the opposite of ["read\_maps"](#read_maps).

Arguments:

- `fh` - Write maps to this open file handle (optional)
- `file` - Open this filepath and write maps to that file (optional)

## parse\_maps\_single\_line $line

Parse and return a single line from a maps file into a region represented as a hashref.

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

## format\_maps\_single\_line \\%region

Return a single line for a maps file from a region represented as a hashref.

This is the opposite of ["parse\_maps\_single\_line"](#parse_maps_single_line).

# SEE ALSO

[proc(5)](http://man.he.net/man5/proc) describes the file format.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/chazmcgarvey/Linux-Proc-Maps/issues](https://github.com/chazmcgarvey/Linux-Proc-Maps/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
