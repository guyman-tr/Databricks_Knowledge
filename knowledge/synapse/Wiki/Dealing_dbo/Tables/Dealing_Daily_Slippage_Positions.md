# Dealing_dbo.Dealing_Daily_Slippage_Positions

## 1. Overview

**Position-level execution slippage records** for every position open or close action executed on a given day. Each row captures the difference between the price the client expected (CustomerChosenRate) and the price actually received (EndForexRate), expressed in both pips and USD, along with an `OverThreshold` flag for actions exceeding the 0.5% slippage threshold. This table is an intermediate staging table in the Best Execution pipeline — it feeds `SP_Best_Execution` which computes `Dealing_Best_Execution_Compensation_CBH` and `_HBC`.

> **⚠️ DATA CURRENCY WARNING**: Maximum data date is **2025-01-11** — approximately 14 months before documentation date. The SP_Slippage_Report and downstream Best Execution pipelines appear to have been decommissioned or significantly disrupted around that date. Treat as potentially deprecated. Confirm with Dealing team before building new consumers.

**Row grain**: `Date` + `PositionID` + `ActionTypeID` (position action — open or close). DISTINCT insert prevents duplicates.

---

## 2. Business Context

`SP_Slippage_Report` (Author: Eden Liberman 2018-04-12, extensively updated by Adar Cahlon through 2024-08) calculates execution slippage for all position actions on the report date.

**Slippage formula**:
- `SlippageInPips` = (CustomerChosenRate − EndForexRate) / instrument precision
- `SlippageInDollar` = SlippageInPips × AmountInUnitsDecimal × ConversionRate
- `slippage %` = `ABS((CustomerChosenRate − EndForexRate) / CustomerChosenRate)` × sign of SlippageInDollar (NULL when CustomerChosenRate ≤ 0)

**ClientViewRate** is the price the client saw in the UI at request time. **CustomerChosenRate** is the rate at which the client's order was accepted (trigger rate for pending orders). The difference between these and the actual execution rate (`EndForexRate`) is the slippage.

**OverThreshold = 1** when `ABS(slippage%) ≥ 0.5%` — these rows are eligible for best-execution compensation review.

**Sources**: LP execution logs (`CopyFromLake.eToroLogs_Real_Hedge_EMSOrders`) for CBH/HBC routing identification; `DWH_dbo.Dim_Position` for position attributes; `CopyFromLake.PriceLog_History_CurrencyPrice` for price ticks; split ratio adjustments via `DWH_dbo.Dim_HistorySplitRatio`.

**Key business rules**:

- **All actions included** (not just over-threshold) — downstream `SP_Best_Execution` filters for `OverThreshold=1`.
- **DISTINCT insert** prevents duplicate rows from the UNION ALL of open/close paths.
- **Split-adjusted**: AmountInUnitsDecimal and price rates adjusted for corporate actions via `Dim_HistorySplitRatio`.
- **DELETE-INSERT by date**: Idempotent daily reload.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 37 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~498,000,000 |
| **Max date** | **2025-01-11** — pipeline appears decommissioned |
| **OverThreshold distribution** | Large majority OverThreshold=0; OverThreshold=1 rows are the compensation candidates |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date for the slippage event. (Tier 2 -- SP_Slippage_Report, @Start) |
| 2 | PositionID | bigint | YES | Position identifier. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.PositionID) |
| 3 | CID | int | YES | Customer identifier. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.CID) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.InstrumentID) |
| 5 | InstrumentName | varchar(45) | YES | Short instrument name/ticker. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Instrument.Name) |
| 6 | InstrumentTypeID | int | YES | Numeric instrument type (1=FX, 5=Stock, 6=ETF, etc.). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Instrument.InstrumentTypeID) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type string. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Instrument.InstrumentType) |
| 8 | HedgeServerID | int | YES | Hedge server that processed the position. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.HedgeServerID) |
| 9 | MirrorID | int | YES | CopyPortfolio / mirror relationship ID (0 if not mirrored). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.MirrorID) |
| 10 | IsBuy | int | YES | Position side as executed: 1=buy, 0=sell. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.IsBuy) |
| 11 | OrigIsBuy | int | YES | Original requested direction before partial close reversals. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.OrigIsBuy) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | Units executed on the specific action (open or close). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.ExecutionAmountInUnits) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Full position size in units (split-adjusted). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.AmountInUnitsDecimal × SplitRatio) |
| 14 | Occurred | datetime | YES | Timestamp when the position action was executed. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.OpenOccurred / CloseOccurred) |
| 15 | EndForexRate | decimal(16,8) | YES | Actual execution rate received (split-adjusted). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.OpenForexRate / CloseForexRate × SplitRatio) |
| 16 | ConversionRate | decimal(16,8) | YES | FX conversion rate to USD (UnitMargin/InitForexRate for opens). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.ConversionRate) |
| 17 | ActionTypeID | int | YES | Numeric action type from the position log. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.ActionTypeID) |
| 18 | ActionType | varchar(50) | YES | Action type string (Open, Manual Close, Take Profit, Stop Loss, OpenOpen). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position action type) |
| 19 | HedgingMode | varchar(10) | YES | Hedging mode of the position (CBH / HBC / etc.). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.HedgingMode) |
| 20 | Precision | int | YES | Instrument price precision (decimal places). (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Instrument.Precision) |
| 21 | IsOpen | int | YES | 1 if this is an open action, 0 if close. (Tier 2 -- SP_Slippage_Report, derived from ActionType) |
| 22 | ExecutionID | int | YES | LP execution identifier from EMS. (Tier 2 -- SP_Slippage_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ExecutionID) |
| 23 | StopRate | decimal(16,8) | YES | Stop loss rate for the position. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.StopRate) |
| 24 | LimitRate | decimal(16,8) | YES | Take profit (limit) rate for the position. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.LimitRate) |
| 25 | RequestID | bigint | YES | Client request identifier (mapped from EMS ClientRequestID). (Tier 2 -- SP_Slippage_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ClientRequestID) |
| 26 | ClientViewRate | numeric(16,8) | YES | Price shown to the client in the UI at request time. (Tier 2 -- SP_Slippage_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ClientViewRate) |
| 27 | CustomerChosenRate | decimal(16,8) | YES | Rate at which the client's order was accepted (trigger rate for pending orders). (Tier 2 -- SP_Slippage_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.CustomerChosenRate) |
| 28 | SlippageInPips | money | YES | Slippage in instrument pips: (CustomerChosenRate − EndForexRate) / Precision. (Tier 2 -- SP_Slippage_Report, computed) |
| 29 | SlippageInDollar | money | YES | Monetary slippage in USD: SlippageInPips × AmountInUnitsDecimal × ConversionRate. (Tier 2 -- SP_Slippage_Report, computed) |
| 30 | slippage % | decimal(38,21) | YES | Percentage slippage: ABS((CustomerChosenRate − EndForexRate) / CustomerChosenRate), signed by SlippageInDollar. NULL when CustomerChosenRate ≤ 0. (Tier 2 -- SP_Slippage_Report, computed) |
| 31 | UpdateDate | datetime | NOT NULL | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_Slippage_Report, GETDATE()) |
| 32 | RequestTime | datetime | YES | Time of the original client request. (Tier 2 -- SP_Slippage_Report, CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.RequestTime) |
| 33 | OverThreshold | tinyint | YES | 1 if ABS(slippage%) ≥ 0.5%, 0 otherwise — compensation eligibility flag. (Tier 2 -- SP_Slippage_Report, computed) |
| 34 | OpenSession | int | YES | Market session identifier at the time of the action. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.OpenSession) |
| 35 | Volume | int | YES | Trading volume associated with the position action. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.Volume) |
| 36 | Regulation | varchar(50) | YES | Customer regulatory jurisdiction. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Regulation.Name) |
| 37 | IsSettled | tinyint | YES | 1=Real stocks, 0=CFD position. (Tier 2 -- SP_Slippage_Report, DWH_dbo.Dim_Position.IsSettled) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| eToroLogs_Real_Hedge_EMSOrders | CopyFromLake | LP execution log (ClientViewRate, CustomerChosenRate, RequestID, ExecutionID) |
| Dim_Position | DWH_dbo | Position attributes (rates, CID, IsSettled, HedgingMode) |
| Dim_Instrument | DWH_dbo | Instrument metadata (Precision, InstrumentType) |
| Dim_HistorySplitRatio | DWH_dbo | Split ratio adjustments for corporate actions |
| PriceLog_History_CurrencyPrice | CopyFromLake | Historical price ticks for ClientViewRate lookup when NULL |
| Dim_Regulation | DWH_dbo | Regulation name lookup |

### Downstream Tables

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_Best_Execution_Compensation_CBH | Dealing_dbo | Reads OverThreshold=1 rows for CBH compensation |
| Dealing_Best_Execution_Compensation_HBC | Dealing_dbo | Reads OverThreshold=1 rows for HBC compensation |
| Dealing_Daily_Latency_Compensation | Dealing_dbo | SlippageInDollar referenced for latency compensation |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Slippage_Report |
| **Author** | Eden Liberman (2018-04-12); Adar Cahlon (extensive updates 2021–2024) |
| **ETL Pattern** | DELETE WHERE Date=@Start + INSERT DISTINCT |
| **Schedule** | SB_Daily (P20) — **APPEARS DECOMMISSIONED** (last data 2025-01-11) |
| **Parameter** | @Start (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Start` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **⚠️ Outdated data** | Maximum date is 2025-01-11. Do not use for current operational monitoring without confirming SP is active. |
| **OverThreshold filter** | For compensation analysis, filter `OverThreshold=1`. All position actions are included but only threshold-breakers matter for Best Execution. |
| **slippage % sign** | Positive = client got worse rate than chosen, negative = client got better rate. |
| **Large table** | ~498M rows — always filter on `Date` first. |
| **Split adjustments** | AmountInUnitsDecimal and EndForexRate are split-adjusted; compare with care to non-adjusted sources. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / Best Execution |
| **Sub-domain** | Position-level execution slippage |
| **Sensitivity** | Customer identifiers (CID) + position data |
| **Quality Score** | 7.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
