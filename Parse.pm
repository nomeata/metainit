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
	    chomp;
            s/^ //;
            s/^\.$//;
            $parsed{$lastkey} .= "\n$_";
        } else {
	    die "Cannot parse $!";
	}
    }
    close FILE;

    if (not exists $parsed{Description}) {
        $parsed{Description} = $parsed{Name}
    }

    ($parsed{Path}, $parsed{Args}) = split(/\s/,$parsed{Exec});

    $parsed{"Required-Start"} =	[split(/\s/,$parsed{"Required-Start"})];
    $parsed{"Should-Start"} =	[split(/\s/,$parsed{"Should-Start"})];
    $parsed{"Required-Stop"} =	[split(/\s/,$parsed{"Required-Stop"})];
    $parsed{"Should-Stop"} =	[split(/\s/,$parsed{"Should-Stop"})];

    return %parsed;
}


# Return a true value
1;
