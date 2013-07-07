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

my @hosts = split /\s+/, $config->{hosts};

use Test::More 'no_plan';

# Change @INC from inside the script
use Cwd qw(abs_path);
use lib dirname( dirname abs_path $0) . '/lib';

use OH::Monitor::Disk qw(disk_free);
use OH::Monitor::Uptime qw(is_up);

for my $host (@hosts) {
    is( is_up($host), 'ok', "$host is up" );
    is( disk_free( $host, 80 ), 'ok', "$host has enough disk space" );
}
