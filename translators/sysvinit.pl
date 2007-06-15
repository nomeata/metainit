#!/usr/bin/perl

use strict;
use warnings;

use Parse;

my $metainit_dir = './examples';
my $etc = './etc';
my $utils = '.';
my $updatercd = './update-rc.d';

#
# Rough plan of operation:
#    (Maybe:
#     Check all init files, find all generated ones, see if the metainit 
#     file is missing and delete them then)
#    Check all metainit files, whether the init.d file is out of date.
#    If the init.d file was created, find a suitable rc2.d/ number and run update-rc.
#

use Getopt::Long;

my $remove = '';
GetOptions( 'remove-metainit=s' => \$remove );

if ($remove) {
	# Operation: Remove all geranted files for the given metainit name
	remove($remove)
} else {
	# Operation: Rebuild everything
	
	#check_orphaned_initscripts()
	my @metainits = read_metainits();
	my @generated = ();
	foreach my $metainit (@metainits) {
		my $created = regenerate_initscript($metainit);
		push @generated, $metainit->{Name} if $created;
	}

	my %arrangement = ();
	open(ARRANGE, '-|',"$utils/arrange-sysvinit.pl",@generated) or die $!;
	while (<ARRANGE>) {
		if (/^([\w\.-]+) (\d\d)$/){
			$arrangement{$1} = $2;
		} else {
			die "Can't parse $_";
		}
	}
	close ARRANGE;

	while (my ($initname,$num) = each %arrangement) {
		system($updatercd, $initname, "defaults", $num);
	}


}

sub read_metainits{
	my @metainits;
	for my $metainit_file (<$metainit_dir/*.metainit>) {
		push @metainits, Parse::parse($metainit_file);
	}
	return @metainits;
}

sub regenerate_initscript {
	my ($metainit) = @_;
	my $initscript = init_script_name($metainit);
	my $new = not -e $initscript;

	
	if (not $new) {
		my $can_touch = 0;
		open INIT, '<', $initscript or die $!;
		while (<INIT>) {
			if (/DO NOT EDIT THIS FILE/) {
				$can_touch = 1;
				last;
			}
		}
		close INIT;
		warn "Not overriding user-modified init script $initscript.\n";
		return 0 if (not $can_touch);
	} else {
		# Here me might want to check if the file is up-to-date.
		# For now, we just override it always.
	}

	system("$utils/create-sysvinit-file.pl", $metainit->{File}, $initscript);

	return $new;

}

sub init_script_name {
	my ($metainit) = @_;
	return sprintf "%s/init.d/%s", $etc, $metainit->{Name};
}

sub remove {
	die "Remove not yet implemented"
}
