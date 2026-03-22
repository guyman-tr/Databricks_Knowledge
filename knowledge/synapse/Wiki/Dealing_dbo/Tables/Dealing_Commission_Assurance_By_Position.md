---
object: Dealing_Commission_Assurance_By_Position
schema: Dealing_dbo
type: Table
description: Position-level daily commission assurance table comparing actual charged commission versus the calculated expected commission (AmountInUnits × spread/precision). Only rows with |diff| > $0.0051 are stored.
etl_sp: Dealing_dbo.SP_Rev_Assurance
frequency: Daily
status: Active (last: 2026-03-10)
row_count: 90,821,207
distribution: HASH(PositionID)
index: CLUSTERED COLUMNSTORE INDEX
batch: 14
quality: 8.5
---

# Dealing_Commission_Assurance_By_Position

Position-level commission integrity table. For each trading day, captures positions where the **actual commission charged differs meaningfully from the calculated expected commission** — defined as |diff| > $0.0051. The expected commission is computed as `AmountInUnitsDecimal × (Ask - Bid) / 10^Precision`, i.e., the full spread-based commission.

90.8M rows across ~4 years (2022-01-02 to 2026-03-10), distributed by PositionID with a clustered columnstore index for analytical queries.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Position data (PositionID, InstrumentID, AmountInUnitsDecimal, Commission, MirrorID, OpenDateID) |
| Source | `DWH_staging.etoro_Trade_ProviderToInstrument` | Precision (decimal places) per instrument |
| Source | `Dealing_staging.External_Etoro_Trade_InstrumentSpread` | Current bid/ask spread per instrument (SpreadTypeID=1) |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentType, Name; filter: SellCurrencyID = 1 (USD instruments only) |
| Filter | `DWH_dbo.Dim_Customer` | PlayerLevelID ≠ 4 (exclude employees/test accounts) |
| Writer | `Dealing_dbo.SP_Rev_Assurance` | Daily, OpsDB Priority 0 |

## 1. Business Purpose

- Identifies positions where commission was charged incorrectly (over or under)
- `diff = Commission - RealComm` — positive means over-charged, negative means under-charged
- Threshold |diff| > $0.0051 filters out rounding noise
- Used by Dealing/Finance to audit commission accuracy and detect configuration drift

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Expected commission (RealComm) | `AmountInUnitsDecimal × (Ask - Bid) / 10^Precision` — full spread as commission |
| Actual commission (Commission) | What was actually charged, from DWH_dbo.Dim_Position |
| diff | `Commission - RealComm` — positive = overcharged, negative = undercharged |
| Threshold | Only positions with |diff| > $0.0051 are stored (filters micro-rounding) |
| SellCurrencyID = 1 filter | Only USD-denominated instruments included |

## 3. Grain

One row per **PositionID on a given Date** where the commission diverges from calculated. Multiple rows can exist for the same PositionID if checked on multiple dates.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Trading date the position was checked (OpenDateID matches @DateID) | Tier 2 | Daily partition key |
| PositionID | bigint | Unique position identifier | Tier 1 | HASH distribution key; FK to DWH_dbo.Dim_Position |
| MirrorID | int | Copy trade mirror group ID; 0 for manual trades | Tier 1 | >0 = Copy trade |
| InstrumentID | int | Instrument traded | Tier 1 | FK to DWH_dbo.Dim_Instrument |
| InstrumentType | varchar(50) | Instrument type (Currencies, Stocks, Commodities, etc.) | Tier 2 | From Dim_Instrument |
| InstrumentName | varchar(50) | Instrument display name (e.g., EUR/USD, AAPL/USD) | Tier 2 | From Dim_Instrument.Name |
| AmountInUnitsDecimal | decimal(16,6) | Position size in instrument units | Tier 1 | Used in commission calculation |
| Spread | numeric(22,15) | `(Ask - Bid) / 10^Precision` — the spread in price units at time of check | Tier 2 | Real-time spread from External_Etoro_Trade_InstrumentSpread |
| Commission | money | Actual commission charged on position open | Tier 1 | From DWH_dbo.Dim_Position |
| RealComm | numeric(38,20) | Calculated expected commission: `AmountInUnitsDecimal × Spread` | Tier 2 | SP-computed |
| diff | numeric(38,20) | `Commission - RealComm`; positive = overcharged, negative = undercharged | Tier 2 | Only rows with \|diff\| > 0.0051 stored |
| UpdateDate | datetime | ETL metadata: row write timestamp | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Today's largest commission discrepancies
SELECT TOP 20 PositionID, InstrumentName, InstrumentType,
       Commission, RealComm, diff
FROM Dealing_dbo.Dealing_Commission_Assurance_By_Position
WHERE Date = CAST(GETDATE() AS DATE)
ORDER BY ABS(diff) DESC;

-- Monthly count of positions with commission issues by instrument type
SELECT CONVERT(varchar(7), Date, 126) AS Month,
       InstrumentType, COUNT(*) AS PositionCount,
       SUM(diff) AS TotalDiff
FROM Dealing_dbo.Dealing_Commission_Assurance_By_Position
GROUP BY CONVERT(varchar(7), Date, 126), InstrumentType
ORDER BY Month DESC;
```

> **Performance note**: 90.8M rows with HASH(PositionID) CCI. Query by Date range or PositionID for best performance. Avoid full scans without date predicates.

## 6. Data Quality & Caveats

- Spread used is the **real-time spread at check time** (from External_Etoro_Trade_InstrumentSpread), not the spread at trade open time — differences can be expected for volatile instruments
- Only USD-denominated instruments (SellCurrencyID = 1) — non-USD instruments are excluded
- Sample data shows EUR/USD positions with |diff| values of ~$0.007–$0.097 — typical rounding differences
- 90.8M rows; avoid `SELECT *` — use column projection and date filtering

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_Commission_Assurance` | Monthly summary aggregated from same SP |
| `Dealing_dbo.Dealing_Rollover_Assurance` | Third output of SP_Rev_Assurance — rollover fee integrity |
| `DWH_dbo.Dim_Position` | Primary source; Commission and AmountInUnitsDecimal |

## 8. Operational Notes

- **ETL**: `SP_Rev_Assurance` runs daily (OpsDB Priority 0). DELETE + INSERT for current date
- **Scheduling**: ProcessType 1 (SQL), ProcessName SB_Daily
- **Table design**: HASH(PositionID)/CCI vs ROUND_ROBIN/CI in Commission_Assurance — designed for PositionID-level lookups

---
*Quality score: 8.5/10 — Comprehensive coverage. Spread timing ambiguity is the main caveat.*
