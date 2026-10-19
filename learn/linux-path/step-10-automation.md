# Step 10: Automation

> **Time:** ~8-10 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 1](step-01-linux-fundamentals.md), [Step 4](step-04-shell-scripting.md), [Step 6](step-06-system-security.md) · **Next:** [Step 11: Virtualization and Containers](step-11-virtualization-and-containers.md)

<!-- -->

> [!WARNING]
> Automation can make the same mistake on many machines at once. Test every playbook, module, or Terraform plan on a throwaway VM or container first, and always run `terraform plan` (or `ansible-playbook --check`) before `apply`/`--diff`. Never hard-code real passwords — use vaults or secrets.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task). Cron and systemd-timer tasks ran in Ubuntu 24.04/AlmaLinux 9 containers. Ansible playbooks were syntax-checked; `ansible-playbook` against a real host is *typical output*. Terraform and GitHub Actions are described from documentation and marked *typical output* (they need cloud credentials or a GitHub repository).

---

## Beginner

### Task 10.1: Schedule a job with `cron`

- **What you will learn:** the five time fields, editing a user crontab, absolute paths, and mailing/output redirection.
- **Target distro:** both. Service: `cron` (Debian/Ubuntu) or `crond` (RHEL; package `cronie`).
- **Risk level:** `safe` (the job below only appends to a log in your home).

```bash
# Make sure cron is installed and running
sudo systemctl enable --now cron        # RHEL: sudo systemctl enable --now crond
systemctl is-active cron || sudo systemctl start cron

# A tiny job: append the current date to a log every minute
echo '* * * * * /bin/date >> ~/cron-test.log 2>&1' | crontab -
crontab -l
sleep 65
tail -n 3 ~/cron-test.log
```

**Verify it worked:** `~/cron-test.log` gains a new line about once a minute after you install the crontab.

*Typical output:* three lines like `Sun Oct 18 00:01:00 UTC 2026`.

**Acceptance criteria:**

- [ ] `crontab -l` shows your job.
- [ ] The log file gains a new line within a minute or two.

**Undo it**

```bash
crontab -r
rm -f ~/cron-test.log
```

**Troubleshooting:**

- Job never runs: cron service not enabled/started, or the command uses a relative path — use `/bin/date`, not `date`.
- Empty output: cron's `PATH` is tiny; always use absolute paths and redirect stderr (`2>&1`).
- Percent sign `%` in the command: cron treats it as a newline; escape it as `\%`.

### Task 10.2: Schedule a job with a systemd timer

- **What you will learn:** a `.service` (oneshot) plus a `.timer`, `OnCalendar`, `Persistent=`, and why timers beat cron for system services (journald logging, dependencies, retries).
- **Target distro:** both (systemd).
- **Risk level:** `safe` (the job below only touches a file in your home).

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/daily-report.service <<'EOF'
[Unit]
Description=Daily report job

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "$(date): daily report" >> ~/timer-test.log'
EOF

cat > ~/.config/systemd/user/daily-report.timer <<'EOF'
[Unit]
Description=Run daily-report.service every 5 minutes for the lab

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now daily-report.timer
systemctl --user list-timers --all | grep daily-report
```

Wait a few minutes, then:

```bash
journalctl --user -u daily-report.service -n 5 --no-pager
tail -n 3 ~/timer-test.log
```

**Verify it worked:** `list-timers` shows `daily-report.timer`, and `journalctl` shows the service ran.

**Acceptance criteria:**

- [ ] `systemctl --user list-timers` lists the timer with a future next-run.
- [ ] `journalctl --user -u daily-report.service` shows at least one successful run.

**Undo it**

```bash
systemctl --user disable --now daily-report.timer
rm ~/.config/systemd/user/daily-report.service ~/.config/systemd/user/daily-report.timer
systemctl --user daemon-reload
rm -f ~/timer-test.log
```

**Troubleshooting:**

- Timer never fires: `Persistent=true` means missed runs catch up at boot; check `systemctl --user status daily-report.timer`.
- User services die at logout: run `sudo loginctl enable-linger "$USER"` so the user manager survives.
- `ExecStart` not found: use an absolute path (`/bin/sh`, `/usr/bin/date`).

> **cron vs systemd timer — choose:** cron for simple per-user recurring commands; systemd timers when you want journald logging, dependency ordering, missed-run catch-up, or integration with the rest of systemd.

### Task 10.3: Ansible basics

- **What you will learn:** inventory, ad-hoc commands, and a playbook that installs a package and starts a service — idempotently.
- **Target distro:** both (Ansible is control-machine only; target needs Python and SSH). Install: `sudo apt install -y ansible` / `sudo dnf install -y ansible` (EPEL).
- **Risk level:** `safe` for read-only/ad-hoc; `destructive` if a playbook rewrites configs or removes packages — use `--check` first.

Inventory (`~/lab/hosts`):

```ini
[lab]
127.0.0.1 ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

Ad-hoc (ping every host):

```bash
ansible all -i ~/lab/hosts -m ping
```

Playbook (`~/lab/uptime.yml`) — installs nothing risky, just gathers facts:

```yaml
---
- hosts: lab
  become: false
  tasks:
    - name: Show OS and uptime
      ansible.builtin.debug:
        msg: "Host {{ ansible_hostname }} is {{ ansible_distribution }} {{ ansible_distribution_version }}; uptime {{ ansible_uptime.seconds }} seconds"
```

Run:

```bash
ansible-playbook -i ~/lab/hosts ~/lab/uptime.yml
```

*Typical output:* `ok: [127.0.0.1] => { "msg": "Host ... is Ubuntu 24.04 ...; uptime N seconds" }`.

**Verify it worked:** `ansible all -m ping` returns `pong`; `ansible-playbook` ends with `ok=1 changed=0`.

**Acceptance criteria:**

- [ ] `ansible -m ping` reaches the host.
- [ ] The playbook runs with `changed=0` on the second run (idempotent).

**Undo it:** `rm -rf ~/lab/hosts ~/lab/uptime.yml`; uninstall ansible if you no longer need it.

**Troubleshooting:**

- `Host key verification failed`: add `HostKeyChecking=false` in `ansible.cfg`, or `ssh-copy-id` your key to the target first.
- `Python is not installed`: the target needs `/usr/bin/python3` (set `ansible_python_interpreter`).
- `Permission denied` on `become`: the remote user needs passwordless `sudo` or you must pass `--ask-become-pass`.

### Task 10.4: Terraform basics

- **What you will learn:** declare a provider, write a resource, and the `init → plan → apply → destroy` workflow. *Typical output: not run here — it needs cloud credentials (or a local provider).*
- **Target distro:** both (the `terraform` binary is the same; download from HashiCorc or install via package).
- **Risk level:** `destructive` — `apply` creates real resources that can cost money; `destroy` deletes them. Always `plan` first.

```hcl
# ~/lab/main.tf  (example: a local file resource, no cloud)
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

resource "local_file" "note" {
  content  = "managed by terraform"
  filename = "${path.module}/terraform-note.txt"
}
```

```bash
terraform init
terraform plan        # read this: what will be created/changed/destroyed
terraform apply       # type yes when prompted
cat terraform-note.txt
terraform destroy     # clean up; type yes
```

**Verify it worked (typical):** `terraform plan` shows `+ local_file.note`; `apply` reports `Apply complete! Resources: 1 added, 0 changed, 0 destroyed`.

**Acceptance criteria:**

- [ ] `terraform plan` shows no surprises before you apply.
- [ ] `apply` creates exactly the resources you intended.
- [ ] `destroy` removes them and `terraform show` is empty.

**Undo it:** `terraform destroy`, then `rm -rf ~/lab/.terraform terraform.tfstate* main.tf`.

**Troubleshooting:**

- `plan` wants to recreate everything: you changed a `count` or `for_each`, or the provider version changed — read the plan, don't blindly apply.
- Credentials rejected: set them via environment variables (`AWS_ACCESS_KEY_ID`, etc.) or a provider config, never committed to Git.
- State drift: someone edited the resource outside Terraform; `terraform plan` shows the difference — decide whether to adopt or revert.

### Task 10.5: GitHub Actions for shell projects (worked example: this repo's CI)

- **What you will learn:** a workflow that shellchecks and runs tests on every push and pull request, using this repository as the example.
- **Target distro:** the workflow runs on GitHub-hosted `ubuntu-latest` runners.
- **Risk level:** `safe` (reads the repo; the workflow here only lints and tests).

This repository's CI runs under `.github/`. The worked example below mirrors it: on every push/pull request it checks out the code, installs shellcheck/shfmt/bats, lints `lib` and `projects`, and runs the Bats suite.

```yaml
# .github/workflows/ci.yml  (this repo's real workflow; mirrored here as an example)
name: CI
on: [push, pull_request]
jobs:
  shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y shellcheck shfmt bats jq
      - run: shellcheck -x lib/**/*.sh projects/**/*.sh
      - run: shfmt -d -i 4 -ci lib projects tests/test_helper.bash
      - run: bats --timing tests/
```

See the live file: [`.github/`](https://github.com/akintunero/Linux-Projects/tree/main/.github) — this repository's continuous integration, which verifies every shell script with ShellCheck, shfmt and Bats on each change.

**Verify it worked (typical):** open the "Actions" tab of this repo on GitHub; the latest run shows all jobs green. A failing job lists the exact script and ShellCheck warning.

**Acceptance criteria:**

- [ ] You can point at a green CI run for this repo.
- [ ] You can add a new `.sh` under `lib/` or `projects/` and the lint job still passes locally (`shellcheck -x` and `shfmt -d`).

**Undo it:** none (CI is read-only verification).

**Troubleshooting:**

- Workflow won't run: it must live at `.github/workflows/*.yml` on the default branch, and Actions must be enabled for the repository.
- `shellcheck` fails on a new script: fix the warning locally, then push; the CI job will turn green.

---

## Step checklist

- [ ] 10.1 cron job installed and firing
- [ ] 10.2 systemd timer installed and logged in the journal
- [ ] 10.3 Ansible inventory + playbook run with `changed=0`
- [ ] 10.4 `terraform init → plan → apply → destroy` (typical output OK)
- [ ] 10.5 You can point at this repo's green CI run

## Further reading

- [crontab(5)](https://man7.org/linux/man-pages/man5/crontab.5.html): the five time fields and special strings (`@daily`, `@hourly`).
- [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html): `OnCalendar`, `Persistent=`, and timer options.
- [Ansible documentation](https://docs.ansible.com/): inventory, modules, and playbook language.
- [Terraform getting started](https://developer.hashicorp.com/terraform/tutorials): `init`, `plan`, `apply`, `destroy`.
- [GitHub Actions docs](https://docs.github.com/en/actions): workflow syntax and the `actions/checkout` action.
- [This repo's CI](https://github.com/akintunero/Linux-Projects/actions): the worked example of linting and testing shell scripts on every change.

**Next:** [Step 11: Virtualization and Containers](step-11-virtualization-and-containers.md)
