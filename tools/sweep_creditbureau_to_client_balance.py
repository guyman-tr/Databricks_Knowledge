"""Sweep the corpus-wide 'CreditBureau' fabrication out of UC column comments.

Three patterns:
  Cat 1 — plain IsCreditReportValidCB with short boilerplate:
          replace whole comment with canonical, preserve any (Tier N - ...) tail.
  Cat 2 — _ThisMonth / _ThisWeek / _ThisQuarter / _ThisYear rolling slice:
          surgical replace of the embedded **1 if customer ... CreditBureau context).**
          sentence, preserve slice mechanics and provenance tails.
  Cat 3 — IsCreditReportValidCBPrev legacy/null:
          surgical word swap, preserve Always-NULL marker.

Auth: same as deploy_converged.py / apply_tvf_col_comments.py.
"""
from __future__ import annotations
import argparse
import os
import re
import sys

DBX_HOST = "adb-5142916747090026.6.azuredatabricks.net"
DBX_HTTP_PATH = "/sql/1.0/warehouses/208214768b0e0308"

CANONICAL_PLAIN = (
    "Financial-customer flag for Client_Balance reports (CB = Client_Balance, "
    "NOT CreditBureau). Approximately = IsValidCustomer with AccountTypeID != 2 "
    "and 6 hardcoded CID exceptions for CountryID=250 — eToro-EU subsidiary "
    "accounts where the parent custodies assets (counted in regulatory capital "
    "reports; not counted as business revenue)."
)

CANONICAL_SLICE_INNER = (
    "**Financial-customer flag for Client_Balance reports (CB = Client_Balance, "
    "NOT CreditBureau); ≈ IsValidCustomer with AccountTypeID != 2 and 6 hardcoded "
    "CID exceptions for CountryID=250 — subsidiary eToro-EU accounts counted in "
    "regulatory capital reports.**"
)

# Common tier-tail patterns we should preserve
TIER_TAIL_RX = re.compile(r"\(Tier\s*\d+[^)]*\)\s*$")

# The exact CreditBureau sentence embedded inside the rolling-slice comments
SLICE_BOLD_RX = re.compile(
    r"\*\*1 if customer is eligible for CreditBureau credit report validation "
    r"\(CB = CreditBureau context\)\.\*\*"
)


def esc_sql(text: str) -> str:
    return text.replace("'", "''")


def transform_plain(comment: str, table_short: str) -> str:
    """Cat 1: replace whole comment with canonical, keep tier tail if present."""
    m = TIER_TAIL_RX.search(comment)
    tail = m.group(0) if m else ""
    if tail:
        return f"{CANONICAL_PLAIN} {tail}".strip()
    return CANONICAL_PLAIN


def transform_slice(comment: str) -> str:
    """Cat 2: surgical inner-sentence replacement, keep everything else."""
    if SLICE_BOLD_RX.search(comment):
        return SLICE_BOLD_RX.sub(CANONICAL_SLICE_INNER, comment)
    # Fallback: try a softer substitution
    return (comment
            .replace("CreditBureau credit report validation",
                     "Client_Balance financial-customer validation")
            .replace("CB = CreditBureau context",
                     "CB = Client_Balance, NOT CreditBureau"))


def transform_legacy_prev(comment: str) -> str:
    """Cat 3: surgical word swap for the IsCreditReportValidCBPrev legacy col."""
    return (comment
            .replace("prior credit bureau validity",
                     "prior Client_Balance validity (CB = Client_Balance, NOT CreditBureau)")
            .replace("Prior credit bureau validity",
                     "Prior Client_Balance validity (CB = Client_Balance, NOT CreditBureau)"))


_CANON_KEEP = "<<<KEEP_NOT_CB>>>"


def transform_generic_inline(comment: str) -> str:
    """Catch-all: replace 'CreditBureau' / 'credit bureau' textually,
    keeping the surrounding context. Protects the intentional 'NOT CreditBureau'
    anchor token from cascading token substitutions via a placeholder swap."""
    out = comment

    # 1. Phrase-level whole-sentence replacements (these emit 'NOT CreditBureau'
    #    intentionally — we need to protect that anchor before token-level sub).
    phrase_subs = [
        ("1 if customer is eligible for CreditBureau credit report validation",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
        ("1 if the customer is eligible for credit bureau reporting",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
        ("1 if the customer has a valid credit report (cb=Credit Bureau)",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
        ("Credit Bureau reporting eligibility flag. 1 = eligible for credit reporting.",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)."),
        ("Credit bureau report validity flag at conversion time",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau); captured at conversion time"),
        ("Credit report validity flag for US credit bureau reporting.",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)."),
        ("Credit bureau validity flag (1=credit report validated against external credit bureau)",
         "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
    ]
    for old, new in phrase_subs:
        out = out.replace(old, new)

    # 2. Protect the intentional 'NOT CreditBureau' anchor token.
    out = out.replace("NOT CreditBureau", _CANON_KEEP)

    # 3. Token-level fallbacks for any 'CreditBureau' / 'credit bureau' that
    #    survived (in older / table-specific wording variants).
    out = out.replace("CreditBureau", "Client_Balance")
    out = out.replace("Credit Bureau", "Client_Balance")
    out = out.replace("credit bureau", "Client_Balance")
    out = out.replace("credit-bureau", "Client_Balance")

    # 4. Restore the protected anchor.
    out = out.replace(_CANON_KEEP, "NOT CreditBureau")
    return out


# (table_schema, table_name, column_name, category)
TARGETS = [
    # Cat 1 — plain IsCreditReportValidCB (will use transform_generic_inline
    # to preserve table-specific tails like "GROUP BY pass-through")
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_daily_aggregated", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_eu_custody", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_positionpnl_uk_custody", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e", "IsCreditReportValidCB", "inline"),
    ("bi_db", "gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e", "IsCreditReportValidCB", "inline"),
    ("bi_output", "bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu", "IsCreditReportValidCB", "inline"),
    ("bi_output", "bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_uk", "IsCreditReportValidCB", "inline"),
    ("bi_output", "finance_tables_functions_revenue_trading_fees", "IsCreditReportValidCB", "inline"),
    ("dwh", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked", "IsCreditReportValidCB", "inline"),
    ("finance", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints", "IsCreditReportValidCB", "inline"),
    ("finance", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_non_us_settlement_new_2025", "IsCreditReportValidCB", "inline"),
    ("finance", "gold_sql_dp_prod_we_bi_db_dbo_client_balance_breakdown_instrument_level", "IsCreditReportValidCB", "inline"),
    ("general", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg", "IsCreditReportValidCB", "inline"),
    ("pii_data", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer", "IsCreditReportValidCB", "inline"),
    ("pii_data", "gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid", "IsCreditReportValidCB", "inline"),

    # Cat 2 — rolling slices (preserve slice mechanics)
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status", "IsCreditReportValidCB_ThisMonth", "slice"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status", "IsCreditReportValidCB_ThisQuarter", "slice"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status", "IsCreditReportValidCB_ThisWeek", "slice"),
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status", "IsCreditReportValidCB_ThisYear", "slice"),
    ("bi_output", "bi_output_vg_ddr_customers_snapshot", "IsCreditReportValidCB_ThisMonth", "slice"),
    ("bi_output", "bi_output_vg_ddr_customers_snapshot", "IsCreditReportValidCB_ThisQuarter", "slice"),
    ("bi_output", "bi_output_vg_ddr_customers_snapshot", "IsCreditReportValidCB_ThisYear", "slice"),

    # Cat 3 — Always-NULL legacy
    ("general", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg", "IsCreditReportValidCBPrev", "legacy"),
]


def open_connection():
    from databricks import sql
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)")
        return sql.connect(server_hostname=DBX_HOST, http_path=DBX_HTTP_PATH, access_token=token)
    from databricks.sdk import WorkspaceClient
    profile = os.environ.get("DATABRICKS_MCP_PROFILE", "guyman")
    print(f"Auth: SDK profile '{profile}'")
    wc = WorkspaceClient(profile=profile)
    return sql.connect(
        server_hostname=DBX_HOST,
        http_path=DBX_HTTP_PATH,
        credentials_provider=lambda: wc.config.authenticate,
    )


def fetch_comment(cur, schema, table, col):
    q = (
        f"SELECT comment FROM system.information_schema.columns "
        f"WHERE table_catalog='main' AND table_schema='{esc_sql(schema)}' "
        f"AND table_name='{esc_sql(table)}' "
        f"AND lower(column_name)=lower('{esc_sql(col)}')"
    )
    cur.execute(q)
    row = cur.fetchone()
    return row[0] if row else None


def transform(comment: str, category: str) -> str:
    if category == "slice":
        return transform_slice(comment)
    if category == "legacy":
        return transform_legacy_prev(comment)
    return transform_generic_inline(comment)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dry_run and not args.apply:
        print("Specify --dry-run or --apply")
        return 2

    print(f"Targets: {len(TARGETS)}")
    print(f"Connecting to {DBX_HOST}...")
    conn = open_connection()
    cur = conn.cursor()
    print("Connected.\n")

    applied = skipped = failed = 0
    for schema, table, col, cat in TARGETS:
        fqn = f"main.{schema}.{table}"
        try:
            current = fetch_comment(cur, schema, table, col)
        except Exception as e:
            print(f"  FAIL   {fqn}.{col}   fetch failed: {e}")
            failed += 1
            continue
        if current is None:
            print(f"  SKIP   {fqn}.{col}   column not found")
            skipped += 1
            continue

        new_comment = transform(current, cat)
        # Residue check — strip the intentional 'NOT CreditBureau' anchor
        # (and similar protected phrasings) before scanning for genuine leftover.
        residue_test = new_comment
        for protected in ("NOT CreditBureau", "NOT *CreditBureau*"):
            residue_test = residue_test.replace(protected, "")
        if "creditbureau" in residue_test.lower() or "credit bureau" in residue_test.lower():
            print(f"  WARN   {fqn}.{col}   transform left CreditBureau residue, skipping")
            print(f"         current  : {current[:140]}")
            print(f"         new      : {new_comment[:140]}")
            skipped += 1
            continue
        if new_comment == current:
            print(f"  NOOP   {fqn}.{col}   no change")
            skipped += 1
            continue

        if args.dry_run:
            print(f"  DRY    {fqn}.{col}   ({cat})")
            print(f"         BEFORE : {current[:140]}{'...' if len(current) > 140 else ''}")
            print(f"         AFTER  : {new_comment[:140]}{'...' if len(new_comment) > 140 else ''}")
            applied += 1
            continue

        stmt = f"COMMENT ON COLUMN {fqn}.{col} IS '{esc_sql(new_comment)}'"
        try:
            cur.execute(stmt)
            applied += 1
            print(f"  OK     {fqn}.{col}   ({cat})  len={len(new_comment)}")
        except Exception as e:
            failed += 1
            print(f"  FAIL   {fqn}.{col}   {str(e)[:200]}")

    print(f"\nApplied: {applied}  Skipped/NOOP: {skipped}  Failed: {failed}")
    cur.close()
    conn.close()
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
