package OH::Monitor::Sec;

use Exporter qw(import);
our @EXPORT_OK = qw (last_from);

use Net::SSH qw(ssh_cmd);
use List::MoreUtils qw(uniq);

sub last_from {
    my $host = shift;
    my $cmd  = 'last -aw';

    my $cmd_lines = ( $host eq 'localhost' )
      ? `$cmd`

      # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
      : eval { ssh_cmd( "root\@$host", $cmd ) };

    my %origins;

    for ( split '\n', $cmd_lines ) {

        # skip uninteresting lines
        next if /^\s*$/;
        next if /^wtmp begins/;

        my ( $user, $from ) = (split)[ 0, -1 ];
        push @{ $origins{$user} }, $from;
    }

    for my $user ( sort keys %origins ) {
        my @uniq_from = uniq @{ $origins{$user} };
        if ( @uniq_from == 1 ) {
            delete $origins{$user};
        }
    }

    if ( keys %origins ) {
        return \%origins;    # ref to HoA
    } else {
        return 'ok';
    }
}

1;
