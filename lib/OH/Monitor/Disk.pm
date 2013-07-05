package OH::Monitor::Disk;

use Exporter qw(import);
our @EXPORT_OK = qw (disk_free);

use Net::SSH qw(ssh_cmd);

sub disk_free {
    my $host      = shift;
    my $threshold = shift;     # % of disk space
    my $cmd       = "df -h";

    # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
    my @df_lines =
      ( $host eq 'localhost' )
      ? `$cmd`
      : eval { split( "\n", ssh_cmd( "root\@$host", $cmd ) ) };

    for (@df_lines) {
        next unless /^\//;     # skip virtual disks
        my ( $fs, $use, $mount_point ) = (split)[ 0, 4, 5 ];
        ( my $use_numeric = $use ) =~ s/%$//;
        if ( $use_numeric >= $threshold ) {
            return "$mount_point ($fs) is $use full";
        } else {
            return 'ok';
        }
    }
}

1;
