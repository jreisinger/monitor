# Monitor

Simple server/network monitoring based on the [testing framework](http://perldoc.perl.org/Test/More.html) that comes with Perl.
Main ideas are stolen :) from:

* [Checking your website's health, part 2](http://www.stonehenge.com/merlyn/LinuxMag/col54.html)
* [Intercepting TAP output](http://perlmonks.org/?node_id=685378)
* [Automating System Administration with Perl, 2nd Edition](http://shop.oreilly.com/product/9780596006396.do) (p. 522)

Tests (i.e. checks) stored in `t` are run and evaluated by `monitor.pl`. Subroutines used by
tests are in `lib`.

## Installation

### SSH keys

In order to login to remote servers without password, copy your public key
(that is the key of the monitoring machine) to remote machine's (the monitored
machine) authorized keys:

* local host: `~/.ssh/id_rsa.pub`
* remote host: `~/.ssh/authorized_keys`

### Configuration file

Put configuration into `t/.conf.yml`:

    # send report to this address
    email: jeffrey.lebowski@dude.com

    # hosts to monitor
    hosts:
        - localhost
        - host.domain.com
        - host2.domain.org

    # report sending intervals
    # (see set() method from Cache::Cache for time info)
    repeat-message:
        # how often to repeat "all clear" message
        all-clear: never
        # how often to repeat test failed
        troubles: 30 minutes

    # configuration of checks
    sec-checks:
        ok-origins:
            - localhost
            - known-host.org

## Usage

Ad hoc checks:

    $ ./monitor.pl adhoc

Regular checks, i.e. monitoring:

    $ crontab -l

    # monitor servers
    */5 * * * *     /paht/to/monitor.pl

If you're developing new checks or debugging old ones:

    $ perl t/<check>.t
