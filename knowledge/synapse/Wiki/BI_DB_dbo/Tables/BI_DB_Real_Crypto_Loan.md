# BI_DB_dbo.BI_DB_Real_Crypto_Loan

## 1. Overview

Monthly snapshot of **real crypto loan positions** aggregated at the instrument level. Captures x2 leveraged real crypto positions (where half the position value is effectively a loan from the platform). Only runs on the last day of each month.

**Row grain**: One InstrumentID + Regulation per Date (month-end only)

---

## 2. Business Context

When a customer buys real crypto with x2 leverage, they put up 50% and the platform lends the other 50% (the "crypto loan"). This table tracks the aggregate loan exposure by instrument and regulation for finance reconciliation.

**Key business rules**:
- **Month-end only**: `@IsEndOfMonth = 'Y'` check from Dim_Date. SP does nothing on non-month-end dates.
- **Position filter**: `InstrumentID >= 100000` (crypto), `IsSettled = 1` (real), `Leverage = 2` (x2 leveraged).
- **Customer filter**: `IsCreditReportValidCB = 1 AND PlayerLevelID <> 4` (valid, non-internal customers).
- **InitialUnits / CurrentUnits**: From Dim_Position.InitialUnits and BI_DB_PositionPnL.AmountInUnitsDecimal.
- **InitialAmountCryptoLoan**: `Dim_Position.InitialAmountCents / 100` -- the original loan amount.
- **CurrentAmountCryptoLoan**: `BI_DB_PositionPnL.Amount` -- current position value (market-adjusted).

**BI_DB_PositionPnL dependency**: Primary source for current position state.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 11 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Month-end date. Clustered index. Only populated on last day of month. (Tier 2 -SP_Real_Crypto_Loans, @date) |
| 2 | InstrumentID | int | YES | Crypto instrument ID from BI_DB_PositionPnL. Values: 100017 (ADA), 100028 (ZEC), etc. (Tier 2 -SP_Real_Crypto_Loans, BI_DB_PositionPnL.InstrumentID) |
| 3 | Instrument | varchar(100) | YES | Instrument name from Dim_Instrument.Name. Values: "ADA/USD", "ZEC/USD", etc. (Tier 2 -SP_Real_Crypto_Loans, Dim_Instrument.Name) |
| 4 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. This table is real-loan only (value is always 1). (Tier 5 — Expert Review) |
| 5 | Leverage | int | YES | Always 2 (x2 leveraged). Filter condition, not variable. (Tier 2 -SP_Real_Crypto_Loans, BI_DB_PositionPnL.Leverage) |
| 6 | InitialUnits | money | YES | Total initial crypto units at position opening. SUM from Dim_Position.InitialUnits. (Tier 2 -SP_Real_Crypto_Loans, Dim_Position.InitialUnits) |
| 7 | CurrentUnits | money | YES | Current crypto units (may change due to fees/adjustments). SUM from BI_DB_PositionPnL.AmountInUnitsDecimal. (Tier 2 -SP_Real_Crypto_Loans, BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 8 | InitialAmountCryptoLoan | money | YES | Original loan amount in USD. SUM(InitialAmountCents/100) from Dim_Position. (Tier 2 -SP_Real_Crypto_Loans, Dim_Position.InitialAmountCents) |
| 9 | CurrentAmountCryptoLoan | money | YES | Current position value in USD (market-adjusted). SUM from BI_DB_PositionPnL.Amount. (Tier 2 -SP_Real_Crypto_Loans, BI_DB_PositionPnL.Amount) |
| 10 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -SP_Real_Crypto_Loans, GETDATE()) |
| 11 | Regulation | varchar(20) | YES | Regulation name from Dim_Regulation.Name. Added Oct 2021. (Tier 2 -SP_Real_Crypto_Loans, Dim_Regulation.Name) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary -- current position data (units, amount, instrument) |
| Dim_Position | DWH_dbo | Initial position data (InitialUnits, InitialAmountCents) |
| Dim_Instrument | DWH_dbo | Instrument name, crypto filter (InstrumentTypeID=10) |
| Fact_SnapshotCustomer | DWH_dbo | Customer validity + regulation |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Date | DWH_dbo | IsLastDayOfMonth check |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Real_Crypto_Loans |
| **Author** | Guy Manova (2021-10-01) |
| **ETL Pattern** | DELETE-INSERT by Date (month-end only) |
| **Grain** | InstrumentID + Regulation per Date |
| **Schedule** | Daily (SB_Daily, Priority 99) but only executes on last day of month |
| **Parameter** | @date (DATE) |
| **Conditional** | `IF @IsEndOfMonth = 'Y'` -- skips non-month-end days |
| **Architecture** | #pos (filtered PositionPnL) -> #assetlevel (aggregated with dims) -> INSERT |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Monthly data only** | Only month-end dates have rows. Don't expect daily data. |
| **IsSettled and Leverage constant** | Always 1 and 2 respectively. These are filter conditions, not variable dimensions. |
| **Crypto loan = position value** | CurrentAmountCryptoLoan is the full position value, not just the loan portion. The loan is effectively 50%. |
| **BI_DB_PositionPnL dependency** | Must run after SP_PositionPnL for accurate current values. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Crypto Lending |
| **Sub-domain** | Real Crypto Loan Exposure |
| **Sensitivity** | Instrument-level aggregate -- low PII risk |
| **Owner** | Finance team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #7*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*
