# User and group management

One validated command, `usermgmt.sh`, wraps the standard `useradd`, `usermod`, `userdel`, `groupadd`
and `groupdel` tools. It replaces twelve near-identical scripts and fixes their common flaws:
unquoted variables, passwords passed as arguments, and no input validation.

> [!WARNING]
> Almost every command changes accounts and needs root. Practise in a VM or the
> [dev container](../../setup/README.md), and **always run with `--dry-run` first**.

## Usage

```bash
./usermgmt.sh --dry-run create-user alice      # prints the command, changes nothing
sudo ./usermgmt.sh create-user alice           # prompts for a password (hidden)
printf '%s\n' "$PW" | sudo ./usermgmt.sh create-user bob --password-stdin
sudo ./usermgmt.sh add-to-group alice docker
sudo ./usermgmt.sh lock-user alice
sudo ./usermgmt.sh unlock-user alice
sudo ./usermgmt.sh set-expiry alice 2030-01-31
sudo ./usermgmt.sh delete-user alice
./usermgmt.sh list-users
```

Dry-run output shows exactly what would run:

```text
+ useradd -m -s /bin/bash -- alice
+ usermod -a -G docker -- alice
```

| Old script | New command |
|------------|-------------|
| `create_user.sh` | `create-user NAME [--shell S] [--no-home]` |
| `delete_users.sh` | `delete-user NAME [--keep-home]` |
| `change_user_password.sh` | `set-password NAME` |
| `lock_user_account.sh` / `unlock_user_account.sh` | `lock-user` / `unlock-user` |
| `set_user_expiry.sh` | `set-expiry NAME YYYY-MM-DD` (`never` clears it) |
| `modify_user_home.sh` | `set-home NAME /new/home [--move]` |
| `list_users.sh` | `list-users` |
| `create_group.sh` / `delete_group.sh` | `create-group` / `delete-group` |
| `add_user_to_group.sh` | `add-to-group USER GROUP` |
| `list_group.sh` | `list-groups USER` |

## Safety built in

- **Dry run.** `--dry-run` never needs root and never changes anything.
- **No passwords in arguments.** They would be visible in `ps` and shell history. Use the prompt or
  `--password-stdin`; dry-run output never echoes the password.
- **Validated names.** Only `[a-z_][a-z0-9_-]{0,31}`. Anything like `-rf`, `a;b` or `../etc` is refused.
- **`root` and system accounts are protected.** `root` is always refused; accounts with UID below 1000
  need `--force`.
- **`usermod -a -G`.** The `-a` matters: without it `usermod` *replaces* all of a user's groups.
- **Undo.** Lock has unlock; set-expiry has `never`; set-home can `--move` the files.

## Run the tests

The suite uses `--dry-run` only, so it is safe anywhere and needs no root:

```bash
bats ../../tests/usermgmt.bats
```

## Exercises

1. **Easy.** Add `show-user NAME` that prints `id`, shell, home and expiry (`chage -l`).
2. **Medium.** Add `create-user --from-file users.csv` to create many users in one go, with a
   dry-run preview.
3. **Hard.** Add `audit` that reports accounts with empty passwords, UID 0 duplicates and users with a
   login shell but no password aging.
