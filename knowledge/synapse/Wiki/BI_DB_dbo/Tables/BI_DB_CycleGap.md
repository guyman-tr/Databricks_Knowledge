# BI_DB_dbo.BI_DB_CycleGap

## 1. Overview

Transaction-level **client balance cycle gap** detail. Each row is one reconciled discrepancy tied to either a **withdraw (cashout)** workflow or a **position** open/close mismatch for customers who appear in `DWH_dbo.Util_ResultsLiabilities_Cycle` with a non-zero cycle on the report date. Amounts and statuses explain expected vs. paid/reversed flows; `PrevGap*` columns chain to the prior row for the same logical `ID` (withdraw or position).

**Row grain**: One gap event per `Date` + `CID` + `Type` + `ID` (main insert filters `Gap <> 0.000`; a second INSERT appends manual **Processed** withdraw exceptions from `Fact_BillingWithdraw`).

---

## 2. Business Context

Gaps start from **util cycle results** (`Util_ResultsLiabilities_Cycle` where `AbsCycle != 0` for `@date`). `SP_CycleGap` then:

- Builds **cashout (CO)** gap logic from `Fact_CustomerAction` (request/close/reverse/pay), `etoro_History_WithdrawAction`, and `Fact_BillingWithdraw` for billing vs. history integrity.
- Adds **position** gaps for remaining cycle customers where `Dim_Position` open/close does not align with `Fact_CustomerAction` on the boundary dates.
- Unifies withdraw vs. position rows in `#gaps` with `Type` = `Withdraw` or `Position`, then enriches customer attributes from snapshot dimensions (`#RegulationID`).

**Key business rules**:

- **Withdraw `Gap`**: CASE logic in `#co_gap` (duplicate CIDs, pay-on-date vs. prior, `Cycle` from util); manual append uses `-1 * (Amount_Withdraw + Fee)` from `Fact_BillingWithdraw`.
- **Position `Gap`**: From `#position_gap`; combined with withdraw as `COALESCE(a.Gap, b.Gap * -1)` in `#gaps` (sign convention per 2020-05-17 change history).
- **GapClosed**: `1` when current `Gap` plus the prior gap for the same `ID` sums to zero; else `0`.
- **Main insert filter**: `WHERE a.Gap <> 0.000`.

**Downstream context**: `BI_DB_Daily_CB_Gaps_All` (daily aggregate), `BI_DB_CB_CycleGap_Categorization` (categorized gaps).

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 27 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live data verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-20** against Azure Synapse dedicated pool (ODBC; equivalent to `synapse_sql` MCP `execute_sql_read_only`).

| Check | Result |
|--------|--------|
| **Row count** | 202,404 |
| **`Type` distribution** | `Withdraw` 202,395; `Position` 9 |
| **`COStatusPosType` (top values)** | `Processed Manual` 174,305; `Processed` 20,046; `InProcess` 6,761; `Pending` 765; `Canceled` 252; `Rejected` 191; `Partially Processed` 54; `Reversed` 14; `Partialy Reversed` 6; `ClosedAt00:00` 5; `OpenAt00:00` 4; `Integrity CHECK Billing.Withdraw` 1 |
| **Recent sample (`TOP 5` by `Date` DESC)** | Latest dates show `Processed Manual` withdraw rows with negative `Gap` matching `COPosAmount`; `Country` NULL in sampled rows |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date; SP parameter `@date`. (Tier 2 -SP_CycleGap, @date) |
| 2 | CID | int | YES | Customer real CID. (Tier 2 -SP_CycleGap, #gaps.CID) |
| 3 | Type | varchar(20) | YES | `Withdraw` or `Position`. (Tier 2 -SP_CycleGap, #gaps.Type) |
| 4 | ID | bigint | YES | WithdrawID when Type = Withdraw; PositionID when Type = Position. (Tier 2 -SP_CycleGap, #gaps.ID) |
| 5 | StatusORTypeID | int | YES | Withdraw: `CashoutStatusID`; position: `ActionTypeID` from open/close pattern. (Tier 2 -SP_CycleGap, #gaps.StatusORTypeID) |
| 6 | COStatusPosType | varchar(50) | YES | Withdraw: `Dim_CashoutStatus.Name`, `Integrity CHECK Billing.Withdraw`, or `Processed Manual`; position: `OpenAt00:00` / `ClosedAt00:00`. (Tier 2 -SP_CycleGap, Dim_CashoutStatus.Name / computed CASE) |
| 7 | Occurred | datetime | YES | Withdraw status time or position occurrence. (Tier 2 -SP_CycleGap, #gaps.Occurred) |
| 8 | COPosAmount | money | YES | Requested cashout amount or position notional amount. (Tier 2 -SP_CycleGap, #gaps.COPosAmount) |
| 9 | Payed | money | YES | Total paid toward withdraw (`TotalPayed` in `#gaps`); often NULL for position-only rows. (Tier 2 -SP_CycleGap, #gaps.TotalPayed) |
| 10 | Fee | money | YES | Request commission. (Tier 2 -SP_CycleGap, Fact_CustomerAction.Commission) |
| 11 | Reverse | money | YES | Reversed amount (ActionTypeID 37) per withdraw. (Tier 2 -SP_CycleGap, #reverse.AmountRequest) |
| 12 | Gap | money | YES | Resolved monetary gap. (Tier 2 -SP_CycleGap, #co_gap.Gap / #position_gap.Gap) |
| 13 | GapClosed | bit | YES | 1 if current and prior gap for same `ID` net to zero. (Tier 2 -SP_CycleGap, computed vs. BI_DB_CycleGap history) |
| 14 | PrevGapDate | date | YES | Prior row `Date` for same `ID`. (Tier 2 -SP_CycleGap, BI_DB_CycleGap.Date) |
| 15 | PrevGapAmount | money | YES | Prior `Gap`. (Tier 2 -SP_CycleGap, BI_DB_CycleGap.Gap) |
| 16 | PrevStatusORTypeID | int | YES | Prior `StatusORTypeID` (withdraw chain). (Tier 2 -SP_CycleGap, BI_DB_CycleGap.StatusORTypeID) |
| 17 | PrevCOStatusPosType | varchar(50) | YES | Prior `COStatusPosType`. (Tier 2 -SP_CycleGap, BI_DB_CycleGap.COStatusPosType) |
| 18 | UpdateDate | datetime | YES | Insert time `GETDATE()`. (Tier 3 -SP_CycleGap, GETDATE()) |
| 19 | Regulation | varchar(50) | YES | Regulation name from snapshot. (Tier 2 -SP_CycleGap, Dim_Regulation.Name) |
| 20 | IsGermanBaFin | int | YES | 1 if CID in `V_GermanBaFin` for report date. (Tier 2 -SP_CycleGap, V_GermanBaFin.CID) |
| 21 | IsCreditReportValidCB | int | YES | From customer snapshot. (Tier 2 -SP_CycleGap, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 22 | AccountType | varchar(100) | YES | `Dim_AccountType.Name`. (Tier 2 -SP_CycleGap, Dim_AccountType.Name) |
| 23 | Country | varchar(100) | YES | Intended source `Dim_Country.Name` via `#RegulationID`; SSDT `INSERT` list does not map this column -- often NULL in production. (Tier 2 -SP_CycleGap, Dim_Country.Name) |
| 24 | Label | varchar(100) | YES | `Dim_Label.Name`. (Tier 2 -SP_CycleGap, Dim_Label.Name) |
| 25 | PlayerLevel | varchar(100) | YES | `Dim_PlayerLevel.Name`. (Tier 2 -SP_CycleGap, Dim_PlayerLevel.Name) |
| 26 | PlayerStatus | varchar(100) | YES | `Dim_PlayerStatus.Name`. (Tier 2 -SP_CycleGap, Dim_PlayerStatus.Name) |
| 27 | MifidCategory | varchar(100) | YES | `Dim_MifidCategorization.Name`. (Tier 2 -SP_CycleGap, Dim_MifidCategorization.Name) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|---------------|
| Util_ResultsLiabilities_Cycle | DWH_dbo | Seed CIDs (`#cubegap`, AbsCycle != 0) |
| Fact_CustomerAction | DWH_dbo | Withdraw and position-related actions |
| etoro_History_WithdrawAction | dbo | Withdraw status timeline |
| Fact_BillingWithdraw | DWH_dbo | Billing vs. history mismatch (`#incorrect_status`, `#popToUpdate`) |
| Dim_Position | DWH_dbo | Open/close for position-gap branch |
| Dim_CashoutStatus | DWH_dbo | Status labels |
| Fact_SnapshotCustomer | DWH_dbo | Snapshot + regulation join |
| Dim_Range, Dim_Date | DWH_dbo | As-of resolution |
| Dim_Regulation, Dim_Country, Dim_Label, Dim_PlayerLevel, Dim_PlayerStatus, Dim_MifidCategorization, Dim_AccountType | DWH_dbo | `#RegulationID` |
| V_GermanBaFin | BI_DB_dbo | `#GermanBafin` |
| BI_DB_CycleGap | BI_DB_dbo | Prior gap for chain |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_CycleGap |
| **Author** | Katy F (2018-03-30); multiple revisions |
| **ETL Pattern** | DELETE `WHERE [Date] = @date`; INSERT (main + manual withdraw rows) |
| **Grain** | One gap event per key per date (non-zero gap on main path) |
| **Schedule** | Daily, Priority 99 -- FinanceReportSPS (OpsDB) |
| **Parameter** | @date (DATE) |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Date** | Clustered index on `Date`. |
| **Type + ID** | Always interpret `ID` together with `Type`. |
| **Chains** | Use `PrevGapDate`, `PrevGapAmount`, `GapClosed`. |
| **Zeros** | Main path filters `Gap <> 0.000`. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Client Money Reconciliation |
| **Sub-domain** | Cycle gap detail |
| **Sensitivity** | CID, balances, withdraw IDs |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
