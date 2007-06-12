package Parse

sub parse {
    my $fh = shift;

    my %parsed;
    my $lastkey;
    while (<$fh>) {
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

