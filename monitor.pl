#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use YAML;
use TAP::Harness;
use Cache::FileCache;
use Data::Dumper;

## CONFIG

# load configuration from config file
my $conf_file = File::Spec->catfile( dirname($0), "t", ".conf.yml" );
die "'$conf_file' problem: $!" unless -e $conf_file;
my $content = eval { local ( @ARGV, $/ ) = ($conf_file); <>; };
my $config = Load($content);

my $ALL_CLEAR_INTERVAL = $config->{'repeat-message'}->{'all-clear'};
my $TEST_FAIL_INTERVAL = $config->{'repeat-message'}->{'troubles'};
my $email              = $config->{email};

sub SEND_REPORT {    # what do I do with a report?
    ##open STDOUT, "|mail -s 'monitor' $email" or die "sendmail: $!";
    open STDOUT, "|mail -s 'monitor' $email" or die "sendmail: $!";
    @_ = "ALL CLEAR\n" unless @_;
    print @_;
}

## END CONFIG

## PARSE TESTS RESULTS

# Set merge => 1 not to see STDERR (test results' comments)
my $harness = TAP::Harness->new( { verbosity => -3, merge => 1 } );
my @tests = glob "t/*.t";

$harness->callback( made_parser => \&hijack_parser );
$harness->runtests(@tests);

my @troubles;    # AoA

sub hijack_parser {
    my ( $parser, $test_ref ) = @_;
    while ( my $result = $parser->next ) {
        $result->is_test or next;
        $result->is_actual_ok and next;
        ( my $description = $result->description ) =~ s/- //;
        my $test = $test_ref->[1];
        push @troubles, [ $test, $description ];
    }
}

## CREATE AND PRINT/SEND REPORT

my $report = join "\n", map $_->[0] . " => " . $_->[1], @troubles;

my $cache = Cache::FileCache->new( { namespace => 'healthcheck_reporter' } );

if ($report) {    # we got trouble
    $cache->remove("");    # blow away good report stamp
    if ( $cache->get($report) ) {

        print "This bad report has been seen (resent in $TEST_FAIL_INTERVAL)\n";
    } else {
        $cache->set( $report, 1, $TEST_FAIL_INTERVAL );
        SEND_REPORT($report);
    }
} else {                   # all clear
    if ( $cache->get("") ) {    # already said good?
        print
          "This good report has been seen (resent in $ALL_CLEAR_INTERVAL)\n";
    } else {
        $cache->clear();        # all is forgiven
        $cache->set( "", 1, $ALL_CLEAR_INTERVAL );
        SEND_REPORT();          # empty means good report
    }
}
