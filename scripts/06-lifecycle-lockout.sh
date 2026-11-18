#!/bin/bash
# On idm01 after `kinit admin`.
# Lifecycle: one change locks the user out of EVERY enrolled server
ipa user-disable alice      # ssh alice@rhel01 / rhel02 -> refused
ipa user-enable  alice      # -> works again
# Lockout: 3 bad passwords (pwpolicy maxfail=3)
for i in 1 2 3; do echo "wrong-$i" | KRB5CCNAME=/tmp/cc kinit carol; done
ipa user-status carol       # Failed logins: 3 ; correct password now -> "Client's credentials have been revoked"
ipa user-unlock carol       # admin unlock (lockouttime=0)
