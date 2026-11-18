#!/bin/bash
# On idm01: pre-create a client with a ONE-TIME enrollment password, so the admin password never touches the client.
# Usage: ./03-add-host-otp.sh rhel02 192.168.31.12
h=$1; ip=$2
ipa host-add $h.lab.example.com --ip-address=$ip --random     # prints "Random password: ..." (single use)
[ "$h" = rhel02 ] && ipa hostgroup-add-member webservers --hosts=$h.lab.example.com
