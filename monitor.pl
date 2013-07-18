#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use YAML;
use TAP::Harness;
use Cache::FileCache;
use Data::Dumper;
$|++;

## CONFIG

# load configuration from config file
my $conf_file = File::Spec->catfile( dirname($0), "t", ".conf.yml" );
die "'$conf_file' problem: $!" unless -e $conf_file;
my $content = eval { local ( @ARGV, $/ ) = ($conf_file); <>; };
my $config = Load($content);

# where and how often to send messages
my $email              = $config->{email};
my $ALL_CLEAR_INTERVAL = $config->{'repeat-message'}->{'all-clear'};
my $TEST_FAIL_INTERVAL = $config->{'repeat-message'}->{'troubles'};

# command line mode?
my $adhoc = shift // undef;

sub SEND_REPORT {    # what do I do with a report?
    unless ($adhoc) {
        open STDOUT, "|mail -s 'monitor' $email"
          or die "sendmail: $!";
    }
    @_ = "ALL CLEAR\n" unless @_;
    push @_, "\n";
    print @_;
}

## END CONFIG

## PARSE TESTS RESULTS

# so we can find the test scripts
chdir dirname($0) or warn "Cannot chdir to dirname of $0: $!";
my @tests = glob "t/*.t";

# Set merge => 1 not to see STDERR (i.e. test results' comments)
my $harness = TAP::Harness->new( { verbosity => -3, merge => 1 } );

# http://perlmonks.org/?node_id=685378
$harness->callback( made_parser => \&hijack_parser );
$harness->runtests(@tests);

my @troubles;    # AoA - test names with descriptions

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

# let's cache the reports
my $cache = Cache::FileCache->new( { namespace => 'healthcheck_reporter' } );

if ($report) {    # we got trouble
    $cache->remove("");    # delete data associated with "" from cache
    if ( $cache->get($report) ) {

        ##print "This bad report has been seen (resent in $TEST_FAIL_INTERVAL)\n";
        ##$cache->set( $report, 1, $TEST_FAIL_INTERVAL );
    } else {
        $cache->set( $report, 1, $TEST_FAIL_INTERVAL );
        SEND_REPORT($report);
    }
} else {    # all clear
    if ( $cache->get("") ) {    # already said good?
        ##print "This good report has been seen (resent in $ALL_CLEAR_INTERVAL)\n";
    } else {
        $cache->clear();        # all is forgiven
        $cache->set( "", 1, $ALL_CLEAR_INTERVAL );
        SEND_REPORT();          # empty means good report
    }
}
