# Step 5: Package Management

> **Time:** ~6-8 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md) · **Next:** [Step 6: System Security](step-06-system-security.md)

<!-- -->

> [!WARNING]
> Package changes can break a system (removed dependencies, held packages, a bad repository).
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot afford to lose.
> Never add a repository or key you have not verified, and never run `apt remove` or `dnf remove`
> without reading the list of packages it will take with it.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
Tasks were run as root in Ubuntu 24.04 and AlmaLinux 9 containers. Where a task shows both families, the
RHEL commands were verified on AlmaLinux 9 unless marked *typical*.

## Cheat sheet: apt vs dnf

| Job | Debian / Ubuntu | RHEL family (dnf) |
|-----|-----------------|-------------------|
| Refresh metadata | `sudo apt update` | automatic (`dnf makecache`) |
| Install | `sudo apt install PKG` | `sudo dnf install PKG` |
| Remove | `sudo apt remove PKG` | `sudo dnf remove PKG` |
| Upgrade all | `sudo apt upgrade` | `sudo dnf upgrade` |
| Search | `apt search WORD` | `dnf search WORD` |
| Info / versions | `apt-cache policy PKG` | `dnf info PKG`, `dnf --showduplicates list PKG` |
| Which package owns a file | `dpkg -S /path` | `rpm -qf /path` |
| List files in a package | `dpkg -L PKG` | `rpm -ql PKG` |
| Low-level installer | `dpkg -i FILE.deb` | `rpm -i FILE.rpm` |

---

## Beginner

### Task 5.1: Install, update and remove packages

- **What you will learn:** the package manager lifecycle: refresh metadata, check the candidate version, install, remove, and clean up unused dependencies.
- **Target distro:** both (commands below for `apt`; the RHEL equivalents are in the table).
- **Risk level:** `safe` for small packages; `destructive` if you `remove` something a lot of other software needs (read the confirmation list).

```bash
sudo apt update
apt-cache policy tree
sudo apt install -y tree jq htop
sudo apt remove -y htop
sudo apt autoremove -y
sudo apt clean
```

RHEL family:

```bash
sudo dnf install -y tree jq htop     # htop and tree may need EPEL: sudo dnf install -y epel-release
sudo dnf remove -y htop
sudo dnf autoremove -y
```

**Verify it worked**

```bash
dpkg -l tree jq htop | tail -3        # RHEL: rpm -q tree jq htop
dpkg -s htop 2>&1 | head -1
```

**Expected output** (captured; versions depend on your release):

```text
ii htop 3.3.0-4build1
ii jq 1.7.1-3ubuntu0.24.04.2
ii tree 2.1.1-2ubuntu3.24.04.2
dpkg-query: package 'htop' is not installed and no information is available
```

The first three lines were taken before `htop` was removed; the last line shows it gone afterwards.

**Acceptance criteria**

- [ ] 3 packages installed, one removed, and `autoremove` ran.
- [ ] You can answer "which package owns `/usr/bin/tree`?" (`dpkg -S` / `rpm -qf`).

**Undo it**

```bash
sudo apt install -y htop      # put back what you removed
sudo apt remove -y tree jq    # or remove what you added
```

**Troubleshooting**

- `E: Unable to locate package`: run `sudo apt update`, check the name with `apt search`, and check your `sources` list.
- `E: Could not get lock /var/lib/dpkg/lock-frontend`: another package process runs. Wait, do not delete the lock.
- `Error: Unable to find a match` (dnf): the package lives in EPEL or CRB. Enable them: `sudo dnf install epel-release && sudo dnf config-manager --set-enabled crb`.

### Task 5.2: Build a package and host it in your own repository

- **What you will learn:** what is inside a `.deb`/`.rpm`, how repository metadata (`Packages` or `repodata`) is generated, and how clients consume it.
- **Target distro:** both. Debian/Ubuntu: `dpkg-dev lintian`. RHEL: `rpm-build createrepo_c`.
- **Risk level:** `safe` for the build; adding `[trusted=yes]` or `gpgcheck=0` disables signature checks and is for **lab use only**. Sign real repositories (see troubleshooting).

**Debian/Ubuntu**

```bash
sudo apt install -y dpkg-dev lintian
P=/tmp/hello-lab_1.0.0-1_all
mkdir -p $P/DEBIAN $P/usr/bin $P/usr/share/doc/hello-lab
cat > $P/DEBIAN/control <<'EOF'
Package: hello-lab
Version: 1.0.0-1
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 5.0)
Maintainer: Lab Admin <lab@example.com>
Description: Tiny demo tool for the packaging lab
 Prints a greeting and its own version.
EOF
printf '#!/usr/bin/env bash\necho "hello from hello-lab 1.0.0"\n' > $P/usr/bin/hello-lab
chmod 755 $P/usr/bin/hello-lab
cat > $P/usr/share/doc/hello-lab/copyright <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: 2026 Lab Admin
License: MIT
EOF
printf 'hello-lab (1.0.0-1) unstable; urgency=low\n\n  * Initial release.\n\n -- Lab Admin <lab@example.com>  Sat, 17 Oct 2026 12:00:00 +0000\n' | gzip -9n > $P/usr/share/doc/hello-lab/changelog.Debian.gz
dpkg-deb --root-owner-group --build $P
lintian /tmp/hello-lab_1.0.0-1_all.deb

sudo mkdir -p /srv/repo && sudo cp /tmp/hello-lab_1.0.0-1_all.deb /srv/repo/
cd /srv/repo && sudo sh -c 'dpkg-scanpackages --multiversion . > Packages && gzip -kf Packages'
echo 'deb [trusted=yes] file:/srv/repo ./' | sudo tee /etc/apt/sources.list.d/lab.list
sudo apt update && sudo apt install -y hello-lab
hello-lab
```

**RHEL family**

```bash
sudo dnf install -y rpm-build createrepo_c
mkdir -p ~/rpmbuild/{SPECS,SOURCES}
cat > ~/rpmbuild/SPECS/hello-lab.spec <<'EOF'
Name:           hello-lab
Version:        1.0.0
Release:        1%{?dist}
Summary:        Tiny demo tool for the packaging lab
License:        MIT
BuildArch:      noarch
Requires:       bash

%description
Prints a greeting and its own version.

%install
mkdir -p %{buildroot}%{_bindir}
printf '#!/usr/bin/env bash\necho "hello from hello-lab %{version}"\n' > %{buildroot}%{_bindir}/hello-lab
chmod 755 %{buildroot}%{_bindir}/hello-lab

%files
%{_bindir}/hello-lab

%changelog
* Sat Oct 17 2026 Lab Admin <lab@example.com> - 1.0.0-1
- Initial release
EOF
rpmbuild -bb ~/rpmbuild/SPECS/hello-lab.spec
sudo mkdir -p /srv/repo && sudo cp ~/rpmbuild/RPMS/noarch/*.rpm /srv/repo/ && sudo createrepo_c /srv/repo
sudo tee /etc/yum.repos.d/lab.repo >/dev/null <<'EOF'
[lab]
name=Lab repo
baseurl=file:///srv/repo
enabled=1
gpgcheck=0
EOF
sudo dnf install -y hello-lab && hello-lab
```

**Verify it worked**

**Expected output:**

```text
dpkg-deb: building package 'hello-lab' in '/tmp/hello-lab_1.0.0-1_all.deb'.
W: hello-lab: initial-upload-closes-no-bugs [usr/share/doc/hello-lab/changelog.Debian.gz:1]
W: hello-lab: no-manual-page [usr/bin/hello-lab]
hello from hello-lab 1.0.0
```

(`lintian` warnings are acceptable for a lab package; errors are not. My first attempt put the
script in `/usr/local/bin` and omitted the copyright and changelog, and lintian reported `E:` errors for each.)
On AlmaLinux the last line is `hello from hello-lab 1.0.0` as well, after `dnf` prints `Installed: hello-lab-1.0.0-1.el9.noarch`.

**Acceptance criteria**

- [ ] `apt policy hello-lab` / `dnf info hello-lab` shows your repository as the source.
- [ ] `lintian` shows no `E:` lines.
- [ ] `dpkg -L hello-lab` / `rpm -ql hello-lab` lists `/usr/bin/hello-lab`.

**Undo it**

```bash
sudo apt remove -y hello-lab; sudo rm /etc/apt/sources.list.d/lab.list; sudo apt update
sudo dnf remove -y hello-lab; sudo rm /etc/yum.repos.d/lab.repo       # RHEL
sudo rm -r /srv/repo
```

**Troubleshooting**

- `Release file ... is not signed` / `GPG error`: you left out `[trusted=yes]`. For a real repo, sign with `gpg` and ship the public key in `/etc/apt/keyrings/` (reference it with `signed-by=`); on RHEL set `gpgcheck=1` and `gpgkey=`.
- `dpkg-scanpackages: command not found`: install `dpkg-dev`.
- `error: Bad exit status ... (%install)`: your spec macros or paths are wrong; read the lines above the error.

### Task 5.3: Automate updates, safely

- **What you will learn:** a manual update script, and the distro-supported tools that do the same job unattended: `unattended-upgrades` (Debian/Ubuntu) and `dnf-automatic` (RHEL).
- **Target distro:** both.
- **Risk level:** `can lock you out` of a working service if an automatic upgrade restarts or breaks it. Use security-only updates on servers, test first, and keep snapshots.

```bash
cat > ~/bin/update-system.sh <<'EOF'
#!/usr/bin/env bash
# Update packages. Usage: sudo update-system.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }
if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get -y -qq upgrade
  apt-get -y -qq autoremove
elif command -v dnf >/dev/null; then
  dnf -y -q upgrade --refresh
  dnf -y -q autoremove
fi
[[ -f /var/run/reboot-required ]] && echo "reboot required"
[[ ! -x /usr/bin/needs-restarting ]] || needs-restarting -r || true
exit 0
EOF
chmod +x ~/bin/update-system.sh
sudo ~/bin/update-system.sh
```

Now the supported unattended options:

```bash
# Debian/Ubuntu: security updates automatically
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades     # answer Yes
sudo unattended-upgrade --dry-run --debug | tail -5

# RHEL family: security updates automatically
sudo dnf install -y dnf-automatic
sudo sed -i 's/^upgrade_type.*/upgrade_type = security/; s/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer
```

**Verify it worked.** `update-system.sh` uses only commands verified in Task 5.1; the unattended tools were
*not run* because they need a full systemd host. *Typical output:* `unattended-upgrade --dry-run` ends with
`No packages found that can be upgraded unattended and no pending auto-removals` on an up-to-date machine, and
`systemctl list-timers dnf-automatic.timer` shows the next run.

**Acceptance criteria**

- [ ] The script updates the system, removes orphans and tells you whether to reboot.
- [ ] You know where the unattended tool logs (`/var/log/unattended-upgrades/`, `journalctl -u dnf-automatic`).
- [ ] Production policy is written down: which updates auto-apply, which need a human, and when you reboot.

**Undo it**

```bash
sudo apt remove -y unattended-upgrades          # RHEL: sudo systemctl disable --now dnf-automatic.timer
rm ~/bin/update-system.sh
```

**Troubleshooting**

- `dpkg was interrupted, you must manually run 'dpkg --configure -a'`: run exactly that, then retry.
- Held-back packages (`The following packages have been kept back`): use `sudo apt full-upgrade` after reading the list.
- Kernel updated but old kernel runs: reboot. Use `uname -r` vs the newest in `/boot`.

---

## Intermediate

### Task 5.4: A local package cache or mirror

- **What you will learn:** serving packages from inside your network to save bandwidth and speed up installs. For most labs a **caching proxy** (`apt-cacher-ng`) is better than `apt-mirror`: a full Ubuntu mirror is hundreds of GB, the proxy stores only what clients request.
- **Target distro:** Debian/Ubuntu (`apt-cacher-ng`). RHEL family: `reposync` + `createrepo_c` for a mirror, or Pulp/Katello for a managed one.
- **Risk level:** `safe` (but the cache holds files from the internet; keep it on a trusted network).

```bash
# on the cache server
sudo apt install -y apt-cacher-ng
curl -s -o /dev/null -w "acng http=%{http_code}\n" http://127.0.0.1:3142/acng-report.html

# on each client
echo 'Acquire::http::Proxy "http://CACHE-SERVER:3142";' | sudo tee /etc/apt/apt.conf.d/01proxy
sudo apt install -y cowsay
find /var/cache/apt-cacher-ng -name '*.deb' | head -3          # on the cache server
```

RHEL family mirror of one repo (large; try a small repo first, typical, not run here):

```bash
sudo dnf install -y dnf-utils createrepo_c
sudo dnf reposync --repoid=appstream --download-metadata -p /srv/mirror --newest-only
```

**Verify it worked**

**Expected output** (captured; the first line is `curl`'s):

```text
acng http=200
/var/cache/apt-cacher-ng/uburep/pool/universe/c/cowsay/cowsay_3.03+dfsg2-8_all.deb
```

A second client installing the same package must not download it again: the cache server's
`/var/log/apt-cacher-ng/apt-cacher.log` shows a `HIT`.

**Acceptance criteria**

- [ ] The package is in the cache after the first install.
- [ ] A second machine's install is served from the cache.
- [ ] The cache server's disk usage is monitored.

**Undo it**

```bash
sudo rm /etc/apt/apt.conf.d/01proxy
sudo apt remove -y apt-cacher-ng
```

**Troubleshooting**

- `Could not connect to CACHE-SERVER:3142`: firewall (open 3142/tcp) or the service is not running.
- HTTPS repositories bypass the proxy: apt-cacher-ng only caches HTTP unless you configure a pass-through (`PassThroughPattern`). Many third-party repos use HTTPS.
- Stale metadata: set a shorter `ExTreshold` or clear the cache with the web report page.

### Task 5.5: Multiple versions of a toolchain (the modern SCL replacement)

- **What you will learn:** Software Collections (SCL) are **discontinued** (CentOS 7 era). On RHEL 8 and later the equivalents are **AppStream module streams** (`dnf module`) and versioned packages (`python3.12`), and for developer toolchains containers or `pyenv`/`nvm`.
- **Target distro:** RHEL family 8/9/10 (AlmaLinux, Rocky, RHEL). Not available on Debian/Ubuntu (use versioned packages like `python3.12`, or `deadsnakes`/PPAs with care).
- **Risk level:** `safe`, but switching a module stream after install needs a reset and may remove packages.

```bash
dnf module list nodejs
sudo dnf module enable -y nodejs:22
sudo dnf module install -y nodejs:22/common
node --version
```

**Verify it worked**

**Expected output** (listing was captured on AlmaLinux 9; the install and version were *not run*):

```text
nodejs     18     common [d], development, minimal, s2i                 Javascript runtime
nodejs     20     common [d], development, minimal, s2i                 Javascript runtime
nodejs     22     common [d], development, minimal, s2i                 Javascript runtime
nodejs     24     common [d], development, minimal, s2i                 Javascript runtime
```

`[d]` marks the default profile. After install, `node --version` prints `v22.x.y`.

**Acceptance criteria**

- [ ] You can list the available streams and choose one.
- [ ] You can explain why mixing streams requires `dnf module reset`.
- [ ] You know the supported lifetime of your stream (`dnf module info nodejs:22`).

**Undo it**

```bash
sudo dnf module remove -y nodejs
sudo dnf module reset -y nodejs
```

**Troubleshooting**

- `Modular dependency problems` / `conflicting requests`: reset the stream (`dnf module reset NAME`) before enabling another.
- `No match for argument: module`: you are on dnf5 (Fedora 41+, RHEL 10 may change); see `dnf5 module --help` or the distro docs.
- Application needs a newer runtime than AppStream offers: run it in a container (Podman, [Step 11](step-11-virtualization-and-containers.md)).

### Task 5.6: Pin and hold package versions

- **What you will learn:** the difference between **hold** (do not change this package), **pin** (prefer this version or repository), and **versionlock** on RHEL.
- **Target distro:** both.
- **Risk level:** `can lock you out` of security fixes. A held package never gets patches, so record why and review it regularly.

```bash
# Debian/Ubuntu
sudo apt-mark hold hello-lab
apt-mark showhold

sudo tee /etc/apt/preferences.d/pin-hello >/dev/null <<'EOF'
Package: hello-lab
Pin: version 1.0.0-1
Pin-Priority: 1001
EOF
apt-cache policy hello-lab
```

```bash
# RHEL family
sudo dnf install -y python3-dnf-plugin-versionlock
sudo dnf versionlock add hello-lab
dnf versionlock list
```

(Use the `hello-lab` package from Tasks 5.2 and 5.7, or any installed package.)

**Verify it worked**

**Expected output** (Ubuntu):

```text
hello-lab set on hold.
hello-lab
hello-lab:
  Installed: 1.1.0-1
  Candidate: 1.0.0-1
  Version table:
 *** 1.1.0-1 500
        500 file:/srv/repo ./ Packages
        100 /var/lib/dpkg/status
     1.0.0-1 1001
        500 file:/srv/repo ./ Packages
```

AlmaLinux:

```text
Adding versionlock on: hello-lab-0:1.0.0-1.el9.*
hello-lab-0:1.0.0-1.el9.*
```

Notice the pin priority 1001 makes `apt` *prefer* 1.0.0 even if that means a downgrade. A hold
is gentler: it just freezes what is installed.

**Acceptance criteria**

- [ ] `apt upgrade` / `dnf upgrade` leaves the held package alone (the output says it was kept back).
- [ ] You can list all holds and locks.
- [ ] Each hold has a documented reason and a review date.

**Undo it**

```bash
sudo apt-mark unhold hello-lab; sudo rm /etc/apt/preferences.d/pin-hello
sudo dnf versionlock delete hello-lab          # RHEL
```

**Troubleshooting**

- A pinned package causes `unmet dependencies`: pins above 1000 can force downgrades. Prefer holds unless you need a specific source.
- Pin ignored: the file name in `preferences.d` must not contain a `.` apart from an optional `.pref`, and the `Package:` line is exact.
- `versionlock` command missing: the plugin package name differs on dnf5 (`dnf5 versionlock`).

---

## Advanced

### Task 5.7: Package in-house software properly

- **What you will learn:** instead of writing your own package manager (reinventing dependency solving is a classic mistake), ship internal software as native `.deb`/`.rpm` packages with versions, dependencies and install/upgrade/remove scripts, and let `apt`/`dnf` do the rest.
- **Target distro:** both (Debian shown; RPM equivalents use `%post`, `%preun` in the spec from Task 5.2). For many formats from one definition look at [nfpm](https://nfpm.goreleaser.com/).
- **Risk level:** `safe` in the lab repo from Task 5.2; maintainer scripts run as root, so review them like code.

Build version 1.1.0 with a `postinst` script, publish it, and upgrade:

```bash
P2=/tmp/hello-lab_1.1.0-1_all
cp -r /tmp/hello-lab_1.0.0-1_all $P2
sed -i 's/1\.0\.0-1/1.1.0-1/' $P2/DEBIAN/control
sed -i 's/1\.0\.0/1.1.0/' $P2/usr/bin/hello-lab
cat > $P2/DEBIAN/postinst <<'EOF'
#!/bin/sh
set -e
echo "hello-lab configured" >&2
exit 0
EOF
chmod 755 $P2/DEBIAN/postinst
dpkg-deb --root-owner-group --build $P2
sudo cp /tmp/hello-lab_1.1.0-1_all.deb /srv/repo/
cd /srv/repo && sudo sh -c 'dpkg-scanpackages --multiversion . > Packages && gzip -kf Packages'
sudo apt update
apt list --upgradable 2>/dev/null | grep hello-lab
sudo apt upgrade -y
hello-lab
sudo apt remove -y hello-lab
```

**Verify it worked**

**Expected output** (the key lines):

```text
Setting up hello-lab (1.1.0-1) ...
hello-lab configured
hello from hello-lab 1.1.0
```

and after `apt remove`, `dpkg -s hello-lab` reports `package 'hello-lab' is not installed`. (If `hello-lab`
still runs right after removal, your shell cached the path: run `hash -r`.)

**Acceptance criteria**

- [ ] `apt` sees 1.1.0 as an upgrade and applies it without manual steps.
- [ ] Dependencies are declared in `Depends:` and are installed automatically.
- [ ] Remove deletes the files; you know the difference between `remove` and `purge`.

**Undo it:** as in Task 5.2.

**Troubleshooting**

- `dpkg: error processing archive ... trying to overwrite`: two packages ship the same path. Fix the file list, or use `Replaces:`/`Conflicts:`.
- Maintainer script fails and blocks upgrades: `sudo dpkg --purge --force-remove-reinstreq PKG` as a last resort, then fix the script.
- Always bump the version for every change; `apt` ignores a same-version rebuild.

### Task 5.8: Detect package drift across servers

- **What you will learn:** compare installed versions with a reference list on many hosts. This is read-only reporting; do the actual fixing with Ansible ([Step 10](step-10-automation.md)) so changes are repeatable and reviewable. Running arbitrary `apt upgrade` from a loop on 50 servers is how outages happen.
- **Target distro:** both (uses `dpkg-query` or `rpm`).
- **Risk level:** `safe` (reads only). SSH needs key-based access ([Step 6](step-06-system-security.md)).

```bash
sudo tee /usr/local/bin/pkg-drift.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Compare installed package versions on this host (or over SSH) with a reference list.
# Usage: pkg-drift.sh REFERENCE_FILE [user@host]
# REFERENCE_FILE has lines "package version" for the packages you care about.
set -euo pipefail
ref="${1:?usage: pkg-drift.sh REFERENCE_FILE [user@host]}"
host="${2:-}"

installed() {
  local cmd
  if command -v dpkg-query >/dev/null; then
    cmd="dpkg-query -W -f='\${Package} \${Version}\n'"
  else
    cmd="rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}\n'"
  fi
  if [[ -n "$host" ]]; then ssh -o BatchMode=yes -- "$host" "$cmd"; else bash -c "$cmd"; fi
}

drift=0
current="$(installed | LC_ALL=C sort)"
while read -r pkg want; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  have="$(awk -v p="$pkg" '$1 == p {print $2; exit}' <<< "$current")"
  if [[ -z "$have" ]]; then echo "MISSING  $pkg (want $want)"; drift=1
  elif [[ "$have" != "$want" ]]; then echo "DIFFERS  $pkg have=$have want=$want"; drift=1
  else echo "ok       $pkg $have"; fi
done < "$ref"
exit "$drift"
EOF
sudo chmod +x /usr/local/bin/pkg-drift.sh

v=$(dpkg-query -W -f='${Version}' tree)          # RHEL: rpm -q --qf '%{VERSION}-%{RELEASE}' tree
printf '# reference\ntree %s\nbash 0.0.1\nnonexistent-pkg 1.0\n' "$v" > /tmp/ref.txt
pkg-drift.sh /tmp/ref.txt; echo "rc=$?"
for h in web1 web2; do pkg-drift.sh /tmp/ref.txt "admin@$h"; done        # many hosts
```

**Verify it worked**

**Expected output** (captured, local run):

```text
ok       tree 2.1.1-2ubuntu3.24.04.2
DIFFERS  bash have=5.2.21-2ubuntu4 want=0.0.1
MISSING  nonexistent-pkg (want 1.0)
rc=1
```

The SSH form was *not run* (needs reachable hosts), but it calls the same function remotely.

**Acceptance criteria**

- [ ] Exit code is `0` only when every listed package matches.
- [ ] `shellcheck` is clean.
- [ ] You can run it against two hosts and combine the results.

**Undo it:** `sudo rm /usr/local/bin/pkg-drift.sh /tmp/ref.txt`

**Troubleshooting**

- `Permission denied (publickey)`: `BatchMode=yes` refuses to prompt. Set up keys ([Task 6.2](step-06-system-security.md)).
- Everything `MISSING`: package names differ between distros (`apache2` vs `httpd`). Keep one reference per family.
- Epoch or release suffix differences: compare the full string from `dpkg-query`/`rpm`, as the script does.

### Task 5.9: CI for packages

- **What you will learn:** build, lint, install-test, then publish only if all steps pass. The same steps work in Jenkins, GitLab CI or GitHub Actions; this repo uses GitHub Actions, so the example is for that. Jenkins is still common in enterprises; the job body (a shell script) is identical.
- **Target distro:** Debian/Ubuntu runner (use a matching container for RPMs).
- **Risk level:** `safe`. Publishing credentials must live in repository **secrets**, never in the workflow file.

Put the build-and-test logic in a script that runs the same locally and in CI. First the inputs
(a control template with a `@VERSION@` placeholder, and the program):

```bash
mkdir -p packaging src
cat > packaging/control.in <<'EOF'
Package: hello-lab
Version: @VERSION@
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 5.0)
Maintainer: Lab Admin <lab@example.com>
Description: Tiny demo tool for the packaging lab
 Prints a greeting and its own version.
EOF
printf '#!/usr/bin/env bash\necho "hello from hello-lab 1.1.0"\n' > src/hello-lab
```

Then the script:

```bash
cat > packaging/copyright <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: 2026 Lab Admin
License: MIT
EOF
cat > ci-package.sh <<'EOF'
#!/usr/bin/env bash
# Build, lint and smoke-test hello-lab. Run inside an Ubuntu container or VM.
set -euo pipefail
version="${1:?usage: ci-package.sh VERSION}"
pkg="hello-lab_${version}-1_all"
build="$(mktemp -d)"
doc="$build/$pkg/usr/share/doc/hello-lab"
mkdir -p "$build/$pkg/DEBIAN" "$build/$pkg/usr/bin" "$doc"
sed "s/@VERSION@/${version}-1/" packaging/control.in > "$build/$pkg/DEBIAN/control"
install -m 755 src/hello-lab "$build/$pkg/usr/bin/hello-lab"
install -m 644 packaging/copyright "$doc/copyright"
printf 'hello-lab (%s-1) unstable; urgency=low\n\n  * Release %s.\n\n -- Lab Admin <lab@example.com>  %s\n' \
  "$version" "$version" "$(date -R)" | gzip -9n > "$doc/changelog.Debian.gz"
dpkg-deb --root-owner-group --build "$build/$pkg"
lintian --fail-on error "$build/$pkg.deb"
sudo dpkg -i "$build/$pkg.deb"
hello-lab | grep -q "$version"
echo "package OK: $build/$pkg.deb"
EOF
chmod +x ci-package.sh
```

A minimal GitHub Actions workflow (`.github/workflows/package.yml`; *not run here*, adapt the paths to your repo):

```yaml
name: package
on:
  push:
    tags: ["v*"]
  pull_request:
jobs:
  build:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y dpkg-dev lintian
      - run: ./ci-package.sh "1.1.0"
      - uses: actions/upload-artifact@v4
        with:
          name: hello-lab-deb
          path: /tmp/tmp.*/hello-lab_*.deb
```

**Verify it worked.** `ci-package.sh` was run in an Ubuntu 24.04 container (as root, with `sudo`
installed). The workflow YAML was *not run*.

**Expected output** (tail):

```text
W: hello-lab: initial-upload-closes-no-bugs [usr/share/doc/hello-lab/changelog.Debian.gz:1]
W: hello-lab: no-manual-page [usr/bin/hello-lab]
Setting up hello-lab (1.1.0-1) ...
package OK: /tmp/tmp.6vyhMGNdMe/hello-lab_1.1.0-1_all.deb
```

Break it on purpose: delete the `Description:` line from `packaging/control.in`. Lintian then reports
`E: hello-lab: required-field ... Description` and the script exits non-zero before installing anything.

**Acceptance criteria**

- [ ] The pipeline fails on a lint error and passes on a clean build.
- [ ] The package is installed and executed once in the pipeline, not just built.
- [ ] Publishing happens only on tags, using secrets for signing keys and upload tokens.

**Undo it:** delete the workflow file and `ci-package.sh`.

**Troubleshooting**

- `sudo: a terminal is required`: CI runners have passwordless sudo; in a plain container run as root and drop `sudo`.
- `lintian: command not found`: install it in the job before use.
- Artifact path does not match: print the real path with `echo` in the script and use that in the upload step.

---

## Step checklist

- [ ] 5.1 Install / remove
- [ ] 5.2 Build a package and a repo
- [ ] 5.3 Automated updates
- [ ] 5.4 Package cache / mirror
- [ ] 5.5 Module streams (SCL replacement)
- [ ] 5.6 Hold, pin, versionlock
- [ ] 5.7 Package in-house software
- [ ] 5.8 Package drift report
- [ ] 5.9 CI pipeline

## Further reading

- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/): how to package software the Debian way.
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/): spec files and rpmbuild from scratch.
- [Debian Wiki: SecureApt](https://wiki.debian.org/SecureApt): how repository signing works and how to do it right.
- [Red Hat: Managing software with the DNF tool](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/managing_software_with_the_dnf_tool/index): modules, versionlock and repositories on RHEL 9.

**Next:** [Step 6: System Security](step-06-system-security.md)
