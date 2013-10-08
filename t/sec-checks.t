#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use YAML;
use Data::Dumper;

# read content of $conf_file into $content
my $conf_file = File::Spec->catfile( dirname($0), ".conf.yml" );
die "'$conf_file' problem: $!" unless -e $conf_file;
my $content = eval { local ( @ARGV, $/ ) = ($conf_file); <>; };

# load yaml into perl hashRef
my $config = Load($content);

my @hosts = @{ $config->{hosts} };

use Test::More 'no_plan';

# Change @INC from inside the script
use Cwd qw(abs_path);
use lib dirname( dirname abs_path $0) . '/lib';

use OH::Monitor::Sec qw(last_from net_scan);

for my $host (@hosts) {
    my $from = last_from($host);
    is( $from, 'ok', "login from unknown origin(s) on $host\n" . Dumper $from );
}

for my $host (@hosts) {
    my @ports = net_scan($host);
    is( $ports[0], 'ok', "unexpected open ports on $host (@ports)" );
}
