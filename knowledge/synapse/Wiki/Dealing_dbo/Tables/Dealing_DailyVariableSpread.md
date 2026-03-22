---
object: Dealing_dbo.Dealing_DailyVariableSpread
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.0
status: active
---

# Dealing_DailyVariableSpread

## 1. Purpose

Daily aggregation of **variable spread revenue** (commissions and rollover fees) by HedgeServer × InstrumentType × InstrumentName. "Variable spread" refers to eToro's variable-markup commission model rather than fixed spreads. Produced by `SP_DailyVariableSpread` (OpsDB-tracked). Sources `DWH_dbo.Fact_CustomerAction` with quality filters applied (excludes internal accounts, staff players, and test labels). Used by finance/trading teams to track commission revenue by LP routing server and instrument type.

> **✅ ACTIVE pipeline.** 12,727,771 rows. 2022-01-01 – 2026-03-10.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 12,727,771 |
| **Date range** | 2022-01-01 – 2026-03-10 ✅ ACTIVE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on FullDate ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_DailyVariableSpread` |
| **Frequency** | Daily |
| **OpsDB tracked** | ✅ Yes — Priority 0, SB_Daily |
| **Load mode** | DELETE WHERE FullDate = @Date, then INSERT |
| **Source** | `DWH_dbo.Fact_CustomerAction` |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| FullDate | date | Trade date. Note: `FullDate` not `Date` — use this in WHERE clauses. (Tier 2 — SP_DailyVariableSpread) |
| DateID | int | Date dimension key corresponding to FullDate. (Tier 2 — DWH_dbo.Dim_Date) |
| HedgeServerID | int | Hedge server that routed these positions. Groups commission revenue by LP routing path. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| InstrumentType | varchar(50) | Instrument asset class (Stocks, Crypto, FX, etc.). (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| InstrumentName | varchar(50) | Instrument name. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| Commissions | money | Sum of commission charged by eToro for this group. (Tier 2 — DWH_dbo.Fact_CustomerAction.Commission) |
| FullCommissions | money | Sum of full commission (including all fee components) for this group. (Tier 2 — DWH_dbo.Fact_CustomerAction.FullCommission) |
| RollOverFee | money | Sum of rollover fees for positions held overnight. (Tier 2 — DWH_dbo.Fact_CustomerAction.RollOverFee) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |

## 5. Business Rules & Relationships

- **Quality filters applied**: `PlayerLevelID ≠ 4` (excludes staff/internal), `IsValidCustomer = 1`, `LabelID NOT IN (26, 30)` (excludes test/demo labels). Revenue figures reflect real client activity only.
- **`HedgeServerID`**: Groups by hedge routing server — links to LP performance. NULL HedgeServerID = platform-rejected orders (no LP involved).
- **`Commissions` vs `FullCommissions`**: `Commissions` is the net commission received; `FullCommissions` includes all fee components (may include regulatory surcharges). Difference = additional fee components.
- **`RollOverFee`**: Overnight financing charge — positive = client paid, negative = client received credit (rare, for short positions on dividend-paying instruments).
- **Date key**: `FullDate` is the primary date column (not `Date`). `DateID` is the integer surrogate key for joins to `DWH_dbo.Dim_Date`.
- **High row count**: 12.7M rows over 4 years reflects one row per HedgeServerID × InstrumentType × InstrumentName per day — many combinations active daily.

## 6. Query Notes

```sql
-- Daily commission revenue by instrument type
SELECT FullDate, InstrumentType,
       SUM(Commissions) AS TotalCommissions,
       SUM(FullCommissions) AS TotalFullCommissions,
       SUM(RollOverFee) AS TotalRollover
FROM [Dealing_dbo].[Dealing_DailyVariableSpread]
WHERE FullDate >= '2025-01-01'
GROUP BY FullDate, InstrumentType
ORDER BY FullDate, TotalCommissions DESC
```

```sql
-- Commission by HedgeServer (LP routing attribution)
SELECT HedgeServerID, SUM(Commissions) AS Commissions, SUM(RollOverFee) AS Rollover
FROM [Dealing_dbo].[Dealing_DailyVariableSpread]
WHERE FullDate = '2025-06-01'
GROUP BY HedgeServerID
ORDER BY Commissions DESC
```

## 7. Production Lineage

DWH-computed aggregation from DWH_dbo.Fact_CustomerAction. No upstream production wiki.

## 8. Known Issues & Notes

- **`FullDate` not `Date`**: Primary date column is named `FullDate` — joins using `Date` will fail.
- **`DateID` join**: Available for Dim_Date joins but redundant with `FullDate` for most use cases.
- **Label exclusions**: LabelID 26 and 30 are excluded — confirm what these labels represent to understand scope.

---
*Quality score: 8.0/10 | Documented: 2026-03-21 | Writer: SP_DailyVariableSpread*
