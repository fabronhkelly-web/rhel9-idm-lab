#!/bin/bash
# Users, groups, STIG-aligned password policy, HBAC (replacing allow_all) and central sudo. Run on idm01 after `kinit admin`.
set -euo pipefail
ipa pwpolicy-mod global_policy --minlength=15 --minclasses=4 --maxlife=60 --minlife=1 \
  --history=5 --maxfail=3 --failinterval=900 --lockouttime=0      # lockouttime 0 = admin must unlock

ipa group-add linux_admins  --desc="Full admin on all Linux servers"
ipa group-add web_operators --desc="Restart/inspect httpd on web servers only"
ipa user-add alice --first=Alice --last=Admin      --shell=/bin/bash
ipa user-add bob   --first=Bob   --last=Webops     --shell=/bin/bash
ipa user-add carol --first=Carol --last=Contractor --shell=/bin/bash   # in no group: should be denied everywhere
ipa group-add-member linux_admins  --users=alice
ipa group-add-member web_operators --users=bob
ipa hostgroup-add webservers --desc="Web servers"

# Host-based access control: explicit rules, then turn off the default allow_all
ipa hbacrule-add admins_everywhere --hostcat=all --servicecat=all
ipa hbacrule-add-user admins_everywhere --groups=linux_admins
ipa hbacrule-add webops_on_webservers
ipa hbacrule-add-user    webops_on_webservers --groups=web_operators
ipa hbacrule-add-host    webops_on_webservers --hostgroups=webservers
ipa hbacrule-add-service webops_on_webservers --hbacsvcs=sshd
ipa hbacrule-disable allow_all

# Central sudo
ipa sudocmd-add "/usr/bin/systemctl restart httpd"
ipa sudocmd-add "/usr/bin/systemctl status httpd"
ipa sudorule-add admins_all --hostcat=all --cmdcat=all --runasusercat=all --runasgroupcat=all
ipa sudorule-add-user admins_all --groups=linux_admins
ipa sudorule-add webops_httpd
ipa sudorule-add-user webops_httpd --groups=web_operators
ipa sudorule-add-host webops_httpd --hostgroups=webservers
ipa sudorule-add-allow-command webops_httpd --sudocmds="/usr/bin/systemctl restart httpd" --sudocmds="/usr/bin/systemctl status httpd"
