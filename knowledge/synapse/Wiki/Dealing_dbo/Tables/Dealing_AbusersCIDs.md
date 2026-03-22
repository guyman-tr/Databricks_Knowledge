# Dealing_dbo.Dealing_AbusersCIDs

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_AbusersCIDs |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 10 |
| **Primary Source** | `DWH_dbo.Dim_Position` (Trade.PositionTbl, etoroDB-REAL) |
| **ETL SP** | `Dealing_dbo.SP_AbusersCIDs` |
| **Refresh** | Daily per @Date (delete+insert) |
| **PII** | YES — contains CID |
| **Tags** | dealing, compliance, abuse-detection, short-duration, front-running, surveillance, stocks |

---

## 1. Business Meaning

`Dealing_AbusersCIDs` is a **daily short-duration stock trading abuse detector**. It identifies customers who appear to be front-running stock price movements by repeatedly opening and closing positions in the same stock within 10 minutes, with a high success rate.

This pattern is distinct from `Dealing_AbuseAPI` (burst API exploitation): while AbuseAPI targets millisecond-level bursts, AbusersCIDs targets customers who consistently profit from correctly predicting near-term price movements at the minutes-level — suggesting possible information advantage or platform latency exploitation.

**Flagging criteria (per CID×Instrument per day, all must be met)**:
1. **Stocks only** (`InstrumentTypeID=5`)
2. **Positions opened on @Date** with **duration < 10 minutes**
3. **Manual close only** (`ClosePositionReasonID=0`)
4. **PositiveProfit ≥ 4**: at least 4 of the short-duration positions had positive NetProfit
5. **SuccessRate ≥ 0.8**: ≥80% of positions were profitable
6. **TotalNetProfit ≥ $100**: meaningful aggregate profit (excludes noise)
7. **PriceChangeHigherThan1Percent ≥ 4**: at least 4 positions where the price moved ≥1% between open and close (`|EndForexRate - InitForexRate| / InitForexRate >= 0.01`)

The combination of high success rate + significant price movements suggests the customer is systematically profiting from rapid price events, not random noise.

**SP Author**: Adar Cahlon (2023-07-22). Newer detection method than AbuseAPI.

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_AbusersCIDs(@Date)`:

1. **`#PositionsData`**: All stock positions opened on @Date (InstrumentTypeID=5), closed manually (ClosePositionReasonID=0), with duration < 10 minutes. Computes `PercentagePriceChange = (EndForexRate - InitForexRate) / InitForexRate` for each position.

2. **`#Profit`**: Per CID×InstrumentID: aggregates `TotalNetProfit`, `PositiveProfit` (count of profitable positions), `TotalTrades` (total count), `SuccessRate` (PositiveProfit / TotalTrades), `PriceChangeHigherThan1Percent` (count of positions with |PercentagePriceChange| ≥ 1%).

3. **`#RelevantCIDs`**: Filters #Profit rows meeting all thresholds: PositiveProfit≥4, SuccessRate≥0.8, TotalNetProfit≥100, PriceChangeHigherThan1Percent≥4.

4. **`#AllData`**: Joins #PositionsData back to #RelevantCIDs to deduplicate and attach InstrumentName.

5. **Sentinel insert** via `#Date` + `#TotalTable`: LEFT JOIN Dim_Date ensures at least one row per date even if #AllData is empty — same sentinel pattern as `Dealing_AbuseAPI`.

6. **INSERT** into `Dealing_AbusersCIDs` with `@Date` and `GETDATE()`.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Position` | `PositionID, CID` | Position data (primary source) |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter (stocks only) and name |
| `DWH_dbo.Dim_Date` | `FullDate` | Sentinel row insert |
| `Dealing_dbo.Dealing_AbuseAPI` | `CID` | Related API burst detection (different abuse pattern) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_AbusersCIDs)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date (@Date parameter). Clustered index key. NULL on sentinel rows (no flagged events). (Tier 2 — SP_AbusersCIDs) |
| 2 | CID | int | YES | Customer account ID. NULL on sentinel rows. **PII field.** (Tier 2 — SP_AbusersCIDs) |
| 3 | InstrumentID | int | YES | The stock instrument in which the abuse pattern was detected. FK to DWH_dbo.Dim_Instrument. Stocks only (InstrumentTypeID=5). (Tier 2 — SP_AbusersCIDs) |
| 4 | InstrumentName | varchar(100) | YES | Instrument display name from Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_AbusersCIDs) |
| 5 | TotalNetProfit | decimal(16,6) | YES | Sum of NetProfit across all flagged short-duration positions for this CID×Instrument on @Date. Flagging threshold: ≥ $100. (Tier 2 — SP_AbusersCIDs) |
| 6 | PositiveProfit | int | YES | Count of positions with `NetProfit > 0` for this CID×Instrument on @Date. Flagging threshold: ≥ 4. (Tier 2 — SP_AbusersCIDs) |
| 7 | TotalTrades | int | YES | Total count of short-duration (<10 min) stock positions opened by this CID in this instrument on @Date (manual close, stocks only). Used as denominator for SuccessRate. (Tier 2 — SP_AbusersCIDs) |
| 8 | SuccessRate | decimal(16,6) | YES | `PositiveProfit / TotalTrades` — fraction of positions that were profitable. Flagging threshold: ≥ 0.8 (80%). E.g., 0.916667 = 11 of 12 trades profitable. (Tier 2 — SP_AbusersCIDs) |
| 9 | UpdateDate | datetime | NOT NULL | ETL metadata: `GETDATE()` at time SP ran. Always populated including sentinel rows. (Tier 2 — SP_AbusersCIDs) |
| 10 | PriceChangeHigherThan1Percent | int | YES | Count of positions where `|EndForexRate - InitForexRate| / InitForexRate >= 0.01` (1% price movement). Flagging threshold: ≥ 4. High values suggest the customer is consistently catching significant price moves. (Tier 2 — SP_AbusersCIDs) |

---

## 5. Usage Notes

**Filter NULL rows**: Always use `WHERE CID IS NOT NULL` to exclude sentinel rows (clean days with no detections).

**Granularity**: One row per CID×InstrumentID×Date (after the LEFT JOIN, sentinel rows are per Date only). The same CID can appear multiple times on the same Date if they triggered the pattern in multiple instruments.

**PercentagePriceChange not stored**: The position-level `PercentagePriceChange` used to compute `PriceChangeHigherThan1Percent` is not retained in the output — only the count is stored. To reconstruct individual position analysis, join to `Dim_Position` on CID + OpenDateID.

**Comparison with AbuseAPI**: `Dealing_AbuseAPI` detects bursts (3+ positions in 1 second). `Dealing_AbusersCIDs` detects pattern-level abuse (many short-duration trades with high success rate). A customer can trigger both. The CID column links both tables.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position (Trade.PositionTbl via DWH ETL) |
| **Refresh** | Daily per date via `SP_AbusersCIDs(@Date)` |
| **SP Author** | Adar Cahlon (2023-07-22) |
| **PII** | YES — CID |
| **Compliance** | Short-duration stock trading abuse detection for Dealing/Compliance surveillance |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Active data up to 2026-03-10 with real flagged events |
| SP Logic | 5/5 | Short SP (174 lines) fully analyzed |
| Upstream Wiki | 4/5 | Primary source (Dim_Position) documented; Dim_Instrument documented |
| Business Context | 2/5 | Atlassian MCP unavailable; purpose fully recoverable from SP description |
| **Total** | **8.2/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
