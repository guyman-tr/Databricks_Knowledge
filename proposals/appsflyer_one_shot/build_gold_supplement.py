"""Render a SUPPLEMENT alter for the bi_db gold mirror.

Strategy: 80 of 89 columns on
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports already have
deployed comments (last batch 2026-05-07, 162/162 succeeded). Rather than
re-deploy 89 statements, this supplement adds ONLY the 9 missing columns
(SubParam1-5 + etr_y / etr_ym / etr_ymd) plus a refreshed TABLE COMMENT that
cross-references the PDF source-of-truth.

Output is APPENDED to the existing alter.sql so the file stays the
canonical deploy source. The deploy script is idempotent on already-applied
column comments.
"""
from __future__ import annotations
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ALTER_PATH = ROOT / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables" / "BI_DB_AppFlyer_Reports.alter.sql"
GOLD_FQN = "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports"


REFRESHED_TABLE_COMMENT = (
    "BI_DB_AppFlyer_Reports - cleansed Synapse mirror of the AppsFlyer "
    "Raw Data Export feed for the eToro OneApp Android / OneApp iOS apps. "
    "131M+ rows since 2022-10-25. Loaded daily by SP_AppFlyer_Reports from "
    "BI_DB_AppFlyer_Reports_Ext (raw varchar landing). 89 columns: 80 of 81 "
    "AppsFlyer-documented vendor fields (the SP DROPS `IP` at load time - "
    "only present on the de_output silver sibling), 5 eToro pipeline-added "
    "fields (DateID / Date / EtoroAppID / EtoroAppName / EtoroReport), 1 "
    "always-NULL DDL artefact (UpdateDate, not in the SP INSERT list), and "
    "3 UC-pipeline partition columns (etr_y / etr_ym / etr_ymd). Always "
    "filter EtoroReport (the 3 classes never sum cleanly: OrganicInstalls "
    "86.5M / InAppEvents 37.8M / Installs 7.0M) and EventSource IN "
    "('SDK','S2S') (~1M rows carry malformed JSON-fragment values). Prefer "
    "_S2S events for revenue / FTD / registration. CID resolution: "
    "main.bi_db.bronze_marketperformance_tracking_customer.AppsflyerID. "
    "Field-level vendor-doc reference: proposals/AppsFlyer_Fields.pdf."
)


SUPPLEMENT_COLS: list[tuple[str, str]] = [
    ("Contributor3TouchTime", "Date and time of the 3rd (oldest) contributing touchpoint. Stored as TIMESTAMP on this gold mirror (Contributor1/2 TouchTime are STRING - the type-asymmetry is a known anomaly; SP_AppFlyer_Reports CASTs Contributor3 to datetime while leaving 1/2 as varchar). (Tier 1 - AppsFlyer field contributor3_touch_time)"),
    ("SubParam1", "Custom parameter populated by the advertiser in the attribution link. Used for eToro-side tracking dimensions passed through the AppsFlyer OneLink / S2S URL. (Tier 1 - AppsFlyer field af_sub1)"),
    ("SubParam2", "Custom parameter populated by the advertiser in the attribution link. Used for eToro-side tracking dimensions passed through the AppsFlyer OneLink / S2S URL. (Tier 1 - AppsFlyer field af_sub2)"),
    ("SubParam3", "Custom parameter populated by the advertiser in the attribution link. Used for eToro-side tracking dimensions passed through the AppsFlyer OneLink / S2S URL. (Tier 1 - AppsFlyer field af_sub3)"),
    ("SubParam4", "Custom parameter populated by the advertiser in the attribution link. Used for eToro-side tracking dimensions passed through the AppsFlyer OneLink / S2S URL. (Tier 1 - AppsFlyer field af_sub4)"),
    ("SubParam5", "Custom parameter populated by the advertiser in the attribution link. Used for eToro-side tracking dimensions passed through the AppsFlyer OneLink / S2S URL. (Tier 1 - AppsFlyer field af_sub5)"),
    ("etr_y", "Year partition value injected by the gold UC pipeline. Equals YEAR(etr_ts). Used as Delta partition key for year-level pruning. (Tier 2 - UC pipeline metadata; not present in Synapse source DDL)"),
    ("etr_ym", "Year-month partition value (YYYYMM as INT) injected by the gold UC pipeline. Equals YEAR(etr_ts)*100 + MONTH(etr_ts). Used as Delta partition key for month-level pruning. (Tier 2 - UC pipeline metadata; not present in Synapse source DDL)"),
    ("etr_ymd", "Year-month-day partition value (YYYYMMDD as INT) injected by the gold UC pipeline. Equals YEAR(etr_ts)*10000 + MONTH(etr_ts)*100 + DAY(etr_ts). Used as Delta partition key for day-level pruning. (Tier 2 - UC pipeline metadata; not present in Synapse source DDL)"),
]


def sql_quote(s: str) -> str:
    return s.replace("'", "''")


def main() -> None:
    if not ALTER_PATH.exists():
        raise SystemExit(f"Existing alter.sql not found at {ALTER_PATH}")

    raw = ALTER_PATH.read_text(encoding="utf-8")

    # Strip any prior LAST EXECUTION footer; new footer will be appended after re-deploy.
    body = re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================\s*",
        "",
        raw,
        flags=re.DOTALL,
    ).rstrip()

    # Guard against re-running: if SubParam1 already has a comment ALTER, skip.
    if "ALTER COLUMN SubParam1 COMMENT" in body:
        print("Supplement already present (SubParam1 ALTER detected) - rewriting cleanly.")
        # Rewrite: drop everything from the supplement marker onward.
        marker = "\n-- == 2026-06-10 SUPPLEMENT (one-shot AppsFlyer deploy)"
        if marker in body:
            body = body.split(marker, 1)[0].rstrip()

    suppl: list[str] = []
    suppl.append("\n-- == 2026-06-10 SUPPLEMENT (one-shot AppsFlyer deploy) ==")
    suppl.append("-- Adds: refreshed table comment + 9 missing column comments")
    suppl.append("-- (SubParam1-5 + etr_y / etr_ym / etr_ymd).")
    suppl.append("-- Source-of-truth: proposals/AppsFlyer_Fields.pdf")
    suppl.append("-- ----------------------------------------------------------\n")

    suppl.append("-- ---- Refreshed Table Comment ----")
    # The original alter used SET TBLPROPERTIES; for symmetry with the silver
    # alter we switch to COMMENT ON TABLE here (both are accepted by UC).
    suppl.append(
        f"COMMENT ON TABLE {GOLD_FQN} IS '{sql_quote(REFRESHED_TABLE_COMMENT)}';\n"
    )

    suppl.append(f"-- ---- Supplement Column Comments ({len(SUPPLEMENT_COLS)} columns) ----")
    for col, comment in SUPPLEMENT_COLS:
        suppl.append(
            f"ALTER TABLE {GOLD_FQN} ALTER COLUMN {col} COMMENT '{sql_quote(comment)}';"
        )

    out = body + "\n" + "\n".join(suppl) + "\n"
    ALTER_PATH.write_text(out, encoding="utf-8")
    print(f"Updated {ALTER_PATH}")
    print(f"  body kept: {len(body):,} chars")
    print(f"  supplement: {len(SUPPLEMENT_COLS)} new ALTER COLUMN + 1 refreshed COMMENT ON TABLE")


if __name__ == "__main__":
    main()
