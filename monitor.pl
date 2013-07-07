#!/usr/bin/perl
use strict;
use warnings;
use TAP::Harness;

# Set merge => 1 not to see STDERR (test results' comments)
my $harness = TAP::Harness->new( { verbosity => -3, merge => 0 } );
my @tests = glob "t/*.t";

$harness->callback( made_parser => \&hijack_parser );
$harness->runtests(@tests);

sub hijack_parser {
    my ( $parser, $test_ref ) = @_;
    while ( my $result = $parser->next ) {
        $result->is_test or next;
        $result->is_actual_ok and next;
        ( my $description = $result->description ) =~ s/- //;
        print "We got trouble with '$description' in $test_ref->[1]\n";
    }
}
