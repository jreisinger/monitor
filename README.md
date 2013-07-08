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

### Hosts to monitor

Define hosts you want to monitor in `t/.conf.yml`:

    hosts: localhost host1.domain.com host2.domain.org