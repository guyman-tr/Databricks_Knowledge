"""
Build a Synapse -> Unity Catalog object map for all objects referenced in
knowledge/skills/**.md.

This script lives in the **domain-knowledge** repo (Domain_Knowledge)
but reads several wiki-side artifacts from the sibling **wiki** repo
(Databricks_Knowledge). The wiki repo's location is resolved as follows:

  1. Environment variable WIKI_REPO_ROOT (preferred for CI / non-default layouts).
  2. Sibling on disk: <this_repo>/../Databricks_Knowledge.
  3. Fallback: <this_repo> itself (covers the legacy single-repo layout where
     skills + wikis lived together).

If the wiki side is missing, alter.sql / pipeline-map / uc_domains / synapse-wiki
discovery is silently skipped — only HARDCODED_UC_OVERRIDES, _node_alias_map.json,
and _kpi_views_index.json (both local) will resolve refs. Re-run from a checkout
that has the wiki repo available for a full pass.

Sources of truth (priority order):
  1. .alter.sql files in <wiki>/knowledge/synapse/Wiki/<schema>/Tables/*.alter.sql
     -> "-- UC Target: <name>" line is the deployed UC fully-qualified name,
        OR "_Not_Migrated" sentinel when intentionally Synapse-only.
  2. <wiki>/knowledge/synapse/Wiki/_generic_pipeline_mapping.json
     -> deterministic ETL mapping: (database_name, schema_name, table_name) -> uc_table
  3. <this_repo>/knowledge/skills/_node_alias_map.json
     -> alias map built during graph parsing (heterogeneous, may include UC name).
  4. <this_repo>/knowledge/skills/_kpi_views_index.json
     -> ground truth for views in main.etoro_kpi[_prep[_stg]].
  5. <wiki>/knowledge/uc_domains/<product>/schemas/<schema>/<Tables|Views>/*.md
     -> ground truth for product-specific UC dumps (spaceship, moneyfarm).

Output (always written to this repo):
  - knowledge/skills/_uc_object_map.json   (machine-readable; one entry per skill ref)
  - knowledge/skills/_uc_object_map.md     (human-readable)
  - knowledge/skills/_uc_object_map.unmapped.txt  (refs we could not resolve)
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SKILLS_DIR = REPO / "knowledge" / "skills"


def _resolve_wiki_repo() -> Path:
    """Return the wiki repo root.

    Priority: env var WIKI_REPO_ROOT > sibling Databricks_Knowledge > self.
    """
    env = os.environ.get("WIKI_REPO_ROOT")
    if env:
        p = Path(env).expanduser().resolve()
        if p.exists():
            return p
        print(
            f"[warn] WIKI_REPO_ROOT={env} does not exist; falling back to sibling/self.",
            file=sys.stderr,
        )

    sibling = REPO.parent / "Databricks_Knowledge"
    if (sibling / "knowledge" / "synapse" / "Wiki").exists():
        return sibling

    if (REPO / "knowledge" / "synapse" / "Wiki").exists():
        return REPO

    print(
        "[warn] No wiki repo located. Set WIKI_REPO_ROOT or clone "
        "Databricks_Knowledge as a sibling. Wiki-side resolution will be skipped.",
        file=sys.stderr,
    )
    return REPO  # last resort; wiki paths simply won't exist below


WIKI_REPO = _resolve_wiki_repo()
WIKI_DIR = WIKI_REPO / "knowledge" / "synapse" / "Wiki"
PROD_DIR = WIKI_REPO / "knowledge" / "ProdSchemas"
UC_DOMAINS_DIR = WIKI_REPO / "knowledge" / "uc_domains"
PIPELINE_MAP_PATH = WIKI_DIR / "_generic_pipeline_mapping.json"
ALIAS_MAP_PATH = SKILLS_DIR / "_node_alias_map.json"
KPI_INDEX_PATH = SKILLS_DIR / "_kpi_views_index.json"


# Synapse "virtual schema" -> (production database, production schema).
# Synapse exposes replicated production tables under aliased schemas; the
# pipeline mapping is keyed on the *real* prod (database, schema, table).
# These let us bridge skill refs like "EXW_Wallet.SentTransactions" to the
# pipeline-mapped UC name.
SYNAPSE_VIRTUAL_SCHEMA_TO_PROD: dict[str, tuple[str, str]] = {
    "EXW_Wallet": ("WalletDB", "Wallet"),
    "EXW_Dictionary": ("WalletDB", "Dictionary"),
    "eMoney_Tribe": ("FiatDwhDB", "Tribe"),
    # FiatDwhDB.dbo is sometimes referenced directly as "FiatDwhDB.dbo.<X>"
    # which is already a pipeline-map key, no synonym needed.
}


# User-confirmed UC view aliases for objects that exist as Synapse wikis but
# were intentionally NOT materialized in UC; they are exposed as views in
# `main.etoro_kpi_prep`. Source: user (2026-05-05).
HARDCODED_UC_OVERRIDES: dict[str, dict] = {
    "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform": {
        "uc_target": "main.etoro_kpi_prep.v_mimo_tradingplatform",
        "uc_object_type": "VIEW",
        "uc_status": "deployed_view_alias",
        "source": "user_override_2026-05-05",
        "note": "Not materialized in UC; queryable as etoro_kpi_prep view.",
    },
    "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform": {
        "uc_target": "main.etoro_kpi_prep.v_mimo_emoneyplatform",
        "uc_object_type": "VIEW",
        "uc_status": "deployed_view_alias",
        "source": "user_override_2026-05-05",
        "note": "Not materialized in UC; queryable as etoro_kpi_prep view.",
    },
    "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform": {
        "uc_target": "main.etoro_kpi_prep.v_mimo_options_platform",
        "uc_object_type": "VIEW",
        "uc_status": "deployed_view_alias",
        "source": "user_override_2026-05-05",
        "note": "Not materialized in UC; queryable as etoro_kpi_prep view.",
    },
    # Hallucinated by an earlier skill draft; the Crypto Wallet platform is
    # OFF the MIMO graph (no per-platform crypto MIMO table exists in DWH).
    # Crypto inflows show up in MIMO_AllPlatforms only after C2F conversion
    # (where they arrive in the eMoney or Trading platforms).
    "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Crypto_Platform": {
        "uc_target": None,
        "uc_object_type": None,
        "uc_status": "non_existent",
        "source": "user_override_2026-05-05",
        "note": "DOES NOT EXIST. Crypto wallet is OFF the MIMO graph. Use MIMO_AllPlatforms with PlatformID filter, or query EXW_dbo facts directly.",
    },
    # Old-DDR vestiges; user instructed to drop all 'old DDR' references in
    # favor of new BI_DB_DDR_Fact_* / BI_DB_DDR_Customer_* framework.
    "BI_DB_dbo.BI_DB_LTV_Predictions": {
        "uc_target": None, "uc_object_type": None, "uc_status": "deprecated_old_ddr",
        "source": "user_override_2026-05-05",
        "note": "Old DDR (LTV). Use new DDR framework. Do not reference.",
    },
    "BI_DB_dbo.BI_DB_LTV_BI_Actual": {
        "uc_target": None, "uc_object_type": None, "uc_status": "deprecated_old_ddr",
        "source": "user_override_2026-05-05",
        "note": "Old DDR (LTV). Use new DDR framework. Do not reference.",
    },
    "BI_DB_dbo.BI_DB_CID_DailyPanel_FullData": {
        "uc_target": None, "uc_object_type": None, "uc_status": "deprecated_old_ddr",
        "source": "user_override_2026-05-05",
        "note": "Old DDR (super-wide daily panel). Use new DDR framework. Do not reference.",
    },
    "BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData": {
        "uc_target": None, "uc_object_type": None, "uc_status": "deprecated_old_ddr",
        "source": "user_override_2026-05-05",
        "note": "Old DDR (super-wide monthly panel). Use new DDR framework. Do not reference.",
    },
    "BI_DB_dbo.BI_DB_DDR_CID_Level": {
        "uc_target": None, "uc_object_type": None, "uc_status": "deprecated_old_ddr",
        "source": "user_override_2026-05-05",
        "note": "Old DDR (CID-level rollup). Use new DDR framework. Do not reference.",
    },
}


# ---------------------------------------------------------------------------
# 1. Source loaders
# ---------------------------------------------------------------------------

def load_synapse_wiki_index() -> set[str]:
    """Set of `<Schema>.<Object>` known to have a Synapse Wiki page."""
    out: set[str] = set()
    for md in WIKI_DIR.rglob("*.md"):
        if md.name.startswith("_"):
            continue
        # Only "Tables/" md, ignore .lineage.md / .review-needed.md by stem
        stem = md.stem
        if stem.endswith(".lineage") or stem.endswith(".review-needed"):
            continue
        try:
            i = md.parts.index("Wiki")
        except ValueError:
            continue
        if i + 1 >= len(md.parts):
            continue
        schema = md.parts[i + 1]  # e.g. BI_DB_dbo
        out.add(f"{schema}.{stem}")
    return out


def load_alter_sql_targets() -> dict[str, dict]:
    """schema.object (Synapse-cased) -> {uc_target, source}"""
    out: dict[str, dict] = {}
    pattern = re.compile(r"^--\s*UC Target:\s*`?([^`\r\n]+?)`?\s*(?:--.*)?$", re.MULTILINE)
    for alter_path in WIKI_DIR.rglob("*.alter.sql"):
        # filename: BI_DB_DDR_Fact_MIMO_AllPlatforms.alter.sql in BI_DB_dbo/Tables/
        try:
            text = alter_path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        m = pattern.search(text)
        if not m:
            continue
        target = m.group(1).strip()
        # normalise: strip leading "main." if present, lowercase, drop backticks
        target_clean = target.strip().strip("`")

        # Synapse schema = parent folder of "Tables/<file>.alter.sql"
        # e.g. .../BI_DB_dbo/Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.alter.sql
        try:
            schema = alter_path.parent.parent.name  # BI_DB_dbo
        except Exception:
            schema = ""
        obj = alter_path.stem.replace(".alter", "")
        # Strip ".alter" leftovers (Path.stem already drops .sql)
        if obj.endswith(".alter"):
            obj = obj[:-6]
        full_synapse = f"{schema}.{obj}"

        target_lower = target_clean.lower()
        is_not_migrated = (
            target_lower.startswith("_not_migrated")
            or target_lower.startswith("_not found")
            or "no uc target" in target_lower
            or "custom billing pipeline" in target_lower  # Fact_Deposit_State / similar
            or target_clean.startswith("_")               # any other "_..." sentinel
        )
        # Heuristic: only accept fully-qualified UC targets that look like
        # main.<schema>.<obj> with at least 2 dots and lowercase letters/_.
        looks_like_uc = (
            target_clean.count(".") >= 2
            and target_clean.split(".")[0] in {"main", "pii_data"}
        )
        if is_not_migrated:
            uc_status = "not_migrated"
            uc_target = None
        elif looks_like_uc:
            uc_status = "deployed"
            uc_target = target_clean
        else:
            # Something parseable but not a UC FQN — treat as not_migrated.
            uc_status = "not_migrated"
            uc_target = None
        out[full_synapse] = {
            "uc_target": uc_target,
            "uc_status": uc_status,
            "source": "alter.sql",
            "alter_file": str(alter_path.relative_to(WIKI_REPO)),
            "raw_target": target_clean,
        }
    return out


def load_pipeline_mapping() -> dict[str, dict]:
    """database.schema.table -> uc_table  (PROD source path)."""
    if not PIPELINE_MAP_PATH.exists():
        return {}
    data = json.loads(PIPELINE_MAP_PATH.read_text(encoding="utf-8"))
    rows = data.get("mappings") or data.get("data") or []
    out: dict[str, dict] = {}
    for r in rows:
        db = (r.get("database_name") or "").strip()
        schema = (r.get("schema_name") or "").strip()
        table = (r.get("table_name") or "").strip()
        uc_table = (r.get("uc_table") or "").strip()
        if not (db and schema and table and uc_table):
            continue
        # Common keying styles used in skill primary_objects:
        keys = {
            f"{db}.{schema}.{table}",       # full triple
            f"{schema}.{table}",            # schema.table
        }
        # Some Synapse skill refs key on db_dbo (e.g. "EXW_dbo" instead of "WalletDB"+"dbo")
        # We can't bridge that automatically; alter.sql + alias map cover those.
        for k in keys:
            out.setdefault(k, {
                "uc_target": f"main.{uc_table}",
                "uc_status": "deployed_prod",
                "source": "pipeline_mapping",
                "source_type": r.get("source_type"),
                "business_group": r.get("business_group"),
                "frequency_minutes": r.get("frequency_minutes"),
            })
    return out


def load_alias_map() -> dict[str, list[str]]:
    if not ALIAS_MAP_PATH.exists():
        return {}
    return json.loads(ALIAS_MAP_PATH.read_text(encoding="utf-8"))


def load_kpi_views_index() -> dict[str, dict]:
    """schema.name (lowercased) -> {uc_target, type=VIEW}"""
    if not KPI_INDEX_PATH.exists():
        return {}
    data = json.loads(KPI_INDEX_PATH.read_text(encoding="utf-8"))
    out: dict[str, dict] = {}
    for v in data:
        s = v.get("schema") or ""
        n = v.get("name") or ""
        if not (s and n):
            continue
        out[f"{s}.{n}".lower()] = {
            "uc_target": f"main.{s}.{n}",
            "uc_status": "deployed",
            "uc_object_type": "VIEW",
            "source": "kpi_views_index",
        }
    return out


def load_uc_domains() -> dict[str, dict]:
    """Walk uc_domains/*/schemas/*/Tables|Views/*.md -> object map."""
    out: dict[str, dict] = {}
    if not UC_DOMAINS_DIR.exists():
        return out
    for md in UC_DOMAINS_DIR.rglob("*.md"):
        parts = md.parts
        try:
            i = parts.index("schemas")
        except ValueError:
            continue
        # uc_domains / <product> / schemas / <schema> / <Tables|Views> / <name>.md
        if i + 3 >= len(parts):
            continue
        schema = parts[i + 1]
        kind = parts[i + 2]   # "Tables" or "Views"
        name = md.stem
        if kind not in ("Tables", "Views"):
            continue
        key = f"{schema}.{name}".lower()
        out[key] = {
            "uc_target": f"main.{schema}.{name}",
            "uc_status": "deployed",
            "uc_object_type": "TABLE" if kind == "Tables" else "VIEW",
            "source": f"uc_domains/{parts[i - 1]}",
        }
    return out


# ---------------------------------------------------------------------------
# 2. Skill ref scraping
# ---------------------------------------------------------------------------

# A "ref" in skill front-matter primary_objects looks like:
#   - BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms     # comment
#   - "EXW_dbo.EXW_C2F_E2E (with comment)"
# Only the first whitespace-delimited token after the dash is the qualified name.

REF_LINE = re.compile(
    r'^\s*-\s+["\']?'
    r'(?P<ref>[A-Za-z_][\w]*\.[A-Za-z_][\w]*(?:\.[A-Za-z_][\w]*)?)'
    r'["\']?(?:\s|$|"|#)'
)


def scan_skill_refs(skills_dir: Path) -> list[tuple[str, str, int]]:
    """Return (ref, skill_relpath, line_no) tuples for every primary_objects entry.

    We restrict to the front-matter `primary_objects:` block to avoid pulling
    in random schema.table mentions from prose.
    """
    out: list[tuple[str, str, int]] = []
    for md in skills_dir.rglob("*.md"):
        if md.name.startswith("_"):
            # Skip discovery artifacts (_router.md is allowed though)
            if md.name != "_router.md":
                continue
        try:
            lines = md.read_text(encoding="utf-8", errors="ignore").splitlines()
        except Exception:
            continue

        in_fm = False
        in_block = False
        block_keys = (
            "primary_objects:",
            "qa_only_objects:",
            "intersects_with:",  # we skip these for naming, but track
            "uses:",
        )
        for i, line in enumerate(lines, 1):
            if line.strip() == "---":
                in_fm = not in_fm
                continue
            if not in_fm:
                continue
            stripped = line.rstrip()
            if any(stripped.startswith(k) for k in block_keys):
                in_block = stripped.startswith(("primary_objects:", "qa_only_objects:"))
                continue
            if not in_block:
                continue
            # Stop block on a top-level YAML key (no leading whitespace + colon).
            if line and not line[0].isspace() and ":" in line:
                in_block = False
                continue
            m = REF_LINE.match(line)
            if not m:
                continue
            ref = m.group("ref")
            # Filter obvious non-objects (e.g. front-matter scalars that match)
            if "." not in ref:
                continue
            out.append((ref, str(md.relative_to(REPO)), i))
    return out


# ---------------------------------------------------------------------------
# 3. Resolution
# ---------------------------------------------------------------------------

def resolve_one(
    ref: str,
    alter_targets: dict[str, dict],
    pipeline_map: dict[str, dict],
    alias_map: dict[str, list[str]],
    kpi_index: dict[str, dict],
    uc_domains: dict[str, dict],
    synapse_wikis: set[str],
) -> dict:
    """Return a resolution record."""
    # Hardcoded overrides win.
    if ref in HARDCODED_UC_OVERRIDES:
        rec = {"ref": ref, "confidence": "HIGH"}
        rec.update(HARDCODED_UC_OVERRIDES[ref])
        return rec

    parts = ref.split(".")

    # Already 3-part UC name (catalog.schema.object)? mark as native UC.
    if len(parts) == 3 and parts[0] in {"main", "pii_data"}:
        return {
            "ref": ref,
            "uc_target": ref,
            "uc_status": "uc_native",
            "source": "skill_already_uc",
            "confidence": "HIGH",
        }

    # 2-part with UC-style schema (lowercase + bronze/gold/dim/fact-prefix table)?
    if len(parts) == 2:
        schema, obj = parts
        # Heuristic: schemas like "etoro_kpi", "etoro_kpi_prep", "de_output", "bi_output",
        # "finance", "general", "emoney", "dwh", "bi_db", "dealing" are UC schemas.
        UC_SCHEMAS = {
            "etoro_kpi", "etoro_kpi_prep", "etoro_kpi_prep_stg",
            "de_output", "bi_output", "bizops_output",
            "finance", "general", "emoney", "dwh", "bi_db", "dealing",
            "billing", "trading", "compliance", "settings", "userapidb",
            "spaceship", "moneyfarm",
        }
        if schema in UC_SCHEMAS:
            # Try kpi_index first for view confirmation
            kpi_hit = kpi_index.get(f"{schema}.{obj}".lower())
            if kpi_hit:
                return {
                    "ref": ref,
                    "uc_target": kpi_hit["uc_target"],
                    "uc_object_type": kpi_hit.get("uc_object_type"),
                    "uc_status": "deployed",
                    "source": "kpi_views_index",
                    "confidence": "HIGH",
                }
            uc_dom_hit = uc_domains.get(f"{schema}.{obj}".lower())
            if uc_dom_hit:
                return {
                    "ref": ref,
                    "uc_target": uc_dom_hit["uc_target"],
                    "uc_object_type": uc_dom_hit.get("uc_object_type"),
                    "uc_status": "deployed",
                    "source": uc_dom_hit["source"],
                    "confidence": "HIGH",
                }
            # Otherwise: treat as native UC (lowercase the object, but ref looked already UC).
            return {
                "ref": ref,
                "uc_target": f"main.{schema}.{obj}".lower(),
                "uc_status": "uc_native_inferred",
                "source": "uc_schema_heuristic",
                "confidence": "MEDIUM",
            }

    # Synapse-style: <Schema>.<Object>
    # Try alter.sql first
    alter_hit = alter_targets.get(ref)
    if alter_hit:
        out = {
            "ref": ref,
            "uc_target": alter_hit["uc_target"],
            "uc_status": alter_hit["uc_status"],
            "source": alter_hit["source"],
            "confidence": "HIGH" if alter_hit["uc_status"] == "deployed" else "HIGH",
            "alter_file": alter_hit.get("alter_file"),
        }
        # If not migrated, try kpi_index for a likely view alias
        if alter_hit["uc_status"] == "not_migrated":
            # heuristic: <object>_lower replacing prefixes
            obj = ref.split(".")[-1]
            cand_keys = [
                f"etoro_kpi_prep.v_{obj.lower()}",
                f"etoro_kpi_prep.{obj.lower()}",
                f"etoro_kpi.v_{obj.lower()}",
            ]
            # Specific MIMO view rename: BI_DB_DDR_Fact_MIMO_X_Platform -> v_mimo_<x>_platform
            mimo_match = re.match(r"BI_DB_DDR_Fact_MIMO_([A-Za-z]+)_Platform$", obj)
            if mimo_match:
                p = mimo_match.group(1).lower()
                cand_keys.insert(0, f"etoro_kpi_prep.v_mimo_{p}_platform")
                cand_keys.insert(0, f"etoro_kpi_prep.v_mimo_{p}platform")
            for ck in cand_keys:
                kpi_hit = kpi_index.get(ck)
                if kpi_hit:
                    out["uc_view_alias"] = kpi_hit["uc_target"]
                    out["uc_view_alias_source"] = "kpi_views_index"
                    break
        return out

    # Pipeline mapping (PROD path) — direct
    pmap_hit = pipeline_map.get(ref)
    if pmap_hit:
        return {
            "ref": ref,
            "uc_target": pmap_hit["uc_target"],
            "uc_status": pmap_hit["uc_status"],
            "uc_object_type": "TABLE",
            "source": "pipeline_mapping",
            "source_type": pmap_hit.get("source_type"),
            "confidence": "HIGH",
        }

    # Pipeline mapping via Synapse virtual-schema synonym
    if len(parts) == 2:
        v_schema, v_obj = parts
        if v_schema in SYNAPSE_VIRTUAL_SCHEMA_TO_PROD:
            prod_db, prod_schema = SYNAPSE_VIRTUAL_SCHEMA_TO_PROD[v_schema]
            for k in (f"{prod_db}.{prod_schema}.{v_obj}", f"{prod_schema}.{v_obj}"):
                pmap_hit = pipeline_map.get(k)
                if pmap_hit:
                    return {
                        "ref": ref,
                        "uc_target": pmap_hit["uc_target"],
                        "uc_status": pmap_hit["uc_status"],
                        "uc_object_type": "TABLE",
                        "source": "pipeline_mapping_via_synonym",
                        "synonym_key": k,
                        "synapse_virtual_schema": v_schema,
                        "prod_database": prod_db,
                        "prod_schema": prod_schema,
                        "confidence": "HIGH",
                    }

    # alias map fallback (UC name often lurks here)
    alias_hits = alias_map.get(ref) or []
    uc_alias = next(
        (a for a in alias_hits if "." in a and (a.startswith("dwh.") or a.startswith("bi_db.")
                                                or a.startswith("emoney.") or a.startswith("etoro_kpi")
                                                or a.startswith("de_output.") or a.startswith("bi_output.")
                                                or a.startswith("dealing.") or a.startswith("compliance.")
                                                or a.startswith("billing.") or a.startswith("trading.")
                                                or a.startswith("pii_data."))),
        None,
    )
    if uc_alias:
        return {
            "ref": ref,
            "uc_target": f"main.{uc_alias}" if not uc_alias.startswith("main.") else uc_alias,
            "uc_status": "deployed",
            "source": "alias_map",
            "confidence": "MEDIUM",
        }

    # KPI index by tail-only (rare)
    obj_only = ref.split(".")[-1].lower()
    for k, hit in kpi_index.items():
        if k.endswith("." + obj_only) or k.endswith(".v_" + obj_only):
            return {
                "ref": ref,
                "uc_target": hit["uc_target"],
                "uc_object_type": "VIEW",
                "uc_status": "deployed",
                "source": "kpi_views_index_tail",
                "confidence": "MEDIUM",
            }

    # Final fallback: object has a Synapse Wiki page but no .alter.sql, no
    # pipeline mapping, no alias. That means it lives only in Synapse — it
    # has not been (and likely will not be) ingested into UC.
    if ref in synapse_wikis:
        return {
            "ref": ref,
            "uc_target": None,
            "uc_status": "synapse_only_no_uc",
            "source": "synapse_wiki_index",
            "confidence": "HIGH",
            "note": "Wiki exists but no UC mapping; Synapse-only object. Genie cannot query this.",
        }

    return {
        "ref": ref,
        "uc_target": None,
        "uc_status": "unknown",
        "source": None,
        "confidence": "LOW",
    }


# ---------------------------------------------------------------------------
# 4. Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("[1/5] Loading alter.sql targets ...", flush=True)
    alter_targets = load_alter_sql_targets()
    print(f"      {len(alter_targets):,} synapse objects with .alter.sql")

    print("[2/5] Loading generic pipeline mapping ...", flush=True)
    pipeline_map = load_pipeline_mapping()
    print(f"      {len(pipeline_map):,} pipeline mapping keys")

    print("[3/5] Loading alias / kpi / uc_domains / synapse wiki index ...", flush=True)
    alias_map = load_alias_map()
    kpi_index = load_kpi_views_index()
    uc_domains = load_uc_domains()
    synapse_wikis = load_synapse_wiki_index()
    print(f"      alias={len(alias_map):,}  kpi_views={len(kpi_index):,}  uc_domains={len(uc_domains):,}  wikis={len(synapse_wikis):,}")

    print("[4/5] Scanning skill primary_objects refs ...", flush=True)
    refs = scan_skill_refs(SKILLS_DIR)
    print(f"      {len(refs):,} ref-mentions in skills")

    seen: dict[str, dict] = {}
    skill_index: dict[str, list[dict]] = {}
    for ref, skill_path, line_no in refs:
        if ref not in seen:
            seen[ref] = resolve_one(ref, alter_targets, pipeline_map, alias_map, kpi_index, uc_domains, synapse_wikis)
        skill_index.setdefault(skill_path, []).append({
            "ref": ref,
            "line": line_no,
            "resolution": seen[ref],
        })

    out_json = {
        "generated_by": "tools/skills/build_uc_object_map.py",
        "total_unique_refs": len(seen),
        "by_status": {},
        "objects": dict(sorted(seen.items())),
        "by_skill": skill_index,
    }
    status_counts: dict[str, int] = {}
    for r in seen.values():
        status_counts[r.get("uc_status", "unknown")] = status_counts.get(r.get("uc_status", "unknown"), 0) + 1
    out_json["by_status"] = status_counts

    json_path = SKILLS_DIR / "_uc_object_map.json"
    json_path.write_text(json.dumps(out_json, indent=2), encoding="utf-8")
    print(f"      wrote {json_path.relative_to(REPO)} ({len(seen)} unique refs)")
    print(f"      status counts: {status_counts}")

    # Markdown
    md_path = SKILLS_DIR / "_uc_object_map.md"
    lines: list[str] = []
    lines.append("# Synapse ↔ Unity Catalog object map (skill references)")
    lines.append("")
    lines.append(f"_Generated by `tools/skills/build_uc_object_map.py`. {len(seen)} unique refs across `knowledge/skills/**.md`._")
    lines.append("")
    lines.append("Status legend:")
    lines.append("- **deployed** — object exists in UC at `uc_target`. Genie should use it.")
    lines.append("- **deployed_prod** — production source-table mapped via Generic Pipeline (`bronze_*`).")
    lines.append("- **deployed_view_alias** — Synapse object exposed as a view in `etoro_kpi_prep` (not materialized). Use the view in Genie.")
    lines.append("- **uc_native** — skill ref already UC-flavored (no rename needed).")
    lines.append("- **uc_native_inferred** — UC-flavored but not in any index; needs live verification.")
    lines.append("- **not_migrated** — `alter.sql` explicitly `_Not_Migrated`. **Genie cannot query this** unless a `uc_view_alias` is listed.")
    lines.append("- **synapse_only_no_uc** — Synapse Wiki exists but no UC ingest. **Genie cannot query this**.")
    lines.append("- **non_existent** — object does NOT exist anywhere; remove from skill.")
    lines.append("- **deprecated_old_ddr** — old DDR framework; remove from skill.")
    lines.append("- **unknown** — could not be resolved offline; needs live UC validation.")
    lines.append("")
    lines.append("| Synapse / skill ref | UC target | Type | Status | View alias (if not migrated) | Source |")
    lines.append("|---|---|---|---|---|---|")
    for ref, r in sorted(seen.items()):
        uc_target = r.get("uc_target") or "—"
        uc_type = r.get("uc_object_type") or ""
        status = r.get("uc_status", "unknown")
        view_alias = r.get("uc_view_alias") or ""
        src = r.get("source") or ""
        lines.append(f"| `{ref}` | `{uc_target}` | {uc_type} | {status} | `{view_alias}` | {src} |")
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"      wrote {md_path.relative_to(REPO)}")

    # Action-required report (cannot be queried by Genie OR was hallucinated)
    BAD = {"unknown", "not_migrated", "synapse_only_no_uc", "non_existent", "deprecated_old_ddr"}
    bad_refs = {r: v for r, v in seen.items() if v.get("uc_status") in BAD}

    action_path = SKILLS_DIR / "_uc_object_map.action_required.md"
    a_lines: list[str] = []
    a_lines.append("# UC validation — action-required references")
    a_lines.append("")
    a_lines.append(f"_Generated by `tools/skills/build_uc_object_map.py`. {len(bad_refs)} of {len(seen)} skill refs cannot be used by Databricks Genie as written._")
    a_lines.append("")

    by_skill: dict[str, list[tuple[str, dict]]] = {}
    for skill_path, items in skill_index.items():
        for it in items:
            r = it["ref"]
            if r in bad_refs:
                by_skill.setdefault(skill_path, []).append((r, bad_refs[r]))

    for skill_path in sorted(by_skill):
        a_lines.append(f"## `{skill_path}`")
        a_lines.append("")
        a_lines.append("| Ref | Status | Recommendation |")
        a_lines.append("|---|---|---|")
        seen_in_skill: set[str] = set()
        for r, v in by_skill[skill_path]:
            if r in seen_in_skill:
                continue
            seen_in_skill.add(r)
            status = v.get("uc_status")
            note = v.get("note") or ""
            view_alias = v.get("uc_view_alias")
            if status == "non_existent":
                rec = f"REMOVE — {note}"
            elif status == "deprecated_old_ddr":
                rec = f"REMOVE — {note}"
            elif status == "not_migrated":
                if view_alias:
                    rec = f"Replace with view: `{view_alias}` (Synapse table not in UC)"
                else:
                    rec = "Mark as **QA-only / Synapse-only**; do not use in Databricks Genie SQL."
            elif status == "synapse_only_no_uc":
                rec = "Mark as **QA-only / Synapse-only**; not ingested into UC."
            elif status == "unknown":
                rec = "Resolve via live UC query (run `databricks auth login`, then re-run this script)."
            else:
                rec = ""
            a_lines.append(f"| `{r}` | {status} | {rec} |")
        a_lines.append("")

    action_path.write_text("\n".join(a_lines) + "\n", encoding="utf-8")
    print(f"[5/5] {len(bad_refs)} refs need attention across {len(by_skill)} skill(s) -> {action_path.relative_to(REPO)}")

    # Backwards-compatible flat list
    unmapped_path = SKILLS_DIR / "_uc_object_map.unmapped.txt"
    unmapped_path.write_text("\n".join(sorted(bad_refs)) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
