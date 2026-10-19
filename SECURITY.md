# Security Policy

## Scope

This repository teaches Linux administration, including security hardening. The
scripts under `projects/` can change users, groups, containers and files on the
machine that runs them. A flaw in a script, or an unsafe instruction in a
lesson, is in scope. Examples:

- A script that can be made to run attacker-controlled commands.
- A lesson that would lock learners out of their system, expose a service, or
  weaken security without a warning and an undo step.
- Secrets or personal data committed to the repository.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Use GitHub's private reporting:
**Security → Advisories → Report a vulnerability** on this repository.

Include the file, what you did, what happened and what you expected. You will
get a first reply within 7 days.

## Supported versions

Only the `main` branch is maintained.

## Safe practice for learners

- Run lessons in the provided devcontainer or a throwaway VM, not on a machine
  you rely on.
- Read a script before you run it with `sudo`.
- Use `--dry-run` where a script offers it (`usermgmt.sh`, `docker-manager.sh`).
- Never type real passwords as command-line arguments: they appear in `ps` and
  shell history.
