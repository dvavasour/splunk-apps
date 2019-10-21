These are the spells to work around the default permissions assigned in `/var/log` on modern GNU/Linux systems

These examples assume that Splunk has been installed and runs with its group set as `splunk`

Firstly run `setACLs.sh` as root, then (also as root) drop the file `Splunk_ACLs` into `/etc/logrotate.d/Splunk_ACLs`. There should be no need to reboot, but you'll need to restart Splunk (or the forwarder).

Details taken from https://serverfault.com/questions/258827/what-is-the-most-secure-way-to-allow-a-user-read-access-to-a-log-file/780226#780226

Note, this should be considered particular to Red Hat and equivalent (CentOS, Amazon Linux etc). For Ubuntu/Raspbian based distros the logfiles may vary.
