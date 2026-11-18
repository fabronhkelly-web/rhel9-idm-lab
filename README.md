# Red Hat IdM (FreeIPA) for RHEL 9: Central Identity, Access Control and Sudo

Home lab: a Red Hat Identity Management server with integrated DNS manages users, host-based access
control (HBAC), central sudo and a STIG-aligned password policy for two RHEL 9 servers, one of them
DISA-STIG hardened in FIPS mode.

Part of a series: [rhel9-stig-hardening](https://github.com/fabronhkelly-web/rhel9-stig-hardening) ·
[rhel9-ansible-project](https://github.com/fabronhkelly-web/rhel9-ansible-project)

## Lab
| Host | IP | Role |
|---|---|---|
| idm01.lab.example.com | 192.168.31.10 | IdM server 4.13 (LDAP, Kerberos KDC, CA, DNS), realm `LAB.EXAMPLE.COM` |
| rhel01.lab.example.com | 192.168.31.11 | IdM client, FIPS mode, manually STIG-hardened |
| rhel02.lab.example.com | 192.168.31.12 | IdM client, `webservers` host group, STIG playbook applied (95%) |

## Policy design
| Who | Group | Can SSH to | Sudo |
|---|---|---|---|
| alice | `linux_admins` | every host | everything |
| bob | `web_operators` | `webservers` only (rhel02) | `systemctl restart/status httpd` only |
| carol | none | nowhere | none |

- **HBAC:** explicit rules first, then the default `allow_all` rule **disabled**.
- **Password policy:** 15 characters, 4 classes, 60-day max, 1-hour min, history 5, **3 failures = lock until an admin unlocks**.
- **Enrollment:** clients join with a **one-time password** (`ipa host-add --random`); the admin password never touches a client.

## Results (verified)
| Test | Result |
|---|---|
| `ipa-server-install` with DNS | All 9 services RUNNING; forward and reverse DNS resolve |
| Client enrollment (rhel01 FIPS/STIG, rhel02 STIG) | Joined; IdM users resolve with `id`; STIG PAM features kept |
| `ipa hbactest` and real SSH logins | alice: both hosts · bob: rhel02 only · carol: refused everywhere |
| `sudo -l -U bob` on rhel02 | `(root) /usr/bin/systemctl status httpd, /usr/bin/systemctl restart httpd` |
| First login | Admin-set temporary password expired, forced change at first `kinit` |
| `ipa user-disable alice` | Refused on **both** servers immediately; `user-enable` restores |
| 3 bad passwords for carol | `Failed logins: 3`; correct password then rejected (*credentials revoked*); `ipa user-unlock` restores |
| Clock skew (+10 min on rhel02) | `krb5_child: Clock skew too great` in the journal, but login **still succeeded** from SSSD cached credentials; fixed with chronyd + `makestep` |

## Troubleshooting I ran into
- **`Unexpected system mask: 0077`**: `ipa-server-install` refuses to run with a restrictive umask. I had set 077 to protect the generated password file; set 022 just for the install.
- **`ipa-client-install` resets authselect features**: it dropped `with-smartcard` on the STIG-hardened client. I recorded the features before joining and re-enabled them after.
- **IdM brings its own Apache**: removed an old lab `httpd` vhost from the cloned base before installing.
- **Clock skew can hide**: MIT `kinit` auto-corrects skew (`kdc_timesync`), and SSSD falls back to cached credentials, so a skewed server can look healthy. The evidence is in `journalctl` (`krb5_child`), not in a failed login. Existing users keep working; first-time logins and services that need fresh tickets fail.
- **Testing mistakes I caught**: a test script that cleared all Kerberos caches (`kdestroy -A`) also dropped the admin ticket, and a login check matched text echoed from its own command line. Both were rerun with stricter checks before recording any result.

## Scripts ([`scripts/`](scripts))
| Script | Purpose |
|---|---|
| `01-ipa-server-install.sh` | IdM server + DNS, generated passwords in a root-only file |
| `02-identity-policy.sh` | Password policy, users, groups, HBAC, central sudo |
| `03-add-host-otp.sh` | Pre-create host with one-time enrollment password |
| `04-enroll-client.sh` | DNS to IdM, `ipa-client-install`, restore STIG PAM features |
| `05-verify-access.sh` | `ipa hbactest` matrix and sudo check |
| `06-lifecycle-lockout.sh` | Disable/enable, lockout/unlock |
| `07-clock-skew.sh` | Break-and-fix Kerberos time skew |

## Interview notes
- Why HBAC instead of local `AllowUsers`? One policy, every server, audited in one place, and removing access is one command.
- Why OTP enrollment? Least privilege: the client never sees an admin credential.
- STIG tie-in: IdM is how smart card/CAC (`sssd_enable_certmap`) and central account management (AC-2) would be met in production.

## Disclaimer
Personal home lab using `lab.example.com` (reserved for documentation). No real systems, users or credentials.
