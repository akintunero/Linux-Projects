# Content Style Guide

Every lesson in this repository follows this standard. The goal: a learner who
has never opened a terminal can work through the material alone, safely, and
know at each step whether they got it right.

## Principles

1. **Learn by doing.** Every concept is followed by something to type and an
   expected result.
2. **Safe by default.** Anything that can break a system, lock you out, or
   delete data carries a warning *before* the command and an undo step *after*.
3. **Correct habits from day one.** Examples use `[[ ]]`, quoted variables,
   `read -r`, `set -euo pipefail` (from the lesson that introduces it), and
   pass `shellcheck`.
4. **Real-world scenarios.** Prefer "rotate a log file" over "print a
   multiplication table".
5. **Verifiable.** Exercises state acceptance criteria; solutions exist and are
   tested.

## Formatting rules

- Code goes in fenced blocks with a language tag: ` ```bash `, ` ```text `
  for expected output, ` ```ini ` / ` ```yaml ` for config files.
- Shell prompts are not part of copy-pasteable blocks. Show output in a
  separate ` ```text ` block labelled **Expected output**.
- Lines wrap at about 100 characters in prose. One sentence per idea.
- File names: lowercase kebab-case (`day-05.md`), `README.md` for indexes.
- Callouts use GitHub alert syntax: `> [!WARNING]`, `> [!TIP]`, `> [!NOTE]`.
- Links must work. Prefer official docs (man7.org, GNU manuals, distro docs)
  over blog posts and videos. Every external link gets a one-line description
  of what the reader will find there.

## Daily lesson template (`learn/30-days-of-bash`, `learn/linux-in-20-days`)

```markdown
# Day NN: Title

> **Time:** ~45 min · **Level:** Beginner/Intermediate/Advanced
> **Prerequisites:** [Day NN-1](day-NN-1.md) (or "none")

## Goal
By the end of this lesson you can: (3 bullets, each verifiable)

## Concepts
Short explanations. Each new idea is followed immediately by a runnable example.

## Worked example
A realistic mini-scenario built up step by step, with Expected output.

## Common mistakes
| Mistake | Why it fails | Fix |
|---------|--------------|-----|

## Exercises
### Easy
### Medium
### Hard
Each exercise: task, input/constraints, and **Acceptance criteria**.

### Break it
A short script containing 1-3 bugs. The learner finds and fixes them.

## Solutions
<details>
<summary>Easy</summary>

(solution walk-through; full scripts live in `solutions/day-NN/`)

</details>

## Self-check
5 quick questions. Answers collapsed in `<details>`.

## Cheat sheet
The 5-10 commands or syntax forms from this lesson.

## Further reading
- [Title](url): one line describing what you will learn there.

**Next:** [Day NN+1](day-NN+1.md)
```

## Solutions layout

```text
learn/30-days-of-bash/solutions/day-05/easy.sh
learn/30-days-of-bash/solutions/day-05/medium.sh
learn/30-days-of-bash/solutions/day-05/hard.sh
learn/30-days-of-bash/solutions/day-05/break-it.fixed.sh
```

Solutions must pass `shellcheck` (see `.shellcheckrc`) and run on Bash 4.4+.
Scripts that need root or touch the system must say so in a header comment and
be exercised only inside the devcontainer.

## Step template (`learn/linux-path`)

Each task inside a step has:

1. **What you will learn**
2. **Target distro** (Debian/Ubuntu, RHEL family, or both with tabs)
3. **Risk level** (`safe`, `can lock you out`, `destructive`) and warning
4. **Commands** (copy-pasteable)
5. **Verify it worked** (command + expected output)
6. **Undo it**
7. **Troubleshooting** (top 2-3 errors)

Steps with risky tasks open with:

> [!WARNING]
> Do this in a throwaway VM or the devcontainer, never on a machine you cannot
> afford to lose. Keep a second SSH session open while changing SSH or firewall
> settings.

## Review checklist

- [ ] Every code block is fenced and tagged
- [ ] Every command was run and the output pasted is real
- [ ] `shellcheck` is clean on all `.sh` and extracted snippets
- [ ] Links return HTTP 200
- [ ] Warnings and undo steps present for risky actions
- [ ] No claims the repo does not back up
