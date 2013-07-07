monitor
=======

Server monitoring

## Installation

### SSH keys

In order to login to remote servers without password, copy your public key
(that is the key of the monitoring machine) to remote machine's (the monitored
machine) authorized keys:

* local host: `~/.ssh/id_rsa.pub`
* remote host: `/root/.ssh/authorized_keys`

