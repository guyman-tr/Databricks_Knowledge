"""Render the bridge ALTER, view ALTER, and minimal wikis from columns_data.py.

Silver alter+wiki are already produced (build_silver_alter.py / build_silver_wiki.py).
Gold-table refresh is handled separately via build_gold_supplement.py since 80 of
89 columns already have deployed comments and we only need to ADD the 9 missing.
"""
from __future__ import annotations
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from columns_data import BRIDGE_TABLE_COMMENT, BRIDGE_COLS, VIEW_COMMENT, VIEW_COLS  # noqa: E402

BRIDGE_FQN = "main.bi_db.bronze_marketperformance_tracking_customer"
VIEW_FQN = "main.bridgeclaw_permitted_data.appflyer_reports"


def sql_quote(s: str) -> str:
    return s.replace("'", "''")


def render_table_alter(fqn: str, table_comment: str, cols: list[tuple[str, str]],
                       table_tags: dict[str, str] | None = None,
                       header: str = "") -> str:
    out: list[str] = []
    out.append(header.rstrip() + "\n")
    out.append("-- ---- Table Comment ----")
    out.append(f"COMMENT ON TABLE {fqn} IS '{sql_quote(table_comment)}';\n")
    if table_tags:
        out.append("-- ---- Table Tags ----")
        out.append(f"ALTER TABLE {fqn} SET TAGS (")
        kvs = ",\n".join(f"    '{k}' = '{sql_quote(v)}'" for k, v in table_tags.items())
        out.append(kvs)
        out.append(");\n")
    out.append(f"-- ---- Column Comments ({len(cols)} columns) ----")
    for col, comment in cols:
        out.append(
            f"ALTER TABLE {fqn} ALTER COLUMN {col} COMMENT '{sql_quote(comment)}';"
        )
    return "\n".join(out) + "\n"


def render_view_alter(fqn: str, view_comment: str, cols: list[tuple[str, str]],
                      view_tags: dict[str, str] | None = None,
                      header: str = "") -> str:
    out: list[str] = []
    out.append(header.rstrip() + "\n")
    out.append("-- ---- View Comment ----")
    out.append(f"ALTER VIEW {fqn} SET TBLPROPERTIES ('comment' = '{sql_quote(view_comment)}');\n")
    if view_tags:
        out.append("-- ---- View Tags ----")
        out.append(f"ALTER VIEW {fqn} SET TAGS (")
        kvs = ",\n".join(f"    '{k}' = '{sql_quote(v)}'" for k, v in view_tags.items())
        out.append(kvs)
        out.append(");\n")
    out.append(f"-- ---- View Column Comments ({len(cols)} columns) ----")
    for col, comment in cols:
        out.append(
            f"COMMENT ON COLUMN {fqn}.{col} IS '{sql_quote(comment)}';"
        )
    return "\n".join(out) + "\n"


# ---------- Bridge (table) -----------------------------------------------
BRIDGE_HEADER = """-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_marketperformance_tracking_customer
-- Generated: 2026-06-10 | one-shot AppsFlyer deployment
-- Target: Unity Catalog EXTERNAL Delta table comment + column comments
-- Source-of-truth: AppsFlyer field doc (proposals/AppsFlyer_Fields.pdf) for the
--                  three vendor-documented columns (AppsflyerID, IDFV, FirebaseID);
--                  observed values for the rest. Five fields explicitly carry a
--                  NEEDS REVIEW marker because semantic / enum mapping is unknown.
-- =============================================================================
"""
BRIDGE_TAGS = {
    "domain": "marketing_attribution",
    "object_type": "cid_device_bridge",
    "source_schema": "bi_db",
    "source_system": "marketperformance pipeline",
    "pipeline": "one-shot-appsflyer-deploy",
    "pipeline_version": "2026-06-10",
    "primary_consumers": "main.de_output.de_output_appsflyer_silver_reports; main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports",
    "needs_review": "DeviceTypeID; PartitionCol; UserUniqueIdentifierCookie; AdditionalData; iOSAdTrackingPermissionID enum",
    "semantic_grade": "3",
}

bridge_path = ROOT / "knowledge" / "UC_generated" / "bi_db" / "Tables" / "bronze_marketperformance_tracking_customer.alter.sql"
bridge_path.parent.mkdir(parents=True, exist_ok=True)
bridge_path.write_text(
    render_table_alter(BRIDGE_FQN, BRIDGE_TABLE_COMMENT, BRIDGE_COLS, BRIDGE_TAGS, BRIDGE_HEADER),
    encoding="utf-8",
)
print(f"Wrote bridge alter: {bridge_path} ({len(BRIDGE_COLS)} cols)")

# ---------- View (bridgeclaw) --------------------------------------------
VIEW_HEADER = """-- =============================================================================
-- Databricks ALTER Script: main.bridgeclaw_permitted_data.appflyer_reports (VIEW)
-- Generated: 2026-06-10 | one-shot AppsFlyer deployment
-- Target: Unity Catalog VIEW comment + column comments
-- View definition: filtered subset of main.de_output.de_output_appsflyer_silver_reports
--                  WHERE dateid > 20260531
-- Syntax note: views use COMMENT ON COLUMN (ANSI) not ALTER TABLE ALTER COLUMN.
-- =============================================================================
"""
VIEW_TAGS = {
    "domain": "marketing_attribution",
    "object_type": "permissioned_view",
    "source_schema": "bridgeclaw_permitted_data",
    "underlying_table": "main.de_output.de_output_appsflyer_silver_reports",
    "filter": "dateid > 20260531",
    "pipeline": "one-shot-appsflyer-deploy",
    "pipeline_version": "2026-06-10",
    "semantic_grade": "4",
}

view_path = ROOT / "knowledge" / "UC_generated" / "bridgeclaw_permitted_data" / "Views" / "appflyer_reports.alter.sql"
view_path.parent.mkdir(parents=True, exist_ok=True)
view_path.write_text(
    render_view_alter(VIEW_FQN, VIEW_COMMENT, VIEW_COLS, VIEW_TAGS, VIEW_HEADER),
    encoding="utf-8",
)
print(f"Wrote view alter: {view_path} ({len(VIEW_COLS)} cols)")

# ---------- Bridge wiki (minimal) ----------------------------------------
bridge_wiki_path = ROOT / "knowledge" / "UC_generated" / "bi_db" / "Tables" / "bronze_marketperformance_tracking_customer.md"
BRIDGE_WIKI = f"""---
object_fqn: {BRIDGE_FQN}
object_type: EXTERNAL
schema: bi_db
generator: one-shot AppsFlyer deployment
column_count: {len(BRIDGE_COLS)}
row_count: 48021494
distinct_cids: 48021494
generated_at: '2026-06-10'
upstreams:
- marketperformance pipeline (DataPlatform)
downstreams:
- main.de_output.de_output_appsflyer_silver_reports (joined on AppsflyerID)
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports (joined on AppsflyerID)
needs_review:
- DeviceTypeID enum (1 / 2 / 3 - mapping unknown)
- PartitionCol semantics (0-9 + one -1; presumed hash)
- UserUniqueIdentifierCookie (web cookie ID? sparse 18%)
- AdditionalData (sparse 2%, content schema unknown)
- iOSAdTrackingPermissionID full enum (only 0 / 1 observed)
---

# bronze_marketperformance_tracking_customer

> CID-to-mobile-device-identity bridge for AppsFlyer attribution. 48M rows, 1 row per CID. Joins to the AppsFlyer fact (silver or gold) on AppsflyerID = AppsFlyerID (note vendor lowercase-f spelling on this side).

## Why this table exists

On the AppsFlyer fact tables, `CustomerUserID` is **null on Installs and OrganicInstalls** because no CID exists pre-registration. To roll mobile-attributed events up to a CID across the full lifecycle (install -> registration -> KYC -> FTD), join through this bridge on `AppsflyerID`.

## Coverage

| Field | Populated rows | % of 48M CIDs |
|---|---:|---:|
| `AppsflyerID` | 20.9M | 43% (CIDs who registered via OneApp mobile) |
| `FirebaseID` | 9.3M | 19% |
| `UserUniqueIdentifierCookie` | 8.9M | 18% |
| `IDFV` | 1.4M | 3% (iOS-only post-ATT) |
| `iOSAdTrackingPermissionID = 1` | 1.3M | 3% (ATT-Authorized share) |
| `AdditionalData` | 1.0M | 2% (sparse) |

## Five fields that need review

The user explicitly requested no speculation on these. Comments capture only observed values:

- **`DeviceTypeID`** (INT) — three values: 1 (~27M), 2 (~10.1M), 3 (~10.9M). The split does NOT match the AppsFlyer Platform split (~75% Android / ~23% iOS), so it's NOT a one-to-one Platform code.
- **`PartitionCol`** (INT) — 0-9 (~4.8M each) + one `-1` row. Looks like upstream hash distribution metadata.
- **`UserUniqueIdentifierCookie`** (STRING) — sparse 18% population. Name suggests a web-tracking cookie ID for cross-device CID resolution.
- **`AdditionalData`** (STRING) — sparse 2% population. Content schema unknown.
- **`iOSAdTrackingPermissionID`** (INT) — only `0` (97%) and `1` (3%) observed; the 4-value Apple ATTrackingManager enum (NotDetermined / Restricted / Denied / Authorized) is not represented at this storage grain.

## Canonical join

```sql
SELECT mp.CID, mp.GCID, a.EventName, a.EventRevenueUSD, a.MediaSource, a.Date
FROM main.de_output.de_output_appsflyer_silver_reports a
JOIN main.bi_db.bronze_marketperformance_tracking_customer mp
  ON a.AppsFlyerID = mp.AppsflyerID
WHERE a.EtoroReport = 'InAppEvents'
  AND a.EventSource IN ('SDK','S2S')
  AND a.EventName IN ('FTD_S2S','Registration_S2S','Open Trade')
  AND a.Date >= DATE'2026-05-01';
```

*Generated 2026-06-10 - one-shot AppsFlyer deployment grounded in `proposals/AppsFlyer_Fields.pdf`. Five columns flagged NEEDS REVIEW per user instruction.*
"""
bridge_wiki_path.write_text(BRIDGE_WIKI, encoding="utf-8")
print(f"Wrote bridge wiki: {bridge_wiki_path}")

# ---------- View wiki (minimal) ------------------------------------------
view_wiki_path = ROOT / "knowledge" / "UC_generated" / "bridgeclaw_permitted_data" / "Views" / "appflyer_reports.md"
view_wiki_path.parent.mkdir(parents=True, exist_ok=True)
VIEW_WIKI = f"""---
object_fqn: {VIEW_FQN}
object_type: VIEW
schema: bridgeclaw_permitted_data
generator: one-shot AppsFlyer deployment
column_count: {len(VIEW_COLS)}
generated_at: '2026-06-10'
underlying_table: main.de_output.de_output_appsflyer_silver_reports
filter: dateid > 20260531
---

# bridgeclaw_permitted_data.appflyer_reports (VIEW)

> Permissioned PII-safe view over the AppsFlyer mobile-attribution silver fact. 33-column subset of `main.de_output.de_output_appsflyer_silver_reports`, filtered `dateid > 20260531`.

## Source

```sql
SELECT
  DateID, EtoroReport, EventSource,
  AppsFlyerID, CustomerUserID,
  EventTime, InstallTime,
  Partner, MediaSource, Channel,
  Campaign, CampaignID, Adset, AdsetID, Ad, AdID, AdType,
  Region, CountryCode,
  Platform, DeviceType, OSVersion, AppVersion,
  EventName, EventValue, EventRevenue, EventRevenueUSD,
  Date,
  CostModel, CostValue, CostCurrency,
  IsRetargeting, RetargetingConversionType
FROM main.de_output.de_output_appsflyer_silver_reports
WHERE dateid > 20260531;
```

## Columns excluded from the silver fact (and why it matters)

The view drops:
- **Location detail**: `State`, `City`, `PostalCode`, `DMA`, `IP` — likely PII redaction for permissioned consumers.
- **Device-network**: `WIFI`, `Operator`, `Carrier`, `Language`.
- **Sub-params**: all 5 `SubParam1..5`.
- **Most device IDs**: `AdvertisingID`, `IDFA`, `IDFV`, `AndroidID`, `IMEI` (only `AppsFlyerID` + `CustomerUserID` survive).
- **HTTP attribution metadata**: `HTTPReferrer`, `OriginalURL`, `UserAgent`, `IsReceiptValidated`, `AttributionLookback`, `ReengagementWindow`, `IsPrimaryAttribution`.
- **Multi-touch contributors**: all 15 `Contributor1/2/3*` columns.
- **eToro pipeline app fields**: `EtoroAppID`, `EtoroAppName` (Platform / AppID retained).
- **AppsFlyer SDK metadata**: `SDKVersion`, `AppID`, `AppName`, `BundleID`, `Keywords`.

## What this view IS suitable for

- KPI dashboards keyed on `MediaSource × Campaign × Date × Platform`
- Funnel counts by `EventName` (use `_S2S` suffix for revenue / FTD analytics)
- Cohort retention via `InstallTime` and `EventName`
- Per-CID rollups via the `CustomerUserID` direct join (no need for the `bronze_marketperformance_tracking_customer` bridge if the consumer can stomach the empty-on-Installs gap)

## What this view IS NOT suitable for

- Device-level cohorting (no `IDFA` / `IDFV` / `AdvertisingID` / `AndroidID`)
- Multi-touch / view-through attribution (no `Contributor1/2/3*`)
- Geo deep-dives (no `City` / `State` / `PostalCode` / `DMA` / `IP`)
- Cost-per-install analytics needing carrier / wifi context

For any of the above, use the underlying silver fact directly (where access permits).

## Filter contract: `dateid > 20260531`

The view definition hard-codes a forward-cutover guard. Per user instruction this is **a one-off setup** - someone preferred silver as the source for this permissioned face. Do **not** read it as a strategic deprecation of the gold mirror. Past dates remain queryable on `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports`.

*Generated 2026-06-10 - one-shot AppsFlyer deployment.*
"""
view_wiki_path.write_text(VIEW_WIKI, encoding="utf-8")
print(f"Wrote view wiki: {view_wiki_path}")

print()
print("All bridge + view artifacts written.")
