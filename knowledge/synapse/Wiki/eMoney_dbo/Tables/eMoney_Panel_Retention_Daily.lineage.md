---
object: eMoney_Panel_Retention_Daily
schema: eMoney_dbo
type: Table
lineage_version: 1
generated: "2026-04-20"
---

# Column Lineage — eMoney_Panel_Retention_Daily

## §1 Source Objects

| Alias | Object | Role |
|-------|--------|------|
| PF | eMoney_dbo.eMoney_Panel_FirstDates | Customer first-touch dates; eligibility gate (FMI_Date IS NOT NULL) |
| DA | eMoney_dbo.eMoney_Dim_Account | Account eligibility filter (IsValidETM=1, GCID_Unique_Count=1); multi-account dedup |
| FSC | DWH_dbo.Fact_SnapshotCustomer | Daily customer snapshot; provides ClubID, CountryID, RegulationID dimensions |
| DPL | DWH_dbo.Dim_PlayerLevel | Club tier name and category |
| DC | DWH_dbo.Dim_Country | Country display name |
| FCA | DWH_dbo.Fact_CustomerAction | MIMO transaction amounts and counts (ActionTypeID 7=Deposit, 8=Withdrawal) |
| DR | DWH_dbo.Dim_Range | Date range slicer used in #Pop population build |

## §2 ETL Pattern

- Writer SP: `SP_eMoney_Panel_Retention`
- Pattern: WHILE loop incremental; watermark = `MAX(Report_Date)` in table
- Eligibility: Customers in `eMoney_Panel_FirstDates` WHERE `FMI_Date IS NOT NULL`, joined to `eMoney_Dim_Account` WHERE `IsValidETM=1 AND GCID_Unique_Count=1`
- Multi-account dedup: CIDs with multiple eMoney accounts → earliest FMI_Date kept via `#Duplicate1`/`#Duplicate2` temp tables
- FundingTypeID discriminator: 33 = eMoney, <>33 = Other
- ActionTypeID scope: 7 = Deposit (Deposits sub-window), 8 = Withdrawal (CO sub-window); combined 7+8 = base MIMO
- Time windows: LT=Lifetime (all dates), 3M=trailing 3 months from @ReportDate, Monthly=current calendar month
- Tier thresholds: eMoney_Inactive = 0 eMoney volume/count; Low_Active = eMoney share ≤ 80% of total; High_Active = eMoney share > 80% of total; No_MIMO_3M/Monthly = NULL/zero total in that window

## §3 Column-Level Lineage

| # | Column | Source Object | Source Column / Expression | Tier |
|---|--------|--------------|---------------------------|------|
| 1 | Report_Date | SP loop | @ReportDate loop variable | Tier 2 |
| 2 | Report_Date_ID | SP computed | CONVERT(int, @ReportDate, 112) | Tier 2 |
| 3 | GCID | eMoney_Panel_FirstDates | GCID (via #Pop) | Tier 4 |
| 4 | CID | eMoney_Panel_FirstDates | CID (via #Pop) | Tier 4 |
| 5 | ClubID | DWH_dbo.Dim_PlayerLevel | PlayerLevelID (via FSC.PlayerLevelID JOIN) | Tier 4 |
| 6 | Club | DWH_dbo.Dim_PlayerLevel | DisplayName | Tier 4 |
| 7 | ClubCategory | SP computed | CASE ClubID: 1→NoClub, 3/5→LowClub, 2/6/7→HighClub, 4→Internal | Tier 2 |
| 8 | CountryID | DWH_dbo.Dim_Country | CountryID (via FSC) | Tier 4 |
| 9 | Country | DWH_dbo.Dim_Country | DisplayName | Tier 4 |
| 10 | Seniority_TP_RegDate | eMoney_Panel_FirstDates | DATEDIFF(DAY, TP_Registration_Date, @ReportDate) | Tier 2 |
| 11 | Seniority_TP_FTDDate | eMoney_Panel_FirstDates | DATEDIFF(DAY, TP_FTD_Date, @ReportDate) | Tier 2 |
| 12 | Seniority_eMoney_AccCreatedDate | eMoney_Dim_Account | DATEDIFF(DAY, CurrencyBalanceCreateDate, @ReportDate) | Tier 2 |
| 13 | Seniority_eMoney_FMIDate | eMoney_Panel_FirstDates | DATEDIFF(DAY, FMI_Date, @ReportDate) | Tier 2 |
| 14 | Value_TotalActions_LT | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID IN (7,8), all FundingTypeIDs, all dates | Tier 2 |
| 15 | Value_eMoneyActions_LT | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID IN (7,8), all dates | Tier 2 |
| 16 | Value_OtherActions_LT | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID IN (7,8), all dates | Tier 2 |
| 17 | Value_TotalActions_3M | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID IN (7,8), date in 3M window | Tier 2 |
| 18 | Value_eMoneyActions_3M | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, 3M window | Tier 2 |
| 19 | Value_OtherActions_3M | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, 3M window | Tier 2 |
| 20 | Value_TotalActions_3M_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8 (Withdrawal/CO), all FundingTypeIDs, 3M window | Tier 2 |
| 21 | Value_eMoneyActions_3M_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=8, 3M window | Tier 2 |
| 22 | Value_OtherActions_3M_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=8, 3M window | Tier 2 |
| 23 | Value_TotalActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=7 (Deposit), all FundingTypeIDs, 3M window | Tier 2 |
| 24 | Value_eMoneyActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=7, 3M window | Tier 2 |
| 25 | Value_OtherActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=7, 3M window | Tier 2 |
| 26 | Value_TotalActions_LT_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8, all FundingTypeIDs, all dates | Tier 2 |
| 27 | Value_eMoneyActions_LT_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=8, all dates | Tier 2 |
| 28 | Value_OtherActions_LT_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=8, all dates | Tier 2 |
| 29 | Value_TotalActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=7, all FundingTypeIDs, all dates | Tier 2 |
| 30 | Value_eMoneyActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=7, all dates | Tier 2 |
| 31 | Value_OtherActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=7, all dates | Tier 2 |
| 32 | CNT_TotalActions_LT | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID IN (7,8), all FundingTypeIDs, all dates | Tier 2 |
| 33 | CNT_eMoneyActions_LT | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID IN (7,8), all dates | Tier 2 |
| 34 | CNT_OtherActions_LT | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID IN (7,8), all dates | Tier 2 |
| 35 | CNT_TotalActions_3M | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID IN (7,8), 3M window | Tier 2 |
| 36 | CNT_eMoneyActions_3M | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, 3M window | Tier 2 |
| 37 | CNT_OtherActions_3M | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, 3M window | Tier 2 |
| 38 | CNT_TotalActions_3M_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=8, all FundingTypeIDs, 3M window | Tier 2 |
| 39 | CNT_eMoneyActions_3M_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=8, 3M window | Tier 2 |
| 40 | CNT_OtherActions_3M_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=8, 3M window | Tier 2 |
| 41 | CNT_TotalActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=7, all FundingTypeIDs, 3M window | Tier 2 |
| 42 | CNT_eMoneyActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=7, 3M window | Tier 2 |
| 43 | CNT_OtherActions_3M_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=7, 3M window | Tier 2 |
| 44 | CNT_TotalActions_LT_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=8, all FundingTypeIDs, all dates | Tier 2 |
| 45 | CNT_eMoneyActions_LT_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=8, all dates | Tier 2 |
| 46 | CNT_OtherActions_LT_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=8, all dates | Tier 2 |
| 47 | CNT_TotalActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=7, all FundingTypeIDs, all dates | Tier 2 |
| 48 | CNT_eMoneyActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=7, all dates | Tier 2 |
| 49 | CNT_OtherActions_LT_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=7, all dates | Tier 2 |
| 50 | Amount_Tier_LT | SP computed | CASE: eMoney_Inactive if eMoneyActions_LT=0; Low_Active if eMoney/Total≤0.8; High_Active if >0.8 | Tier 2 |
| 51 | Amount_Tier_3M | SP computed | Same tier logic on 3M window; adds No_MIMO_3M if no actions in 3M window | Tier 2 |
| 52 | TX_Tier_LT | SP computed | Same tier logic as Amount_Tier_LT but on CNT columns | Tier 2 |
| 53 | TX_Tier_3M | SP computed | Same tier logic as Amount_Tier_3M but on CNT columns | Tier 2 |
| 54 | Amount_Tier_LT_Deposits | SP computed | Tier logic on Deposits-only LT subset | Tier 2 |
| 55 | Amount_Tier_3M_Deposits | SP computed | Tier logic on Deposits-only 3M subset | Tier 2 |
| 56 | TX_Tier_LT_Deposits | SP computed | Tier logic (CNT) on Deposits-only LT subset | Tier 2 |
| 57 | TX_Tier_3M_Deposits | SP computed | Tier logic (CNT) on Deposits-only 3M subset | Tier 2 |
| 58 | Amount_Tier_LT_CO | SP computed | Tier logic on CO (Withdrawal) LT subset | Tier 2 |
| 59 | Amount_Tier_3M_CO | SP computed | Tier logic on CO (Withdrawal) 3M subset | Tier 2 |
| 60 | TX_Tier_LT_CO | SP computed | Tier logic (CNT) on CO LT subset | Tier 2 |
| 61 | TX_Tier_3M_CO | SP computed | Tier logic (CNT) on CO 3M subset | Tier 2 |
| 62 | Value_TotalActions_Monthly | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID IN (7,8), current calendar month | Tier 2 |
| 63 | Value_eMoneyActions_Monthly | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, monthly window | Tier 2 |
| 64 | Value_OtherActions_Monthly | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, monthly window | Tier 2 |
| 65 | CNT_TotalActions_Monthly | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID IN (7,8), monthly window | Tier 2 |
| 66 | CNT_eMoneyActions_Monthly | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, monthly window | Tier 2 |
| 67 | CNT_OtherActions_Monthly | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, monthly window | Tier 2 |
| 68 | Value_TotalActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=7, monthly window | Tier 2 |
| 69 | Value_eMoneyActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=7, monthly window | Tier 2 |
| 70 | Value_OtherActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=7, monthly window | Tier 2 |
| 71 | CNT_TotalActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=7, monthly window | Tier 2 |
| 72 | CNT_eMoneyActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=7, monthly window | Tier 2 |
| 73 | CNT_OtherActions_Monthly_Deposits | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=7, monthly window | Tier 2 |
| 74 | Value_TotalActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE ActionTypeID=8, monthly window | Tier 2 |
| 75 | Value_eMoneyActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID=33, ActionTypeID=8, monthly window | Tier 2 |
| 76 | Value_OtherActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | SUM(Amount) WHERE FundingTypeID<>33, ActionTypeID=8, monthly window | Tier 2 |
| 77 | CNT_TotalActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE ActionTypeID=8, monthly window | Tier 2 |
| 78 | CNT_eMoneyActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID=33, ActionTypeID=8, monthly window | Tier 2 |
| 79 | CNT_OtherActions_Monthly_CO | DWH_dbo.Fact_CustomerAction | COUNT(*) WHERE FundingTypeID<>33, ActionTypeID=8, monthly window | Tier 2 |
| 80 | Amount_Tier_Monthly | SP computed | Tier logic on Monthly window; adds No_MIMO_Monthly if no monthly actions | Tier 2 |
| 81 | TX_Tier_Monthly | SP computed | Tier logic (CNT) on Monthly window | Tier 2 |
| 82 | Amount_Tier_Monthly_Deposits | SP computed | Tier logic on Deposits-only Monthly subset | Tier 2 |
| 83 | TX_Tier_Monthly_Deposits | SP computed | Tier logic (CNT) on Deposits-only Monthly subset | Tier 2 |
| 84 | Amount_Tier_Monthly_CO | SP computed | Tier logic on CO Monthly subset | Tier 2 |
| 85 | TX_Tier_Monthly_CO | SP computed | Tier logic (CNT) on CO Monthly subset | Tier 2 |
| 86 | UpdateDate | SP computed | GETDATE() at SP execution time | Tier 2 |

## §4 Tier 1 Coverage Summary

- Tier 1: 0 (expected — pure analytics aggregation; all values are computed or cross-schema)
- Tier 2: 82 columns (SP-computed aggregations, CASE logic, derived metrics)
- Tier 4: 4 columns (GCID, CID, ClubID/Club, CountryID/Country — cross-schema or intra-schema without on-disk upstream wiki)

## §5 UC External Lineage

UC Target: `_Not_Migrated` (eMoney_dbo tables are Synapse-only)
