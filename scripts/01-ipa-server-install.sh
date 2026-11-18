#!/bin/bash
# Install Red Hat IdM (FreeIPA) with integrated DNS on idm01. Run as root.
# Passwords are generated, kept in a root-only file, and never printed.
set -euo pipefail
gen() { python3 -c "import secrets,string;a=string.ascii_letters+string.digits;print('Lab-'+''.join(secrets.choice(a) for _ in range(20))+'9x')"; }
( umask 077; [ -f /root/idm-passwords ] || printf "DM_PASSWORD=%s\nADMIN_PASSWORD=%s\n" "$(gen)" "$(gen)" > /root/idm-passwords )
source /root/idm-passwords
dnf -y install ipa-server ipa-server-dns
firewall-cmd --permanent --add-service={freeipa-4,dns} && firewall-cmd --reload
umask 022     # ipa-server-install refuses to run with umask 077 ("Unexpected system mask")
ipa-server-install -U --realm LAB.EXAMPLE.COM --domain lab.example.com \
  --hostname idm01.lab.example.com --ip-address 192.168.31.10 \
  --ds-password "$DM_PASSWORD" --admin-password "$ADMIN_PASSWORD" \
  --setup-dns --auto-forwarders --auto-reverse --no-dnssec-validation
echo "$ADMIN_PASSWORD" | kinit admin && ipactl status
dig +short idm01.lab.example.com @127.0.0.1; dig +short -x 192.168.31.10 @127.0.0.1
