# BI_DB_dbo.BI_DB_Daily_CreditLine

## 1. Overview

Daily **credit line tracking** per customer. Each row captures a customer's total credit line amount, associated fees, liability ratio, and exceedance status for one day. The table accumulates as a rolling daily snapshot, with each day built from the previous day's data plus new credit line actions.

**Row grain**: One RealCID per DateID

---

## 2. Business Context

Credit lines are leveraged buying power extended to customers. This table tracks each customer's credit line day-over-day, including fee calculations and whether the customer's credit-to-liability ratio has exceeded the 50% threshold.

**Key business rules**:
- **Accumulation via MERGE**: Previous day's snapshot (#snap) is merged with today's credit line actions (#bonus) from `Fact_CustomerAction` (ActionTypeID=9, BonusTypeID=71).
- **Fee lookup**: `MonthlyTableFeeCost` from `BI_DB_CreditLine_Amounts` mapping table. `DailyFee = MonthlyTableFeeCost / DaysInMonth`.
- **CLRatio**: `TotalCLAmount / Liabilities` (from V_Liabilities). Division-by-zero protected.
- **IsExceeded**: 1 when `CLRatio > 0.5`. The 50% threshold triggers risk monitoring.
- **ExceedingDaysCount**: Accumulates from previous day if still exceeded; resets to 0 if ratio drops below 50%.
- **DateReceive / DateDeduct**: Date when credit line was received or deducted (only set on the day of the action).

**Consumed by**: `SP_CID_Daily_NWA` (BI_DB_CID_Daily_NWA), multiple CMR automation SPs.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 13 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC, RealCID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID. Part of clustered index. From previous day's snapshot or new Fact_CustomerAction. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction.RealCID) |
| 2 | Date | date | YES | Calendar date. Set from SP @ds parameter. (Tier 2 -- SP_Daily_CreditLine, @ds) |
| 3 | DateID | int | YES | Date as integer YYYYMMDD. Part of clustered index. (Tier 2 -- SP_Daily_CreditLine, @ds) |
| 4 | TotalCLAmount | decimal(11,2) | YES | Total credit line amount in USD. Carried forward from previous day + any new credit line actions for today. (Tier 2 -- SP_Daily_CreditLine, accumulated) |
| 5 | MonthlyTableFeeCost | decimal(11,2) | YES | Monthly fee based on credit line tier from BI_DB_CreditLine_Amounts lookup. NULL if credit line amount not in tier table. (Tier 2 -- SP_Daily_CreditLine, BI_DB_CreditLine_Amounts.Cost) |
| 6 | DailyFee | decimal(11,2) | YES | Daily fee: `MonthlyTableFeeCost / DAY(EOMONTH(@ds))`. Pro-rated by days in the month. (Tier 2 -- SP_Daily_CreditLine, computed) |
| 7 | Liabilities | decimal(11,2) | YES | Customer's total liabilities from V_Liabilities on this date. Used for CLRatio calculation. (Tier 2 -- SP_Daily_CreditLine, V_Liabilities.Liabilities) |
| 8 | CLRatio | decimal(11,2) | YES | Credit line to liability ratio: `TotalCLAmount / Liabilities`. Division-by-zero protected (denominator defaults to 1). (Tier 2 -- SP_Daily_CreditLine, computed) |
| 9 | IsExceeded | int | YES | Flag: 1 if `CLRatio > 0.5` (credit line exceeds 50% of liabilities). Risk threshold indicator. (Tier 2 -- SP_Daily_CreditLine, computed) |
| 10 | ExceedingDaysCount | int | YES | Consecutive days the credit line has been exceeded. Incremented from previous day if still exceeded, 0 if not. (Tier 2 -- SP_Daily_CreditLine, accumulated) |
| 11 | DateReceive | date | YES | Date the credit line was received. Only set on the day of the credit line action; NULL otherwise. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction) |
| 12 | DateDeduct | date | YES | Date the credit line was deducted. Only set on the day of the deduction action; NULL otherwise. (Tier 2 -- SP_Daily_CreditLine, Fact_CustomerAction) |
| 13 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -- SP_Daily_CreditLine, GETDATE()) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_Daily_CreditLine | BI_DB_dbo | Self -- previous day's snapshot used as base |
| Fact_CustomerAction | DWH_dbo | New credit line actions (ActionTypeID=9, BonusTypeID=71) |
| V_Liabilities | DWH_dbo | Customer liabilities for CLRatio calculation |
| BI_DB_CreditLine_Amounts | BI_DB_dbo | Fee tier lookup table |

### Consumers

| Consumer | Purpose |
|----------|---------|
| SP_CID_Daily_NWA | CreditLine column via LEFT JOIN |
| CMR automation SPs | Credit line reconciliation reports |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Daily_CreditLine |
| **ETL Pattern** | DELETE-INSERT by DateID (with MERGE for accumulation) |
| **Grain** | One row per RealCID per DateID |
| **Schedule** | Daily (SB_Daily, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @ds (DATE) |
| **Delete Scope** | `DELETE WHERE DateID = @dsint` |
| **Self-referencing** | Yes -- reads previous day's data to build today's |
| **Architecture** | #snap (prev day) MERGE #bonus (today's actions), then #lastexceeded, #insert, final INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID + RealCID** | Composite clustered index. |
| **Self-referencing dependency** | Must run sequentially -- today depends on yesterday. |
| **TotalCLAmount = 0** | Customers with zero credit line are present (deducted or never had). Check the fee tier table for valid tiers. |
| **ExceedingDaysCount gaps** | If the SP misses a day, the count resets. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Credit Line Management |
| **Sub-domain** | Daily Credit Line Tracking |
| **Sensitivity** | Contains CID, financial metrics -- PII-adjacent |
| **Owner** | Finance / CMR team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #5*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*
