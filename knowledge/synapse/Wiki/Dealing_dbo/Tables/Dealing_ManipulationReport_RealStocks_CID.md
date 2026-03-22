# Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_ManipulationReport_RealStocks_CID |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 18 |
| **Primary Source** | Multi-source: DWH_dbo.Dim_Position, DWH_dbo.Dim_Customer, DWH_dbo.Dim_Instrument |
| **ETL SP** | `Dealing_dbo.SP_ManipulationReport_RealStocks` (same SP as instrument-level table) |
| **Refresh** | Daily per @dd date |
| **PII** | YES — contains CID, UserName, Country, Manager |
| **Tags** | dealing, market-manipulation, compliance, real-stocks, regulation, surveillance, cid-level |

---

## 1. Business Meaning

`Dealing_ManipulationReport_RealStocks_CID` is the **customer-level breakdown** of the daily market manipulation surveillance report for real stocks and ETFs. While `Dealing_ManipulationReport_RealStocks` flags instruments with suspicious aggregate activity, this table identifies the **specific customers (CIDs)** within those instruments whose individual trading patterns are anomalous.

**Scope**: Same universe as the parent table — real assets (IsSettled=1), Stocks and ETFs (InstrumentTypeID IN 5,6), manual positions only (MirrorID=0), valid customers in regulated jurisdictions (RegulationID IN 1,2,4). Weekdays only.

Each row represents **one customer flagged for anomalous activity in one instrument** on the reporting date. A customer can appear multiple times if they traded multiple flagged instruments.

**Flagging criteria**: A customer×instrument combination is flagged when either:
1. The customer accounts for more than **50% of all trades** in that instrument that day (`NumberOfTrades / AllTrades > 0.5`)
2. The customer's trade count exceeds **2× the 30-day average daily opens** for that instrument (`NumberOfTrades / AvgDailyOpen > 2`)

These thresholds are designed to identify customers who are disproportionately active in a single instrument — a key behavioral indicator in market manipulation surveillance.

**Relationship**: This table is populated by the same SP (`SP_ManipulationReport_RealStocks`) as the instrument-level table but from a separate query section. It complements the KPI-level signals in the parent table by providing the customer identity behind the aggregate anomalies.

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

Computed within `SP_ManipulationReport_RealStocks(@dd)` after the instrument-level INSERT, using the same position universe (`#All_Positions_Data`):

1. **`#TradesPerInstrument`**: Aggregates all valid customers' trade activity per instrument — total `NumberOfTrades` (positions opened on @dd, excluding partial-close children), `Volume` (USD), `Units` (shares). This gives the "total market" denominator for each instrument.

2. **`#TradesPerCIDAndInstrument`**: Same aggregation broken down by customer (CID). Per CID×instrument: `NumberOfTrades` (positions opened on @dd, excluding partial-close children), `Volume`, `Units`, plus customer metadata: `UserName`, `Country`, `Club`, `Manager`, `Regulation`.

3. **`#AvgDailyKPIs`**: 30-day trailing average of daily opens per instrument (pre-computed earlier in the SP).

4. **`#Flags`**: Joins `#TradesPerCIDAndInstrument` to `#TradesPerInstrument` and `#AvgDailyKPIs`, then filters with the flagging criteria:
   ```sql
   WHERE a.NumberOfTrades / NULLIF(b.NumberOfTrades, 0) > 0.5
      OR a.NumberOfTrades / NULLIF(c.AvgDailyOpen, 0) > 2
   ```
   Computes:
   - `PercentOfTotalTrades = NumberOfTrades / AllTrades` — customer's share of instrument's day total
   - `PercentOfAvg30Days = NumberOfTrades / AvgDailyOpen` — customer's activity relative to 30-day norm

5. **INSERT** into `Dealing_ManipulationReport_RealStocks_CID` from `#Flags` with `GETDATE()` as `UpdateDate`.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_ManipulationReport_RealStocks` | `Date, InstrumentID` | Instrument-level parent; same SP, same day |
| `DWH_dbo.Dim_Position` | `PositionID, InstrumentID, RealCID` | Position universe source |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter and metadata |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter, username |
| `DWH_dbo.Fact_SnapshotCustomer` | `RealCID` | Country, Manager, Regulation, Club |
| `DWH_dbo.Dim_Regulation` | `DWHRegulationID` | Regulation filter and name |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_ManipulationReport_RealStocks)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date. Matches `@dd` parameter. Clustered index key. Weekdays only. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 2 | CID | bigint | YES | Customer ID — the flagged customer's account identifier. FK to DWH_dbo.Dim_Customer. **PII field.** (Tier 2 — SP_ManipulationReport_RealStocks) |
| 3 | UserName | varchar(max) | YES | The customer's eToro username. **PII field.** Sourced from Dim_Customer or Fact_SnapshotCustomer via #All_Positions_Data. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 4 | Country | varchar(250) | YES | Customer's country of residence. From Fact_SnapshotCustomer → Dim_Country. **PII field.** (Tier 2 — SP_ManipulationReport_RealStocks) |
| 5 | Manager | varchar(250) | YES | Account manager assigned to this customer. From Fact_SnapshotCustomer → Dim_Manager. **PII field.** Used by compliance team to route flagged customers to their managers. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 6 | Regulation | varchar(50) | YES | Regulatory entity for this customer. From Dim_Regulation.Name. Values: 'CySEC', 'FCA', or other regulators with RegulationID IN (1,2,4). (Tier 2 — SP_ManipulationReport_RealStocks) |
| 7 | Club | varchar(50) | YES | Customer's eToro club/player level (e.g., 'Bronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus'). From Dim_PlayerLevel. Used for customer segmentation in compliance review. (Tier 3 — live data) |
| 8 | InstrumentID | int | YES | The instrument in which the customer was flagged. FK to DWH_dbo.Dim_Instrument. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 9 | InstrumentDisplayName | varchar(250) | YES | User-facing name of the flagged instrument (e.g., 'Mastercard', 'Aon plc'). From Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 10 | InstrumentType | varchar(50) | YES | 'Stocks' or 'ETF'. From Dim_Instrument.InstrumentType. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 11 | NumberOfTrades | int | YES | Count of positions this customer opened in this instrument on `Date` (positions with OpenDateID = @dd, excluding partial-close children). The customer's individual trade count — numerator for both flagging thresholds. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 12 | AllTrades | int | YES | Total count of positions opened by ALL customers in this instrument on `Date` (same filter). Represents the total market activity in this instrument today. Denominator for `PercentOfTotalTrades`. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 13 | AvgDailyOpen | float | YES | 30-day trailing average of daily position opens for this instrument, from `#AvgDailyKPIs`. Computed as `OpenVolume30Days / 30`. Denominator for `PercentOfAvg30Days`. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 14 | Volume | bigint | YES | Total USD trading volume (opens + closes) for this customer in this instrument on `Date`. Sum of Dim_Position.Volume across all positions. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 15 | Units | float | YES | Total shares traded by this customer in this instrument on `Date`. Sum of AmountInUnitsDecimal across positions. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 16 | PercentOfAvg30Days | float | YES | `NumberOfTrades / AvgDailyOpen` — how many times the customer's trade count exceeds the 30-day average. Value > 2 triggers the second flagging condition. E.g., 2.5 means the customer alone opened 2.5× the typical daily activity for this instrument. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 17 | PercentOfTotalTrades | float | YES | `NumberOfTrades / AllTrades` — the fraction of today's total instrument trades attributable to this customer. Value > 0.5 triggers the first flagging condition. E.g., 1.0 = customer was the only trader in this instrument today. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 18 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at time SP ran. Not a business timestamp. (Tier 2 — SP_ManipulationReport_RealStocks) |

---

## 5. Usage Notes

**Flagging thresholds**: A row exists because at least one condition holds:
- `PercentOfTotalTrades > 0.5`: This customer dominated that instrument today (>50% of all trades)
- `PercentOfAvg30Days > 2`: This customer's activity today was >2× the instrument's 30-day average

Both can be true simultaneously. Check both columns when reviewing.

**Connecting to parent table**: This table does NOT use the KPI column structure of `Dealing_ManipulationReport_RealStocks`. To understand which aggregate KPI an instrument was flagged under, join to the parent table on `Date + InstrumentID`.

**PII handling**: This table contains `CID`, `UserName`, `Country`, and `Manager` — direct customer identifiers. Access should be restricted to the Dealing/Compliance team per data governance policy.

**Volume vs AllTrades**: `Volume` is USD dollar volume; `AllTrades` and `NumberOfTrades` are trade counts (number of positions opened). A customer can have high `PercentOfTotalTrades` with a low USD `Volume` if they opened many small trades.

**Distribution**: ROUND_ROBIN, clustered on Date. Always filter on `Date` first.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position (Trade.PositionTbl via DWH ETL) |
| **Refresh** | Daily per weekday via `SP_ManipulationReport_RealStocks(@dd)` |
| **SP Author** | Amir Gurewitz (2019); Synapse migration 2024 |
| **PII** | YES — CID, UserName, Country, Manager |
| **Compliance** | Used for customer-level market manipulation surveillance under CySEC/FCA regulatory obligations |
| **Related** | `Dealing_ManipulationReport_RealStocks` for instrument-level aggregate signals |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Sample up to 2026-03-10 (active) |
| SP Logic | 5/5 | CID-level query section fully traced in SP_ManipulationReport_RealStocks |
| Upstream Wiki | 2/5 | Shared sources with parent table; no separate upstream wiki |
| Business Context | 2/5 | Atlassian MCP unavailable; flagging logic derived from SP |
| **Total** | **7.8/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
