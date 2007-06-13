#!/usr/bin/perl

use strict;
use warnings;

use Parse;

my $metainit_dir = './examples';
my $etc = './etc';

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
	my @generated = regenerate_initscripts();

}

sub read_metainits{
	my @metainits;
	for my $metainit_file (<$metainit_dir/*.metainit>) {
		push @metainits, Parse::parse($metainit_file)
	}
	
}

sub regenerate_initscripts {

}

sub remove {
	die "Remove not yet implemented"
}
