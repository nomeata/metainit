#! /usr/bin/perl
#
# update-rc.d	Update the links in /etc/rc[0-9S].d/
#

use strict;
use warnings;

# This is a locally modified version of /usr/sbin/update-rc.d to work in the local 
# directory, to use for testing purposes.

my $initd = "$ENV{PWD}/etc/init.d";
my $etcd  = "$ENV{PWD}/etc/rc";
my $notreally = 0;

# Only parse the LSB headers when this flag exist.  It is to be used
# while we test this new feature, and should be removed when we are
# confident that LSB headers are correct. [pere 2006-09-06]
my $lsbparseflag = "/etc/update-rc.d-lsbparse";

# Print usage message and die.

sub usage {
	print STDERR "update-rc.d: error: @_\n" if ($#_ >= 0);
	print STDERR <<EOF;
usage: update-rc.d [-n] [-f] <basename> remove
       update-rc.d [-n] <basename> defaults [NN | sNN kNN]
       update-rc.d [-n] <basename> start|stop NN runlvl [runlvl] [...] .
		-n: not really
		-f: force
EOF
	exit (1);
}

# Check out options.
my $force;

while($#ARGV >= 0 && ($_ = $ARGV[0]) =~ /^-/) {
	shift @ARGV;
	if (/^-n$/) { $notreally++; next }
	if (/^-f$/) { $force++; next }
	if (/^-h|--help$/) { &usage; }
	&usage("unknown option");
}

# Action.

&usage() if ($#ARGV < 1);
my $bn = shift @ARGV;
if ($ARGV[0] ne 'remove') {
    if (! -f "$initd/$bn") {
	print STDERR "update-rc.d: $initd/$bn: file does not exist\n";
	exit (1);
    }
} elsif (-f "$initd/$bn") {
    if (!$force) {
	printf STDERR "update-rc.d: $initd/$bn exists during rc.d purge (use -f to force)\n";
	exit (1);
    }
}

my @startlinks;
my @stoplinks;

$_ = $ARGV[0];
if    (/^remove$/)       { &checklinks ("remove"); }
elsif (/^defaults$/)     { &defaults; &makelinks }
elsif (/^(start|stop)$/) { &startstop; &makelinks; }
else                     { &usage; }

exit (0);

# Check if there are links in /etc/rc[0-9S].d/ 
# Remove if the first argument is "remove" and the links 
# point to $bn.

sub is_link () {
    my ($op, $fn, $bn) = @_;
    if (! -l $fn) {
	print STDERR "update-rc.d: warning: $fn is not a symbolic link\n";
	return 0;
    } else {
	my $linkdst = readlink ($fn);
	if (! defined $linkdst) {
	    die ("update-rc.d: error reading symbolic link: $!\n");
	}
	if (($linkdst ne "../init.d/$bn") && ($linkdst ne "$initd/$bn")) {
	    print STDERR "update-rc.d: warning: $fn is not a link to ../init.d/$bn or $initd/$bn\n";
	    return 0;
	}
    }
    return 1;
}

sub checklinks {
    my ($i, $found, $fn, $islnk);

    print " Removing any system startup links for $initd/$bn ...\n"
	if (defined $_[0] && $_[0] eq 'remove');

    $found = 0;

    foreach $i (0..9, 'S') {
	unless (chdir ("$etcd$i.d")) {
	    next if ($i =~ m/^[789S]$/);
	    die("update-rc.d: chdir $etcd$i.d: $!\n");
	}
	opendir(DIR, ".");
	foreach $_ (readdir(DIR)) {
	    next unless (/^[SK]\d\d$bn$/);
	    $fn = "$etcd$i.d/$_";
	    $found = 1;
	    $islnk = &is_link ($_[0], $fn, $bn);
	    next unless (defined $_[0] and $_[0] eq 'remove');
	    if (! $islnk) {
		print "   $fn is not a link to ../init.d/$bn; not removing\n"; 
		next;
	    }
	    print "   $etcd$i.d/$_\n";
	    next if ($notreally);
	    unlink ("$etcd$i.d/$_") ||
		die("update-rc.d: unlink: $!\n");
	}
	closedir(DIR);
    }
    $found;
}

sub parse_lsb_header {
    my $initdscript = shift;
    my %lsbinfo;
    if (-e $lsbparseflag) {
	my $lsbfound = 0;
	my $lsbheaders = "Provides|Default-Start|Default-Stop";
	open(INIT, "<$initdscript") || die "error: unable to read $initdscript";
	while (<INIT>) {
	    chomp;
	    $lsbfound = 1 if (m/^\#\#\# BEGIN INIT INFO$/);
	    last if (m/\#\#\# END INIT INFO$/);
	    if (m/^\# (Default-Start|Default-stop):\s*(\S?.*)$/i) {
		$lsbinfo{lc($1)} = $2;
	    }
	}
	close(INIT);
    }
    return %lsbinfo;
}


# Process the arguments after the "defaults" keyword.

sub defaults {
    my ($start, $stop) = (20, 20);

    &usage ("defaults takes only one or two codenumbers") if ($#ARGV > 2);
    $start = $stop = $ARGV[1] if ($#ARGV >= 1);
    $stop  =         $ARGV[2] if ($#ARGV >= 2);
    &usage ("codenumber must be a number between 0 and 99")
	if ($start !~ /^\d\d?$/ || $stop  !~ /^\d\d?$/);

    $start = sprintf("%02d", $start);
    $stop  = sprintf("%02d", $stop);

    my %lsbinfo = parse_lsb_header("$initd/$bn");

    if (exists $lsbinfo{'default-stop'}) {
	for my $level (split(/\s+/, $lsbinfo{'default-stop'})) {
	    $level = 99 if ($level eq 'S');
	    $stoplinks[$level] = "K$stop";
	}
    } else {
	$stoplinks[0] = $stoplinks[1] = $stoplinks[6] = "K$stop";
    }

    if (exists $lsbinfo{'default-start'}) {
	for my $level (split(/\s+/, $lsbinfo{'default-start'})) {
	    $level = 99 if ($level eq 'S');
	    $startlinks[$level] = "S$start";
	}
    } else {
	$startlinks[2] = $startlinks[3] =
	    $startlinks[4] = $startlinks[5] = "S$start";
    }

    1;
}

# Process the arguments after the start or stop keyword.

sub startstop {

    my($letter, $NN, $level);

    while ($#ARGV >= 0) {
	if    ($ARGV[0] eq 'start') { $letter = 'S'; }
	elsif ($ARGV[0] eq 'stop')  { $letter = 'K' }
	else {
	    &usage("expected start|stop");
	}

	if ($ARGV[1] !~ /^\d\d?$/) {
	    &usage("expected NN after $ARGV[0]");
	}
	$NN = sprintf("%02d", $ARGV[1]);

	shift @ARGV; shift @ARGV;
	$level = shift @ARGV;
	do {
	    if ($level !~ m/^[0-9S]$/) {
		&usage(
		       "expected runlevel [0-9S] (did you forget \".\" ?)");
	    }
	    if (! -d "$etcd$level.d") {
		print STDERR
		    "update-rc.d: $etcd$level.d: no such directory\n";
		exit(1);
	    }
	    $level = 99 if ($level eq 'S');
	    $startlinks[$level] = "$letter$NN" if ($letter eq 'S');
	    $stoplinks[$level]  = "$letter$NN" if ($letter eq 'K');
	} while (($level = shift @ARGV) ne '.');
	&usage("action with list of runlevels not terminated by \`.'")
	    if ($level ne '.');
    }
    1;
}

# Create the links.

sub makelinks {
    my($t, $i);
    my @links;

    if (&checklinks) {
	print " System startup links for $initd/$bn already exist.\n";
	exit (0);
    }
    print " Adding system startup for $initd/$bn ...\n";

    # nice unreadable perl mess :)

    for($t = 0; $t < 2; $t++) {
	@links = $t ? @startlinks : @stoplinks;
	for($i = 0; $i <= $#links; $i++) {
	    my $lvl = $i;
	    $lvl = 'S' if ($i == 99);
	    next if (!defined $links[$i] or $links[$i] eq '');
	    print "   $etcd$lvl.d/$links[$i]$bn -> ../init.d/$bn\n";
	    next if ($notreally);
	    symlink("../init.d/$bn", "$etcd$lvl.d/$links[$i]$bn")
		|| die("update-rc.d: symlink: $!\n");
	}
    }

    1;
}
