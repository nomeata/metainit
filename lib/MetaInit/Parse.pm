package MetaInit::Parse;

sub parse {
    my $filename = shift;
    open(FILE, "<", $filename) || die $!;

    my %parsed;
    my $lastkey;
    while (<FILE>) {
	# Ignore empty lines and comments
	chomp;
	next if /^$/ or /^#/;
        if (my ($key, $value) = m/^(\S.*): (.*)/) {
            $parsed{$key} = $value;
	    $lastkey = $key;
        }
        elsif ($lastkey) {
            s/^ //;
            s/^\.$//;
            $parsed{$lastkey} .= "\n$_";
        } else {
	    die "Cannot parse $_";
	}
    }
    close FILE;

    if (not exists $parsed{Description}) {
        $parsed{Description} = $parsed{Name}
    }

    {
	no warnings qw(uninitialized);
	($parsed{Path}, $parsed{Args}) = split(/\s+/,$parsed{Exec});

	my @splits = qw(Required-Start Should-Start Required-Stop Should-Stop);

	for (@splits){
		$parsed{$_} = [ split m/\s+/, $parsed{$_} ];
	}
    }

    my @mandatory = qw(Exec Name);

    my $error_msg = "";
    for (@mandatory){
	    $error_msg .= "No '$_:' provided\n" unless $parsed{$_};
    } 
    die $error_msg if $error_msg;

    $parsed{File} = $filename;

    return \%parsed;
}


# Return a true value
1;
