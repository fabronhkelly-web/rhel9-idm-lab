#!/bin/bash
# On idm01 after `kinit admin`: policy-level test of who may SSH where.
for u in alice bob carol; do for h in rhel01 rhel02; do
  printf "%-6s -> %-7s " $u $h; ipa hbactest --user=$u --host=$h.lab.example.com --service=sshd | grep "Access granted"
done; done
# On a client as root: what IdM sudo grants
#   sudo -l -U bob      -> (root) /usr/bin/systemctl status httpd, /usr/bin/systemctl restart httpd   (rhel02 only)
