#!/bin/sh

# This will probably be /usr/lib/metainit/translators once
translators_dir='./translators/'

# This is just a thin wrapper around the per-init-system
# translators. 
for trans in translators_dir/*
do
	trans "$@"
done
