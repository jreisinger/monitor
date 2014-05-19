package OH::Monitor::Mail;

use strict;
use Exporter qw(import);
our @EXPORT_OK = qw(unread_mail);

use Net::SSH qw(ssh_cmd);

sub unread_mail {
    my $host     = shift;
    my $username = shift;

    my $cmd = "cat /var/mail/$username";

    # run $cmd system command locally or remotely
    my $login = getlogin || getpwuid($<);
    my $cmd_lines = ( $host eq 'localhost' )
      ? `$cmd`

      # ssh_cmd - STDOUT returned as single string STDERR throws fatal error
      : eval { ssh_cmd( "$login\@$host", $cmd ) };

    die "Problem with '$cmd' on '$host': $@" if $@;

    # New lines means new mail
    if ($cmd_lines) {
        return 'new mail';
    } else {
        return 'ok';
    }
}

1;
