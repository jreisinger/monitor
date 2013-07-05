package OH::Monitor::Uptime;

use Exporter qw(import);
our @EXPORT_OK = qw (is_up);

use Net::Ping;

###################
sub is_up {
###################
    my $host = shift;
    my @down;
    my $p = Net::Ping->new();
    push @down, $host unless $p->ping($host);
    $p->close();

    if (@down) {
        return "down";
    } else {
        return 'ok';
    }
}

1;
