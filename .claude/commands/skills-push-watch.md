---
description: Watch DataPlatform PRs opened by /skills-push, auto-fix mechanical CI failures, route everything else to inbox + sub-agent diff proposal you approve before push.
---

# /skills-push-watch — Babysit DataPlatform PRs

You are running the user's `/skills-push-watch` loop. This command drains
`audits/babysit/queue.txt` (populated by `/skills-push` Phase 8) and watches
each PR through the `tools/babysit_dp_pr.py` poller. The poller auto-fixes one
class of failure (pr-title-checker) and routes everything else to an inbox
under `audits/babysit/inbox/`. Your job is to handle the inbox items by
proposing diffs via a sub-agent that the user approves before push.

## When this command activates

- The user runs `/skills-push-watch` (with or without a PR number).
- The user says "babysit the PR", "drain the babysit queue", "watch the
  skills-push PR", "check on the DA-xxxx PR".
- The user references a PR number AND a recently-opened skills-push PR is in
  the queue.

## v1 scope (locked 2026-06-09)

- AUTO-FIX inside the poller: **pr-title-checker only.** The poller re-applies
  the rename via `gh api -X PATCH` (same recipe as `skills-push` Phase 7 Step 5).
- Everything else: poller writes to `audits/babysit/inbox/{PR}_{check}_{ts}.json`
  (and `.log` if a workflow log tail is available) and exits with code 2.
  You then spawn a sub-agent per inbox item to **propose a minimal patch**.
  You do NOT push without explicit user approval of each diff. The user
  approves each diff in chat before push.
- Time budget per PR: 6 iterations, 90 minutes wall-clock. Don't override
  without asking the user first.
- The poller never merges. You never merge. The reviewer merges.

## Workflow

### Step 1 — Resolve arguments

Parse the user's prompt:

- If they passed a PR number (`#3897`, `3897`, `pr/3897`), watch only that one
  → run `python tools/babysit_dp_pr.py --pr <N>`.
- If they passed `--once`, append `--once` to the script invocation (one
  classification pass, no polling sleep — useful for probes).
- Otherwise drain the queue → run `python tools/babysit_dp_pr.py`.

If `audits/babysit/queue.txt` is empty AND no `--pr` was passed, tell the user
the queue is empty and stop. Don't go hunting for PRs to watch.

### Step 2 — Surface the heartbeat

Before running the poller, tell the user one line:

```
Babysitting DataPlatform PR(s). Poller logs every iteration; expect 60s
between status checks. Auto-fix is title-checker only — everything else
will pause for your review.
```

### Step 3 — Run the poller and read its exit code

```powershell
python tools/babysit_dp_pr.py [args]
```

The script may run up to 90 minutes — set `block_until_ms: 180000` (the
no-silent-idle ceiling). If the script is still running when 3 min elapses,
surface a one-line progress note ("still polling, last iter was X") and
continue. Repeat if needed.

Map exit codes:

| code | meaning | next step |
|---|---|---|
| 0 | Ready to merge — all checks green, no blocking reviews | Print success summary, stop. Do NOT merge. |
| 2 | Human-required — inbox items written | Go to Step 4 |
| 3 | Thrashing — same failure signature after a push | Stop. Print state file path. Ask user how to proceed. |
| 4 | Budget — iterations or wall-clock | Stop. Print state file path. Ask if they want to extend or step in. |
| 5 | Fatal — gh CLI error, PR not found | Stop. Surface the error verbatim. |

### Step 4 — Handle inbox items (only on exit 2)

For each `audits/babysit/inbox/*.json` file that:
1. Has `pr_number` matching a PR processed in this run, AND
2. Does NOT have a sibling `<stem>.processed` marker file,

do the following per file:

**4a. Read the inbox json + the log tail (if `<stem>.log` exists).**

**4b. Spawn a sub-agent via the `Task` tool with `subagent_type: generalPurpose`** and the following prompt template:

```
You are a verifier-and-fixer sub-agent for a DataPlatform skills-push PR.
DO NOT push. DO NOT modify the DataPlatform repo. Return only a unified
diff and a one-line justification, in JSON, with this shape:

{
  "verdict": "fixable" | "needs-human" | "ignore-flaky",
  "justification": "one sentence on why",
  "diff": "<unified diff applied at repo root, OR empty string if not fixable>",
  "target_repo": "DataPlatform" | "Databricks_Knowledge",
  "follow_up_commit_subject": "DA-XXX <short imperative subject>"
}

INPUTS:
- PR: #{pr_number} - {pr_title}
- Failing check: {check_name} ({check_conclusion})
- Check log tail (200 lines): <inlined from .log file or null>
- Inbox json: <inlined from .json file>
- Skill-creator CI rules: read DataPlatform/databricks/data-skills/skills/skill-creator/SKILL.md
- /skills-push rules: read .cursor/skills/skills-push/SKILL.md

RULES:
- A "fixable" verdict means the failure is mechanical (validator regex,
  missing section, formatter) AND the diff resolves it without changing
  the user-intended skill content.
- A "needs-human" verdict means the failure reflects a content judgement
  (description quality, scope of the skill, table selection) that the
  user must make.
- A "ignore-flaky" verdict means the check is known-flaky (transient
  network, runner outage) and a re-run is the right action.
- Read the actual files via Read before writing the diff. Do not guess
  what's in skill-creator/SKILL.md.
- Diff must apply cleanly with `git apply --check` at the repo root of
  the named target_repo.
```

**4c. Read the sub-agent's JSON response.** Surface a brief summary to the user:
the verdict, the justification, and the diff (truncated to 60 lines if longer,
with a link to the inbox json for the full context).

**4d. Ask the user to approve** via the `AskQuestion` tool with options:
- `approve` — apply the diff and push
- `edit` — show the diff, let the user edit it in chat, then apply
- `skip` — write the `.processed` marker with `skipped: true`, move on
- `stop` — write nothing, end the command

**4e. On approve:** apply the diff to the DataPlatform repo (or this repo if
`target_repo` says so), commit with `follow_up_commit_subject` (it MUST start
with the same ticket key as the PR branch), push to the PR branch, then write
the `.processed` marker as JSON:

```json
{
  "ts": "<utc ts>",
  "verdict": "fixable",
  "commit_sha": "<from git rev-parse HEAD>",
  "pushed": true
}
```

**4f. On skip/stop:** write the marker, move on / exit.

### Step 5 — After all inbox items handled

Re-invoke the poller for the PRs that had inbox items, in `--once` mode, to
re-classify after the pushes. If the re-classification is ready (exit 0),
print success. If a NEW failure appeared, repeat Step 4.

If a PR has had inbox items processed twice with no progress, stop and tell
the user — it's thrashing-by-other-means.

### Step 6 — Final summary

Print one block per PR:

```
PR #3897  DA-47_3897_add_mimo_panel_ddr_sub_skill
  result:        <ready|human-required|thrashing|budget|fatal>
  iterations:    <N>
  auto-fixes:    <count of title PATCH ops>
  inbox handled: <N approved> / <N skipped> / <N stopped>
  state file:    audits/babysit/3897.json
  pr url:        https://github.com/eToro/DataPlatform/pull/3897
```

## What this command does NOT do

- **Does not merge any PR.** Same guardrail as `/skills-push` itself.
- **Does not push without user approval.** The only exception is the
  title-checker auto-fix, which is fully deterministic and the user has
  explicitly opted in (v1 scope decision 2026-06-09).
- **Does not touch the source `knowledge/skills/<id>/SKILL.md` files**
  unless the sub-agent's verdict explicitly says the fix belongs in this
  repo AND the user approves. Source of truth still lives in
  `Databricks_Knowledge`.
- **Does not edit CI workflows** to make failures pass. If the
  pr-title-checker config itself is broken, that's a separate PR against
  `.github/workflows/`.
- **Does not run `git config`, `--force`, `--no-verify`, or `--no-gpg-sign`.**

## Failure mode catalog

| Symptom | Cause | Action |
|---|---|---|
| Poller exits 5 immediately | `gh` not authenticated, or PR num invalid | Tell user `gh auth status`, abort |
| Poller exits 0 but PR still red on GitHub UI | New check appeared after exit | Re-run `/skills-push-watch --pr <N>` |
| Title PATCH succeeds but title-checker still red on next iter | CI cached the old title, or different rule firing | If signature is identical and we just pushed, exit 3 (thrashing) handles it |
| Sub-agent returns `needs-human` for everything | Failures really are content-related | Stop the loop, tell user the inbox is theirs |
| `git apply --check` fails on the proposed diff | Sub-agent hallucinated context | Reject the diff, ask user, do NOT re-prompt the sub-agent in the same chat (rotate context) |
| Multiple PRs in queue, first one needs-human | Don't drain blindly | Poller already pauses on first non-zero exit — that's correct |

## Coexistence with `/skills-push`

- `/skills-push` Phase 8 appends the freshly-opened PR number to
  `audits/babysit/queue.txt` (one PR per line). It also prints a final hint:
  `PR queued for babysit — run /skills-push-watch to drain.`
- This command is the drain.
- Running `/skills-push` without `/skills-push-watch` is fine — the queue
  just accumulates. The user can drain at any cadence they like.
