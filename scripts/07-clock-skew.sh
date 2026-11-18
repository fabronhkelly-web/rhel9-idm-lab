#!/bin/bash
# On a client (root): break Kerberos with clock skew, find it, fix it.
systemctl stop chronyd
date -s "+10 minutes"
# - `kinit` alone may still work: MIT krb5 corrects skew itself (kdc_timesync)
# - SSH as an IdM user: journal shows  krb5_child: Clock skew too great
#   ...but login can STILL succeed, because SSSD falls back to cached credentials
journalctl -u sssd --since "-15 min" | grep -i "skew"
systemctl start chronyd && chronyc -a makestep
chronyc tracking | grep "System time"
