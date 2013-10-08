package OH::Monitor::Disk;

use Exporter qw(import);
our @EXPORT_OK = qw (disk_free);

use Net::SSH qw(ssh_cmd);

sub disk_free {
    my $host      = shift;
    my $threshold = shift;                   # % of disk space
    my $cmd       = "df -hP 2> /dev/null";

    # run $cmd system command locally or remotely
    my $login = getlogin || getpwuid($<);
    my $cmd_lines = ( $host eq 'localhost' )
      ? `$cmd`

      # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
      : eval { ssh_cmd( "$login\@$host", $cmd ) };

    die "No output from command '$cmd' for host '$host'" unless $cmd_lines;

    my @full_disks;

    for ( split '\n', $cmd_lines ) {
        next unless /^\//;    # skip virtual disks
        my ( $fs, $use, $mount_point ) = (split)[ 0, 4, 5 ];
        ( my $use_numeric = $use ) =~ s/%$//;
        if ( $use_numeric >= $threshold ) {
            push @full_disks, $mount_point;
        }
    }

    if (@full_disks) {
        return @full_disks;
    } else {
        return 'ok';
    }
}

1;
