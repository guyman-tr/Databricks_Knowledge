#!/usr/bin/env python3
"""Genie Spaces Watcher -- diff -> evaluate -> conditional skill push.

Detects new Genie spaces and curation changes in existing spaces, scores each
space by how much durable knowledge its builder encoded (baseline/sample
queries and measures score highest; instructions + data sources are the
fallback context), and -- only when a space encodes ingestable knowledge --
runs /skills-ingest and conditionally /skills-push via the Cursor SDK.

State:
  current   = the materialized Genie cache in this repo
              (knowledge/skills/_genie_spaces_index.json + _genie_cache/<id>.json),
              refreshed by the existing extract_genie_edges tooling, OR a
              --current JSON file (fixtures / a fresh export).
  baseline  = Data_Skills_Automation/Genie_Watcher/state/snapshot.json

Dry-run (offline, no Databricks / no Cursor SDK):
  python Data_Skills_Automation/Genie_Watcher/watch.py \
      --current Data_Skills_Automation/Genie_Watcher/fixtures/current_spaces.json \
      --snapshot Data_Skills_Automation/Genie_Watcher/fixtures/_tmp_snapshot.json \
      --dry-run --no-notify --no-runlog \
      --manifest-out Data_Skills_Automation/Genie_Watcher/out/manifest.json
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

APP = "genie"
DEFAULT_SNAPSHOT = "Data_Skills_Automation/Genie_Watcher/state/snapshot.json"
GENIE_INDEX = REPO_ROOT / "knowledge" / "skills" / "_genie_spaces_index.json"
GENIE_CACHE_DIR = REPO_ROOT / "knowledge" / "skills" / "_genie_cache"

# Minimum curation score below which a space is processed as "skipped" (too
# thin to ingest as durable knowledge).
MIN_INGEST_SCORE = 30


def _as_dict(serialized: Any) -> dict[str, Any]:
    """Genie serialized_space arrives as a JSON string (live cache) or dict (fixture)."""
    if isinstance(serialized, str):
        try:
            return json.loads(serialized)
        except json.JSONDecodeError:
            return {}
    if isinstance(serialized, dict):
        return serialized
    return {}


def score_space(serialized: Any) -> tuple[int, list[str]]:
    """Score a space 0-100 by curated-knowledge richness."""
    spec = _as_dict(serialized)
    instructions = spec.get("instructions") or {}
    data_sources = spec.get("data_sources") or {}
    score = 0
    reasons: list[str] = []

    measures = ((instructions.get("sql_snippets") or {}).get("measures")) or []
    samples = spec.get("sample_questions") or spec.get("benchmarks") or []
    if measures:
        score += 30
        reasons.append(f"{len(measures)} builder measure(s)")
    if samples:
        score += 20
        reasons.append(f"{len(samples)} sample/benchmark query(ies)")

    text_instr = instructions.get("text_instructions") or []
    if text_instr:
        score += 25
        reasons.append(f"{len(text_instr)} instruction block(s)")
    joins = instructions.get("join_specs") or []
    if joins:
        score += 15
        reasons.append(f"{len(joins)} curated join(s)")

    tables = data_sources.get("tables") or []
    col_desc = sum(
        1
        for t in tables
        for c in (t.get("column_configs") or [])
        if c.get("description")
    )
    if col_desc:
        score += 10
        reasons.append(f"{col_desc} described column(s)")
    if tables and not reasons:
        reasons.append(f"{len(tables)} data source(s) only (thin)")

    return min(score, 100), reasons


def _load_from_repo_cache() -> dict[str, Any]:
    if not GENIE_INDEX.exists():
        raise SystemExit(
            f"Genie index not found: {GENIE_INDEX}. Refresh the cache with the "
            "extract_genie_edges tooling, or pass --current."
        )
    index = json.loads(GENIE_INDEX.read_text(encoding="utf-8"))
    records: dict[str, Any] = {}
    for entry in index:
        sid = entry.get("space_id")
        if not sid:
            continue
        cache_file = GENIE_CACHE_DIR / f"{sid}.json"
        serialized = ""
        if cache_file.exists():
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            serialized = cached.get("serialized_space", "")
        records[sid] = {
            "space_id": sid,
            "title": entry.get("title", ""),
            "warehouse_id": entry.get("warehouse_id", ""),
            "tables": entry.get("tables", []),
            "n_tables": entry.get("n_tables", 0),
            "n_join_specs": entry.get("n_join_specs", 0),
            "serialized_space": serialized,
        }
    return records


def _normalize_records(raw: Any) -> dict[str, Any]:
    spaces = raw.get("spaces") if isinstance(raw, dict) else raw
    records: dict[str, Any] = {}
    for entry in spaces or []:
        sid = entry.get("space_id")
        if not sid:
            continue
        records[sid] = entry
    return records


def fetch_current(current_override: str | None) -> dict[str, dict[str, Any]]:
    if current_override:
        raw = json.loads(Path(current_override).read_text(encoding="utf-8"))
        records = _normalize_records(raw)
    else:
        records = _load_from_repo_cache()

    # Hash only on durable fields so a title tweak alone is a "changed" signal
    # but volatile metadata does not churn the snapshot.
    out: dict[str, dict[str, Any]] = {}
    for sid, rec in records.items():
        score, reasons = score_space(rec.get("serialized_space"))
        out[sid] = {
            "space_id": sid,
            "title": rec.get("title", ""),
            "warehouse_id": rec.get("warehouse_id", ""),
            "tables": rec.get("tables", []),
            "n_tables": rec.get("n_tables", len(rec.get("tables", []))),
            "n_join_specs": rec.get("n_join_specs", 0),
            "score": score,
            "score_reasons": reasons,
            "serialized_space": rec.get("serialized_space", ""),
        }
    return out


def make_work_item(key: str, record: dict[str, Any], change_kind: str) -> WorkItem:
    kind = "genie_new" if change_kind == "new" else "genie_changed"
    payload = {k: v for k, v in record.items() if k != "serialized_space"}
    return WorkItem(
        id=f"{APP}:{kind}:{key}",
        kind=kind,
        title=record.get("title") or key,
        payload=payload,
        source_ref=key,
    )


def build_prompt(item: WorkItem, ctx: RunContext) -> str:
    p = item.payload
    stage_step = (
        "4) STAGING MODE: run /skills-ingest only; DO NOT run /skills-push. "
        "Leave pr_url as null.\n"
        if ctx.staging
        else "4) Otherwise run /skills-ingest for the synthesized skill/domain amendment, "
        "and if the overlap gate passes, run /skills-push.\n"
    )
    return (
        "You are the autonomous Genie Spaces knowledge watcher.\n"
        f"A Genie space was detected as {item.kind} and scored for curation.\n"
        f"- space_id: {item.source_ref}\n"
        f"- title: {item.title}\n"
        f"- curation_score: {p.get('score')}/100 ({', '.join(p.get('score_reasons') or []) or 'none'})\n"
        f"- tables: {', '.join((p.get('tables') or [])[:12])}\n\n"
        "Cached definition lives at "
        f"knowledge/skills/_genie_cache/{item.source_ref}.json (serialized_space).\n\n"
        "Required flow:\n"
        "1) Read the cached space definition (instructions, join_specs, measures, "
        "sample questions, data sources).\n"
        "2) Compare against existing knowledge/skills/ and dwh-domain skills. Decide "
        "whether it introduces NEW durable knowledge (a new metric definition, join "
        "rule, domain, or skill amendment) not already captured.\n"
        f"3) If curation_score < {MIN_INGEST_SCORE} OR the knowledge already exists, "
        "do NOT push; return skipped.\n"
        f"{stage_step}"
        "5) Return exactly one line:\n"
        'RESULT_JSON:{"status":"done|skipped|error","artifact_ref":"<skill id/domain or null>",'
        '"pr_url":"<url or null>","notes":"short reason"}\n'
    )


def simulate(item: WorkItem) -> ItemOutcome:
    score = int(item.payload.get("score") or 0)
    if score < MIN_INGEST_SCORE:
        return ItemOutcome(
            item_id=item.id,
            status="skipped",
            ok=True,
            artifact_ref=None,
            notes=f"dry-run: curation score {score} < {MIN_INGEST_SCORE}; thin space, not ingested",
        )
    return ItemOutcome(
        item_id=item.id,
        status="done",
        ok=True,
        artifact_ref=f"skill:genie-{item.source_ref}",
        pr_url="https://example.invalid/dataplatform/pull/DRYRUN-genie",
        notes=f"dry-run: score {score}; would ingest + conditionally push",
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
