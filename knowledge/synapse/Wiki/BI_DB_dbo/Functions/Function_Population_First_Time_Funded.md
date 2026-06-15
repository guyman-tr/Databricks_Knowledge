# Function_Population_First_Time_Funded

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 18 (T1: 2, T2: 16) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

For **depositors** with a warehouse **FTD** (excluding a curated “bad FTD” set), joins **first verified** snapshot range and left-joins **first trade**, **first IOB** (interest-on-balance), and **first options trade**. Computes a single **FirstFundedDateID/Date** as the latest of FTD, verification, and the earliest qualifying trading/options/IOB activity.

## 2. Parameters

No parameters.

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Dim_Customer | DWH_dbo |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo |
| Dim_FTDPlatform | DWH_dbo |
| Fact_SnapshotCustomer | DWH_dbo |
| Dim_Range | DWH_dbo |
| Dim_Position | DWH_dbo |
| Function_Revenue_OptionsPlatform | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Dim_Customer.RealCID | Direct (via `DWH_FTD`) | T1 |
| 2 | FTDPlatformID | Dim_Customer.FTDPlatformID | Platform/account type of the first deposit (AccountTypeId from source). Added 2025-09-12. (Tier 2 — SP_Dim_Customer) (via Dim_Customer) | T2 |
| 3 | FTDPlatform | Dim_FTDPlatform.FTDPlatformName | `COALESCE(FTDPlatformName, 'TP')` | T3 |
| 4 | FTDDateID | Dim_Customer.FirstDepositDate | `CAST(CONVERT(VARCHAR(8), FirstDepositDate, 112) AS INT)` | T2 |
| 5 | FTDDate | Dim_Customer.FirstDepositDate | `CAST(FirstDepositDate AS DATE)` | T2 |
| 6 | FTDTime | Dim_Customer.FirstDepositDate | Same timestamp as FTD column (first deposit) | T2 |
| 7 | FirstTradeDateID | Dim_Position.OpenDateID | `MIN(OpenDateID)` **WHERE** `ISNULL(IsAirDrop,0) = 0`, grouped by `CID AS RealCID` | T2 |
| 8 | FirstTradeDate | Dim_Position.OpenDateID | `CONVERT(DATE, CONVERT(VARCHAR(8), MIN(OpenDateID)), 112)` under same **non-airdrop** position filter as row 7 | T2 |
| 9 | FirstTradeTime | Dim_Position.OpenOccurred | `MIN(OpenOccurred)` under same **non-airdrop** position filter as row 7 | T2 |
| 10 | FirstIOBDateID | Fact_CustomerAction.Occurred | `MIN(CAST(FORMAT(CAST(Occurred AS DATE), 'yyyyMMdd') AS INT))` where `ActionTypeID = 36` and `CompensationReasonID = 57` | T2 |
| 11 | FirstIOBDate | Fact_CustomerAction.Occurred | `CAST(MIN(Occurred) AS DATE)` | T2 |
| 12 | FirstIOBTime | Fact_CustomerAction.Occurred | `MIN(Occurred)` | T2 |
| 13 | FirstOptionsTradeDateID | Function_Revenue_OptionsPlatform.FirstTradeDateID | `MIN(FirstTradeDateID)` by `RealCID` | T2 |
| 14 | FirstOptionsTradeDate | Function_Revenue_OptionsPlatform.FirstTradeDate | `MIN(FirstTradeDate)` | T2 |
| 15 | FirstVerifiedDateID | Dim_Range.FromDateID | `MIN(FromDateID)` where `VerificationLevelID = 3` on snapshot | T2 |
| 16 | FirstVerifiedDate | Dim_Range.FromDateID | `CONVERT(DATE, CONVERT(VARCHAR(8), MIN(FromDateID)), 112)` | T2 |
| 17 | FirstFundedDateID | Dim_Customer, Dim_Range, Dim_Position, Fact_CustomerAction, Function_Revenue_OptionsPlatform | `GREATEST(FTDDateID, FirstVerifiedDateID, COALESCE(LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID), COALESCE(...)))` | T2 |
| 18 | FirstFundedDate | *(same as row 17)* | `CONVERT(DATE, CONVERT(VARCHAR(8), FirstFundedDateID), 112)` | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-08-20 | Guy M | IOB alternative; removed false FTDs |
| 2025-09-30 | Guy M | IOB logic fix (trade after IOB) |
| 2025-10-16 | Guy M | Options trade; null handling |
| 2025-11-23 | Guy M | Bad FTD removal without harming legitimate later FTDs |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
