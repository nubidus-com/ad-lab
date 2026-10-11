# Lab description

Active Directory lab `vaultshields.local` (NetBIOS `VAULTSHIELDS`) running on an Apple Silicon Mac
with VirtualBox, using ARM64 Windows boxes built by `tools/build-box.sh`.

## Servers

Host-only network `192.168.56.0/24` (plus a NAT adapter on each VM for internet access).

| VM | Hostname | IP | OS | Role | WinRM / SSH from host | RDP from host |
|---|---|---|---|---|---|---|
| win-dc01 | WIN-DC01 | 192.168.56.10 | Windows Server 2025 (ARM64) | Domain controller, DNS | 127.0.0.1:25985 | 127.0.0.1:23389 |
| win-srv01 | WIN-SRV01 | 192.168.56.11 | Windows Server 2025 (ARM64) | Member server | 127.0.0.1:35985 | 127.0.0.1:33389 |
| win-srv02 | WIN-SRV02 | 192.168.56.12 | Windows Server 2025 (ARM64) | Member server | 127.0.0.1:45985 | 127.0.0.1:43389 |
| win-client01 | WIN-CLIENT01 | 192.168.56.13 | Windows 11 (ARM64) | Domain workstation | 127.0.0.1:55985 | 127.0.0.1:53389 |
| linux-srv01 | LINUX-SRV01 | 192.168.56.14 | Ubuntu 24.04 (arm64) | Linux server, LAMP (Apache), joined via realm/sssd | SSH 127.0.0.1:6222 | - |

Notes:
- All servers, the client and the Linux server are joined to the domain.
- SQL Server (`mssql` role) is skipped: there is no SQL Server build for ARM Windows.
- `bob` is a local Administrator on win-client01.
- DNS forwarders on the DC: 8.8.8.8, 8.8.4.4.
- Apache on linux-srv01: `http://192.168.56.14/`.

## Credentials

| Account | Password | Notes |
|---|---|---|
| vagrant | vagrant | Local account on Windows VMs, Vagrant/WinRM user; also the Linux SSH user (key auth) |
| Administrator (`VAULTSHIELDS\Administrator`) | StrongPass123! | Domain admin |
| admin | StrongPass123! | Domain Admins member |
| bob, alice | StrongPass123! | Standard users (default `Users` container) |
| all 20 people below | password123 | Standard users in the `People` OUs |

Directory Services Restore Mode password: `StrongPass123!`.
Password complexity is disabled domain-wide (min length 8, no history) so the simple lab passwords work.
Lab only; never use this in production.

## Organizational units

```
vaultshields.local
├── Users              (default container: Administrator, vagrant, admin, bob, alice, built-in groups)
├── People
│   ├── IT
│   ├── Engineering
│   ├── Database
│   ├── Messaging
│   ├── HR
│   ├── Finance
│   ├── Sales
│   └── Support
├── Groups             (the five admin groups)
└── Domain Controllers
```

## Admin groups (OU `Groups`)

| Group | Purpose | Members |
|---|---|---|
| DC Admins | Domain controller administrators (member of Domain Admins) | jsmith, mjohnson, dwilliams, sbrown |
| SQL Server Admins | SQL Server administrators | cmoore, ptaylor |
| Web Server Admins | Web server administrators | rjones, jwilson |
| Linux Admins | Linux server administrators | ldavis, mmiller |
| Mail Server Admins | Mail server administrators | tanderson, bthomas |

Other groups, created in the domain root by the `ad_groups` variable: allTeams, DBAOracle, DBASQLServer,
DBAMongo, DBARedis, DBAEnterprise, JustATestDemo (no members).

## People (OU `People`, password `password123`)

| Username | Name | Department OU | Group |
|---|---|---|---|
| jsmith | John Smith | IT | DC Admins |
| mjohnson | Mary Johnson | IT | DC Admins |
| dwilliams | David Williams | IT | DC Admins |
| sbrown | Sarah Brown | IT | DC Admins |
| rjones | Robert Jones | Engineering | Web Server Admins |
| jwilson | Jennifer Wilson | Engineering | Web Server Admins |
| ldavis | Linda Davis | Engineering | Linux Admins |
| mmiller | Michael Miller | Engineering | Linux Admins |
| cmoore | Charles Moore | Database | SQL Server Admins |
| ptaylor | Patricia Taylor | Database | SQL Server Admins |
| tanderson | Thomas Anderson | Messaging | Mail Server Admins |
| bthomas | Barbara Thomas | Messaging | Mail Server Admins |
| jjackson | Joseph Jackson | HR | - |
| lwhite | Lisa White | HR | - |
| dharris | Daniel Harris | Finance | - |
| nmartin | Nancy Martin | Finance | - |
| mthompson | Mark Thompson | Sales | - |
| kgarcia | Karen Garcia | Sales | - |
| pmartinez | Paul Martinez | Sales | - |
| srobinson | Susan Robinson | Support | - |

## Where this is defined

| What | File |
|---|---|
| VMs, IPs, ports | `Vagrantfile`, `inventory/group_vars/all.yml` |
| Users, OUs, groups | `roles/domain_controller/defaults/main.yml`, `roles/domain_controller/tasks/directory.yml` |
| Playbooks | `playbooks/*.yml` |
| ARM64 box builder | `tools/build-box.sh` |

## Operating notes

- Set `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` before running `ansible-playbook` on macOS.
- Linux playbook extra vars: `-e ansible_user=vagrant -e ansible_ssh_private_key_file=.vagrant/machines/linux-srv01/virtualbox/private_key`.
- The Linux domain join uses `realm join --membership-software=samba` (adcli fails against a Server 2025 DC).
- Cloned Windows Server VMs share a machine SID and must be sysprepped before joining the domain.
