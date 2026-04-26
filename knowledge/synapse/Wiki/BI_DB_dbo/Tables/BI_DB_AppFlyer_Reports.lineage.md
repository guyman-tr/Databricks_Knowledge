---
table: BI_DB_dbo.BI_DB_AppFlyer_Reports
lineage_tier: Tier 3 — derived from ETL SP code and AppFlyer platform knowledge
generated: 2026-04-22
---

# Lineage: BI_DB_AppFlyer_Reports

## ETL Pipeline

```
AppFlyer Platform (third-party mobile attribution SDK/API)
  → Lake ingestion (Fivetran / batch export — three report types merged)
  → BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext   [all-varchar(4000) staging, HEAP, ROUND_ROBIN, 86 cols + IP]
  → BI_DB_dbo.SP_AppFlyer_Reports           [DELETE+INSERT, type casting, ISO standardization]
        @dt DATE  →  @dt_int = CONVERT(@dt, 112)
  → BI_DB_dbo.BI_DB_AppFlyer_Reports        [mostly-varchar target, CLUSTERED(Date ASC, EtoroReport ASC)]
```

## Writer SP: SP_AppFlyer_Reports

| Property | Value |
|----------|-------|
| SP | `BI_DB_dbo.SP_AppFlyer_Reports` |
| Author | Katy F (2016-05-25) |
| OpsDB Priority | 0 — base layer (no intra-schema dependencies) |
| Frequency | Daily (SB_Daily process, ProcessType SQL) |
| Pattern | DELETE WHERE `DateID = @dt_int` + INSERT from `BI_DB_AppFlyer_Reports_Ext` WHERE `DateID = @dt_int` |
| Date window | Single-day replace per run |

**Key transformations in SP:**
- `AttributedTouchTime`: `CASE WHEN value = 'None' THEN NULL ELSE CAST AS datetime` — converts AppFlyer 'None' string → SQL NULL
- `InstallTime`: direct `CAST AS datetime`
- `CountryCode`: `CASE WHEN value = 'UK' THEN 'GB' ELSE value` — ISO-2 standardization (GB preferred over UK)
- `IsRetargeting`: `CASE WHEN ISNULL(val,'0') = '1' THEN 'true' ELSE 'false'` — boolean string normalization
- `WIFI`: same `'true'`/`'false'` string normalization
- `IsPrimaryAttribution`: same `'true'`/`'false'` string normalization
- `Contributor1TouchTime`, `Contributor2TouchTime`: `CASE WHEN val IN ('None','USD','usd') THEN NULL ELSE val` — cleans malformed touch time strings; stored as varchar
- `Contributor3TouchTime`: similar NULL cleanup but `CAST AS datetime` — inconsistent with Contributor1/2
- `HTTPReferrer`: `LEFT([HTTPReferrer], 4000)` — explicit truncation to varchar(4000) column size
- `UpdateDate`: **NOT in INSERT list** — column is always NULL in target table (DDL artifact)
- Note: `SelectMax(DateID)` diagnostic query runs at SP start (not functional, does not affect output)

## Upstream Sources

| Layer | Object | Type | Description |
|-------|--------|------|-------------|
| Origin | AppFlyer Platform | Third-party SaaS | Mobile attribution platform. Three report types are merged into one staging table: OrganicInstalls, Installs (non-organic), InAppEvents. No eToro production DB upstream. |
| Staging | `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext` | Internal varchar staging (HEAP) | All columns varchar(4000) except 2 masked (City, IsReceiptValidated) and `IP` column not present in target. 86+ columns. ROUND_ROBIN, HEAP. |

## Downstream Consumers

| Consumer SP | Output Tables | Type |
|-------------|--------------|------|
| `BI_DB_dbo.SP_Marketing_Cube` | `BI_DB_dbo.BI_DB_MarketingDailyRawData` | Marketing cube daily aggregation |
| `BI_DB_dbo.SP_Marketing_Cube` | `BI_DB_dbo.BI_DB_MarketingMonthlyRawData` | Marketing cube monthly aggregation |

`BI_DB_AppFlyer_Reports` is a **key upstream dependency** for the marketing analytics cube. `SP_Marketing_Cube` is also Priority 0 (SB_Daily) but depends on this table completing first.

## Upstream Wiki

No upstream wiki applies. AppFlyer is a third-party marketing attribution platform; data does not originate from any eToro production database with a Tier 1 wiki.

## Notes

- `EtoroReport` is the key partition dimension: `OrganicInstalls` (86M rows), `InAppEvents` (35.6M rows), `Installs` (6.8M rows) — always filter by EtoroReport for targeted queries
- `DateID`/`Date` = **event date** (date the in-app event or install was recorded), NOT install date. For install events, `Date` = `InstallTime`. For InAppEvents, `Date` may be weeks/months after `InstallTime`.
- `City` is DDM-masked (shows as `'xxxx'` to non-privileged users)
- `UpdateDate` is always NULL — not populated by the SP despite existing in DDL
- `Contributor3TouchTime` is typed as `datetime` in DDL while `Contributor1/2TouchTime` are `varchar` — architectural inconsistency
- Live date range: 2022-10-25 → 2026-04-12 (~128.6M rows)
