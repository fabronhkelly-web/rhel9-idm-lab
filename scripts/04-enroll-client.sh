#!/bin/bash
# On each client (root): point DNS at IdM, join with the one-time password, keep STIG PAM features.
# Usage: OTP='<one-time password>' ./04-enroll-client.sh
set -euo pipefail
umask 022
authselect current                                    # record features before (faillock, without-nullok, smartcard...)
nmcli con mod ens160 ipv4.dns 192.168.31.10 ipv4.ignore-auto-dns yes && nmcli con up ens160
dig +short _kerberos._udp.lab.example.com SRV         # IdM DNS answers the Kerberos SRV record
dnf -y install ipa-client
ipa-client-install -U --domain lab.example.com --realm LAB.EXAMPLE.COM \
  --server idm01.lab.example.com --password "$OTP" --mkhomedir --no-ntp
# ipa-client-install re-selects the authselect profile: re-enable the STIG features it dropped
for f in with-faillock without-nullok with-mkhomedir with-sudo with-smartcard; do authselect enable-feature $f || true; done
authselect current
id alice; id bob
