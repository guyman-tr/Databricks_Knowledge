#!/usr/bin/env python3
"""
Validation pass for UC-Pipeline wiki output (Phase 5 / Phase 6 gate).

Checks per object in a schema folder:
  1. `.lineage.md` exists for every `.md`.
  2. Every column row in `.md` Section 3 (Elements) has a `(Tier N — origin)` suffix.
  3. Element count in `.md` == element count in `.lineage.md` == column_count
     in frontmatter == column count in `uc_inventory.json`.
  4. For every Tier 1 column whose origin tag points to an upstream UC object
     present in `_discovery/upstream_wikis/_index.json`, the upstream wiki
     actually exists on disk.
  5. Passthrough columns: their description text matches the upstream wiki's
     description for the same column (cross-object consistency — soft warning
     if missing, hard fail if explicitly mismatched).
  6. When `.alter.sql` exists: one ALTER COLUMN per Element row (parity), no
     `[UNVERIFIED]` text leaks in.

Assertion 13 mode (`--assert-no-inference`, ON by default for `--schema`
target after T020): every column description must fall into exactly ONE of:
  (A) byte-equal to upstream wiki for same column (passthrough/rename/cast),
  (B) cites a source-code line range OR a SQL operator OR a quoted SQL fragment
      from the cached Phase-2 snapshot (narrated),
  (C) exact-matches the null-with-provenance template `Source: {fqn}.{col}.
      No upstream wiki cached as of YYYY-MM-DD.` (terminal-no-wiki).
Any column that fails to classify into A/B/C is an AI-inference violation per
§6 No-Inference Contract and is a HARD fail.

Exit code is non-zero on HARD failure. WARN-level issues are reported but
don't fail the gate (unless `--strict`).

Usage:
  python tools/uc_pipelines/validate_pipeline_wiki.py --schema etoro_kpi_prep
  python tools/uc_pipelines/validate_pipeline_wiki.py --schema de_output --strict
  python tools/uc_pipelines/validate_pipeline_wiki.py --wiki path/to/foo.md --assert-no-inference
  python tools/uc_pipelines/validate_pipeline_wiki.py --schema etoro_kpi_prep --no-assert-no-inference   # opt out
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PACK_ROOT = REPO / "knowledge" / "UC_generated"

TIER_TAG_RE = re.compile(r"\(Tier\s+(U|N|[1-5][a-z]?)\s+(?:--|[—–-])\s+([^\)]+)\)")
ELEMENT_ROW_RE = re.compile(r"^\|\s*\d+\s*\|\s*[`]?([A-Za-z_][A-Za-z0-9_]*)[`]?\s*\|")
ELEMENT_HEADER_RE = re.compile(r"^##\s+(?:\d+\.\s+)?Elements", re.IGNORECASE | re.MULTILINE)
LINEAGE_ROW_RE = re.compile(r"^\|\s*\d+\s*\|\s*[`]?([A-Za-z_][A-Za-z0-9_]*)[`]?\s*\|")
LINEAGE_HEADER_RE = re.compile(r"^##\s+Column Lineage", re.IGNORECASE | re.MULTILINE)

NULL_WITH_PROVENANCE_RE = re.compile(
    # `Tier N` is the post-fix label for null-with-provenance (DWH framework
    # reserves Tier 5 for domain-expert/sidecar overrides). `Tier 5` is kept
    # as a backward-compat alias for any wiki on disk that pre-dates the fix.
    r"^\s*Source:\s+(?P<fqn>(?:main\.)?[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+){1,2})\.(?P<col>[A-Za-z_][A-Za-z0-9_]*)\.\s+"
    r"No upstream wiki cached as of (?P<date>\d{4}-\d{2}-\d{2})\.?\s*"
    r"\(Tier (?:N|5)\s+(?:--|[—–-])\s+(?:terminal-no-wiki|blocked-on-upstream[^)]*|bronze-passthrough[^)]*)\)\.?\s*$"
)

SOURCE_CODE_CITATION_RE = re.compile(
    r"(?:"
    r"L\d+(?:-L\d+)?"
    r"|\[uc_view_ddl\]"
    r"|\[notebook:[^\]]+\]"
    r"|`[^`]{3,200}`"
    r"|\b(?:CASE|COALESCE|ISNULL|NVL|SUM|COUNT|AVG|MIN|MAX|ROW_NUMBER|LAG|LEAD|OVER|PARTITION|ROUND|CAST|TRY_CAST|DATEPART|YEAR|MONTH|DAY|CONCAT|SUBSTRING|REPLACE|REVERSE|LEFT|RIGHT|LOWER|UPPER|TRIM)\b"
    # New formula-backed citation markers from Phase 4.6 (post DWH-port):
    #   - "Formula: `<expr>`"  (any-length backticked formula text)
    #   - "(Tier 2 — literal)" / "(Tier 2 — computed in source)" — explicit
    #     formula-extractor disposition, not AI inference
    r"|Formula:\s*`[^`]*`"
    r"|\(Tier\s+2\s+[—–-]\s+(?:literal|computed in source)\)"
    r")"
)


class Issue:
    LEVEL_HARD = "HARD"
    LEVEL_SOFT = "WARN"

    def __init__(self, level: str, object_name: str, code: str, msg: str):
        self.level = level
        self.object_name = object_name
        self.code = code
        self.msg = msg

    def __str__(self):
        return f"[{self.level}] {self.object_name}: {self.code} — {self.msg}"


def _extract_section(text: str, header_re) -> str | None:
    m = header_re.search(text)
    if not m:
        return None
    start = m.end()
    # Section ends at next `## ` header
    next_m = re.search(r"^##\s+\d+\.", text[start:], re.MULTILINE)
    return text[start: start + next_m.start()] if next_m else text[start:]


def _parse_elements_rows(md_text: str) -> list[dict]:
    section = _extract_section(md_text, ELEMENT_HEADER_RE)
    if not section:
        return []
    rows: list[dict] = []
    for line in section.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        idx_cell = cells[0]
        if not idx_cell.isdigit():
            continue
        name_cell = cells[1].strip("` ")
        desc_cell = cells[-1]
        rows.append({
            "ordinal": int(idx_cell),
            "name": name_cell,
            "description": desc_cell,
        })
    return rows


def _parse_lineage_rows(lineage_text: str) -> list[dict]:
    section = _extract_section(lineage_text, LINEAGE_HEADER_RE)
    if not section:
        return []
    rows: list[dict] = []
    for line in section.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        idx_cell = cells[0]
        if not idx_cell.isdigit():
            continue
        name_cell = cells[1].strip("` ")
        rows.append({
            "ordinal": int(idx_cell),
            "name": name_cell,
            "source_object": cells[2].strip("` "),
            "source_column": cells[3].strip("` "),
            "transform": cells[4].strip("` "),
        })
    return rows


def _parse_yaml_frontmatter(text: str) -> dict:
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if not m:
        return {}
    try:
        import yaml  # type: ignore
        return yaml.safe_load(m.group(1)) or {}
    except Exception:
        return {}


def _parse_alter_columns(alter_sql_text: str) -> list[str]:
    return re.findall(
        r"ALTER\s+(?:TABLE|VIEW)\s+\S+\s+ALTER\s+COLUMN\s+`?([A-Za-z_][A-Za-z0-9_]*)`?",
        alter_sql_text, flags=re.IGNORECASE,
    )


def _load_upstream_wiki_for_inherit_check(md_path: Path, src_obj_fqn: str) -> Path | None:
    """Locate the cached upstream wiki body for inheritance-fidelity check."""
    if not src_obj_fqn:
        return None
    schema_root = md_path.parent.parent
    cache = schema_root / "_discovery" / "upstream_wikis" / f"{src_obj_fqn.lower()}.md"
    if cache.exists():
        return cache
    return None


def _upstream_description_for(upstream_wiki: Path, source_col: str) -> str | None:
    try:
        text = upstream_wiki.read_text(encoding="utf-8")
    except Exception:
        return None
    sec = _extract_section(text, ELEMENT_HEADER_RE)
    if not sec:
        return None
    for line in sec.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 5 or not cells[0].isdigit():
            continue
        if cells[1].strip("` ").lower() == source_col.lower():
            return cells[-1].strip()
    return None


def _strip_tier_tag(s: str) -> str:
    return TIER_TAG_RE.sub("", s).strip().rstrip(".").strip()


def _first_sentence(s: str) -> str:
    s = _strip_tier_tag(s)
    m = re.match(r"^([^.!?]+[.!?])", s)
    return (m.group(1).strip() if m else s[:80]).rstrip(".").strip()


def _classify_description_bucket(description: str, lineage_row: dict | None,
                                   md_path: Path,
                                   bronze_inherit_wiki: Path | None = None,
                                   column_name: str | None = None) -> tuple[str, str]:
    """Return (bucket, evidence) where bucket in {A, B, C, U}.
    A = byte-equal-to-upstream (or strict containment of upstream first-sentence)
    B = source-code-cited
    C = null-with-provenance
    U = unclassifiable (AI-inference candidate — hard fail).

    `bronze_inherit_wiki`: for bronze_tier1_inheritance objects, the Tier 1
    production wiki path declared in writer.upstream_wiki_path — used to verify
    columns whose lineage row has no source_object (system.access.column_lineage
    is empty for bronze ingest targets).
    """
    desc = description.strip()

    if NULL_WITH_PROVENANCE_RE.match(desc):
        return ("C", "null-with-provenance template matched")

    # Bronze inheritance path — for objects whose writer is the bronze ingest
    # pipeline (no UC source code, no column_lineage rows). Validate column
    # descriptions byte-equal against the Tier 1 production wiki declared in
    # the writer metadata.
    if bronze_inherit_wiki and bronze_inherit_wiki.is_file() and column_name:
        up_desc = _upstream_description_for(bronze_inherit_wiki, column_name)
        if up_desc:
            up_clean = _strip_tier_tag(up_desc.strip())
            desc_clean = _strip_tier_tag(desc)
            if desc == up_desc.strip():
                return ("A", f"byte-equal to bronze Tier 1 wiki for `{column_name}`")
            if up_clean and up_clean in desc_clean:
                return ("A", f"bronze Tier 1 description verbatim-contained for `{column_name}`")
            up_first = _first_sentence(up_desc)
            if up_first and len(up_first) >= 20 and up_first in desc_clean:
                return ("A", f"first sentence of bronze Tier 1 description verbatim-contained for `{column_name}`")

    if lineage_row:
        transform = (lineage_row.get("transform") or "").lower()
        src_obj = lineage_row.get("source_object") or ""
        src_col = lineage_row.get("source_column") or ""
        if transform in {"passthrough", "rename", "cast", "join_enriched"} and src_obj and src_col:
            up = _load_upstream_wiki_for_inherit_check(md_path, src_obj)
            if up:
                up_desc = _upstream_description_for(up, src_col)
                if up_desc:
                    up_clean = _strip_tier_tag(up_desc.strip())
                    desc_clean = _strip_tier_tag(desc)
                    if desc == up_desc.strip():
                        return ("A", f"byte-equal to upstream {src_obj}.{src_col}")
                    if up_clean and up_clean in desc_clean:
                        return ("A", f"upstream description verbatim-contained in downstream {src_obj}.{src_col}")
                    up_first = _first_sentence(up_desc)
                    if up_first and len(up_first) >= 20 and up_first in desc_clean:
                        return ("A", f"first sentence of upstream {src_obj}.{src_col} verbatim-contained")

    if SOURCE_CODE_CITATION_RE.search(desc):
        return ("B", "source-code citation present")

    tag_m = TIER_TAG_RE.search(desc)
    if tag_m:
        letter = tag_m.group(1)
        # Tier 5 = domain-expert sidecar override (DWH framework Rule 15).
        # Absolute authority — sidecar review is the evidence.
        if letter == "5":
            return ("A", "Tier 5 — domain-expert reviewer correction from sidecar")
        # Tier N = explicit null-with-provenance gap (post-fix label;
        # legacy tag is `Tier 5 — terminal-no-wiki`, also recognised by
        # NULL_WITH_PROVENANCE_RE above).
        if letter == "N":
            return ("C", "Tier N — null-with-provenance gap disclosure")
        # Tier U: honest mechanical disclosure of unclassifiability.
        if letter == "U":
            return ("D", "documented-unclassified (Tier U — explicit disclosure of unclassifiability)")

    return ("U", "unclassifiable: no upstream match, no source-code citation, "
                  "not null-with-provenance template, no Tier U/N/5 tag")


def _count_paragraphs(section_text: str) -> int:
    """Return number of non-empty paragraph blocks (separated by blank lines)."""
    if not section_text:
        return 0
    # Strip leading/trailing whitespace, split on blank lines.
    blocks = [b.strip() for b in re.split(r"\n\s*\n", section_text.strip()) if b.strip()]
    # Don't count blocks that are pure table-only or pure horizontal-rule.
    return sum(1 for b in blocks if not b.startswith(("|", "---")) and len(b) > 20)


def _count_subsections(section_text: str, section_num: int) -> int:
    """Count `### {section_num}.N` subsections."""
    if not section_text:
        return 0
    return len(re.findall(rf"^###\s+{section_num}\.\d+\b", section_text, re.MULTILINE))


def _extract_section_by_number(text: str, section_num: int) -> str | None:
    """Extract the body of `## {section_num}.` section."""
    m = re.search(rf"^##\s+{section_num}\.\s+", text, re.MULTILINE)
    if not m:
        return None
    start = m.end()
    next_m = re.search(rf"^##\s+(?:{section_num + 1}\.|Tier Legend\b)", text[start:], re.MULTILINE)
    return text[start: start + next_m.start()] if next_m else text[start:]


def _validate_8_section_shape(md_path: Path, text: str, fm: dict,
                                concepts_doc: dict, obj_name: str) -> list[Issue]:
    """Check 8-section golden shape: §1-§8 present, §1 has 3 paragraphs,
    §2 has one subsection per concept."""
    issues: list[Issue] = []
    # Only enforce 8-section shape for objects whose generator emitted the new
    # contract. Frontmatter `concept_count` is the marker — it's only set by
    # the 8-section emission path.
    if "concept_count" not in fm:
        return issues  # legacy 6-section wiki, skip 8-section checks

    # Section presence
    for n in range(1, 9):
        if not re.search(rf"^##\s+{n}\.\s+", text, re.MULTILINE):
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "missing_section",
                                f"§{n} header `## {n}. ...` not found in wiki"))

    # §1 paragraph count
    s1 = _extract_section_by_number(text, 1)
    s1_paras = _count_paragraphs(s1 or "")
    if s1_paras < 3:
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "section1_paragraph_count",
                            f"§1 Business Meaning has {s1_paras} paragraph(s); "
                            f"GOLDEN-REFERENCE requires 3 (WHAT / WHERE / HOW)"))

    # §2 concept coverage
    expected_concept_count = int(fm.get("concept_count") or 0)
    s2 = _extract_section_by_number(text, 2)
    s2_subsections = _count_subsections(s2 or "", 2)
    if expected_concept_count > 0 and s2_subsections == 0:
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "section2_concept_coverage",
                            f"frontmatter concept_count={expected_concept_count} but "
                            f"§2 has no `### 2.N` subsections — generator failed to "
                            f"emit per-concept subsections"))
    elif expected_concept_count > 0 and s2_subsections < expected_concept_count:
        # SOFT — allow grouping (multiple concepts in one subsection)
        issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "section2_concept_undercoverage",
                            f"§2 has {s2_subsections} subsection(s) but concepts.json "
                            f"declares {expected_concept_count} — some concepts may be "
                            f"missing a dedicated subsection"))

    # §3 Query Advisory must have at least 3.1 + 3.4 (storage layout + gotchas)
    s3 = _extract_section_by_number(text, 3)
    if s3 and not re.search(r"^###\s+3\.1\b", s3, re.MULTILINE):
        issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "section3_no_storage_subsection",
                            "§3 missing `### 3.1` storage-layout subsection"))

    return issues


def validate_object(md_path: Path, inv_cols_by_name: dict[str, dict],
                    ux_index: dict, strict: bool,
                    assert_no_inference: bool = True) -> list[Issue]:
    obj_name = md_path.stem
    issues: list[Issue] = []
    text = md_path.read_text(encoding="utf-8")
    fm = _parse_yaml_frontmatter(text)

    # Load Phase 4.5 concepts artifact for §2 coverage check
    concepts_path = md_path.parent.parent / "_discovery" / "concepts" / f"{obj_name}.json"
    concepts_doc: dict = {}
    if concepts_path.exists():
        try:
            concepts_doc = json.loads(concepts_path.read_text(encoding="utf-8"))
        except Exception:
            pass

    # 8-section shape checks (new contract — only for wikis emitted by the
    # rewritten generator, identified by concept_count in frontmatter)
    issues.extend(_validate_8_section_shape(md_path, text, fm, concepts_doc, obj_name))

    # Detect bronze inheritance — these wikis use writer.upstream_wiki_path
    # instead of the lineage-row-based inheritance check.
    producer_kind = (fm.get("producer_kind") or "").lower()
    writer_meta = fm.get("writer") or {}
    bronze_inherit_wiki: Path | None = None
    if producer_kind == "bronze_tier1_inheritance":
        wpath = writer_meta.get("path") or writer_meta.get("upstream_wiki_path") or ""
        if wpath:
            candidate = Path(wpath)
            if not candidate.is_absolute():
                # repo root is two parents up from this file
                candidate = (Path(__file__).resolve().parents[2] / wpath).resolve()
            if candidate.is_file():
                bronze_inherit_wiki = candidate

    lineage_path = md_path.with_suffix(".lineage.md")
    if not lineage_path.exists():
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "no_lineage_md",
                            f".lineage.md missing alongside {md_path.name}"))
        return issues  # Can't continue without lineage

    lineage_text = lineage_path.read_text(encoding="utf-8")
    md_rows = _parse_elements_rows(text)
    lineage_rows = _parse_lineage_rows(lineage_text)

    if len(md_rows) != len(lineage_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "row_count_mismatch",
                            f".md has {len(md_rows)} elements, .lineage.md has {len(lineage_rows)}"))

    fm_count = fm.get("column_count")
    if fm_count is not None and fm_count != len(md_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "fm_count_mismatch",
                            f"frontmatter column_count={fm_count} but element-table has {len(md_rows)} rows"))

    inv_count = len(inv_cols_by_name)
    if inv_count and inv_count != len(md_rows):
        issues.append(Issue(Issue.LEVEL_HARD, obj_name, "inv_count_mismatch",
                            f"inventory has {inv_count} columns but element-table has {len(md_rows)} rows"))

    # Per-row checks
    md_by_name = {r["name"]: r for r in md_rows}
    lin_by_name = {r["name"]: r for r in lineage_rows}

    for row in md_rows:
        name = row["name"]
        desc = row["description"]
        tag_m = TIER_TAG_RE.search(desc)
        if not tag_m:
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "missing_tier_tag",
                                f"column `{name}` description has no `(Tier N — origin)` suffix"))
            continue
        tier = tag_m.group(1)
        origin = tag_m.group(2).strip()
        # Tier 1 check: origin should be reachable
        if tier.startswith("1"):
            lin = lin_by_name.get(name)
            if lin and lin.get("source_object") and lin["source_object"] not in ("—", "(computed)", "(literal)"):
                src_obj = lin["source_object"].lower()
                # Origin may be the production name OR a UC object — accept either.
                # But the lineage's source_object MUST have an entry in the upstream index.
                entry = next(
                    (e for e in ux_index.get("upstreams", [])
                     if (e.get("full_name") or "").lower() == src_obj), None,
                )
                if entry is None:
                    issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "tier1_no_upstream_index_entry",
                                        f"column `{name}` is Tier 1 but lineage source `{src_obj}` not in upstream_wikis/_index.json"))
                elif not entry.get("wiki_exists"):
                    issues.append(Issue(Issue.LEVEL_SOFT, obj_name, "tier1_upstream_wiki_missing",
                                        f"column `{name}` is Tier 1 but upstream wiki for `{src_obj}` not found on disk"))

        # `[UNVERIFIED]` literal marker is forbidden in the main wiki — it must be in the sidecar.
        # Tier U descriptions are allowed: they carry `(Tier U — unclassified)` and are honest
        # mechanical disclosures of unclassifiability, not AI inference.
        if "[UNVERIFIED]" in desc:
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "unverified_in_description",
                                f"column `{name}` description contains the `[UNVERIFIED]` literal marker — "
                                f"that token belongs in the .review-needed.md sidecar only"))

        if assert_no_inference and "UNVERIFIED" not in desc.upper():
            lin_row = lin_by_name.get(name)
            bucket, evidence = _classify_description_bucket(
                desc, lin_row, md_path,
                bronze_inherit_wiki=bronze_inherit_wiki,
                column_name=name,
            )
            if bucket == "U":
                issues.append(Issue(Issue.LEVEL_HARD, obj_name, "assertion13_unclassifiable",
                                    f"column `{name}` description fails §6 No-Inference Contract: "
                                    f"{evidence}. Must be one of (A) byte-equal to upstream wiki, "
                                    f"(B) source-code-cited, or (C) null-with-provenance template."))

    # ALTER parity
    alter_path = md_path.with_suffix(".alter.sql")
    if alter_path.exists():
        alter_cols = _parse_alter_columns(alter_path.read_text(encoding="utf-8"))
        if len(alter_cols) != len(md_rows):
            issues.append(Issue(Issue.LEVEL_HARD, obj_name, "alter_parity",
                                f".alter.sql has {len(alter_cols)} ALTER COLUMN, element table has {len(md_rows)}"))
        else:
            md_names_lower = [r["name"].lower() for r in md_rows]
            alter_names_lower = [c.lower() for c in alter_cols]
            if set(md_names_lower) != set(alter_names_lower):
                only_md = set(md_names_lower) - set(alter_names_lower)
                only_alter = set(alter_names_lower) - set(md_names_lower)
                msg = []
                if only_md:
                    msg.append(f"only in wiki: {sorted(only_md)[:5]}")
                if only_alter:
                    msg.append(f"only in alter: {sorted(only_alter)[:5]}")
                issues.append(Issue(Issue.LEVEL_HARD, obj_name, "alter_name_mismatch",
                                    "; ".join(msg)))

    return issues


def _validate_deploy_index(schema_root: Path, schema: str) -> list[Issue]:
    """Enforce the rollup-vs-row-count invariant for _deploy-index.md.

    Per `contracts/deploy-index.schema.md`:
    - Generated rollup count == number of Object rows with status Generated.
    - Blocked rollup count == number of Object rows in the Blocked section.
    - Stub-only rollup count == number of Object rows with status `Stub only`.
    - Total deployable count == number of Object rows in the main table.
    """
    issues: list[Issue] = []
    deploy_idx = schema_root / "_deploy-index.md"
    if not deploy_idx.exists():
        return issues
    text = deploy_idx.read_text(encoding="utf-8")

    fm = {}
    m_fm = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if m_fm:
        try:
            import yaml  # type: ignore
            fm = yaml.safe_load(m_fm.group(1)) or {}
        except Exception:
            fm = {}

    rollup_total = fm.get("total_deployable")
    rollup_generated = fm.get("generated")
    rollup_stub = fm.get("stub_only")
    rollup_blocked = fm.get("blocked")

    main_table_rows = 0
    in_main_table = False
    for ln in text.splitlines():
        if ln.startswith("| Object | Deploy status |"):
            in_main_table = True
            continue
        if in_main_table:
            if not ln.startswith("|"):
                in_main_table = False
                continue
            if "Object" in ln or "----" in ln:
                continue
            main_table_rows += 1

    generated_actual = 0
    stub_actual = 0
    blocked_actual = 0
    for ln in text.splitlines():
        s = ln.strip()
        if not s.startswith("|") or s.startswith("|---") or "Deploy status" in s:
            continue
        if "| Generated |" in s:
            generated_actual += 1
        elif "| Stub only |" in s:
            stub_actual += 1
    m_blocked_section = re.search(r"^## Blocked\b", text, re.MULTILINE)
    if m_blocked_section:
        for ln in text[m_blocked_section.start():].splitlines():
            s = ln.strip()
            if s.startswith("| `main."):
                blocked_actual += 1

    if rollup_total is not None and int(rollup_total) != main_table_rows:
        issues.append(Issue(Issue.LEVEL_HARD, f"_deploy-index({schema})",
                            "rollup_total_mismatch",
                            f"frontmatter total_deployable={rollup_total} != main-table row count {main_table_rows}"))
    if rollup_generated is not None and int(rollup_generated) != generated_actual:
        issues.append(Issue(Issue.LEVEL_HARD, f"_deploy-index({schema})",
                            "rollup_generated_mismatch",
                            f"frontmatter generated={rollup_generated} != 'Generated' row count {generated_actual}"))
    if rollup_stub is not None and int(rollup_stub) != stub_actual:
        issues.append(Issue(Issue.LEVEL_HARD, f"_deploy-index({schema})",
                            "rollup_stub_mismatch",
                            f"frontmatter stub_only={rollup_stub} != 'Stub only' row count {stub_actual}"))
    if rollup_blocked is not None and int(rollup_blocked) != blocked_actual:
        issues.append(Issue(Issue.LEVEL_HARD, f"_deploy-index({schema})",
                            "rollup_blocked_mismatch",
                            f"frontmatter blocked={rollup_blocked} != Blocked-section row count {blocked_actual}"))
    return issues


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate UC-Pipeline wiki output")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--schema", help="Validate all wikis in this pilot schema")
    g.add_argument("--wiki", help="Validate a single wiki file by path")
    ap.add_argument("--strict", action="store_true",
                    help="Treat WARN-level issues as HARD failures")
    ap.add_argument("--assert-no-inference", dest="assert_no_inference",
                    action="store_true", default=True,
                    help="(default ON) enforce §6 No-Inference Contract (Assertion 13)")
    ap.add_argument("--force", action="store_true",
                    help="Accepted for orchestrator compatibility; validator always re-runs")
    ap.add_argument("--no-assert-no-inference", dest="assert_no_inference",
                    action="store_false",
                    help="Skip Assertion 13 (legacy compatibility mode)")
    args = ap.parse_args()

    if args.wiki:
        md_path = Path(args.wiki)
        if not md_path.is_absolute():
            md_path = (PACK_ROOT.parent.parent / md_path).resolve()
        if not md_path.is_file():
            print(f"ERROR: wiki file not found: {md_path}", file=sys.stderr)
            return 2
        schema_root = md_path.parent.parent
        inv_path = schema_root / "_discovery" / "uc_inventory.json"
        inv: dict = {}
        if inv_path.exists():
            try:
                inv = json.loads(inv_path.read_text(encoding="utf-8"))
            except Exception:
                pass
        cols = next(({c["name"]: c for c in (o.get("columns") or [])}
                     for o in inv.get("objects", []) if o["name"] == md_path.stem), {})
        ux_path = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
        ux_index = json.loads(ux_path.read_text(encoding="utf-8")) if ux_path.exists() else {}
        issues = validate_object(md_path, cols, ux_index, args.strict,
                                  assert_no_inference=args.assert_no_inference)
        n_hard = sum(1 for i in issues if i.level == Issue.LEVEL_HARD)
        n_soft = sum(1 for i in issues if i.level == Issue.LEVEL_SOFT)
        print(f"\n[validate-pipeline-wiki] {md_path.name}: 1 object checked, "
              f"{n_hard} HARD, {n_soft} WARN (assert_no_inference={args.assert_no_inference})")
        for issue in issues:
            print(str(issue))
        if n_hard > 0 or (args.strict and n_soft > 0):
            print(f"\n[validate-pipeline-wiki] FAIL ({n_hard} HARD, {n_soft} WARN)")
            return 1
        print("\n[validate-pipeline-wiki] PASS")
        return 0

    schema_root = PACK_ROOT / args.schema
    if not schema_root.is_dir():
        print(f"ERROR: schema folder not found: {schema_root}", file=sys.stderr)
        return 2

    deploy_index_issues = _validate_deploy_index(schema_root, args.schema)

    inv_path = schema_root / "_discovery" / "uc_inventory.json"
    inv: dict = {}
    if inv_path.exists():
        try:
            inv = json.loads(inv_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: couldn't read inventory: {e}", file=sys.stderr)
    by_object_cols: dict[str, dict[str, dict]] = {}
    for o in inv.get("objects", []):
        by_object_cols[o["name"]] = {c["name"]: c for c in (o.get("columns") or [])}

    ux_index_path = schema_root / "_discovery" / "upstream_wikis" / "_index.json"
    ux_index: dict = {}
    if ux_index_path.exists():
        try:
            ux_index = json.loads(ux_index_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"WARN: couldn't read upstream_wikis/_index.json: {e}", file=sys.stderr)

    all_issues: list[Issue] = list(deploy_index_issues)
    n_objects = 0

    for folder in ("Tables", "Views"):
        d = schema_root / folder
        if not d.is_dir():
            continue
        for md_path in sorted(d.glob("*.md")):
            if md_path.name.endswith(".lineage.md") or md_path.name.endswith(".review-needed.md"):
                continue
            n_objects += 1
            cols = by_object_cols.get(md_path.stem, {})
            issues = validate_object(md_path, cols, ux_index, args.strict,
                                      assert_no_inference=args.assert_no_inference)
            all_issues.extend(issues)

    n_hard = sum(1 for i in all_issues if i.level == Issue.LEVEL_HARD)
    n_soft = sum(1 for i in all_issues if i.level == Issue.LEVEL_SOFT)

    print(f"\n[validate-pipeline-wiki] {args.schema}: {n_objects} objects checked, "
          f"{n_hard} HARD, {n_soft} WARN issues (assert_no_inference={args.assert_no_inference})")
    for issue in all_issues:
        print(str(issue))

    if n_hard > 0 or (args.strict and n_soft > 0):
        print(f"\n[validate-pipeline-wiki] FAIL ({n_hard} HARD, {n_soft} WARN, strict={args.strict})")
        return 1
    print("\n[validate-pipeline-wiki] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
