# Function_Population_OTD_DateRange

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 3 (T1: 0, T2: 3) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Builds, per customer, the **date range where “one-time depositor” (OTD)** status applies. **Deposit events (TP):** **`Fact_CustomerAction`** grouped by `DateID`, `RealCID` **WHERE** **`ActionTypeID = 7 OR (ActionTypeID = 44 AND IsFTD = 1)`** **AND** **`FundingTypeID <> 33`**. **Deposit events (eMoney):** **`eMoney_Fact_Transaction_Status`** **WHERE** **`TxStatusID = 2`** (settled) **AND** **`TxTypeID IN (7, 14)`**, grouped by `TxStatusModificationDateID`, `CID`. Unioned daily counts are ranked by `DateID`; customers whose **first row** already has **`CountDeposits > 1`** are **excluded**. **ToDateID** logic: if only one deposit day ever → **today’s** `DateID`; if first day had multiple deposits in branch → `MIN(DateID)`; else **second** deposit `DateID` or fallback `MIN(DateID)`.

## 2. Parameters

No parameters.

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| eMoney_Fact_Transaction_Status | eMoney_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID, eMoney_Fact_Transaction_Status.CID | Union of **filtered** deposit-day aggregates (see business meaning); after excluding **multi-deposit-first-day** `RealCID`, `GROUP BY RealCID` in `DATERANGE` | T2 |
| 2 | FromDateID | Fact_CustomerAction.DateID, eMoney_Fact_Transaction_Status.TxStatusModificationDateID | **`MIN(DateID)`** over **`RankedDeposits`** (per-customer deposit timeline after filters) | T2 |
| 3 | ToDateID | Fact_CustomerAction, eMoney_Fact_Transaction_Status | `CASE WHEN MIN(TotalRows)=1 THEN CAST(FORMAT(CAST(GETDATE() AS DATE), 'yyyyMMdd') AS INT) WHEN MIN(CountDeposits)>1 THEN MIN(DateID) ELSE COALESCE(MIN(CASE WHEN RowNum=2 THEN DateID END), MIN(DateID)) END` — encodes **single-depositor-open-ended** vs **multi-on-first-day** vs **second-deposit end** | T2 |

*Supporting CTEs: daily `COUNT` by `DateID` and customer; `ROW_NUMBER` ordered by `DateID`; filter out `RealCID` with `RowNum = 1 AND CountDeposits > 1`.*

## 5. Change History (only if found in SQL comments)

*(No dated entries in change block.)*

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
