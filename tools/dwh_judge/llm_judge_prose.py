"""LLM prose judge for the DWH wiki.

For every DWH_dbo object that has at least one column description in
``knowledge/_dwh_wiki_claims.csv``, builds ONE grounded prompt that asks the
model to verdict every column description as WRONG, SLOPPY, CORRECT, or
UNVERIFIABLE. The grounding blob contains:

- the object's full DDL (every column's type/nullable/default)
- any DWH_dbo SP whose body mentions the object (full text)
- any upstream production wiki page referenced by the column's lineage tag

Output: ``knowledge/_dwh_llm_judge.csv``

Hard rules:
1. The LLM MUST quote a verbatim contradicting substring of the ground-truth
   blob to support a WRONG verdict. The script enforces this with a literal
   ``in`` check; verdicts that fail the check are coerced to UNVERIFIABLE.
2. The judge writes only CSV. It never edits wiki files. The applier does
   that, gated by ``approve_y_n=Y`` in the central review CSV.

Driver: the local Claude CLI (``claude.cmd``) is the default. ``--dump-only``
skips the CLI entirely and emits the prompts to a JSONL file so the user can
run them through any LLM and feed responses back.

Usage:
    python tools/dwh_judge/llm_judge_prose.py                 # full run
    python tools/dwh_judge/llm_judge_prose.py --limit 5       # smoke-test
    python tools/dwh_judge/llm_judge_prose.py --dump-only     # no CLI calls
    python tools/dwh_judge/llm_judge_prose.py --object Dim_Customer
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SNAP = REPO / "knowledge" / "_dwh_truth_snapshot"
CLAIMS_CSV = REPO / "knowledge" / "_dwh_wiki_claims.csv"
OUT_CSV = REPO / "knowledge" / "_dwh_llm_judge.csv"
PROMPTS_JSONL = REPO / "knowledge" / "_dwh_llm_prompts.jsonl"
CACHE_DIR = REPO / "knowledge" / "_dwh_llm_judge_cache"

MAX_GROUND_TRUTH_CHARS = 60_000
MAX_DESC_CHARS = 1_200

# ---------------------------------------------------------------------------
# Claude CLI driver (reuses the discovery pattern from tools/wiki-auditor).
# ---------------------------------------------------------------------------


def _resolve_claude_cli() -> str | None:
    override = os.environ.get("DWH_JUDGE_CLAUDE")
    if override and Path(override).exists():
        return override
    for cand in [
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude.cmd",
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude",
    ]:
        if cand.exists():
            return str(cand)
    return shutil.which("claude")


def _run_claude(prompt: str, timeout_s: int = 300) -> str | None:
    cli = _resolve_claude_cli()
    if not cli:
        return None
    try:
        proc = subprocess.run(
            [cli, "--print", "--output-format", "text"],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            encoding="utf-8",
            errors="replace",
        )
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as e:
        print(f"  [llm] subprocess error: {e}", flush=True)
        return None
    if proc.returncode != 0:
        print(f"  [llm] non-zero exit: {proc.returncode}; stderr={proc.stderr[:200]}",
              flush=True)
        return None
    out = proc.stdout or ""
    if not out.strip():
        return None
    return out


# ---------------------------------------------------------------------------
# Ground-truth blob builder
# ---------------------------------------------------------------------------


def _format_ddl_line(c: dict) -> str:
    t = c["data_type"]
    if t in ("varchar", "char", "nvarchar", "nchar") and c.get("char_max_len") is not None:
        ml = c["char_max_len"]
        t = f"{t}({'max' if ml == -1 else ml})"
    elif t in ("decimal", "numeric") and c.get("numeric_precision") is not None:
        t = f"{t}({c['numeric_precision']},{c.get('numeric_scale') or 0})"
    nullable = "NULL" if c["is_nullable"] else "NOT NULL"
    default = ""
    if c.get("column_default"):
        default = f" DEFAULT {c['column_default']}"
    return f"  {c['name']} {t} {nullable}{default}"


def _relevant_sp_snippets(object_name: str, sp_code: dict, max_total_chars: int) -> str:
    """Return a concatenation of SP bodies that reference the object."""
    needle = object_name
    snippets: list[str] = []
    total = 0
    # Strong preference for SPs whose name contains the object name.
    name_matches = sorted([k for k in sp_code if object_name in k])
    body_matches = sorted([k for k in sp_code if k not in name_matches
                           and needle in (sp_code[k] or "")])
    for k in name_matches + body_matches:
        body = sp_code[k] or ""
        snip = f"\n-- SP: DWH_dbo.{k}\n{body}\n"
        if total + len(snip) > max_total_chars:
            # Try to fit at least a 4k trimmed slice with a marker.
            remaining = max_total_chars - total - 200
            if remaining > 1000:
                snip = (f"\n-- SP: DWH_dbo.{k} (truncated, full length {len(body)})\n"
                        f"{body[:remaining]}\n-- ...[truncated]\n")
                snippets.append(snip)
                total += len(snip)
            break
        snippets.append(snip)
        total += len(snip)
    return "".join(snippets)


def _upstream_for_object(
    object_name: str,
    column_descriptions: dict[str, str],
    upstream: dict,
    max_total_chars: int,
) -> str:
    """Find production wiki files referenced in the column descriptions and
    return their concatenated bodies (subject to the size cap)."""
    prod_tables = upstream.get("prod_tables", {})
    referenced: dict[str, str] = {}
    pat = re.compile(r"\b([A-Z][A-Za-z0-9]+)\.([A-Z][A-Za-z0-9_]+)\b")
    for col, desc in column_descriptions.items():
        for sch, tbl in pat.findall(desc):
            key = f"{sch}.{tbl}"
            if key in prod_tables and key not in referenced:
                referenced[key] = prod_tables[key]
    if not referenced:
        return ""
    out: list[str] = []
    total = 0
    for key, rel in sorted(referenced.items()):
        path = REPO / rel
        try:
            body = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        # First 4k of each upstream wiki is plenty for context.
        if len(body) > 4000:
            body = body[:4000] + "\n[...upstream wiki truncated...]"
        chunk = f"\n--- Upstream wiki: {key} ({rel}) ---\n{body}\n"
        if total + len(chunk) > max_total_chars:
            break
        out.append(chunk)
        total += len(chunk)
    return "".join(out)


def _build_ground_truth(
    object_name: str,
    object_ddl: dict,
    sp_code: dict,
    upstream: dict,
    column_descriptions: dict[str, str],
) -> str:
    ddl_lines = [_format_ddl_line(c) for c in object_ddl["columns"]]
    kind = object_ddl["kind"]
    ddl_block = f"DDL of DWH_dbo.{object_name} ({kind}):\n" + "\n".join(ddl_lines)

    # Budget the SP + upstream content together.
    remaining = MAX_GROUND_TRUTH_CHARS - len(ddl_block) - 1000
    sp_budget = max(2000, remaining // 2)
    up_budget = max(2000, remaining - sp_budget)

    sp_block = _relevant_sp_snippets(object_name, sp_code, sp_budget)
    up_block = _upstream_for_object(object_name, column_descriptions,
                                    upstream, up_budget)

    parts = [ddl_block]
    if sp_block:
        parts.append("\nRelevant SP code (DWH_dbo, full bodies):\n" + sp_block)
    if up_block:
        parts.append("\nUpstream production wiki excerpts:\n" + up_block)
    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------


SYSTEM_INSTRUCTIONS = """You are a strict data-documentation auditor for the eToro DWH.

You will receive ONE DWH_dbo object's ground truth (live DDL + every SP that
touches the object + every upstream production-wiki excerpt referenced in the
descriptions) and a list of column descriptions written in the local DWH
wiki. Each description has a stable ``claim_id`` so you can reference it
unambiguously even when two descriptions exist for the same column.

For each description you must classify it as:

  WRONG          The description states a fact that contradicts something
                 in the ground truth blob above. You MUST quote the
                 contradicting Tier-1 text verbatim. If you cannot quote a
                 literal substring of the ground-truth blob that contradicts
                 the description, return UNVERIFIABLE instead.

  SLOPPY         Verbose, redundant, missing context, or vague -- but
                 factually consistent with the ground truth. Skip this in
                 your output (do not return SLOPPY rows).

  CORRECT        Factually consistent with the ground truth.

  UNVERIFIABLE   The ground truth gives you no way to evaluate the claim
                 (e.g. the description is about upstream business rules that
                 are not in scope). Return this rather than guessing.

Output format: ONLY a JSON array, one object per description you flagged as
WRONG. Do NOT emit rows for SLOPPY / CORRECT / UNVERIFIABLE; the downstream
filter drops them anyway, and you save bandwidth. NEVER include markdown
fences.

Each row has these keys, all required:

  {
    "claim_id":            "<EXACT claim_id from the input>",
    "column":              "<column name>",
    "verdict":             "WRONG",
    "contradicting_fact_verbatim": "<EXACT verbatim substring of the ground
                                    truth blob that proves the wiki is wrong>",
    "wiki_description":    "<the original wiki description verbatim>",
    "suggested_rewrite":   "<1-2 sentence correct rewrite -- factual, no fluff>"
  }

If you find no WRONG descriptions, return an empty array: []
"""


@dataclass
class ColumnDesc:
    column: str
    description: str
    wiki_file: str
    wiki_line: int


def _assign_claim_ids(
    cols: list[ColumnDesc],
) -> tuple[list[dict], dict[str, list[ColumnDesc]]]:
    """Deduplicate by (column, normalized description) and assign a stable
    ``claim_id`` to each unique entry.

    Returns:
        prompt_items: list of {"claim_id", "column", "wiki_description"}.
        claim_id_to_cds: claim_id -> every ColumnDesc that shares that text
            (e.g. both .md and .alter.sql entries when the prose is identical).
    """
    variants_per_col: dict[str, list[str]] = {}
    for c in cols:
        norm = c.description.strip()
        if norm not in variants_per_col.setdefault(c.column, []):
            variants_per_col[c.column].append(norm)

    prompt_items: list[dict] = []
    claim_id_to_cds: dict[str, list[ColumnDesc]] = {}
    seen_keys: dict[tuple[str, str], str] = {}

    for c in cols:
        norm = c.description.strip()
        key = (c.column, norm)
        if key not in seen_keys:
            n_variants = len(variants_per_col[c.column])
            if n_variants == 1:
                claim_id = c.column
            else:
                idx = variants_per_col[c.column].index(norm) + 1
                claim_id = f"{c.column}#{idx}"
            seen_keys[key] = claim_id
            desc = c.description
            if len(desc) > MAX_DESC_CHARS:
                desc = desc[:MAX_DESC_CHARS - 30] + " [...truncated...]"
            prompt_items.append({
                "claim_id": claim_id,
                "column": c.column,
                "wiki_description": desc,
            })
        claim_id = seen_keys[key]
        claim_id_to_cds.setdefault(claim_id, []).append(c)

    return prompt_items, claim_id_to_cds


def _build_prompt(object_name: str, kind: str, ground_truth: str,
                  prompt_items: list[dict]) -> str:
    payload = json.dumps(prompt_items, indent=2, ensure_ascii=False)
    return (
        SYSTEM_INSTRUCTIONS
        + f"\n\nObject: DWH_dbo.{object_name} ({kind})\n\n"
        + "Ground truth (verbatim Tier-1 sources):\n"
        + "=" * 70 + "\n"
        + ground_truth + "\n"
        + "=" * 70 + "\n\n"
        + "Descriptions to judge (echo claim_id back in every WRONG row):\n"
        + payload
        + "\n\nReturn ONLY the JSON array. No prose."
    )


# ---------------------------------------------------------------------------
# Response parsing & verification
# ---------------------------------------------------------------------------


_JSON_FENCE = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL | re.IGNORECASE)


def _extract_json_array(text: str) -> list | None:
    if not text:
        return None
    fence = _JSON_FENCE.search(text)
    body = fence.group(1).strip() if fence else text.strip()
    start = body.find("[")
    if start < 0:
        return None
    depth = 0
    end = -1
    for i in range(start, len(body)):
        ch = body[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end < 0:
        return None
    blob = body[start:end]
    try:
        parsed = json.loads(blob)
    except json.JSONDecodeError:
        return None
    if not isinstance(parsed, list):
        return None
    return parsed


def _verify_verbatim(quote: str, ground_truth: str) -> bool:
    """Strict substring check. Empty quote is invalid."""
    if not quote or not isinstance(quote, str):
        return False
    if len(quote.strip()) < 10:
        # Too short to be a meaningful citation.
        return False
    return quote in ground_truth


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None,
                    help="Stop after N objects (smoke-test).")
    ap.add_argument("--object", action="append", default=None,
                    help="Limit to specific object name(s).")
    ap.add_argument("--dump-only", action="store_true",
                    help="Don't call the LLM. Just write prompts to JSONL.")
    ap.add_argument("--force", action="store_true",
                    help="Ignore cached LLM responses and re-prompt.")
    args = ap.parse_args()

    print("Loading snapshot + claims...", flush=True)
    ddl = json.loads((SNAP / "ddl.json").read_text(encoding="utf-8"))
    sp_code = json.loads((SNAP / "sp_code.json").read_text(encoding="utf-8"))
    upstream = json.loads((SNAP / "upstream_index.json").read_text(encoding="utf-8"))

    # Group description claims by object.
    by_object: dict[str, list[ColumnDesc]] = {}
    with CLAIMS_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["claim_type"] != "description":
                continue
            if args.object and r["object"] not in args.object:
                continue
            by_object.setdefault(r["object"], []).append(ColumnDesc(
                column=r["column"],
                description=r["claim_value"],
                wiki_file=r["wiki_file"],
                wiki_line=int(r["wiki_line"]),
            ))

    objects = sorted(by_object.keys())
    if args.limit:
        objects = objects[:args.limit]
    print(f"  Objects to judge: {len(objects)}; "
          f"avg cols/object: "
          f"{sum(len(by_object[o]) for o in objects) / max(1, len(objects)):.1f}",
          flush=True)

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    PROMPTS_JSONL.parent.mkdir(parents=True, exist_ok=True)
    prompts_fp = PROMPTS_JSONL.open("w", encoding="utf-8")

    all_violations: list[dict] = []
    stats = {"objects_done": 0, "llm_calls": 0, "parse_fails": 0,
             "wrong_emitted": 0, "verbatim_fail": 0, "no_cli": 0}

    stats["legacy_cache_dropped"] = 0
    stats["legacy_cache_used"] = 0
    stats["legacy_ambiguous_drops"] = 0

    for obj in objects:
        cols = by_object[obj]
        ddl_obj = ddl.get(obj)
        if ddl_obj is None:
            print(f"  [skip] {obj}: not in DDL snapshot", flush=True)
            continue

        prompt_items, claim_id_to_cds = _assign_claim_ids(cols)
        cols_by_name: dict[str, set[str]] = {}
        for c in cols:
            cols_by_name.setdefault(c.column, set()).add(c.description.strip())
        has_ambiguity = any(len(v) > 1 for v in cols_by_name.values())

        column_descs = {item["column"]: item["wiki_description"] for item in prompt_items}
        ground_truth = _build_ground_truth(obj, ddl_obj, sp_code, upstream,
                                           column_descs)
        prompt = _build_prompt(obj, ddl_obj["kind"], ground_truth, prompt_items)

        prompts_fp.write(json.dumps({
            "object": obj,
            "kind": ddl_obj["kind"],
            "n_columns": len(prompt_items),
            "prompt": prompt,
        }, ensure_ascii=False) + "\n")

        if args.dump_only:
            stats["objects_done"] += 1
            continue

        cache_path = CACHE_DIR / f"{obj}.json"
        response_text: str | None = None
        legacy_cache = False
        if cache_path.exists() and not args.force:
            try:
                cached = json.loads(cache_path.read_text(encoding="utf-8"))
                response_text = cached["response"]
                cached_has_claim_id = '"claim_id"' in (response_text or "")
                if has_ambiguity and not cached_has_claim_id:
                    # Legacy cache cannot disambiguate; invalidate.
                    stats["legacy_cache_dropped"] += 1
                    response_text = None
                    print(f"  [cache] {obj}: dropped (legacy, ambiguous)", flush=True)
                else:
                    legacy_cache = not cached_has_claim_id
                    if legacy_cache:
                        stats["legacy_cache_used"] += 1
                    print(f"  [cache] {obj} ({len(prompt_items)} items"
                          f"{', legacy' if legacy_cache else ''})", flush=True)
            except Exception:
                response_text = None

        if response_text is None:
            print(f"  [llm] {obj} ({len(prompt_items)} items, "
                  f"gt={len(ground_truth)} chars)...", flush=True)
            response_text = _run_claude(prompt)
            stats["llm_calls"] += 1
            if response_text is None:
                stats["no_cli"] += 1
                print(f"  [llm] {obj}: no CLI response", flush=True)
                continue
            cache_path.write_text(
                json.dumps({"object": obj, "response": response_text}, ensure_ascii=False),
                encoding="utf-8",
            )

        parsed = _extract_json_array(response_text)
        if parsed is None:
            stats["parse_fails"] += 1
            print(f"  [parse] {obj}: failed", flush=True)
            continue

        obj_violations = 0
        for row in parsed:
            if not isinstance(row, dict):
                continue
            verdict = row.get("verdict", "")
            if verdict != "WRONG":
                continue
            quote = row.get("contradicting_fact_verbatim", "")
            if not _verify_verbatim(quote, ground_truth):
                stats["verbatim_fail"] += 1
                continue

            claim_id = row.get("claim_id", "")
            col = row.get("column", "")

            # Resolve claim_id -> list[ColumnDesc].
            cds = claim_id_to_cds.get(claim_id)
            if cds is None and legacy_cache:
                # Legacy response: no claim_id. Fall back to column lookup,
                # but only if the column has exactly ONE variant in this object
                # (otherwise the mapping is genuinely ambiguous).
                if cols_by_name.get(col) and len(cols_by_name[col]) == 1:
                    # Single variant -> only one claim_id key starts with col.
                    cds = next((v for k, v in claim_id_to_cds.items() if k == col),
                               None)
                else:
                    stats["legacy_ambiguous_drops"] += 1
                    continue
            if not cds:
                continue

            for meta in cds:
                stats["wrong_emitted"] += 1
                obj_violations += 1
                all_violations.append({
                    "object": obj,
                    "column": meta.column,
                    "claim_type": "description",
                    "wiki_value": row.get("wiki_description", meta.description)[:2000],
                    "truth_value": row.get("suggested_rewrite", "")[:2000],
                    "truth_source": "LLM-judged with verbatim Tier-1 citation",
                    "wiki_file": meta.wiki_file,
                    "wiki_line": meta.wiki_line,
                    "verdict_source": "llm",
                    "verdict": "WRONG",
                    "contradicting_fact_verbatim": quote[:2000],
                    "raw_context": meta.description[:300],
                })
        stats["objects_done"] += 1
        if obj_violations:
            print(f"  [done] {obj}: {obj_violations} WRONG", flush=True)

    prompts_fp.close()

    if not args.dump_only:
        OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
        with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=[
                "object", "column", "claim_type", "wiki_value", "truth_value",
                "truth_source", "wiki_file", "wiki_line", "verdict_source",
                "verdict", "contradicting_fact_verbatim", "raw_context",
            ])
            w.writeheader()
            for v in all_violations:
                w.writerow(v)
        print(f"\nWrote {OUT_CSV.relative_to(REPO)} ({len(all_violations)} WRONG rows)")
    print(f"Wrote {PROMPTS_JSONL.relative_to(REPO)} ({stats['objects_done']} objects)")
    print("\nStats:")
    for k, v in stats.items():
        print(f"  {k:<22} {v}")


if __name__ == "__main__":
    main()
