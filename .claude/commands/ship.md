---
name: ship
description: Squash-merge the current branch to main on GitHub, then recreate the branch from main's new tip so the user can keep working on the same branch name with a clean tree.
---

You are running the user's `/ship` workflow.

Context — this is a solo knowledge repo where the working branch is treated as a disposable line off `main`. History up to now is "v1" and never reverted. The user thinks of this as "push to github", which actually means: land everything on `main` via PR + squash, then come back to the working branch ready for the next chunk of work.

## Safety rails (NON-NEGOTIABLE)

Refuse with a clear reason and stop if ANY of these hold:

1. Current branch is `main` (nothing to ship; abort).
2. Working tree has uncommitted changes — print `git status` and stop. Tell the user to commit (or stash) first.
3. `git log origin/main..HEAD` is empty after `git fetch origin --prune` — nothing new vs main; abort.
4. `gh auth status` is not authenticated — tell the user to run `gh auth login`; abort.

Never use `--force`, `--force-with-lease`, `--no-verify`, `--no-gpg-sign`, or `git config` mutations. The flow below doesn't need any of them because the GitHub branch is deleted on merge and then recreated cleanly.

## Shell quirks

This is PowerShell. Use `;` to separate commands, not `&&`. Check `$LASTEXITCODE` between every git/gh step and stop on the first non-zero. Long commands → use a single Shell tool call per logical step, not chained.

## Steps

1. **Capture state.** Run:
   - `git rev-parse --abbrev-ref HEAD` → `$BRANCH`
   - `git fetch origin --prune`
   - `git status --porcelain`
   - `git log --oneline origin/main..HEAD`
   - `gh auth status`

   Apply the safety rails above. If anything aborts, show the user what's blocking and stop.

2. **Confirm.** Show the user the list of commits about to be squashed onto main (`git log --oneline origin/main..HEAD`) and ask via AskQuestion: "Squash-merge these N commits onto main?" with options `Ship it` / `Cancel`. If cancelled, stop cleanly.

3. **Push the branch** so origin has the latest commits: `git push origin HEAD`.

4. **Find or create the PR:**
   - `gh pr view --json number,state,url,title` to check for an existing PR on this branch.
   - If none open, create one: `gh pr create --base main --head $BRANCH --fill`. With `--fill`, the title and body come from the latest commit; for a single-commit branch this is ideal. For a multi-commit branch, the title is the latest commit subject — if that doesn't summarize the whole branch well, after `gh pr create` ask the user (one AskQuestion) whether to keep the auto-title or edit it; if edit, prompt for a new title and run `gh pr edit $BRANCH --title "<new title>"` before merging.

5. **Squash-merge + delete remote branch** in one shot:
   `gh pr merge $BRANCH --squash --delete-branch`

6. **Sync local main:**
   - `git fetch origin --prune` (drops the now-deleted remote ref)
   - `git checkout main`
   - `git pull --ff-only origin main`

7. **Recreate the working branch from new main:**
   - `git checkout -B $BRANCH` (recreates locally pointing at the new main tip)
   - `git push -u origin $BRANCH` (recreates on origin — normal push, no force, because the remote branch was deleted in step 5)

8. **Final summary.** Print:
   - `git log --oneline -5`
   - `git status -sb`
   - The PR URL captured from step 4/5

9. **Tell the user, one line:**
   `Shipped <BRANCH> → main as squash commit <short SHA> (PR #N: <url>). Branch recreated from main; you're on <BRANCH>, tree clean.`

## What NOT to do

- Don't ask the user permission for individual git/gh sub-steps after the single confirmation in step 2.
- Don't try to "preserve" the per-commit history on main — squash is intentional.
- Don't leave the user on `main`; they always end on `$BRANCH`.
- Don't commit anything that isn't already committed when `/ship` starts — that's safety rail #2's job.
