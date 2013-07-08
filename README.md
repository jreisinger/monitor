# Monitor

Simple server/network moniting based on testing framework that comes with Perl. For more see

* [Checking your website's health, part 2](http://www.stonehenge.com/merlyn/LinuxMag/col54.html)
* [Intercepting TAP output](http://perlmonks.org/?node_id=685378)
* [Automating System Administration with Perl, 2nd Edition](http://shop.oreilly.com/product/9780596006396.do) (p. 522)

## Installation

### SSH keys

In order to login to remote servers without password, copy your public key
(that is the key of the monitoring machine) to remote machine's (the monitored
machine) authorized keys:

* local host: `~/.ssh/id_rsa.pub`
* remote host: `/root/.ssh/authorized_keys`

### Configuration file

Put configuration into `t/.conf.yml`:

    # send reports to this address
    email: jeffrey.lebowski@dude.com

    # hosts to monitor
    hosts:
        - localhost
        - host.domain.com
        - host2.domain.org

    repeat-message:
        # how often to repeat "all clear" message
        all-clear: never
        # how often to repeat test failed
        troubles: 15 seconds
