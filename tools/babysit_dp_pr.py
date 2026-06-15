#!/usr/bin/env python
"""babysit_dp_pr.py - Watch a DataPlatform PR and auto-fix mechanical CI failures.

v1 scope (chosen 2026-06-09):
  - AUTO-FIX:    pr-title-checker only. Re-applies the Phase 7 Step 5 rename
                 from .cursor/skills/skills-push/SKILL.md (REST PATCH via gh api).
  - INBOX:       every other failing check is dumped to audits/babysit/inbox/
                 with full context; loop exits with code 2 (human-required).
                 The /skills-push-watch slash command picks up inbox items
                 and spawns sub-agent diff proposals for the user to approve.

Stop conditions:
  0  ready          mergeable=MERGEABLE + all required checks SUCCESS + reviewDecision != CHANGES_REQUESTED
  2  human-required at least one failure classified as needs-judgement (inbox)
  3  thrashing      two iterations with identical failure signature after a push
  4  budget         6 iterations OR 90 min wall-clock
  5  fatal          gh CLI error, PR not found, malformed state

Usage:
    python tools/babysit_dp_pr.py --pr 3897
    python tools/babysit_dp_pr.py                 # drain audits/babysit/queue.txt
    python tools/babysit_dp_pr.py --pr 3897 --poll 30 --max-iter 12 --max-mins 180
    python tools/babysit_dp_pr.py --pr 3897 --once # one classification pass, no waiting

Exit code is per PR; in queue-drain mode the script returns the highest exit code
seen across all PRs processed in this run.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO = "eToro/DataPlatform"
WORKSPACE = Path(__file__).resolve().parent.parent
STATE_DIR = WORKSPACE / "audits" / "babysit"
INBOX_DIR = STATE_DIR / "inbox"
QUEUE_FILE = STATE_DIR / "queue.txt"

DEFAULT_POLL_SECS = 300
DEFAULT_MAX_ITER = 6
DEFAULT_MAX_MINS = 90

TITLE_TICKET_RE = re.compile(r"^([A-Z]{2,5}-\d+)\b")
TITLE_FULL_SLUG_RE = re.compile(r"^[A-Z]{2,5}-\d+_\d+_[a-z0-9]+(_[a-z0-9]+)*$")
SLUG_NORMALISE_RE = re.compile(r"[^a-z0-9]+")
TITLE_CHECKER_HINTS = ("title", "pr-title", "pr_title")


def _ts() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _print(msg: str) -> None:
    print(f"[babysit {_ts()}] {msg}", flush=True)


def _run(cmd: list[str], *, check: bool = True) -> tuple[int, str, str]:
    """Run a command. Returns (rc, stdout, stderr). Never echoes secrets."""
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if check and result.returncode != 0:
        raise RuntimeError(
            f"command failed (rc={result.returncode}): {shlex.join(cmd)}\n"
            f"stdout: {result.stdout[-500:]}\n"
            f"stderr: {result.stderr[-500:]}"
        )
    return result.returncode, result.stdout, result.stderr


def fetch_pr_state(pr_num: int) -> dict[str, Any]:
    rc, out, err = _run(
        [
            "gh", "pr", "view", str(pr_num),
            "--repo", REPO,
            "--json",
            "number,title,headRefName,baseRefName,state,mergeable,"
            "statusCheckRollup,reviewDecision,url",
        ],
        check=False,
    )
    if rc != 0:
        raise RuntimeError(f"gh pr view {pr_num} failed: {err.strip() or out.strip()}")
    return json.loads(out)


def classify_failures(pr: dict[str, Any]) -> list[dict[str, Any]]:
    """Return list of failures with classification: 'title-checker' or 'needs-judgement'.

    Successful and in-progress checks are filtered out here; the caller decides
    whether the absence of failures + a still-running check means 'keep waiting'.
    """
    out: list[dict[str, Any]] = []
    for check in pr.get("statusCheckRollup") or []:
        name = (check.get("name") or check.get("context") or "").strip()
        conclusion = (check.get("conclusion") or check.get("state") or "").upper()
        status = (check.get("status") or "").upper()
        if conclusion in {"SUCCESS", "NEUTRAL", "SKIPPED"}:
            continue
        if conclusion in {"", "PENDING"} and status in {"", "IN_PROGRESS", "QUEUED", "PENDING"}:
            continue
        if conclusion in {"FAILURE", "TIMED_OUT", "ACTION_REQUIRED", "CANCELLED", "STARTUP_FAILURE"}:
            name_l = name.lower()
            classification = (
                "title-checker"
                if any(h in name_l for h in TITLE_CHECKER_HINTS) and "check" in name_l
                else "needs-judgement"
            )
            out.append({
                "name": name,
                "conclusion": conclusion,
                "details_url": check.get("detailsUrl") or check.get("targetUrl"),
                "classification": classification,
            })
    if pr.get("reviewDecision") == "CHANGES_REQUESTED":
        out.append({
            "name": "review:CHANGES_REQUESTED",
            "conclusion": "REVIEW_BLOCKED",
            "details_url": pr.get("url"),
            "classification": "needs-judgement",
        })
    return out


def pending_count(pr: dict[str, Any]) -> int:
    n = 0
    for check in pr.get("statusCheckRollup") or []:
        conclusion = (check.get("conclusion") or check.get("state") or "").upper()
        status = (check.get("status") or "").upper()
        if conclusion in {"", "PENDING"} and status in {"", "IN_PROGRESS", "QUEUED", "PENDING"}:
            n += 1
    return n


def is_ready(pr: dict[str, Any], failures: list[dict[str, Any]]) -> bool:
    if failures:
        return False
    if pending_count(pr) > 0:
        return False
    if (pr.get("mergeable") or "").upper() != "MERGEABLE":
        return False
    if pr.get("reviewDecision") == "CHANGES_REQUESTED":
        return False
    return True


def failure_signature(failures: list[dict[str, Any]]) -> str:
    payload = sorted((f["name"], f["conclusion"]) for f in failures)
    return hashlib.sha1(json.dumps(payload, sort_keys=True).encode()).hexdigest()[:12]


def slugify(text: str) -> str:
    return SLUG_NORMALISE_RE.sub("_", text.lower()).strip("_")


def fix_title_checker(pr: dict[str, Any]) -> tuple[bool, str]:
    """Re-derive the full-slug title and PATCH it. Returns (ok, new_title_or_reason)."""
    pr_num = pr["number"]
    current = pr["title"]
    if TITLE_FULL_SLUG_RE.match(current):
        return False, f"title already conforms ({current}) - failure cause is elsewhere"
    m = TITLE_TICKET_RE.match(current)
    if not m:
        return False, f"title has no ticket prefix: {current!r}"
    ticket = m.group(1)
    raw_human = current[len(ticket):].strip(" :_-")
    if not raw_human:
        return False, f"title has only a ticket, no human title: {current!r}"
    slug = slugify(raw_human)
    if not slug:
        return False, f"slugify produced empty string from: {raw_human!r}"
    prefix = f"{ticket}_{pr_num}_"
    max_slug_len = 100 - len(prefix)
    if len(slug) > max_slug_len:
        slug = slug[:max_slug_len].rstrip("_")
    new_title = f"{prefix}{slug}"
    if not TITLE_FULL_SLUG_RE.match(new_title) or not (15 <= len(new_title) <= 100):
        return False, f"derived title does not satisfy CI regex: {new_title!r}"
    body = json.dumps({"title": new_title})
    proc = subprocess.run(
        ["gh", "api", "-X", "PATCH", f"/repos/{REPO}/pulls/{pr_num}", "--input", "-"],
        input=body, capture_output=True, text=True, encoding="utf-8",
    )
    if proc.returncode != 0:
        return False, f"gh api PATCH failed: {proc.stderr.strip() or proc.stdout.strip()}"
    return True, new_title


def fetch_check_log_tail(check: dict[str, Any], lines: int = 200) -> str | None:
    """Best-effort: pull the tail of the failing run's log via gh run view.
    Returns None if we can't find the run id (common for status-only checks)."""
    url = check.get("details_url") or ""
    m = re.search(r"/runs/(\d+)", url)
    if not m:
        return None
    run_id = m.group(1)
    proc = subprocess.run(
        ["gh", "run", "view", run_id, "--repo", REPO, "--log-failed"],
        capture_output=True, text=True, encoding="utf-8",
    )
    if proc.returncode != 0:
        return None
    body = proc.stdout.strip()
    if not body:
        return None
    body_lines = body.splitlines()
    return "\n".join(body_lines[-lines:])


def dump_to_inbox(pr: dict[str, Any], failure: dict[str, Any]) -> Path:
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    pr_num = pr["number"]
    safe_check = slugify(failure["name"])[:60] or "unknown"
    stem = f"{pr_num}_{safe_check}_{_ts()}"
    log_tail = fetch_check_log_tail(failure)
    payload = {
        "pr_number": pr_num,
        "pr_url": pr.get("url"),
        "pr_title": pr.get("title"),
        "head_ref": pr.get("headRefName"),
        "base_ref": pr.get("baseRefName"),
        "check_name": failure["name"],
        "check_conclusion": failure["conclusion"],
        "check_details_url": failure.get("details_url"),
        "classification": failure["classification"],
        "log_tail_present": log_tail is not None,
        "timestamp_utc": _ts(),
    }
    json_path = INBOX_DIR / f"{stem}.json"
    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    if log_tail:
        (INBOX_DIR / f"{stem}.log").write_text(log_tail, encoding="utf-8")
    return json_path


def load_state(state_path: Path) -> dict[str, Any]:
    if state_path.exists():
        try:
            return json.loads(state_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    return {"attempts": [], "last_signature": None, "last_action": None, "iterations": 0}


def save_state(state: dict[str, Any], state_path: Path) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")


def watch_pr(pr_num: int, *, poll_secs: int, max_iter: int, max_mins: int, once: bool) -> int:
    state_path = STATE_DIR / f"{pr_num}.json"
    state = load_state(state_path)
    state["pr_number"] = pr_num
    state["started_utc"] = state.get("started_utc") or _ts()
    start = time.monotonic()
    budget_secs = max_mins * 60

    for iteration in range(max_iter):
        state["iterations"] = state.get("iterations", 0) + 1
        elapsed = time.monotonic() - start
        if elapsed > budget_secs:
            _print(f"PR #{pr_num} EXIT 4 budget-wall-clock at {int(elapsed)}s")
            state["last_action"] = "budget-wall-clock"
            save_state(state, state_path)
            return 4

        try:
            pr = fetch_pr_state(pr_num)
        except RuntimeError as e:
            _print(f"PR #{pr_num} fatal: {e}")
            state["last_action"] = "fatal"
            save_state(state, state_path)
            return 5

        failures = classify_failures(pr)
        pending = pending_count(pr)
        _print(
            f"PR #{pr_num} iter {iteration + 1}/{max_iter} | "
            f"mergeable={pr.get('mergeable')} review={pr.get('reviewDecision')} "
            f"failed={len(failures)} pending={pending}"
        )

        if is_ready(pr, failures):
            _print(f"PR #{pr_num} EXIT 0 ready ({pr.get('url')})")
            state["last_action"] = "ready"
            save_state(state, state_path)
            return 0

        if not failures and pending > 0:
            if once:
                _print(f"PR #{pr_num} EXIT (once-mode) pending checks still running")
                state["last_action"] = "pending"
                save_state(state, state_path)
                return 0
            state["last_action"] = "waiting"
            save_state(state, state_path)
            time.sleep(poll_secs)
            continue

        sig = failure_signature(failures)
        if (
            sig == state.get("last_signature")
            and state.get("last_action") == "pushed-title"
        ):
            _print(f"PR #{pr_num} EXIT 3 thrashing (same failure signature after fix)")
            state["last_action"] = "thrashing"
            save_state(state, state_path)
            return 3
        state["last_signature"] = sig

        title_fixes = [f for f in failures if f["classification"] == "title-checker"]
        needs_judgement = [f for f in failures if f["classification"] == "needs-judgement"]

        if title_fixes:
            ok, info = fix_title_checker(pr)
            attempt = {
                "iteration": state["iterations"],
                "ts": _ts(),
                "fix": "title-checker",
                "ok": ok,
                "info": info,
            }
            state["attempts"].append(attempt)
            if ok:
                _print(f"PR #{pr_num} title PATCHED -> {info}")
                state["last_action"] = "pushed-title"
                save_state(state, state_path)
                if once:
                    return 0
                time.sleep(poll_secs)
                continue
            _print(f"PR #{pr_num} title fix declined: {info}")
            state["last_action"] = "title-fix-declined"
            inbox_path = dump_to_inbox(pr, title_fixes[0])
            _print(f"  -> inbox: {inbox_path}")
            save_state(state, state_path)
            return 2

        if needs_judgement:
            paths = [dump_to_inbox(pr, f) for f in needs_judgement]
            _print(f"PR #{pr_num} EXIT 2 human-required ({len(paths)} inbox items)")
            for p in paths:
                _print(f"  -> {p}")
            state["last_action"] = "to-inbox"
            save_state(state, state_path)
            return 2

        state["last_action"] = "no-actionable"
        save_state(state, state_path)
        if once:
            return 0
        time.sleep(poll_secs)

    _print(f"PR #{pr_num} EXIT 4 budget-iterations ({max_iter})")
    state["last_action"] = "budget-iterations"
    save_state(state, state_path)
    return 4


def _read_queue() -> list[int]:
    if not QUEUE_FILE.exists():
        return []
    out: list[int] = []
    for ln in QUEUE_FILE.read_text(encoding="utf-8").splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            out.append(int(ln))
        except ValueError:
            _print(f"skip malformed queue line: {ln!r}")
    return out


def _write_queue(pr_nums: list[int]) -> None:
    if pr_nums:
        QUEUE_FILE.write_text("\n".join(str(n) for n in pr_nums) + "\n", encoding="utf-8")
    else:
        QUEUE_FILE.unlink(missing_ok=True)


def drain_queue(args: argparse.Namespace) -> int:
    queue = _read_queue()
    if not queue:
        _print(f"queue empty: {QUEUE_FILE}")
        return 0
    worst = 0
    while queue:
        pr_num = queue[0]
        rc = watch_pr(
            pr_num,
            poll_secs=args.poll,
            max_iter=args.max_iter,
            max_mins=args.max_mins,
            once=args.once,
        )
        worst = max(worst, rc)
        if rc == 0:
            queue.pop(0)
            _write_queue(queue)
        else:
            _print(f"PR #{pr_num} did not reach ready (rc={rc}); leaving in queue head")
            break
    return worst


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--pr", type=int, help="PR number to watch")
    ap.add_argument("--poll", type=int, default=DEFAULT_POLL_SECS)
    ap.add_argument("--max-iter", type=int, default=DEFAULT_MAX_ITER)
    ap.add_argument("--max-mins", type=int, default=DEFAULT_MAX_MINS)
    ap.add_argument("--once", action="store_true",
                    help="One classification pass, no polling sleep. For probes / tests.")
    return ap.parse_args()


def main() -> int:
    args = parse_args()
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    if args.pr is not None:
        return watch_pr(
            args.pr,
            poll_secs=args.poll,
            max_iter=args.max_iter,
            max_mins=args.max_mins,
            once=args.once,
        )
    return drain_queue(args)


if __name__ == "__main__":
    sys.exit(main())
