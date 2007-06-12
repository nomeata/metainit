package Parse;

sub parse {
    my $filename = shift;
    open(FILE, "<$filename") || die "$!";

    my %parsed;
    my $lastkey;
    while (<FILE>) {
	# Ignore empty lines and comments
	next if /^$/ or /^#/;
        #last if /^$/;
        if (my ($key, $value) = m/^([^ ].*): (.*)/) {
            $parsed{$key} = $value;
	    $lastkey = $key;
        }
        elsif ($lastkey) {
            s/^ //;
            s/^\.$//;
            $parsed{$lastkey} .= $_;
        } else {
	    die "Cannot parse $!";
	}
    }

    if (not exists $parsed{Description}) {
        $parsed{Description} = $parsed{Name}
    }

    ($parsed{Path}, $parsed{Args}) = split(/\s/,$parsed{Exec});

    return %parsed;
}


# Return a true value
1;
