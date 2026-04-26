---
table: BI_DB_dbo.BI_DB_AppFlyer_Geo
lineage_tier: Tier 3 — derived from ETL SP code and AppFlyer platform knowledge
generated: 2026-04-22
---

# Lineage: BI_DB_AppFlyer_Geo

## ETL Pipeline

```
AppFlyer Platform (third-party mobile attribution SDK/API)
  → Lake ingestion (Fivetran / batch export)
  → BI_DB_dbo.BI_DB_AppFlyer_Geo_Ext   [all-varchar(500) staging, HEAP, ROUND_ROBIN, 30 cols]
  → BI_DB_dbo.SP_AppFlyer_Geo           [DELETE+INSERT, numeric coercion, loginlead col reorder]
        @dt_e DATE  →  @dt_int = CONVERT(@dt_e, 112)
  → BI_DB_dbo.BI_DB_AppFlyer_Geo        [typed target, CLUSTERED(Date ASC), ROUND_ROBIN]
```

## Writer SP: SP_AppFlyer_Geo

| Property | Value |
|----------|-------|
| SP | `BI_DB_dbo.SP_AppFlyer_Geo` |
| Author | Katy F (2016-06-15) |
| OpsDB Priority | 0 — base layer (no intra-schema dependencies) |
| Frequency | Daily (SB_Daily process, ProcessType SQL) |
| Pattern | DELETE WHERE `EtoroDateID = @dt_int` + INSERT from `#Geo_tmp` temp table |
| Date window | Single-day replace per run |

**Key transformations in SP:**
- All numeric columns (`Clicks`, `Installs`, `ConversionRate`, `Sessions`, `LoyalUsers`, `LoyalUsersInstalls`, `TotalRevenue`, `ARPU`, and all funnel event columns) go through `ISNUMERIC` / `LIKE` CASE expressions that coerce raw strings `'N/A'`, `'0.0000'`, and non-numeric characters → `0` before CAST to the target type. This is necessary because `Geo_Ext` stores everything as varchar.
- `loginleadUniqueusers`, `loginleadEventcounter`, `loginleadSalesinUSD` appear in a different positional order in `Geo_Ext` compared to the target table — the SP explicitly reorders them during the SELECT from temp table.
- No JOIN operations — insert is a direct type-coercing SELECT from the varchar staging source.

## Upstream Sources

| Layer | Object | Type | Description |
|-------|--------|------|-------------|
| Origin | AppFlyer Platform | Third-party SaaS | Mobile attribution platform. Exports aggregate data by country × media source × campaign × app × date. No eToro production DB upstream — this is external marketing data ingested via lake pipeline. |
| Staging | `BI_DB_dbo.BI_DB_AppFlyer_Geo_Ext` | Internal varchar staging (HEAP) | All columns varchar(500). ROUND_ROBIN, HEAP. 30 columns. Populated via lake/Fivetran batch load from AppFlyer API export. |

## Downstream Consumers

None identified in OpsDB procedure dependencies. `BI_DB_AppFlyer_Geo` is a **leaf endpoint** — no downstream stored procedures read from it.

## Upstream Wiki

No upstream wiki applies. AppFlyer is a third-party marketing attribution platform; its data does not originate from any eToro production database with a Tier 1 wiki.

## Notes

- `EtoroAppID` distinguishes mobile platform: `com_etoro_openbook` (Android) vs `id674984916` (iOS)
- `EtoroAppName` = always `'Geo'`; `EtoroReport` = always `'Date'` — AppFlyer export metadata constants
- `Country` is the raw AppFlyer ISO-2 country code. No UK→GB standardization applied here (unlike `BI_DB_AppFlyer_Reports` which does apply `CASE WHEN 'UK' THEN 'GB'`)
- Live date range: 2022-10-29 → 2023-09-17
