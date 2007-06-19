#!perl

use strict;
use warnings;
use Test::More tests => 7;
use Test::NoWarnings;
use Test::Exception;
use MetaInit::Parse;

throws_ok(sub {
        MetaInit::Parse::parse('foo');
}, qr/hash reference expected/, 'needs hash ref');

throws_ok(sub {
        MetaInit::Parse::parse({});
}, qr/no input given/, 'needs input');

throws_ok(sub {
        MetaInit::Parse::parse({ filename => 'something that\'s unlikely to exist' });
}, qr/Failed to open input file/, 'non-existant file');

throws_ok(sub {
        MetaInit::Parse::parse({ input => 'foo' });
}, qr/parsing from handles or strings/, 'parsing from string without passing File and Name fields');

lives_ok(sub {
        MetaInit::Parse::parse({ input => 'Exec: /foo/bar', fields => {
            File => '',
            Name => '',
        } });
}, 'parsing from strign with File and Name fields set');

throws_ok(sub {
        MetaInit::Parse::parse({ input => 'foo: bar', fields => {
            File => '',
            Name => '',
        } });
}, qr/Mandatory field .* not provided/, 'mandatory fields missing');
