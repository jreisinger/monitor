#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use OH::Monitor::Disk qw(disk_free);
use OH::Monitor::Uptime qw(is_up);

my @hosts = qw[ prod1.openhouse.sk localhost prod.openhouse.sk ];

for my $host (@hosts) {
    is( is_up($host), 'ok', "'$host' is up" );
    is( disk_free( $host, 80 ), 'ok', "'$host' has enough disk space" );
}

__END__
use OH::File::Integrity qw(check_f re_check_f);

my @files = qw(/etc/passwd /etc/group1 /etc/nsswitch.conf /tmp/passwd);
check_f(@files);
re_check_f();
