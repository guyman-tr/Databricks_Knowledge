"""Append a small `## PDF cross-reference` appendix to the four existing
wikis that don't get a from-scratch rewrite (gold mirror + 3 Synapse-only
siblings). Idempotent - re-running rewrites the appendix in place.
"""
from __future__ import annotations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

TARGETS = [
    ("knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Reports.md",
     "main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports",
     "Cleansed Synapse mirror; the SP DROPS `IP` at load. 89 cols (80 vendor + 5 eToro + UpdateDate + 3 etr_*)."),
    ("knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Reports_Ext.md",
     "(Synapse-only - not migrated to UC)",
     "Raw varchar landing zone for the AppsFlyer Raw Data Export. 86 cols (81 vendor + 5 eToro), all `varchar`. Receives `IP`."),
    ("knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Geo.md",
     "(Synapse-only - not migrated to UC)",
     "AppsFlyer GEO aggregate at Country x AgencyPMD x MediaSource x Campaign x Date x EtoroAppID grain. Funnel + revenue rollups (Installs / Sessions / LoyalUsers / ftd / loginlead / redeposit / registration / TotalRevenue / ARPU). NOT one of the 86 raw fields - this is a separate aggregate report from AppsFlyer."),
    ("knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Geo_Ext.md",
     "(Synapse-only - not migrated to UC)",
     "Raw varchar landing for the AppsFlyer GEO aggregate."),
]

APPENDIX_MARKER = "<!-- APPSFLYER_PDF_APPENDIX_2026_06_10 -->"

APPENDIX_TEMPLATE = """
{marker}

## AppsFlyer field reference (PDF cross-reference)

> Added 2026-06-10 by the one-shot AppsFlyer deployment.

**UC FQN**: `{fqn}`

**Note**: {note}

The authoritative AppsFlyer-vendor descriptions for every column live in the PDF cross-reference at `proposals/AppsFlyer_Fields.pdf`. The mapping covers every field used in the eToro pipeline against AppsFlyer's documented field name (e.g. `MediaSource <-> media_source`, `Partner <-> af_prt`, `SubParam1..5 <-> af_sub1..5`).

Deployed UC ALTER scripts grounded in the PDF:

| Object | UC ALTER file |
|---|---|
| Silver fact (1:1 with PDF) | `knowledge/UC_generated/de_output/Tables/de_output_appsflyer_silver_reports.alter.sql` |
| Gold mirror (this object's UC face if migrated) | `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AppFlyer_Reports.alter.sql` |
| CID bridge | `knowledge/UC_generated/bi_db/Tables/bronze_marketperformance_tracking_customer.alter.sql` |
| Permissioned view | `knowledge/UC_generated/bridgeclaw_permitted_data/Views/appflyer_reports.alter.sql` |

The five eToro custom fields (`DateID`, `Date`, `EtoroAppID`, `EtoroAppName`, `EtoroReport`) are not in the AppsFlyer schema - see "Custom eToro Fields (Not in AppsFlyer Documentation)" in the PDF.
"""


def upsert_appendix(md_path: Path, fqn: str, note: str) -> None:
    if not md_path.exists():
        print(f"  [SKIP] {md_path} not found")
        return
    body = md_path.read_text(encoding="utf-8")
    appendix = APPENDIX_TEMPLATE.format(marker=APPENDIX_MARKER, fqn=fqn, note=note)
    if APPENDIX_MARKER in body:
        # Strip the existing appendix and everything after the marker (it's the last section).
        idx = body.find(APPENDIX_MARKER)
        # Walk back to the previous "## " or "---" boundary above the marker.
        cut = body.rfind("\n## ", 0, idx)
        if cut == -1:
            cut = idx
        body = body[:cut].rstrip()
    new_body = body.rstrip() + "\n" + appendix.rstrip() + "\n"
    md_path.write_text(new_body, encoding="utf-8")
    print(f"  upserted appendix: {md_path}")


for rel, fqn, note in TARGETS:
    upsert_appendix(ROOT / rel, fqn, note)

print("\nDone.")
