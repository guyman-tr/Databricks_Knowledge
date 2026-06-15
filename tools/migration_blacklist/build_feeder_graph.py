"""Build a feeder graph by grepping SP/View/Function definitions for table refs.

Question we want to answer:
    "If we blacklist surviving table T, will any KEEP procedure break because
     it reads from T?"

Method:
  1. For each bare table name in the surviving universe, build a regex that
     matches references in SQL source (handles bracketed and bare forms).
  2. For each object definition in sp_definitions.csv, scan for every bare
     table from the surviving set.
  3. For each (referring_object_fqn, table_bare) hit, record an edge.
  4. Filter edges so the referring object is itself a KEEP proc (i.e., its
     output is in the surviving universe AND it's not blacklisted).

Outputs:
  - audits/blacklist/_b_work/feeder_edges.csv
        columns: referring_proc, referring_schema, referring_object_type,
                 referenced_table_bare, sample_match
  - audits/blacklist/_b_work/feeder_targets.txt    (bare table names that ARE feeders)
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)
csv.field_size_limit(2**31 - 1)

REPO_ROOT  = Path(__file__).resolve().parents[2]
A3_CSV     = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"
FINAL_CSV  = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_FINAL_2026-05-31.csv"
DEFS_CSV   = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "sp_definitions.csv"

OUT_EDGES   = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "feeder_edges.csv"
OUT_TARGETS = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "feeder_targets.txt"


def main() -> int:
    blacklisted: set[tuple[str, str]] = set()
    with FINAL_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            blacklisted.add((row["ProcedureName"], row["TableName"]))

    surviving_bare: set[str] = set()
    surviving_procs: set[tuple[str, str]] = set()  # (schema, name) of keep procs
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row["ProcedureName"], row["TableName"]) in blacklisted:
                continue
            if (row.get("decision") or "").strip().lower() == "blacklist":
                continue
            tn = row["TableName"]
            if "." in tn:
                bare = tn.split(".", 1)[1].strip("[]")
            else:
                bare = tn
            surviving_bare.add(bare)
            proc = row["ProcedureName"]
            if "." in proc:
                sch, name = proc.split(".", 1)
            else:
                sch, name = "dbo", proc
            surviving_procs.add((sch.strip("[]"), name.strip("[]")))
    print(f"[feeder] surviving bare tables: {len(surviving_bare)}")
    print(f"[feeder] surviving procs:       {len(surviving_procs)}")

    # Compile one big alternation regex for speed.
    # We want to match either [TableName] or Schema.TableName or .TableName
    # bounded by non-word chars on both sides.
    bare_sorted = sorted(surviving_bare, key=lambda x: -len(x))  # longest first to avoid partial overshadow
    # Use word boundary; also escape any special chars.
    pattern = re.compile(
        r"(?<![A-Za-z0-9_])(" + "|".join(re.escape(t) for t in bare_sorted) + r")(?![A-Za-z0-9_])",
        re.IGNORECASE,
    )

    edges: list[tuple[str, str, str, str, str]] = []
    edges_seen: set[tuple[str, str, str]] = set()  # (refschema, refname, table)
    feeder_targets: set[str] = set()

    scanned = 0
    with DEFS_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            sch  = row["schema"]
            name = row["name"]
            otyp = row["object_type"]
            defn = row["definition"] or ""
            scanned += 1

            # Don't have a referring object that maps to a surviving proc?
            # Still useful to know — we ALSO want references from views/funcs
            # since they might be transitive.  Check anyway.
            for m in pattern.finditer(defn):
                referenced = m.group(1)
                # Skip self-reference (an object referring to its own name as
                # a table — uncommon, but let's filter when refname == referenced).
                if name.lower() == referenced.lower():
                    continue
                key = (sch, name, referenced)
                if key in edges_seen:
                    continue
                edges_seen.add(key)
                # Capture small context for sanity-check.
                start = max(0, m.start() - 30)
                end   = min(len(defn), m.end() + 30)
                ctx = defn[start:end].replace("\n", " ").replace("\r", "")
                edges.append((sch, name, otyp, referenced, ctx))

    print(f"[feeder] scanned {scanned} defs, found {len(edges)} (proc, table) edges", flush=True)

    OUT_EDGES.parent.mkdir(parents=True, exist_ok=True)
    with OUT_EDGES.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["referring_schema", "referring_name", "referring_type",
                    "referenced_table_bare", "sample_match"])
        for e in edges:
            w.writerow(e)
    print(f"[feeder] wrote {OUT_EDGES}", flush=True)

    # Now compute feeder_targets: tables read by ANY non-blacklisted procedure
    # other than the proc that produces them.
    # Build a producer map: bare_table -> set of (sch, name) producing it.
    producers: dict[str, set[tuple[str, str]]] = {}
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row["ProcedureName"], row["TableName"]) in blacklisted:
                continue
            if (row.get("decision") or "").strip().lower() == "blacklist":
                continue
            tn = row["TableName"]
            bare = tn.split(".", 1)[-1].strip("[]") if "." in tn else tn
            proc = row["ProcedureName"]
            if "." in proc:
                sch, name = proc.split(".", 1)
            else:
                sch, name = "dbo", proc
            producers.setdefault(bare, set()).add((sch.strip("[]"), name.strip("[]")))

    # For each edge (referring_proc -> table), if referring_proc is in
    # surviving_procs AND it's not the producer of that table itself,
    # the table is a feeder.
    for sch, name, otyp, referenced, _ctx in edges:
        if (sch, name) in surviving_procs:
            # Self-production check
            if (sch, name) in producers.get(referenced, set()):
                continue
            feeder_targets.add(referenced)

    print(f"[feeder] feeder_targets (read by other surviving procs): {len(feeder_targets)}", flush=True)

    OUT_TARGETS.write_text("\n".join(sorted(feeder_targets)) + "\n", encoding="utf-8")
    print(f"[feeder] wrote {OUT_TARGETS}", flush=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
