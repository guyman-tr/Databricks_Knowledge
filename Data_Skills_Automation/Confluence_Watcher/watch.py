#!/usr/bin/env python3
"""Confluence Delta Watcher -- version-diff -> conditional skill amendment.

Detects new / changed Confluence pages from a metadata snapshot and, for pages
that back a skill (or are otherwise tracked), conditionally amends the skill and
pushes. This is deliberately NOT a spray-and-pray Rovo search: it diffs page
*versions* against a baseline so only genuine changes are acted on, and only
tracked/skill-backing pages produce a push.

IMPORTANT -- MCP-session dependency:
  Atlassian access is via the interactive Atlassian MCP, which is not available
  to a headless python process. So this watcher is snapshot-file-driven: an MCP
  step (run inside Cursor) exports current page metadata via
  searchConfluenceUsingCql (lastmodified watermark) + getConfluencePage (version)
  into a JSON file, and this watcher diffs it. There is no headless live fetch;
  --current is REQUIRED.

Snapshot format produced by the MCP step:
  {"pages":[{"page_id","space_key","title","version","last_modified","url",
             "tracked_skill"?,"labels"?}]}

State:
  current   = a --current JSON metadata snapshot (MCP-produced).
  baseline  = Data_Skills_Automation/Confluence_Watcher/state/snapshot.json

Dry-run (offline):
  python Data_Skills_Automation/Confluence_Watcher/watch.py \
      --current Data_Skills_Automation/Confluence_Watcher/fixtures/current_pages.json \
      --snapshot Data_Skills_Automation/Confluence_Watcher/fixtures/_tmp_snapshot.json \
      --dry-run --no-notify --no-runlog \
      --manifest-out Data_Skills_Automation/Confluence_Watcher/out/manifest.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.runner import WatchSpec, run_app

APP = "confluence"
DEFAULT_SNAPSHOT = "Data_Skills_Automation/Confluence_Watcher/state/snapshot.json"


def _is_tracked(rec: dict[str, Any]) -> bool:
    return bool(rec.get("tracked_skill") or rec.get("tracked"))


def _normalize_records(raw: Any) -> dict[str, Any]:
    pages = raw.get("pages") if isinstance(raw, dict) else raw
    out: dict[str, Any] = {}
    for p in pages or []:
        pid = str(p.get("page_id") or p.get("id") or "")
        if not pid:
            continue
        out[pid] = {
            "page_id": pid,
            "space_key": p.get("space_key", ""),
            "title": p.get("title", ""),
            "version": p.get("version", 0),
            "last_modified": p.get("last_modified", ""),
            "url": p.get("url", ""),
            "tracked_skill": p.get("tracked_skill", ""),
            "labels": p.get("labels", []),
            "body": p.get("body", ""),
        }
    return out


def fetch_current(current_override: str | None) -> dict[str, dict[str, Any]]:
    if not current_override:
        raise SystemExit(
            "Confluence watcher has no headless live fetch (Atlassian access is "
            "MCP-only). Produce a metadata snapshot inside Cursor via "
            "searchConfluenceUsingCql + getConfluencePage and pass it with "
            "--current <snapshot.json>. See this app's README."
        )
    raw = json.loads(Path(current_override).read_text(encoding="utf-8"))
    records = _normalize_records(raw)
    # Hash on version + last_modified + title so a version bump is a "changed"
    # signal; labels/url churn alone does not re-trigger.
    out: dict[str, dict[str, Any]] = {}
    for pid, rec in records.items():
        out[pid] = {
            "page_id": pid,
            "space_key": rec["space_key"],
            "title": rec["title"],
            "version": rec["version"],
            "last_modified": rec["last_modified"],
            "url": rec["url"],
            "tracked_skill": rec["tracked_skill"],
            "body": rec.get("body", ""),
        }
    return out


def make_work_item(key: str, record: dict[str, Any], change_kind: str) -> WorkItem:
    kind = "confluence_new_page" if change_kind == "new" else "confluence_changed_page"
    return WorkItem(
        id=f"{APP}:{kind}:{key}",
        kind=kind,
        title=record.get("title") or key,
        payload={
            "page_id": key,
            "space_key": record["space_key"],
            "title": record["title"],
            "version": record["version"],
            "url": record["url"],
            "tracked_skill": record["tracked_skill"],
            "body": record.get("body", ""),
        },
        source_ref=key,
    )


def build_prompt(item: WorkItem, ctx: RunContext) -> str:
    p = item.payload
    tracked = p.get("tracked_skill") or "(none)"
    has_snapshot_body = bool((p.get("body") or "").strip())
    source_step = (
        "1) Use the provided page snapshot body in this payload as source-of-truth. "
        "Do NOT call MCP for this item.\n"
        if has_snapshot_body
        else "1) Fetch the current page via getConfluencePage and compare it to the "
        "cached snapshot under knowledge/confluence/_corpus/.\n"
    )
    body_block = (
        f"- snapshot_body:\n{p.get('body')}\n\n"
        if has_snapshot_body
        else ""
    )
    stage_step = (
        "3) If it backs a skill and the change is material (definitions, formulas, "
        "ownership, lifecycle), refresh the evidence cache and apply a surgical "
        "amendment to the skill via /skills-ingest only. STAGING MODE: DO NOT run "
        "/skills-push.\n"
        if ctx.staging
        else "3) If it backs a skill and the change is material (definitions, formulas, "
        "ownership, lifecycle), refresh the evidence cache and apply a surgical "
        "amendment to the skill, then /skills-push.\n"
    )
    return (
        "You are the autonomous Confluence delta watcher.\n"
        f"A Confluence page was detected as {item.kind}.\n"
        f"- page_id: {p['page_id']}\n"
        f"- title: {item.title}\n"
        f"- space: {p['space_key']}  version: {p['version']}\n"
        f"- url: {p['url']}\n"
        f"- tracked_skill: {tracked}\n\n"
        f"{body_block}"
        "Required flow:\n"
        f"{source_step}"
        "2) If this page does NOT back an existing skill and is not a curated "
        "domain source, do NOT push -- return skipped (avoid spray-and-pray).\n"
        f"{stage_step}"
        "4) Return exactly one line:\n"
        'RESULT_JSON:{"status":"done|skipped|error","artifact_ref":"<skill id or null>",'
        '"pr_url":"<url or null>","notes":"short reason"}\n'
    )


def simulate(item: WorkItem) -> ItemOutcome:
    tracked = item.payload.get("tracked_skill")
    if not tracked:
        return ItemOutcome(
            item_id=item.id,
            status="skipped",
            ok=True,
            artifact_ref=None,
            notes="dry-run: page not skill-backing/tracked; logged only (no spray-and-pray ingest)",
        )
    return ItemOutcome(
        item_id=item.id,
        status="done",
        ok=True,
        artifact_ref=f"skill:{tracked}",
        pr_url=None,
        notes=f"dry-run: tracked page v{item.payload.get('version')} -> would amend skill {tracked}",
    )


SPEC = WatchSpec(
    app=APP,
    default_snapshot=DEFAULT_SNAPSHOT,
    fetch_current=fetch_current,
    make_work_item=make_work_item,
    build_prompt=build_prompt,
    simulate=simulate,
    model_role="correction",
)


if __name__ == "__main__":
    sys.exit(run_app(SPEC))
