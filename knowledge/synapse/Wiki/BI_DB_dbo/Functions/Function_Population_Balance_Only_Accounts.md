# Function_Population_Balance_Only_Accounts

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 2 (T1: 0, T2: 2) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Identifies customers who had **positive equity** somewhere in the period (trading-platform balances, **eMoney** IBAN USD-adjusted balance, or **options** Apex total equity) but **did not** appear as active traders or portfolio-only users in the same date range. Implements the DDR **“balance only”** cohort.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @sdateInt | INT | Start date (YYYYMMDD integer format) |
| @edateInt | INT | End date (YYYYMMDD integer format) |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo |
| eMoneyClientBalance | eMoney_dbo |
| External_Sodreconciliation_apex_EXT981_BuyPowerSummary | BI_DB_dbo |
| External_USABroker_Apex_Options | BI_DB_dbo |
| Dim_Customer | DWH_dbo |
| Function_Population_Active_Traders | BI_DB_dbo |
| Function_Population_Portfolio_Only | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | BI_DB_Client_Balance_CID_Level_New.CID, eMoneyClientBalance.CID, Dim_Customer.RealCID | `COALESCE(tp.RealCID, em.CID, mo.RealCID)` after `FULL OUTER JOIN` of per-source maxima | T2 |
| 2 | MaxAnyEquity | BI_DB_Client_Balance_CID_Level_New, eMoneyClientBalance, External_Sodreconciliation_apex_EXT981_BuyPowerSummary | `ISNULL(eMoneyMaxEquity,0) + ISNULL(TPMaxEquity,0) + ISNULL(TotalEquity,0)` **WHERE** each leg > 0 in its prep CTE; **outer** `RealCID` kept only if sum **> 0** **AND** `RealCID NOT IN` (**`Function_Population_Active_Traders`** ∪ **`Function_Population_Portfolio_Only`**) for same `[@sdateInt,@edateInt]` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-10-22 | Guy M | Options AUM note (single-date function limitation) |
| 2025-11-21 | Guy M | Fixed rare duplication from multi full outer join (options + IBAN) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
