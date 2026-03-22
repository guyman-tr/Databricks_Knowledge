# Function_Population_Funded

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

On a single **`@dateInt`**, returns customers who are **past their first-funded date** per `Function_Population_First_Time_Funded` **and** have **positive combined equity** that day from **trading-platform balances**, **eMoney** settled balance, or **options** AUM (valid customers only on options leg). Prevents “funded” without an actual deposit/funded milestone.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @dateInt | INT | Date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Function_Population_First_Time_Funded | BI_DB_dbo |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo |
| eMoneyClientBalance | eMoney_dbo |
| Function_AUM_OptionsPlatform | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | BI_DB_Client_Balance_CID_Level_New.DateID, eMoneyClientBalance.BalanceDateID, Function_AUM_OptionsPlatform.DateID | All legs **`= @dateInt`**; outer `GROUP BY DateID, RealCID` | T2 |
| 2 | RealCID | BI_DB_Client_Balance_CID_Level_New.CID, eMoneyClientBalance.CID, Function_AUM_OptionsPlatform.RealCID | `CID AS RealCID` / direct from options TVF; **inner join** to **`Function_Population_First_Time_Funded`** on **`RealCID`** with **`FirstFundedDateID <= DateID`** | T2 |
| 3 | Equity | BI_DB_Client_Balance_CID_Level_New, eMoneyClientBalance, Function_AUM_OptionsPlatform | `SUM(Equity)` over union: **(1)** `SUM(ISNULL(TotalLiability,0)+ISNULL(actualNWA,0))` per CID **WHERE** `DateID = @dateInt`; **(2)** `ClosingBalanceBO * USDApproxRate` **WHERE** `BalanceDateID = @dateInt` **AND** `ClosingBalanceCalc > 0`; **(3)** `OptionsTotalEquity` from **`Function_AUM_OptionsPlatform(@dateInt, 1)`** **WHERE** `DateID = @dateInt` **AND** `OptionsTotalEquity > 0`. **Kept only if** joined first-funded row exists **and** aggregated **`Equity > 0`** | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-08-03 | Guy M | Fix: bonus users without deposit no longer counted funded |
| 2025-11-05 | Guy M | IBAN and options equity refresh |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
