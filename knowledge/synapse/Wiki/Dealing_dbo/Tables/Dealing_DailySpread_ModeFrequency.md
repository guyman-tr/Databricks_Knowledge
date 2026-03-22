---
object: Dealing_dbo.Dealing_DailySpread_ModeFrequency
type: Table
schema: Dealing_dbo
database: Synapse DWH
documented: 2026-03-21
quality_score: 8.0
status: active
---

# Dealing_DailySpread_ModeFrequency

## 1. Purpose

Daily per-instrument spread analytics using **modal (most frequent) spread** as the primary metric — more robust than average for skewed spread distributions. Computes two spread types: PP spread (provider-to-provider, from Dim_Position open/close prices) and eToro spread (the markup eToro applies). The `SpreadType` column distinguishes Open vs Close spread analysis. Produced by `SP_DailySpread_ModeFrequency` (OpsDB-tracked). Used by pricing/trading teams to monitor LP pricing quality and eToro margin behavior.

> **✅ ACTIVE pipeline.** 2,379,289 rows. 2024-03-11 – 2026-03-10.

## 2. Data Profile

| Metric | Value |
|--------|-------|
| **Row count** | 2,379,289 |
| **Date range** | 2024-03-11 – 2026-03-10 ✅ ACTIVE |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on Date ASC |

## 3. ETL / Writer

| Property | Value |
|----------|-------|
| **Writer SP** | `Dealing_dbo.SP_DailySpread_ModeFrequency` |
| **Frequency** | Daily |
| **OpsDB tracked** | ✅ Yes — Priority 0, SB_Daily |
| **Load mode** | DELETE WHERE Date = @Date, then INSERT |
| **Source** | `DWH_dbo.Dim_Position` (InitForex, EndForex prices) |

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Trade date. (Tier 2 — SP_DailySpread_ModeFrequency) |
| InstrumentID | int | Instrument identifier. (Tier 2 — DWH_dbo.Dim_Position) |
| InstrumentName | char(50) | Instrument name. Note: char(50) — values are right-padded. (Tier 2 — DWH_dbo.Dim_Instrument) |
| InstrumentType | char(50) | Instrument asset class. Note: char(50) — values are right-padded. (Tier 2 — DWH_dbo.Dim_Instrument) |
| DailyAvg_PPSpread | float | Daily average provider-provider (PP) spread: AVG(|InitForex − EndForex|) across all positions opened/closed. (Tier 2 — computed) |
| DailyAvg_EtoroSpread | float | Daily average eToro spread: average of eToro's bid-ask markup above the PP spread. (Tier 2 — computed) |
| NumberofTradesDaily | int | Number of trades used in spread calculation on this date. (Tier 2 — computed) |
| Daily_EtoroSpread_Mode | float | Modal (most frequent) eToro spread value on this date — more representative than mean for skewed distributions. (Tier 2 — computed) |
| Daily_EtoroSpread_ModeFrequency | float | How often (as fraction or count) the modal eToro spread appeared. (Tier 2 — computed) |
| DailyPPSpread_DividedByEtoroSpread | float | Ratio: DailyAvg_PPSpread / DailyAvg_EtoroSpread. Measures LP raw spread as fraction of eToro's spread. (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated. (Tier 1 — ETL metadata canonical) |
| SpreadType | char(50) | Spread measurement direction: `Open` (spread at position open) or `Close` (spread at position close). Note: char(50) — right-padded. (Tier 2 — SP logic) |
| ModePPSpread | float | Modal (most frequent) PP spread value on this date. (Tier 2 — computed) |

## 5. Business Rules & Relationships

- **Two rows per instrument per date**: One row for `SpreadType = 'Open'` and one for `SpreadType = 'Close'` — always filter by SpreadType when comparing across dates.
- **PP spread vs eToro spread**: PP spread (provider-provider) reflects the raw market bid-ask from LPs. eToro spread adds eToro's markup. `DailyPPSpread_DividedByEtoroSpread` < 1 means eToro's spread is wider than the LP's raw spread (expected — eToro charges a markup).
- **Mode vs Mean**: Mode is the primary analytical metric here (vs average in `Dealing_DailySpreadsAggregated`). Mode is less sensitive to outliers from volatile market-open periods.
- **Source prices**: `InitForex` (open price) and `EndForex` (close price) from `DWH_dbo.Dim_Position` — same source as PnL calculations.
- **`char` columns**: `InstrumentName`, `InstrumentType`, `SpreadType` use char(50) — use RTRIM() for string comparisons.
- **Active since Mar 2024**: This SP was newer than `DailySpreadsAggregated` — mode-frequency analysis was added to complement the hour-by-hour average spread table.

## 6. Query Notes

```sql
-- Instruments with widest modal eToro spread (Open) by month
SELECT YEAR(Date) AS Year, MONTH(Date) AS Month,
       RTRIM(InstrumentName) AS Instrument,
       AVG(Daily_EtoroSpread_Mode) AS AvgModalSpread,
       AVG(DailyPPSpread_DividedByEtoroSpread) AS PPtoEtoroRatio
FROM [Dealing_dbo].[Dealing_DailySpread_ModeFrequency]
WHERE RTRIM(SpreadType) = 'Open'
  AND Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), InstrumentName
ORDER BY AvgModalSpread DESC
```

## 7. Production Lineage

DWH-computed analytics from DWH_dbo.Dim_Position open/close prices. No upstream production wiki.

## 8. Known Issues & Notes

- **`char` type padding**: `InstrumentName`, `InstrumentType`, `SpreadType` are CHAR — always use RTRIM() in comparisons.
- **Two rows per instrument per day**: Forgetting `WHERE SpreadType = 'Open/Close'` will double-count.
- **`Daily_EtoroSpread_ModeFrequency` units**: Confirm if this is a count (integer-like) or fraction — the float type suggests it may be either.

---
*Quality score: 8.0/10 | Documented: 2026-03-21 | Writer: SP_DailySpread_ModeFrequency*
