#!/bin/sh
### In snmpd.sh (make sure this file is chmod +x):
# `chpst -u snmp` runs the given command as the user `xxxxx`.
# If you omit that part, the command will be run as root.

exec chpst -u root /usr/sbin/snmpd -u Debian-snmp -g Debian-snmp -f 2>&1
