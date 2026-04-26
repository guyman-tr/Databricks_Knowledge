"""Sub-Account Option 1 (Another GCID + CID) — static blast-radius scanner.

Scope
-----
Scans every SQL object in DataPlatform/SynapseSQLPool1/sql_dp_prod_we/* and
classifies each Synapse object (SP, Function, View, Table DDL) by how it would
be impacted by Option 1 — adding a new flag (e.g. `IsBotAccount`) on
Dim_Customer to distinguish synthetic sub-account CIDs from real-user CIDs.

Failure mode being modelled
---------------------------
Option 1 mints a new (GCID, CID) pair per sub-account. These behave like real
customers in every join key, but they are NOT real users. Any KPI that COUNTS
distinct users (FTDs, Registrations, Funded, KYC, AML population counts) will
silently inflate by ~Nx (where N = avg sub-accounts per customer). Any KPI
that SUMS money flow (revenue, MIMO, AUM, P&L, balances) is correct as-is
because real money does flow through these CIDs.

The fix is to add `IsBotAccount` (or equivalent) on Dim_Customer / Customers
and either (a) redefine `IsValidCustomer = 1` to also imply `IsBotAccount = 0`,
or (b) require every user-count consumer to manually add `AND IsBotAccount = 0`.

This scanner finds every place that needs to be inspected.

Tier classification
-------------------
Tier A — MUST FIX:
    Object has BOTH a validity filter (IsValidCustomer / IsCreditReportValid /
    IsTestCustomer / IsBot[Account] / IsInternal) AND a user-count signal
    (FTD, Registration, Funded, COUNT(DISTINCT CID), per-customer KPIs that
    are user counts).

Tier B — REVIEW:
    Object has one of:
      - validity filter without user-count signal (likely money-flow — verify)
      - user-count signal without validity filter (potentially a bug)
      - GCID = GCID join (Option 2 risk but also a producer signal)
      - direct touch of Dim_Customer / Customers / Dim_Mirror

Tier C — RESIDUAL:
    Object references CID / GCID purely as a join key (no user-count, no
    validity filter). These should still compile but warrant a quick scan.

Tier 0 — NO TOUCHPOINT:
    Not written to the CSV.

Output
------
    knowledge/business/subaccount-option1-touchpoints.csv
    knowledge/business/subaccount-option1-summary.json
"""
from __future__ import annotations

import csv
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT = Path(r"C:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we")
KNOWLEDGE = Path(__file__).parent
SNAPSHOT_CSV = KNOWLEDGE / "_objectsstatus_snapshot.csv"
OUT_CSV = KNOWLEDGE / "subaccount-option1-touchpoints.csv"
OUT_JSON = KNOWLEDGE / "subaccount-option1-summary.json"

SYNAPSE_SCHEMAS = {
    "BI_DB_dbo", "BI_DB_staging",
    "DWH_dbo", "DWH_staging", "DWH_pagetracking", "DWH_watchlists",
    "Dealing_dbo", "Dealing_staging",
    "eMoney_dbo", "eMoney_Tribe",
    "EXW_dbo", "EXW_Wallet",
    "DE_dbo", "general", "dbo",
    "DWH_tracking", "DWH_Migration",
}

OBJECT_TYPES = ("Stored Procedures", "Functions", "Views", "Tables")


def _re(pat: str, flags=re.IGNORECASE | re.MULTILINE) -> re.Pattern:
    return re.compile(pat, flags)


VALIDITY_PATTERNS = {
    "IsValidCustomer":      _re(r"\bIsValidCustomer\b\s*=\s*1"),
    "IsCreditReportValid":  _re(r"\bIsCreditReportValid\b\s*=\s*1"),
    "IsTestCustomer":       _re(r"\bIsTestCustomer\b\s*=\s*0"),
    "IsBotAccount":         _re(r"\bIsBot(?:Account)?\b\s*=\s*0"),
    "IsInternal":           _re(r"\bIsInternal\b\s*=\s*0"),
    "Customer_Status":      _re(r"\bCustomer_?Status\b\s*=\s*N?'Active'"),
}

USER_COUNT_PATTERNS = {
    "COUNT_DISTINCT_CID":   _re(r"\bCOUNT\s*\(\s*DISTINCT\s+(?:[A-Za-z_]+\.)?CID\b\s*\)"),
    "COUNT_DISTINCT_GCID":  _re(r"\bCOUNT\s*\(\s*DISTINCT\s+(?:[A-Za-z_]+\.)?GCID\b\s*\)"),
    "FTD":                  _re(r"\b(?:FTD(?:_?Date)?|FirstTimeDeposit|IsFTDed|First[_ ]?Time[_ ]?Deposit)\b"),
    "Registration":         _re(r"\b(?:IsRegistered|Registration_?Date|RegistrationDate)\b"),
    "Funded":               _re(r"\b(?:IsFunded|Funded_?Date|FundedAccount|FirstFunded)\b"),
    "GROUP_BY_CID":         _re(r"GROUP\s+BY[^;]{0,200}\bCID\b"),
    "GROUP_BY_GCID":        _re(r"GROUP\s+BY[^;]{0,200}\bGCID\b"),
}

JOIN_FANOUT_PATTERNS = {
    "GCID_eq_GCID":         _re(r"ON\s+\w+\.GCID\s*=\s*\w+\.GCID"),
    "CID_eq_CID":           _re(r"ON\s+\w+\.CID\s*=\s*\w+\.CID"),
}

CUSTOMER_TOUCH_PATTERNS = {
    "Dim_Customer":             _re(r"\bDim_Customer\b"),
    "Customer_Channel":          _re(r"\bDim_Customer_Channel\b"),
    "External_Customer":         _re(r"\bExternal_[A-Za-z0-9_]*Customer[A-Za-z0-9_]*\b"),
    "UserApiDB_Customer":        _re(r"\bUserApiDB[\.\s]*Customer\b"),
    "Dim_Mirror":                _re(r"\bDim_Mirror\b"),
    "MirrorID_or_ParentCID":    _re(r"\b(?:MirrorID|MirrorTypeID|ParentCID|RealCID|MasterAccountCID|SubAccountCID)\b"),
}


def load_snapshot() -> dict[str, dict]:
    """Return mapping ProcedureName(lower) -> {ProcessName, Priority, IsActive}."""
    if not SNAPSHOT_CSV.exists():
        sys.exit(f"missing {SNAPSHOT_CSV} — run _build_objectsstatus_snapshot.py first")
    out: dict[str, dict] = {}
    with SNAPSHOT_CSV.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            out[r["ProcedureName"].lower()] = {
                "ProcessName": r["ProcessName"],
                "Priority": int(r["Priority"]),
                "IsActive": int(r["IsActive"]),
            }
    return out


def parse_object_id(path: Path) -> tuple[str, str, str] | None:
    """Path -> (schema, object_name, object_type) where object_type in {SP,Func,View,Table}."""
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        return None
    parts = rel.parts
    if len(parts) < 3:
        return None
    schema = parts[0]
    if schema not in SYNAPSE_SCHEMAS:
        return None
    type_dir = parts[1]
    if type_dir not in OBJECT_TYPES:
        return None
    fname = path.stem
    if fname.lower().startswith(schema.lower() + "."):
        object_name = fname[len(schema) + 1:]
    else:
        object_name = fname
    type_map = {
        "Stored Procedures": "SP",
        "Functions":         "Func",
        "Views":             "View",
        "Tables":            "Table",
    }
    return schema, object_name, type_map[type_dir]


def scan_text(text: str) -> dict:
    """Run every regex; return (counts_by_pattern, sample_excerpts_by_pattern)."""
    counts: dict[str, int] = {}
    samples: dict[str, list[str]] = {}
    lines = text.splitlines()

    def harvest(group: str, patterns: dict[str, re.Pattern]):
        for pat_name, rx in patterns.items():
            hits = list(rx.finditer(text))
            if not hits:
                continue
            counts[f"{group}.{pat_name}"] = len(hits)
            picks: list[str] = []
            for m in hits[:3]:
                line_no = text.count("\n", 0, m.start()) + 1
                line = lines[line_no - 1].strip() if 0 < line_no <= len(lines) else ""
                line = line[:240]
                picks.append(f"L{line_no}: {line}")
            samples[f"{group}.{pat_name}"] = picks

    harvest("VAL", VALIDITY_PATTERNS)
    harvest("USR", USER_COUNT_PATTERNS)
    harvest("JOIN", JOIN_FANOUT_PATTERNS)
    harvest("CUST", CUSTOMER_TOUCH_PATTERNS)
    return counts, samples


def classify(counts: dict[str, int]) -> tuple[str, list[str]]:
    """Tier A/B/C/0 plus a list of human-readable reason codes."""
    has_validity = any(k.startswith("VAL.") for k in counts)
    has_user_count = any(k.startswith("USR.") for k in counts)
    has_gcid_join = "JOIN.GCID_eq_GCID" in counts
    has_customer_touch = any(k.startswith("CUST.") for k in counts)
    has_any_cid_ref = (
        has_user_count or has_customer_touch
        or "JOIN.CID_eq_CID" in counts or "JOIN.GCID_eq_GCID" in counts
        or has_validity
    )

    reasons: list[str] = []
    if has_validity and has_user_count:
        reasons.append("validity-filter+user-count → must add IsBotAccount filter or redefine IsValidCustomer")
        return "A", reasons

    if has_validity and not has_user_count:
        reasons.append("validity-filter only (likely money-flow) → confirm sub-account CIDs should be INCLUDED")
    if has_user_count and not has_validity:
        reasons.append("user-count without validity filter → likely already buggy; verify")
    if has_gcid_join:
        reasons.append("GCID=GCID join → row fanout if GCID stops being unique per real customer (Option 2 hazard but also signal here)")
    if has_customer_touch and not has_user_count and not has_validity:
        reasons.append("touches Dim_Customer/Customers/Dim_Mirror → schema-add target or consumer")

    if reasons:
        return "B", reasons

    if has_any_cid_ref:
        return "C", ["CID/GCID referenced as join key only — no user-count, no validity filter"]

    return "0", []


def main() -> int:
    snapshot = load_snapshot()
    print(f"loaded {len(snapshot)} priority/process entries from snapshot", flush=True)

    rows = []
    by_tier_pri = Counter()
    by_tier = Counter()
    sample_files = defaultdict(list)

    n_total = 0
    n_skipped = 0
    n_no_touch = 0

    for schema_dir in sorted(REPO_ROOT.iterdir()):
        if not schema_dir.is_dir() or schema_dir.name not in SYNAPSE_SCHEMAS:
            continue
        for type_name in OBJECT_TYPES:
            type_dir = schema_dir / type_name
            if not type_dir.exists():
                continue
            for sql_file in type_dir.glob("*.sql"):
                n_total += 1
                ident = parse_object_id(sql_file)
                if not ident:
                    n_skipped += 1
                    continue
                schema, obj_name, obj_type = ident

                try:
                    text = sql_file.read_text(encoding="utf-8", errors="replace")
                except OSError:
                    n_skipped += 1
                    continue

                counts, samples = scan_text(text)
                tier, reasons = classify(counts)
                if tier == "0":
                    n_no_touch += 1
                    continue

                key = f"{schema}.{obj_name}".lower()
                meta = snapshot.get(key, {})
                priority = meta.get("Priority", -1)
                process = meta.get("ProcessName", "")
                is_active = meta.get("IsActive", -1)

                rows.append({
                    "schema": schema,
                    "object_name": obj_name,
                    "object_type": obj_type,
                    "tier": tier,
                    "priority": priority,
                    "process_name": process,
                    "is_active": is_active,
                    "reasons": " | ".join(reasons),
                    "VAL.IsValidCustomer":       counts.get("VAL.IsValidCustomer", 0),
                    "VAL.IsCreditReportValid":   counts.get("VAL.IsCreditReportValid", 0),
                    "VAL.IsTestCustomer":        counts.get("VAL.IsTestCustomer", 0),
                    "VAL.IsBotAccount":          counts.get("VAL.IsBotAccount", 0),
                    "VAL.IsInternal":            counts.get("VAL.IsInternal", 0),
                    "VAL.Customer_Status":       counts.get("VAL.Customer_Status", 0),
                    "USR.COUNT_DISTINCT_CID":    counts.get("USR.COUNT_DISTINCT_CID", 0),
                    "USR.COUNT_DISTINCT_GCID":   counts.get("USR.COUNT_DISTINCT_GCID", 0),
                    "USR.FTD":                   counts.get("USR.FTD", 0),
                    "USR.Registration":          counts.get("USR.Registration", 0),
                    "USR.Funded":                counts.get("USR.Funded", 0),
                    "USR.GROUP_BY_CID":          counts.get("USR.GROUP_BY_CID", 0),
                    "USR.GROUP_BY_GCID":         counts.get("USR.GROUP_BY_GCID", 0),
                    "JOIN.GCID_eq_GCID":         counts.get("JOIN.GCID_eq_GCID", 0),
                    "JOIN.CID_eq_CID":           counts.get("JOIN.CID_eq_CID", 0),
                    "CUST.Dim_Customer":         counts.get("CUST.Dim_Customer", 0),
                    "CUST.External_Customer":    counts.get("CUST.External_Customer", 0),
                    "CUST.UserApiDB_Customer":   counts.get("CUST.UserApiDB_Customer", 0),
                    "CUST.Dim_Mirror":           counts.get("CUST.Dim_Mirror", 0),
                    "CUST.MirrorID_or_ParentCID": counts.get("CUST.MirrorID_or_ParentCID", 0),
                    "samples_json":              json.dumps(samples, ensure_ascii=False),
                    "file_path":                 str(sql_file),
                })

                pri_bucket = priority if priority >= 0 else "unscheduled"
                by_tier_pri[(tier, pri_bucket)] += 1
                by_tier[tier] += 1

                if tier == "A" and priority >= 60 and len(sample_files[priority]) < 3:
                    sample_files[priority].append(f"{schema}.{obj_name}")

    rows.sort(
        key=lambda r: (
            {"A": 0, "B": 1, "C": 2}.get(r["tier"], 9),
            -(r["priority"] if isinstance(r["priority"], int) else -1),
            r["schema"],
            r["object_name"],
        )
    )

    fieldnames = list(rows[0].keys()) if rows else ["tier", "priority", "schema", "object_name"]
    with OUT_CSV.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    summary = {
        "scope": {
            "repo": str(REPO_ROOT),
            "files_total": n_total,
            "files_skipped_non_synapse": n_skipped,
            "files_no_touchpoint": n_no_touch,
            "files_with_touchpoint": len(rows),
        },
        "by_tier": dict(by_tier),
        "by_tier_priority": {f"{t}|{p}": n for (t, p), n in sorted(by_tier_pri.items(), key=lambda x: (x[0][0], str(x[0][1])))},
        "tier_a_top_priority_examples": dict(sorted(sample_files.items(), reverse=True)),
    }
    OUT_JSON.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(f"\nscan complete:", flush=True)
    print(f"  total files scanned:   {n_total}", flush=True)
    print(f"  skipped (non-Synapse): {n_skipped}", flush=True)
    print(f"  no touchpoint:         {n_no_touch}", flush=True)
    print(f"  touchpoints written:   {len(rows)}\n", flush=True)
    print("by tier:", flush=True)
    for t in ("A", "B", "C"):
        print(f"  {t}: {by_tier.get(t, 0)}", flush=True)
    print("\nby (tier, priority):", flush=True)
    for (t, p), n in sorted(by_tier_pri.items(), key=lambda x: (x[0][0], -(x[0][1] if isinstance(x[0][1], int) else 9999))):
        print(f"  tier {t}  priority {str(p):>11}  -> {n}", flush=True)
    print(f"\nwrote {OUT_CSV}", flush=True)
    print(f"wrote {OUT_JSON}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
