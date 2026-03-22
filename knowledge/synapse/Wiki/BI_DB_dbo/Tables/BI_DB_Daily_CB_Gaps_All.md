# BI_DB_dbo.BI_DB_Daily_CB_Gaps_All

## 1. Overview

Daily **Client Balance gap detection** table. Each row represents a customer whose daily Client Balance cycle calculation does not match the closing balance -- indicating a reconciliation gap. Only rows where `ABS(Gap) > 0.01` are stored. This is an audit/alerting table for the CMR team.

**Row grain**: One CID per DateID (only customers with material gaps)

---

## 2. Business Context

The "gap" is the difference between a customer's `ClosingBalance` and the sum of all expected transaction components (`CycleCalculation`). A gap means something is unaccounted for in the client balance lifecycle. The CMR team uses this table to investigate and resolve discrepancies.

**Key business rules**:
- **Gap formula**: `ClosingBalance - CycleCalculation`
- **CycleCalculation**: Sum of ~27 individual components from `BI_DB_Client_Balance_CID_Level_New`: OpeningBalance, Deposits, Cashouts, CompensationDeposit, UsedBonus, Compensation, NWAAdjustment, CompensationPI, CompensationToAffiliate, TransferCoins, CompensationCashouts, CashoutFee, TransferCoinFees, Chargeback, Refund, OvernightFee, ChargebackLoss, OtherNegatives, CompensationDormantFee, ClientBalanceRealizedPnL, UnrealizedPnLChange, LostDebt, Foreclosure, CompensationPnLAdjustments, NetTransfersNWA, NetTransfersLiability, NetTransfersUnrealizedPnL, NegativeRefill.
- **HAVING filter**: `ABS(Gap) > 0.01` -- only material gaps.
- **IsGermanBaFin**: From V_GermanBaFin (LEFT JOIN via #germanbafin temp table).

**Primary source**: `BI_DB_Client_Balance_CID_Level_New` (BI_DB dependency).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 11 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC, CID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID from BI_DB_Client_Balance_CID_Level_New.CID. (Tier 2 -- SP_Daily_CB_Gaps_All, BI_DB_Client_Balance_CID_Level_New.CID) |
| 2 | DateID | int | YES | Date as integer YYYYMMDD. Part of clustered index. From SP @date parameter. (Tier 2 -- SP_Daily_CB_Gaps_All, @date) |
| 3 | Date | date | YES | Calendar date. Converted from DateID: `CONVERT(date, CONVERT(varchar(10), DateID))`. (Tier 2 -- SP_Daily_CB_Gaps_All, computed from DateID) |
| 4 | Regulation | varchar(100) | YES | Regulation name from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. (Tier 2 -- SP_Daily_CB_Gaps_All, Dim_Regulation.Name) |
| 5 | IsCreditReportValidCB | int | YES | Credit report validity flag from Fact_SnapshotCustomer. 1 = valid for CB reporting. (Tier 2 -- SP_Daily_CB_Gaps_All, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 6 | IsGermanBaFin | int | YES | German BaFin indicator. 1 if CID in V_GermanBaFin for this date, 0 otherwise. (Tier 2 -- SP_Daily_CB_Gaps_All, V_GermanBaFin) |
| 7 | PlayerStatus | varchar(100) | YES | Customer status from Dim_PlayerStatus.Name. Values: "Normal", "Blocked", etc. (Tier 2 -- SP_Daily_CB_Gaps_All, Dim_PlayerStatus.Name) |
| 8 | ClosingBalance | money | YES | Actual closing balance from BI_DB_Client_Balance_CID_Level_New. SUM with ISNULL default 0. (Tier 2 -- SP_Daily_CB_Gaps_All, BI_DB_Client_Balance_CID_Level_New.ClosingBalance) |
| 9 | CycleCalculation | money | YES | Expected closing balance = sum of ~27 individual transaction components from BI_DB_Client_Balance_CID_Level_New. (Tier 2 -- SP_Daily_CB_Gaps_All, computed from BI_DB_Client_Balance_CID_Level_New) |
| 10 | Gap | money | YES | Reconciliation gap: `ClosingBalance - CycleCalculation`. Only rows with `ABS(Gap) > 0.01` are stored. Positive = closing balance higher than expected. (Tier 2 -- SP_Daily_CB_Gaps_All, computed) |
| 11 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -- SP_Daily_CB_Gaps_All, GETDATE()) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo | Primary -- all balance components and closing balance |
| Fact_SnapshotCustomer | DWH_dbo | Customer classification (regulation, credit report validity) |
| Dim_Range | DWH_dbo | Date range resolution |
| Dim_Regulation | DWH_dbo | Regulation name |
| V_GermanBaFin | BI_DB_dbo | German BaFin indicator |
| Dim_PlayerStatus | DWH_dbo | Player status name |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Daily_CB_Gaps_All |
| **Author** | Guy Manova (2021-03-25) |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | One row per CID per DateID (gaps only) |
| **Schedule** | Daily (SB_Daily, Priority 99 -- FinanceReportSPS) |
| **Parameter** | @date (DATE) |
| **Delete Scope** | `DELETE WHERE DateID = @dateID` |
| **Population Filter** | `HAVING ABS(Gap) > 0.01` |
| **Architecture** | Single SELECT/INSERT with #germanbafin temp table for BaFin lookup |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID + CID** | Composite clustered index. |
| **Only gaps stored** | This table only contains customers with material gaps (> $0.01). No-gap customers are absent. |
| **BI_DB_Client_Balance_CID_Level_New dependency** | Must run after SP_Client_Balance_New for accurate data. |
| **Gap sign** | Positive Gap = closing balance exceeds cycle calculation; negative = shortfall. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Client Money Reconciliation |
| **Sub-domain** | Client Balance Gap Detection |
| **Sensitivity** | Contains CID, financial balances -- PII-adjacent |
| **Owner** | Finance / CMR team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 4, Object #4*
*Phases: P1, P2, P8, P9 | Skipped: P3-P7, P9B, P10, P10.5*
