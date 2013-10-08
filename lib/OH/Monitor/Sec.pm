package OH::Monitor::Sec;

use Exporter qw(import);
our @EXPORT_OK = qw (last_from);

use Net::SSH qw(ssh_cmd);
use List::MoreUtils qw(uniq);
use File::Basename qw(dirname);
use YAML qw(Load);

# load configuration from config file
sub _load_config {

    my $conf_file =
      dirname( $INC{'OH/Monitor/Sec.pm'} ) . '/../../../t/' . '.conf.yml';
    die "'$conf_file' problem: $!" unless -e $conf_file;
    my $content = eval { local ( @ARGV, $/ ) = ($conf_file); <>; };
    my $config = Load($content);

    return $config;
}

# Check whether user has logged in from different hosts using the last system command.
sub last_from {
    my $host = shift;
    my $cmd  = 'last -aw';

    # run $cmd system command locally or remotely
    my $login = getlogin || getpwuid($<);
    my $cmd_lines = ( $host eq 'localhost' )
      ? `$cmd`

      # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
      : eval { ssh_cmd( "$login\@$host", $cmd ) };

    die "No output from command '$cmd' for host '$host'" unless $cmd_lines;

    # collect login origins for different users
    my %origins;    # an entry looks like this: user => [ qw(host1 host2) ]
    for ( split '\n', $cmd_lines ) {

        # skip uninteresting lines
        next if /^\s*$/;
        next if /^wtmp begins/;

        my ( $user, $from ) = (split)[ 0, -1 ];
        push @{ $origins{$user} }, $from;
    }

    for my $user ( sort keys %origins ) {

        # remove duplicated origins
        @{ $origins{$user} } = uniq @{ $origins{$user} };

        # remove known origins (set in t/.conf.yml)
        my %temp       = map { $_, 1 } @{ $origins{$user} };
        my $config     = _load_config();
        my @ok_origins = @{ $config->{'sec-checks'}->{'ok-origins'} };
        delete $temp{$_} for @ok_origins;
        @{ $origins{$user} } = keys %temp;

        # remove users who have only logged in from known origins
        if ( @{ $origins{$user} } == 0 ) {
            delete $origins{$user};
        }
    }

    # return check result
    if ( keys %origins ) {
        return \%origins;    # ref to HoA
    } else {
        return 'ok';
    }
}

1;
