"""reporter.py — write report.csv, report.md, _run_metadata.json.

Each audit row carries the full audit context (claim, source, layer, verdict,
proposed fix). The CSV is the machine-readable trail; the MD is for humans
to skim.

Blast-radius hot-list: when a FAIL is detected for a column in a DWH wiki,
we surface how many BI_DB_dbo or UC_generated wikis reference that DWH
object — those are the downstream consumers that inherited the corruption.
"""
from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parents[2]


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------
@dataclass
class AuditRow:
    # Where the Tier 1 claim lives
    dwh_wiki: str             # repo-relative path
    dwh_object: str           # filename stem
    line_no: int
    column_index: str
    column_name: str
    tier_claim_raw: str       # the X text inside (Tier 1 -- X)
    current_desc: str

    # What the source actually says
    source_wiki: str          # repo-relative path or "" if unresolved
    source_column: str        # may differ from claimed column when fuzzy-matched
    source_tier: str          # "1" / "2" / "OLTP-truth" / "" if unknown
    source_desc: str
    match_method: str

    # Verdict
    layer: str                # "L0-unresolved" | "L1-structural" | "L2-semantic"
    verdict: str              # "PASS" | "FAIL"
    severity: str             # "HIGH" | "MEDIUM" | "LOW" | "" for PASS
    judge_reason: str
    proposed_fix: str         # may be empty

    notes: str = ""           # free-form for amber/unresolved cases


@dataclass
class RunMetadata:
    scope: str
    started_at: str
    finished_at: str = ""
    wall_clock_s: float = 0.0
    total_wikis_scanned: int = 0
    total_tier1_tags: int = 0
    counts_by_verdict: dict[str, int] = field(default_factory=dict)
    counts_by_severity: dict[str, int] = field(default_factory=dict)
    counts_by_layer: dict[str, int] = field(default_factory=dict)
    judge_calls_made: int = 0
    judge_cache_hits: int = 0
    judge_failed: int = 0
    llm_disabled: bool = False
    judge_model: str | None = None


# ---------------------------------------------------------------------------
# CSV writer
# ---------------------------------------------------------------------------
CSV_FIELDS = [
    "dwh_wiki", "dwh_object", "line_no", "column_index", "column_name",
    "tier_claim_raw", "current_desc",
    "source_wiki", "source_column", "source_tier", "source_desc",
    "match_method",
    "layer", "verdict", "severity",
    "judge_reason", "proposed_fix", "notes",
]


def write_csv(rows: Iterable[AuditRow], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CSV_FIELDS, extrasaction="ignore",
                           quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for r in rows:
            d = asdict(r)
            w.writerow(d)


# ---------------------------------------------------------------------------
# Blast-radius (cheap rg substitute)
# ---------------------------------------------------------------------------
def _blast_radius_for(dwh_object: str, *, search_roots: list[Path]) -> Counter:
    """Count how many *.md files under each search root mention the DWH object
    name (case-insensitive whole-word). Returns {root_label: count}."""
    counter: Counter = Counter()
    if not dwh_object:
        return counter
    needle = re.compile(rf"\b{re.escape(dwh_object)}\b", re.IGNORECASE)
    for root in search_roots:
        if not root.is_dir():
            continue
        label = root.relative_to(REPO).as_posix()
        for path in root.rglob("*.md"):
            if "_writer_audit" in path.parts or "_discovery" in path.parts:
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            if needle.search(text):
                counter[label] += 1
    return counter


# ---------------------------------------------------------------------------
# Markdown writer
# ---------------------------------------------------------------------------
def _shorten(text: str, n: int = 220) -> str:
    text = (text or "").replace("\n", " ").strip()
    if len(text) <= n:
        return text
    return text[: n - 1].rstrip() + "…"


def _truncate_path(p: str, n: int = 70) -> str:
    return p if len(p) <= n else "…" + p[-(n - 1):]


def write_markdown(
    rows: list[AuditRow],
    meta: RunMetadata,
    out_path: Path,
    *,
    blast_radius_roots: list[Path] | None = None,
    max_fail_rows: int = 200,
    hot_list_top_k: int = 25,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fails = [r for r in rows if r.verdict == "FAIL"]
    passes = [r for r in rows if r.verdict == "PASS"]
    by_severity = Counter(r.severity for r in fails if r.severity)
    by_layer = Counter(r.layer for r in rows)
    by_wiki = Counter(r.dwh_wiki for r in fails)

    # Blast radius — for top-K DWH objects with most FAILs, look outward
    top_objects = Counter(
        r.dwh_object for r in fails if r.layer in ("L1-structural", "L2-semantic")
    )

    lines: list[str] = []
    lines.append(f"# Tier 1 Claim Audit — {meta.scope}")
    lines.append("")
    lines.append(f"_Generated: {meta.started_at} → {meta.finished_at}_  ")
    lines.append(f"_Wall-clock: {meta.wall_clock_s:.1f}s_  ")
    lines.append(f"_Wikis scanned: {meta.total_wikis_scanned} | Tier 1 tags: {meta.total_tier1_tags}_  ")
    lines.append(f"_LLM judge: {'OFF' if meta.llm_disabled else (meta.judge_model or 'default')} | "
                 f"calls={meta.judge_calls_made} cache_hits={meta.judge_cache_hits} "
                 f"failed={meta.judge_failed}_")
    lines.append("")

    # Headline
    lines.append("## Headline")
    lines.append("")
    lines.append(f"- **PASS**: {len(passes)}")
    lines.append(f"- **FAIL**: {len(fails)}")
    for sev in ("HIGH", "MEDIUM", "LOW"):
        if by_severity.get(sev):
            lines.append(f"  - {sev}: {by_severity[sev]}")
    lines.append("")
    lines.append("By layer:")
    for layer, count in by_layer.most_common():
        lines.append(f"- `{layer}`: {count}")
    lines.append("")

    # Top corrupt wikis
    if by_wiki:
        lines.append("## Wikis with the most FAILs")
        lines.append("")
        lines.append("| Rank | Wiki | FAIL count |")
        lines.append("|------|------|------------|")
        for i, (wiki, count) in enumerate(by_wiki.most_common(20), start=1):
            lines.append(f"| {i} | `{_truncate_path(wiki)}` | {count} |")
        lines.append("")

    # Blast radius hot-list
    if top_objects and blast_radius_roots:
        lines.append(f"## Top {hot_list_top_k} corrupted columns — downstream blast radius")
        lines.append("")
        lines.append("For each DWH object with FAILs, the count of *.md files in each search "
                     "root that mention the object by name. A high downstream count means "
                     "many BI_DB_dbo / UC_generated wikis inherited the corrupted text.")
        lines.append("")
        header = ["DWH object", "FAILs"] + [r.relative_to(REPO).as_posix() for r in blast_radius_roots]
        lines.append("| " + " | ".join(header) + " |")
        lines.append("|" + "|".join(["---"] * len(header)) + "|")
        for obj, count in top_objects.most_common(hot_list_top_k):
            br = _blast_radius_for(obj, search_roots=blast_radius_roots)
            row = [f"`{obj}`", str(count)]
            for root in blast_radius_roots:
                row.append(str(br.get(root.relative_to(REPO).as_posix(), 0)))
            lines.append("| " + " | ".join(row) + " |")
        lines.append("")

    # FAIL detail
    if fails:
        lines.append(f"## FAIL detail (first {min(len(fails), max_fail_rows)} of {len(fails)})")
        lines.append("")
        # group by wiki for readability
        grouped: dict[str, list[AuditRow]] = defaultdict(list)
        for r in fails[:max_fail_rows]:
            grouped[r.dwh_wiki].append(r)
        for wiki, items in grouped.items():
            lines.append(f"### `{wiki}` — {len(items)} FAIL(s)")
            lines.append("")
            for r in items:
                lines.append(f"- **line {r.line_no}** `{r.column_name}` — "
                             f"{r.layer} / {r.severity or '-'}")
                lines.append(f"  - claim source: `{r.tier_claim_raw}`")
                lines.append(f"  - source wiki: `{_truncate_path(r.source_wiki) or '(unresolved)'}` "
                             f"(matched col `{r.source_column}` via {r.match_method or 'n/a'}, "
                             f"source tier `{r.source_tier or 'n/a'}`)")
                lines.append(f"  - current: {_shorten(r.current_desc)}")
                lines.append(f"  - source:  {_shorten(r.source_desc) or '_(empty)_'}")
                lines.append(f"  - reason:  {_shorten(r.judge_reason)}")
                if r.proposed_fix:
                    lines.append(f"  - **proposed**: {_shorten(r.proposed_fix, 320)}")
                if r.notes:
                    lines.append(f"  - notes:  {_shorten(r.notes)}")
                lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_metadata(meta: RunMetadata, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(asdict(meta), indent=2, ensure_ascii=False),
                        encoding="utf-8")


def utc_timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%SZ")


def utc_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
