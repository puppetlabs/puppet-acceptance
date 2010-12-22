#!/usr/bin/perl

use Test::More;

main();
sub main
{
    for my $test_script (glob "t/test*.sh" )
    {
        run_one_test( $test_script );
    }
    done_testing();
}

sub run_one_test
{
    my $filename = shift;
    my $expected = get_expected_results( $filename );
    my $output   = `/bin/bash $filename`;
    is( $output, $expected, $filename );
}

sub get_expected_results
{
    my $filename = shift;
    my $file     = do { local @ARGV = $filename; local $/ = <> };

    my $results  = (split /# EXPECTED RESULTS #\s*/, $file)[1];
    $results     =~ s/^#\s*//gm;

    return $results;
}
