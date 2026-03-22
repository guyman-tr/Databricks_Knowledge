---
object: Dealing_dbo.Dealing_Extented_Hours_NewCID
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 7.5
status: stale_pipeline
---

# Dealing_Extented_Hours_NewCID

## 1. Purpose

Tracks **new clients** who trade extended hours for the first time on each date — CIDs that have no prior extended hours position history. Produced by `SP_Extented_Hours_NewCID` using a NOT EXISTS check against all prior `DWH_dbo.Dim_Position` rows where `Exchange = 'Extended Hours Trading'`. Grouped by Date × Country × Instrument × Mirror (copy trading relationship). Used by the CSO (Customer Success Operations) team to monitor extended hours adoption. Note: "Extented" is a typo in the original naming — intentionally preserved.

> **⚠️ PIPELINE ~7 months stale (last: 2025-08-29).** 102,633 rows. 2023-07-03 – 2025-08-29.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 102,633 |
| **Date range** | 2023-07-03 – 2025-08-29 ⚠️ ~7 months stale |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_Extented_Hours_NewCID` |
| **Frequency** | Daily |
| **OpsDB tracked** | ✅ Yes — Priority 0, SB_Daily |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `DWH_dbo.Dim_Position` |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Date when this CID first traded extended hours. NOT NULL. (Tier 2 — SP_Extented_Hours_NewCID) |
| New_CIDs | int | Count of new CIDs on this date for this Instrument × Country × Mirror group. (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. NOT NULL. (Tier 1 — ETL metadata canonical) |
| CountryID | int | Client's country identifier. (Tier 2 — DWH_dbo.Dim_Position / Dim_Customer) |
| Country_Name | varchar(50) | Client's country name. (Tier 2 — DWH_dbo.Dim_Position / Dim_Customer) |
| InstrumentID | int | Instrument traded in extended hours. (Tier 2 — DWH_dbo.Dim_Position) |
| Name | varchar(50) | Instrument name. (Tier 2 — DWH_dbo.Dim_Instrument) |
| Symbol | varchar(100) | Instrument trading symbol. (Tier 2 — DWH_dbo.Dim_Instrument) |
| MirrorID | int | Copy trading mirror identifier — links this position to a copy trader relationship. NULL for direct trades. (Tier 2 — DWH_dbo.Dim_Position) |

## 5. Business Rules & Relationships

- **"New CID" definition**: Client has NO prior positions where `Exchange = 'Extended Hours Trading'` — determined by NOT EXISTS check against all historical `Dim_Position` rows, not just the current date.
- **First-ever extended hours trade**: Once a CID has any extended hours position, they will never appear in this table again — truly first-time adoption tracking.
- **Granularity**: One row per Date × CountryID × InstrumentID × MirrorID combination. `New_CIDs` is the count of first-time traders in that group.
- **CSO team consumer**: Extended hours adoption is a business KPI for the Customer Success Operations team — this table feeds their dashboards.
- **`MirrorID`**: Distinguishes direct trading (NULL) from copy trading via a specific mirror.
- **Stale since Aug 2025**: OpsDB-tracked but last refreshed August 2025 — SP may have been suspended or source stopped.

## 6. Query Notes

```sql
-- New extended hours CIDs by country over time
SELECT Date, Country_Name, SUM(New_CIDs) AS NewTraders
FROM [Dealing_dbo].[Dealing_Extented_Hours_NewCID]
WHERE Date >= '2024-01-01'
GROUP BY Date, Country_Name
ORDER BY Date, NewTraders DESC
```

```sql
-- Most popular instruments for first extended hours trades
SELECT Name, Symbol, SUM(New_CIDs) AS TotalNewCIDs
FROM [Dealing_dbo].[Dealing_Extented_Hours_NewCID]
GROUP BY Name, Symbol
ORDER BY TotalNewCIDs DESC
```

## 7. Production Lineage

DWH-computed analytics from DWH_dbo.Dim_Position filtered to Exchange = 'Extended Hours Trading'. No upstream production wiki.

## 8. Known Issues & Notes

- **Typo in name**: "Extented" (should be "Extended") — preserved in all related objects (table, SP, column names).
- **~7 months stale**: Last refreshed Aug 29, 2025. OpsDB-tracked but not running.
- **NOT EXISTS lookback**: SP reads all historical Dim_Position rows on each run — performance may degrade as Dim_Position grows.

---
*Quality score: 7.5/10 | Documented: 2026-03-21 | Writer: SP_Extented_Hours_NewCID*
