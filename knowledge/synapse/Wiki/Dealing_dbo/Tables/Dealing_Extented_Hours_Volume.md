---
object: Dealing_dbo.Dealing_Extented_Hours_Volume
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.0
status: stale_pipeline
---

# Dealing_Extented_Hours_Volume

## 1. Purpose

Position-level extended hours trading volume detail, categorized by **session** (Pre_Session, Main_Session, Post_Session, OverNight_Session). One row per position traded during extended hours, with the `Category` column identifying which session the trade occurred in. Produced by `SP_Extented_Hours_Volume` (OpsDB-tracked). Supports CSO team dashboards for extended hours volume, client mix, and commission tracking by session. Note: "Extented" is a typo preserved in all related objects. OverNight_Session category added March 2025.

> **⚠️ PIPELINE ~7 months stale (last: 2025-08-31).** 37,956,908 rows. 2023-07-03 – 2025-08-31.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 37,956,908 (38M) |
| **Date range** | 2023-07-03 – 2025-08-31 ⚠️ ~7 months stale |
| **Distribution** | HASH(PositionID) |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Extented_Hours_Volume` |
| **Frequency** | Daily |
| **OpsDB tracked** | ✅ Yes — Priority 0, SB_Daily |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `DWH_dbo.Dim_Position` |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date. NOT NULL. (Tier 2 — SP_Extented_Hours_Volume) |
| PositionID | bigint | Position identifier. Primary key for deduplication. NOT NULL. HASH distribution key. (Tier 2 — DWH_dbo.Dim_Position) |
| CID | int | Client identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentID | int | Instrument identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| Name | nvarchar(255) | Instrument name. Note: nvarchar(255) — wider than `Dealing_Extented_Hours_NewCID.Name`. (Tier 2 — DWH_dbo.Dim_Instrument) |
| Category | nvarchar(255) | Trading session category: `Pre_Session` (10:30–13:30 UTC), `Main_Session` (13:30–20:00 UTC), `Post_Session` (>20:00 UTC), `OverNight_Session` (00:00–10:30 UTC). Added Mar 2025. (Tier 2 — SP logic) |
| Volume | decimal(38,2) | Trade volume in USD equivalent. (Tier 2 — DWH_dbo.Dim_Position) |
| Clicks | int | Number of order clicks contributing to this position. (Tier 2 — DWH_dbo.Dim_Position) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. NOT NULL. (Tier 1 — ETL metadata canonical) |
| Symbol | varchar(100) | Instrument trading symbol. (Tier 2 — DWH_dbo.Dim_Instrument) |
| CountryID | int | Client's country identifier. (Tier 2 — DWH_dbo.Dim_Customer) |
| Country_Name | varchar(50) | Client's country name. (Tier 2 — DWH_dbo.Dim_Customer) |
| Leverage | int | Leverage multiplier on this position. (Tier 2 — DWH_dbo.Dim_Position) |
| MirrorID | int | Copy trading mirror identifier. NULL for direct trades. (Tier 2 — DWH_dbo.Dim_Position) |
| Commission | money | Commission charged for this position. (Tier 2 — DWH_dbo.Dim_Position) |

## 5. Business Rules & Relationships

- **Session categories** (UTC times):
  - `Pre_Session`: 10:30–13:30 (pre-US market open extended hours)
  - `Main_Session`: 13:30–20:00 (US regular market hours)
  - `Post_Session`: after 20:00 (post-market extended hours)
  - `OverNight_Session`: 00:00–10:30 (overnight / pre-European session) — **added March 2025**
- **OverNight_Session availability**: Only present for positions from March 2025 onwards. Positions before this date have only 3 category values.
- **HASH(PositionID) distribution**: Unlike all other Dealing_dbo tables (ROUND_ROBIN), this table uses hash distribution on PositionID — optimizes for joins on PositionID (e.g., joining to `DWH_dbo.Dim_Position`).
- **One row per position**: Each PositionID appears once with its session Category. Not aggregated — position-level grain.
- **CSO team primary table**: This is the higher-cardinality companion to `Dealing_Extented_Hours_NewCID` — the NewCID table tracks first-time traders, this table tracks all trades.
- **`Volume` decimal(38,2)**: Very wide decimal type — allows for large institutional trade sizes.

## 6. Query Notes

```sql
-- Volume by session category
SELECT Date, Category,
       COUNT(DISTINCT CID) AS UniqueCIDs,
       COUNT(*) AS Positions,
       SUM(Volume) AS TotalVolume_USD,
       SUM(Commission) AS TotalCommission
FROM [Dealing_dbo].[Dealing_Extented_Hours_Volume]
WHERE Date >= '2025-01-01'
GROUP BY Date, Category
ORDER BY Date, Category
```

```sql
-- Note: OverNight_Session only available from March 2025
SELECT Category, COUNT(*) AS Rows
FROM [Dealing_dbo].[Dealing_Extented_Hours_Volume]
GROUP BY Category
```

## 7. Production Lineage

DWH-computed analytics from DWH_dbo.Dim_Position filtered to Exchange = 'Extended Hours Trading'. No upstream production wiki.

## 8. Known Issues & Notes

- **~7 months stale**: Last run Aug 31, 2025. OpsDB-tracked but suspended.
- **`OverNight_Session` not backfilled**: Category only exists from March 2025 — historical analysis crossing 4 categories must handle the pre-March 2025 period having only 3.
- **Typo in name**: "Extented" — consistent with companion table and SP.
- **HASH distribution**: Only Dealing_dbo table with HASH distribution — be aware when writing queries that join this with ROUND_ROBIN tables.

---
*Quality score: 8.0/10 | Documented: 2026-03-21 | Writer: SP_Extented_Hours_Volume*
