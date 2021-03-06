package MetaInit::Parse;
use v5.008;
use strict;
use warnings;
use Carp qw/croak/;
use File::Basename;
use Scalar::Util qw/openhandle/;

=head1 NAME

MetaInit::Parse - Parses a MetaInit definition fild

=head1 SYNOPSIS

    $data = MetaInit::Parse::parse($filename)

Opens and parses the specified file. The parsed data is handed back as a
hashref, containing an entry for each definition.

=head2 FILE FORMAT

The file to be parsed should be in a RFC822-like format (field names and values
are separated by a colon (C<:>). Lines starting with a blank are just appended
to their previous line's value. Lines that contain only a period (C<.>) in them
will become an empty line in the output.

Empty lines are ignored. 

Comments are allowed - All characters after a # sign until the end of the 
line are ignored. If you need to include the # sign, prepend it with a 
backslash (\#).

=head2 FIELDS

A MetaInit file has several defined fields, out of which only C<Exec> is mandatory:

=over 4

=item Short-Description

A short (~60 character) description of the daemon. Merely informative.

=item Description

A longer description of the daemon, usually a couple of lines long. Merely
informative.

=item Exec

The command to execute to get the daemon to room. Please keep in mind this 
should start the daemon in the I<foreground>, not send it to the background.

=item Required-Start

The facilities that should be started before this one. This can include the
LSB facility names. It defaults to "B<$local_fs $network $remote_fs>.

=item Required-Stop

B<CURRENTLY IGNORED - SHOULD CHECK LATER>

=item Should-Start

B<CURRENTLY IGNORED - SHOULD CHECK LATER>

=item Should-Stop

B<CURRENTLY IGNORED - SHOULD CHECK LATER>

=item Prestart-Hook

A shell snippet that should be included in the generated init script I<before>
the daemon is run

=item Poststop-hook

A shell snippet that should be included in the generated init script I<after>
the daemon finishes running

=item No-Auto

If this is set to anything, the generated init scripts will be installed in a
way that the deamon is not started by default on system start up. It can still
be started manually (e.g. using /etc/init.d/<name> start) and be configured to
start automatically (e.g. by adjusting the symlinks).

=back

Some fields (Required-Start, Should-Start, Required-Stop and Should-Stop) will
not return strings but arrayrefs - Elements will be separated by whitespace.

=head1 NOTES

Note that this module is written specifically for MetaInit, it will quite 
probably not be useful outside it.

=head1 SEE ALSO

The (as for now inexistent ;-) ) MetaInit documentation

LSB facility names, 
http://refspecs.freestandards.org/LSB_2.1.0/LSB-generic/LSB-generic/facilname.html

=head1 AUTHOR

=cut

my @splits = qw(Required-Start Should-Start Required-Stop Should-Stop);
my @mandatory = qw(Exec);

sub slurp_from_fh {
    my ($fh) = @_;

    return do { local $/; <$fh> };
}

sub process_data {
    my ($data, $parsed) = @_;

    my $lastkey;
    for (split /\n/, $data) {
        chomp;
        # Ignore comments; unescape escaped #s
        s/[^\\]\#.*//;
        s/\\\#/\#/g;
        # Ignore empty lines; convert single dots in a line into empty lines
        next if /^\s*$/;
        s/^\s*\.\s*$//;

        if (my ($key, $value) = m/^(\S.*)\s*:\s*(.*)/) {
            $parsed->{$key} = $value;
            $lastkey = $key;
        }
        elsif ($lastkey) {
            s/^\s+//;
            s/^\.$//;
            $parsed->{$lastkey} .= "\n$_";
        } else {
            die "Cannot parse line: ``$_''";
        }
    }
}

sub fixup_results {
    my (%parsed) = @_;

    my $error_msg = "";
    for my $field (@mandatory) {
            $error_msg .= "Mandatory field `$field' not provided\n" unless exists $parsed{$field};
    }

    croak($error_msg) if $error_msg;

    if (not exists $parsed{Description}) {
        $parsed{Description} = $parsed{"Short-Description"}
    }

    ($parsed{Path}, $parsed{Args}) = split(/\s+/,$parsed{Exec},2);
    $parsed{Basename} = basename $parsed{Path};

    for (@splits){
        $parsed{$_} = [ split m/\s+/, $parsed{$_}||'' ];
    }

    if ($parsed{"No-Auto"}) {
        $parsed{"Start-Levels"} = [];
        $parsed{"Stop-Levels"}  = [1,2,3,4,5];
    } else {
        $parsed{"Start-Levels"} = [2,3,4,5];
        $parsed{"Stop-Levels"}  = [1];
    }

    if ($parsed{"Post-Stop"}) {
        push @{$parsed{"Stop-Levels"}}, 0, 6;
    }

    for (qw/Start-Levels Stop-Levels/) {
        @{$parsed{$_}} = sort @{$parsed{$_}};
    }

    return %parsed;
}

sub parse {
    my ($args) = @_;

    if (ref $args ne 'HASH') {
        croak('hash reference expected');
    }

    my $data;
    my %parsed;

    if (defined $args->{input}) {
        $data = $args->{input};
    }
    elsif (my $fh = openhandle($args->{handle})) {
        $data = slurp_from_fh($fh);
    }
    elsif (defined (my $file = $args->{filename})) {
        open(my $handle, '<', $file)
            or die "Failed to open input file `$file': $!";

        $data = slurp_from_fh($handle);

        $parsed{File} = $file;
        $parsed{Name} = basename($file,'.metainit');
    }
    else {
        croak("no input given; you need to pass a `filename', "
            . "an opened `handle' or an `input' string");
    }

    if (!defined $parsed{File}) {
        if (ref $args->{fields} ne 'HASH'
         || !exists $args->{fields}->{File}
         || !exists $args->{fields}->{Name}) {
            croak("parsing from handles or strings requires the `fields' option to "
                . "be set to a hash reference that defines both the `Name' and the "
                . "`File' field.");
        }
    }

    @parsed{keys %{ $args->{fields} }} = values %{ $args->{fields} };

    # Defaults:

	$parsed{"Short-Description"} = $parsed{Name};
	$parsed{"No-Auto"} = 0;
    $parsed{"Required-Start"} = '$local_fs $network $remote_fs';
    $parsed{"Required-Stop"}  = '$local_fs $network $remote_fs';

    process_data($data, \%parsed);
    %parsed = fixup_results(%parsed);
    
    return \%parsed;
}

# Return a true value
1;

# vim:sw=4:ts=4:expandtab
