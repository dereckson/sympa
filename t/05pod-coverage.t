#!/usr/bin/perl

use strict;
use warnings;
use lib 'src/lib';

use English qw(-no_match_vars);
use Test::More;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import();
};
plan(skip_all => 'Test::Pod::Coverage required') if $EVAL_ERROR;

# Test::Pod::Coverage hardcodes 'lib' as prefix, whereas we use 'src/lib'
my @modules = map {
        s/^src::lib:://; $_
    } all_modules('src/lib');

plan tests => scalar @modules;

foreach my $module (@modules) {
    pod_coverage_ok(
        $module,
    );
}
