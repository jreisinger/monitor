package OH::Monitor::Uptime;

use strict;
use Exporter qw(import);
our @EXPORT_OK = qw (is_up);

use Net::Ping;
use IO::Socket;

###################
sub is_up {
###################
    my $host = shift;
    my $up;

    # try connection to echo port
    my $p = Net::Ping->new();
    if ( $p->ping($host) ) {
        $p->close();
        return 'ok';
    }

    # try connections to other ports
    for my $port (qw(22 80 443)) {
        my $sock = new IO::Socket::INET(
            PeerAddr => $host,
            PeerPort => $port,
            Proto    => 'tcp',
        );
        if ($sock) {
            close($sock);
            return 'ok';
        }
    }

    return "down";
}

1;
