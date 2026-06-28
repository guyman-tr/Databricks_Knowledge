#!/usr/bin/env python3
"""Questions Watcher -- mine real user questions, find skill gaps.

Diff-driven 5th auto_kb watcher. Reads the two question-log gateway tables,
denoises every question into an intent SIGNATURE (metrics first, classifiers
second), clusters recurring interests, scores how well the current skill corpus
covers each intent, and -- only for under-served recurring intents -- runs the
agent to produce a gap dossier with a proposed skill domain/sub-domain outline.

Sources (live):
  MCP   = main.config.monitoring_mcp_logs_mcp_gateway
          (tool in skills_find_skills | databricks_ops_ask_genie; args_preview
           JSON `question` + skills_top_score / skills_match_quality_hint /
           skills_all_below_floor / returned_skill_ids)
  Genie = main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway
          (nl_prompt + space_name + message_status + thumb_down)

State:
  current  = the two live tables over a lookback window, OR a --current JSON
             fixture {"questions":[ {source,prompt,...common shape...} ]}.
  baseline = Data_Skills_Automation/Questions_Watcher/state/snapshot.json
  diff key = the intent signature (NOT the raw text) so a new recurring
             interest, or a cluster that DEGRADES to under-served, is the signal.

PII: user emails are hashed to count distinct users and then discarded. No
email or raw customer-specific value is ever persisted to state, run-log, or
the inventory/dossier artifacts.

Dry-run (offline -- no Databricks, no Cursor SDK):
  python Data_Skills_Automation/Questions_Watcher/watch.py \
      --current Data_Skills_Automation/Questions_Watcher/fixtures/current_questions.json \
      --snapshot Data_Skills_Automation/Questions_Watcher/fixtures/_tmp_snapshot.json \
      --dry-run --no-notify --no-runlog \
      --manifest-out Data_Skills_Automation/Questions_Watcher/out/manifest.json
"""
from __future__ import annotations

import csv
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))

from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.runner import WatchSpec, run_app
from tools.auto_kb.questions.normalize import Cluster, cluster_questions
from tools.auto_kb.questions.coverage import Coverage, classify_cluster

APP = "questions"
DEFAULT_SNAPSHOT = "Data_Skills_Automation/Questions_Watcher/state/snapshot.json"
OUT_DIR = REPO_ROOT / "Data_Skills_Automation" / "Questions_Watcher" / "out"
DOSSIER_DIR = OUT_DIR / "dossiers"

# A cluster must clear ONE of these to be a tracked interest (recurring, not one-off).
MIN_SUPPORT = int(os.environ.get("QUESTIONS_MIN_SUPPORT", "3"))
MIN_DISTINCT_USERS = int(os.environ.get("QUESTIONS_MIN_USERS", "2"))
LOOKBACK_DAYS = int(os.environ.get("QUESTIONS_LOOKBACK_DAYS", "30"))

MCP_TABLE = "main.config.monitoring_mcp_logs_mcp_gateway"
GENIE_TABLE = "main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway"


def _clip(text: str, n: int = 160) -> str:
    t = " ".join(str(text or "").split())
    return t if len(t) <= n else t[: n - 1].rstrip() + "\u2026"


def _user_hash(email: Any) -> str:
    e = str(email or "").strip().lower()
    if not e:
        return ""
    return hashlib.sha1(e.encode("utf-8")).hexdigest()[:12]


def _question_from_args_preview(args_preview: Any) -> str:
    """The MCP gateway stores tool args as a (possibly truncated) JSON string."""
    text = str(args_preview or "").strip()
    if not text:
        return ""
    try:
        obj = json.loads(text)
        if isinstance(obj, dict):
            return str(obj.get("question") or "").strip()
    except json.JSONDecodeError:
        # Truncated JSON -- best-effort regex pull of the question value.
        m = re.search(r'"question"\s*:\s*"([^"]+)', text)
        if m:
            return m.group(1).strip()
    return ""


def _freq_bucket(count: int) -> str:
    if count >= 20:
        return "high"
    if count >= 5:
        return "medium"
    return "low"


def _users_bucket(n: int) -> str:
    if n >= 5:
        return "many"
    if n >= 2:
        return "few"
    return "single"


# --------------------------------------------------------------------------
# Live fetch
# --------------------------------------------------------------------------

def _fetch_live_rows() -> list[dict[str, Any]]:
    from tools.skill_suggestions.db import execute_sql, make_workspace_client, warehouse_id_from_env

    w = make_workspace_client()
    wid = warehouse_id_from_env()
    rows: list[dict[str, Any]] = []

    mcp_sql = f"""
SELECT tool, args_preview, skills_top_score, skills_match_quality_hint,
       skills_all_below_floor, returned_skill_ids, status, user_email
FROM {MCP_TABLE}
WHERE tool IN ('skills_find_skills','databricks_ops_ask_genie')
  AND args_preview IS NOT NULL
  AND ts >= current_timestamp() - INTERVAL {LOOKBACK_DAYS} DAYS
""".strip()
    cols, data = execute_sql(w, sql_text=mcp_sql, warehouse_id=wid)
    idx = {c: i for i, c in enumerate(cols)}
    for d in data:
        rows.append(
            {
                "source": "mcp",
                "prompt": _question_from_args_preview(d[idx["args_preview"]]),
                "skills_top_score": d[idx["skills_top_score"]],
                "skills_match_quality_hint": d[idx["skills_match_quality_hint"]],
                "skills_all_below_floor": d[idx["skills_all_below_floor"]],
                "returned_skill_ids": d[idx["returned_skill_ids"]],
                "status": d[idx["status"]],
                "user_hash": _user_hash(d[idx["user_email"]]),
            }
        )

    genie_sql = f"""
SELECT nl_prompt, space_name, message_status, thumb_down, user_email
FROM {GENIE_TABLE}
WHERE nl_prompt IS NOT NULL AND length(trim(nl_prompt)) > 0
  AND ts >= current_timestamp() - INTERVAL {LOOKBACK_DAYS} DAYS
""".strip()
    cols, data = execute_sql(w, sql_text=genie_sql, warehouse_id=wid)
    idx = {c: i for i, c in enumerate(cols)}
    for d in data:
        rows.append(
            {
                "source": "genie",
                "prompt": d[idx["nl_prompt"]],
                "status": d[idx["message_status"]],
                "thumb_down": d[idx["thumb_down"]],
                "user_hash": _user_hash(d[idx["user_email"]]),
            }
        )
    return rows


def _load_fixture_rows(path: str) -> list[dict[str, Any]]:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    questions = raw.get("questions") if isinstance(raw, dict) else raw
    out: list[dict[str, Any]] = []
    for q in questions or []:
        rec = dict(q)
        # Fixtures may carry user_email instead of a pre-hashed user.
        if "user_hash" not in rec and rec.get("user_email"):
            rec["user_hash"] = _user_hash(rec.get("user_email"))
        rec.pop("user_email", None)
        out.append(rec)
    return out


# --------------------------------------------------------------------------
# Inventory artifacts (full detail; analysis output, not state)
# --------------------------------------------------------------------------

def _write_inventory(scored: list[tuple[Cluster, Coverage]]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    inv = OUT_DIR / "intent_inventory.csv"
    gaps = OUT_DIR / "underserved_clusters.csv"

    fields = [
        "signature", "label", "metrics", "classifiers", "coverage_status",
        "coverage_score", "count", "distinct_users", "sources", "mcp_total",
        "mcp_below_floor", "mcp_above_floor", "genie_total", "genie_fail",
        "thumb_down", "top_skill", "route_hub", "priority", "examples",
    ]

    def _row(cl: Cluster, cov: Coverage) -> dict[str, Any]:
        return {
            "signature": cl.signature,
            "label": cl.label,
            "metrics": "+".join(cl.metrics),
            "classifiers": "+".join(cl.classifiers),
            "coverage_status": cov.coverage_status,
            "coverage_score": cov.coverage_score,
            "count": cl.count,
            "distinct_users": cl.distinct_users,
            "sources": "+".join(sorted(cl.sources)),
            "mcp_total": cl.mcp_total,
            "mcp_below_floor": cl.mcp_below_floor,
            "mcp_above_floor": cl.mcp_above_floor,
            "genie_total": cl.genie_total,
            "genie_fail": cl.genie_fail,
            "thumb_down": cl.thumb_down,
            "top_skill": cov.top_skill,
            "route_hub": cov.route_hub,
            "priority": cov.priority,
            "examples": " | ".join(_clip(e) for e, _ in cl.examples.most_common(3)),
        }

    ranked = sorted(scored, key=lambda sc: sc[1].priority, reverse=True)
    with inv.open("w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=fields)
        wr.writeheader()
        for cl, cov in ranked:
            wr.writerow(_row(cl, cov))

    with gaps.open("w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=fields)
        wr.writeheader()
        for cl, cov in ranked:
            if cov.coverage_status != "well_covered":
                wr.writerow(_row(cl, cov))

    print(f"[{APP}] wrote inventory -> {inv} ({len(ranked)} clusters)")
    print(f"[{APP}] wrote gaps -> {gaps}")


# --------------------------------------------------------------------------
# WatchSpec hooks
# --------------------------------------------------------------------------

def fetch_current(current_override: str | None) -> dict[str, dict[str, Any]]:
    rows = _load_fixture_rows(current_override) if current_override else _fetch_live_rows()
    clusters = cluster_questions(rows)

    scored: list[tuple[Cluster, Coverage]] = [(cl, classify_cluster(cl)) for cl in clusters.values()]
    _write_inventory(scored)

    out: dict[str, dict[str, Any]] = {}
    for cl, cov in scored:
        # Drop pure-fallback clusters (no metric AND no classifier matched) -- these
        # are noise ("hi", "what tables are there"). They stay in the inventory CSV.
        if cl.signature.startswith("o:"):
            continue
        # Track only recurring interests (quantify similar interests, drop one-offs).
        if cl.count < MIN_SUPPORT and cl.distinct_users < MIN_DISTINCT_USERS:
            continue
        out[cl.signature] = {
            "signature": cl.signature,
            "label": cl.label,
            "metrics": cl.metrics,
            "classifiers": cl.classifiers,
            "coverage_status": cov.coverage_status,
            "freq_bucket": _freq_bucket(cl.count),
            "users_bucket": _users_bucket(cl.distinct_users),
            "top_skill": cov.top_skill,
            # denoised + capped -> stable across days (no dates/values to churn).
            "examples": sorted(_clip(e) for e, _ in cl.examples.most_common(3)),
        }
    return out


def make_work_item(key: str, record: dict[str, Any], change_kind: str) -> WorkItem:
    kind = "questions_new_intent" if change_kind == "new" else "questions_changed_intent"
    status = record.get("coverage_status", "unknown")
    return WorkItem(
        id=f"{APP}:{kind}:{key}",
        kind=kind,
        title=f"{record.get('label') or key} [{status}]",
        payload=record,
        source_ref=key,
    )


def _safe_name(signature: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", signature.lower()).strip("_") or "intent"


def build_prompt(item: WorkItem, ctx: RunContext) -> str:
    p = item.payload
    dossier = f"Data_Skills_Automation/Questions_Watcher/out/dossiers/gap_dossier_{_safe_name(item.source_ref)}.md"
    examples = "; ".join(p.get("examples") or [])
    return (
        "You are the autonomous Questions Interest tracker.\n"
        "A recurring user-question intent cluster was detected from the MCP gateway "
        "and Genie gateway logs, denoised to its metric/classifier signature.\n"
        f"- signature: {item.source_ref}\n"
        f"- intent: {p.get('label')}\n"
        f"- metrics: {', '.join(p.get('metrics') or []) or 'none'}\n"
        f"- classifiers: {', '.join(p.get('classifiers') or []) or 'none'}\n"
        f"- coverage_status: {p.get('coverage_status')}\n"
        f"- frequency: {p.get('freq_bucket')}; distinct_users: {p.get('users_bucket')}\n"
        f"- current top routed skill: {p.get('top_skill') or 'none'}\n"
        f"- example (denoised) questions: {examples}\n\n"
        "Required flow:\n"
        "1) If coverage_status == well_covered, confirm an existing skill already "
        "answers this intent and return skipped (no gap).\n"
        "2) Otherwise INVESTIGATE the gap using all available tools: existing "
        "knowledge/skills/ + dwh-domain skills, Tableau reports "
        "(tools/tableau/extract_table_metadata.py), Confluence + Jira via Atlassian "
        "MCP, Synapse/lake wikis (knowledge/synapse/Wiki + ../DB_Schema), and Unity "
        "Catalog (the metrics/classifiers imply specific FQNs).\n"
        "3) Write a GAP DOSSIER markdown to:\n"
        f"   {dossier}\n"
        "   containing: the intent, why current skills fall short, the proposed "
        "placement (new domain vs sub-skill of an existing hub vs cross), candidate "
        "anchor UC tables (FQNs), proposed triggers, and 3-5 sample questions. Use "
        "ONLY denoised intent language -- no user emails, no customer-specific values.\n"
        "4) Do NOT author skill files and do NOT run /skills-push. This tracker "
        "produces a reviewed proposal only.\n"
        "5) Return exactly one line:\n"
        'RESULT_JSON:{"status":"done|skipped|error","artifact_ref":"<dossier path or proposed domain or null>",'
        '"pr_url":null,"notes":"short reason"}\n'
    )


def simulate(item: WorkItem) -> ItemOutcome:
    p = item.payload
    status = p.get("coverage_status")
    if status == "well_covered":
        return ItemOutcome(
            item_id=item.id,
            status="skipped",
            ok=True,
            artifact_ref=p.get("top_skill") or None,
            notes=f"dry-run: intent already well covered by {p.get('top_skill') or 'existing skills'}",
        )
    dossier = f"gap-dossier:{_safe_name(item.source_ref)}"
    return ItemOutcome(
        item_id=item.id,
        status="done",
        ok=True,
        artifact_ref=dossier,
        notes=(
            f"dry-run: {status} intent ({p.get('freq_bucket')} freq, "
            f"{p.get('users_bucket')} users); would build a gap dossier + proposed placement"
        ),
    )


SPEC = WatchSpec(
    app=APP,
    default_snapshot=DEFAULT_SNAPSHOT,
    fetch_current=fetch_current,
    make_work_item=make_work_item,
    build_prompt=build_prompt,
    simulate=simulate,
    model_role="ingest",
)


if __name__ == "__main__":
    sys.exit(run_app(SPEC))
