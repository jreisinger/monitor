package OH::Monitor::Disk;

use Exporter qw(import);
our @EXPORT_OK = qw (disk_free);

use Net::SSH qw(ssh_cmd);

sub disk_free {
    my $host      = shift;
    my $threshold = shift;      # % of disk space
    my $cmd       = "df -hP";

    my $df_lines = ( $host eq 'localhost' )
      ? `$cmd`

      # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
      : eval { ssh_cmd( "root\@$host", $cmd ) };

    my @full_disks;

    for ( split '\n', $df_lines ) {
        next unless /^\//;      # skip virtual disks
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
