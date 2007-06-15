#!/bin/sh

# Interface:
# Rebuild init scripts (e.g., after a meta init script was added or edited)
# $0 
# 
# Removed meta-init-script:
# $0 --remove-metainit <scriptname>
#
# If a init sytem is removed, the maintainer scripts should
# call a script that cleans up the generated files for that system directly.

# This will probably be /usr/lib/metainit/translators once
translators_dir='./translators/'

# This is just a thin wrapper around the per-init-system
# translators. 
for trans in translators_dir/*
do
	trans "$@"
done
