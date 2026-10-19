# Day 05: Editing Files With nano and vim

> **Time:** ~60 min · **Level:** Beginner
> **Prerequisites:** [Day 04](day-04.md)

## Goal

By the end of this lesson you can:

- Open, edit, save and quit in `nano` and in `vim` without getting stuck.
- Search, replace and delete lines in vim, and make the same edit non-interactively with `vim -es`.
- Set a default editor, and edit protected files (`sudoedit`, `visudo`) the safe way.

## Concepts

Almost all Linux configuration is plain text, so editing it comfortably is a core skill. You will meet two editors on servers: `nano` (simple) and `vim` (everywhere, `vi` is nearly always present).

### nano: the menu is at the bottom

`^` means Ctrl. Open with `nano notes.txt`.

| Keys | Action |
|------|--------|
| `Ctrl+O`, Enter | write out (save) |
| `Ctrl+X` | exit (asks to save if you have unsaved changes) |
| `Ctrl+W` | search |
| `Ctrl+K` / `Ctrl+U` | cut line / paste |
| `Ctrl+_` | go to line number |

### vim: modes

vim has *modes*. Getting stuck is almost always being in the wrong one.

| Mode | How to enter | Used for |
|------|--------------|----------|
| Normal | `Esc` | moving and commands |
| Insert | `i` (before cursor), `a` (after), `o` (new line below) | typing text |
| Command-line | `:` from Normal | save, quit, search and replace |

Survival kit, typed in **Normal** mode:

| Keys | Action |
|------|--------|
| `:w` Enter | save |
| `:wq` or `ZZ` | save and quit |
| `:q!` Enter | quit and throw changes away |
| `u` / `Ctrl+R` | undo / redo |
| `dd` / `yy` / `p` | delete line / copy line / paste |
| `/text` Enter, `n` | search, next match |
| `:%s/old/new/g` | replace every `old` in the file |
| `:g/^#/d` | delete every line that starts with `#` |
| `gg` / `G` / `:42` | top / bottom / line 42 |

Stuck? Press `Esc` twice, then type `:q!` and Enter.

### Default editor

Programs such as `git commit`, `crontab -e` and `visudo` start whatever `$EDITOR` names:

```bash
export EDITOR=nano          # for this shell; put it in ~/.bashrc to keep it
```

Debian/Ubuntu can also set a system choice with `sudo update-alternatives --config editor`. RHEL-family systems use `$EDITOR` / `$VISUAL` only.

### Editing root-owned files safely

> [!WARNING]
> Do not open files such as `/etc/sudoers` with a plain `sudo nano`. A syntax error can lock you out of
> `sudo`. Use `sudo visudo`, which checks the file before saving, and `sudoedit /etc/hosts` (or
> `sudo -e`) to edit a copy as yourself and install it afterwards.

**Undo:** before editing any file in `/etc`, copy it: `sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.orig`.

## Worked example

Scenario: a config file needs three changes. First you do them by hand in vim; then you do the same thing with a one-liner you could put in a script.

Create the file:

```bash
cd "$(mktemp -d)"
printf 'server=old.example.com\nport=80\n# comment\nbackup_port=8080\n' > app.conf
```

**By hand** (try it once): `vim app.conf`, then in Normal mode type `:%s/old/new/` Enter, `:g/^#/d` Enter, `:wq` Enter.

**Without opening a screen**, `vim -es` runs the same ex commands silently. Each `-c` is one command and `wq` saves:

```bash
vim -es -c '%s/old/new/' -c 'wq' app.conf; echo "rc=$?"
cat app.conf
```

**Expected output:**

```text
rc=0
server=new.example.com
port=80
# comment
backup_port=8080
```

Now change the port, but only the standalone `80`. A naive `%s/80/8080/` would also turn `8080` into `808080`. `\<` and `\>` match word boundaries:

```bash
vim -es -c 'g/^#/d' -c '%s/\<80\>/8080/' -c 'wq' app.conf
cat app.conf
```

**Expected output:**

```text
server=new.example.com
port=8080
backup_port=8080
```

Finally, run a Normal-mode command on every line with `:normal`; here `A;` appends a semicolon:

```bash
vim -es -c '%normal A;' -c 'wq' app.conf
cat app.conf
```

**Expected output:**

```text
server=new.example.com;
port=8080;
backup_port=8080;
```

**Undo:** the edits are in place, so keep a copy first: `cp -p app.conf app.conf.bak`. Restore with `mv app.conf.bak app.conf`.

## Common mistakes

| Mistake | Why it fails | Fix |
|---------|--------------|-----|
| Typing text in vim and nothing appears, or commands insert letters | Wrong mode | `Esc`, then `i` to type |
| Can't quit vim | Unsaved changes or you are in Insert mode | `Esc`, then `:wq` or `:q!` |
| `:%s/80/8080/` damages `8080` | Pattern matches inside other numbers | Use `\<80\>` word boundaries |
| `vim -es ...` changes nothing | No `wq`: silent mode never saves on its own | End with `-c 'wq'` |
| `sudo nano /etc/sudoers` | No syntax check; one typo breaks sudo | `sudo visudo` |
| Only the first match per line changes | Missing `g` flag | `:s/x/y/g` |

## Exercises

Reference solutions: [`solutions/day-05/`](solutions/day-05/). The scripts use `vim -es` so they can run without a keyboard; do the interactive version by hand first.

### Easy

Using nano, create `notes.txt` with three lines: `buy milk`, `call Sam`, `read man page for tar`. Save and exit.

**Acceptance criteria:**

- `wc -l < notes.txt` prints `3`.
- `grep -x 'call Sam' notes.txt` succeeds.

### Medium

Given `app.conf` with lines `server=app.example.com`, `port=80`, `# old setting`, `backup_port=8080`: change `port` to `8080` without touching `backup_port`, and delete the comment line.

**Acceptance criteria:**

- The file contains exactly `port=8080` and `backup_port=8080` (and no `808080`).
- No line starts with `#`.

### Hard

Write `tidy.sh FILE` that saves `FILE.bak`, deletes comment and blank lines, and makes every remaining line end in exactly one `;`. It must be safe to run twice.

**Acceptance criteria:**

- Input `# header`, `server=a`, blank line, `port=80;` becomes `server=a;` and `port=80;`.
- `FILE.bak` still contains `# header`.
- A second run produces identical output; a missing file gives an error and non-zero status.

### Break it

[`solutions/day-05/break-it.sh`](solutions/day-05/break-it.sh) should turn every standalone `80` into `8080` in `app.conf`. It has three bugs.

**Acceptance criteria:** the result is `port=8080`, `backup_port=8080`, `proxy=8080 8080`, and the file on disk (not just the buffer) has changed.

## Solutions

<details>
<summary>Easy</summary>

Interactive: `nano notes.txt`, type the lines, `Ctrl+O`, Enter, `Ctrl+X`. Scripted equivalent:

```bash
printf 'buy milk\ncall Sam\nread man page for tar\n' > notes.txt
```

Script: [`easy.sh`](solutions/day-05/easy.sh).

</details>

<details>
<summary>Medium</summary>

Interactive: `vim app.conf`, then `:%s/\<80\>/8080/g` Enter, `:g/^#/d` Enter, `:wq` Enter.

```bash
vim -es -c '%s/\<80\>/8080/g' -c 'g/^#/d' -c 'wq' app.conf
```

Script: [`medium.sh`](solutions/day-05/medium.sh).

</details>

<details>
<summary>Hard</summary>

```bash
cp -p -- "$f" "$f.bak"
vim -es -c 'g/^\s*#/d' -c 'g/^\s*$/d' -c '%s/;*$/;/' -c 'wq' -- "$f"
```

`;*$` matches zero or more semicolons at the end of a line and replaces them with exactly one, which is what makes it idempotent. Script with `--self-test`: [`hard.sh`](solutions/day-05/hard.sh).

</details>

<details>
<summary>Break it</summary>

1. No `-c 'wq'`: nothing is written to disk.
2. `80` also matches inside `8080`; use `\<80\>`.
3. Without `g`, only the first `80` on `proxy=80 80` changes.

Fixed script: [`break-it.fixed.sh`](solutions/day-05/break-it.fixed.sh).

</details>

## Self-check

1. How do you leave vim and discard your changes?
2. What do `i` and `Esc` do?
3. Why use `visudo` instead of `sudo nano /etc/sudoers`?
4. What does `:g/^#/d` do?
5. How do you make `crontab -e` open nano?

<details>
<summary>Answers</summary>

1. `Esc`, then `:q!` and Enter.
2. `i` enters Insert mode so you can type; `Esc` returns to Normal mode.
3. `visudo` validates the file before installing it, so a typo cannot lock you out.
4. Deletes every line that begins with `#`.
5. `export EDITOR=nano` before running it (or put that line in `~/.bashrc`).

</details>

## Cheat sheet

```text
nano:  Ctrl+O save · Ctrl+X exit · Ctrl+W search · Ctrl+K cut line · Ctrl+U paste
vim:   Esc normal · i insert · :w save · :wq save+quit · :q! discard · u undo
       /text search · :%s/old/new/g replace all · :g/^#/d delete comment lines
```

```bash
export EDITOR=nano                      # default editor for this shell
sudoedit /etc/hosts                     # edit a root file as yourself
sudo visudo                             # edit sudoers with validation
vim -es -c '%s/a/b/g' -c 'wq' FILE      # scripted edit
```

## Further reading

- [GNU nano documentation](https://www.nano-editor.org/docs.php): official manual and a list of every key binding.
- [Vim user manual: usr_01](https://vimhelp.org/usr_01.txt.html): the official tutorial-style manual, starting from the basics.
- [sudoers manual](https://www.sudo.ws/docs/man/sudoers.man/): what `visudo` is protecting; syntax of every rule.
- [Bash Day 03](../30-days-of-bash/day-03.md): once you edit scripts daily, quoting matters.

**Next:** [Day 06](day-06.md)
