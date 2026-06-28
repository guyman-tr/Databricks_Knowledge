# Column Lineage: main.bi_output.bi_output_vg_parentcid

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_parentcid` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_parentcid.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_parentcid.json` (rows: 76, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyPanel_Copy.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_output.bi_output_vg_date` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy   ←── primary upstream
  + main.bi_output.bi_output_vg_date   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_parentcid   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.bi_output.bi_output_vg_date` | `DateID` | `join_enriched` | (Tier 1 — DDL + SP_PopulateDimDate) | dd.DateID |
| 2 | `Date` | `main.bi_output.bi_output_vg_date` | `Date` | `join_enriched` | (Tier 1 — DDL) | dd.Date |
| 3 | `WeekNumberYear` | `main.bi_output.bi_output_vg_date` | `WeekNumberYear` | `join_enriched` | (Tier 1 — DDL) | dd.WeekNumberYear |
| 4 | `CalendarYearMonth` | `main.bi_output.bi_output_vg_date` | `CalendarYearMonth` | `join_enriched` | (Tier 2 — live sample) | dd.CalendarYearMonth |
| 5 | `CalendarQuarter` | `main.bi_output.bi_output_vg_date` | `CalendarQuarter` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarQuarter |
| 6 | `CalendarYear` | `main.bi_output.bi_output_vg_date` | `CalendarYear` | `join_enriched` | (Tier 1 — DDL) | dd.CalendarYear |
| 7 | `IsLastDayWeek` | `main.bi_output.bi_output_vg_date` | `IsLastDayWeek` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayWeek |
| 8 | `IsLastDayMonth` | `main.bi_output.bi_output_vg_date` | `IsLastDayMonth` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayMonth |
| 9 | `IsLastDayQuarter` | `main.bi_output.bi_output_vg_date` | `IsLastDayQuarter` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayQuarter |
| 10 | `IsLastDayYear` | `main.bi_output.bi_output_vg_date` | `IsLastDayYear` | `join_enriched` | (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) | dd.IsLastDayYear |
| 11 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `CID` | `rename` | (Tier 2 — Fact_SnapshotCustomer) | cp.CID AS RealCID |
| 12 | `UserName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `UserName` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | cp.UserName |
| 13 | `Gender` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Gender` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | cp.Gender |
| 14 | `Manager` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Manager` | `passthrough` | (Tier 2 — Dim_Manager) | cp.Manager |
| 15 | `Country` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Country` | `passthrough` | (Tier 1 — Dictionary.Country) | cp.Country |
| 16 | `Region` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Region` | `passthrough` | (Tier 1 — Ext_Dim_Country) | cp.Region |
| 17 | `Language` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Language` | `passthrough` | (Tier 1 — Dictionary.Language) | cp.Language |
| 18 | `Club` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Club` | `passthrough` | (Tier 1 — Dictionary.PlayerLevel) | cp.Club |
| 19 | `Regulation` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Regulation` | `passthrough` | (Tier 1 — Dictionary.Regulation) | cp.Regulation |
| 20 | `RegisteredReal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `RegisteredReal` | `join_enriched` | (Tier 1 — Customer.CustomerStatic) | dcu.RegisteredReal |
| 21 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dcu.FirstDepositDate |
| 22 | `Seniority` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Seniority` | `passthrough` | (Tier 2 — Dim_Customer) | cp.Seniority |
| 23 | `DaysAsPI` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `DaysAsPI` | `passthrough` | (Tier 2 — Fact_SnapshotCustomer) | cp.DaysAsPI |
| 24 | `CopyType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `CopyType` | `passthrough` | (Tier 2 — Fact_SnapshotCustomer) | cp.CopyType |
| 25 | `PortfolioType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `PortfolioType` | `passthrough` | (Tier 1 — Dictionary.FundType) | cp.PortfolioType |
| 26 | `GuruStatusID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `GuruStatusID` | `passthrough` | (Tier 2 — Fact_SnapshotCustomer) | cp.GuruStatusID |
| 27 | `GuruStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `GuruStatus` | `passthrough` | (Tier 1 — Dictionary.GuruStatus) | cp.GuruStatus |
| 28 | `PreviousGuruStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `PreviousGuruStatus` | `passthrough` | (Tier 2 — Fact_SnapshotCustomer) | cp.PreviousGuruStatus |
| 29 | `TotalDaysInCurrentStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `TotalDaysInCurrentStatus` | `passthrough` | (Tier 2 — Fact_SnapshotCustomer) | cp.TotalDaysInCurrentStatus |
| 30 | `BIO_Len` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `BIO_Len` | `passthrough` | (Tier 2 — External_UserApiDB_dbo_Publications) | cp.BIO_Len |
| 31 | `IsPrivate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `IsPrivate` | `passthrough` | (Tier 2 — Dim_Customer) | cp.IsPrivate |
| 32 | `AllowDisplayFullName` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `AllowDisplayFullName` | `passthrough` | (Tier 2 — External_etoroGeneral_Customer_Settings) | cp.AllowDisplayFullName |
| 33 | `HasAvatar` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `HasAvatar` | `passthrough` | (Tier 2 — Dim_Customer) | cp.HasAvatar |
| 34 | `RiskScore` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `RiskScore` | `passthrough` | (Tier 2 — DWH_CIDsDailyRisk) | cp.RiskScore |
| 35 | `PlayerStatus` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `PlayerStatus` | `passthrough` | (Tier 1 — Dictionary.PlayerStatus) | cp.PlayerStatus |
| 36 | `LastBlockedDate` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `LastBlockedDate` | `passthrough` | (Tier 2 — External_etoro_Customer_BlockedCustomerOperations) | cp.LastBlockedDate |
| 37 | `BlockReason` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `BlockReason` | `passthrough` | (Tier 2 — External_etoro_Dictionary_BlockUnBlockReason) | cp.BlockReason |
| 38 | `CanOpenPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanOpenPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanOpenPosition |
| 39 | `CanClosePosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanClosePosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanClosePosition |
| 40 | `CanEditPosition` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanEditPosition` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanEditPosition |
| 41 | `CanBeCopied` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanBeCopied` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanBeCopied |
| 42 | `CanDeposit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanDeposit` | `join_enriched` | — | pst.CanDeposit |
| 43 | `CanRequestWithdraw` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `CanRequestWithdraw` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatus) | pst.CanRequestWithdraw |
| 44 | `PlayerStatusReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusReasonID` | `join_enriched` | — | fsc.PlayerStatusReasonID |
| 45 | `PlayerStatusReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusReasons) | psr.Name AS PlayerStatusReasonName |
| 46 | `PlayerStatusSubReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `PlayerStatusSubReasonID` | `join_enriched` | — | fsc.PlayerStatusSubReasonID |
| 47 | `PlayerStatusSubReasonName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `PlayerStatusSubReasonName` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerStatusSubReasons) | pssr.PlayerStatusSubReasonName |
| 48 | `TotalEquity` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `TotalEquity` | `passthrough` | (Tier 2 — V_Liabilities) | cp.TotalEquity |
| 49 | `RealizedEquity` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `RealizedEquity` | `passthrough` | (Tier 2 — Fact_SnapshotEquity) | cp.RealizedEquity |
| 50 | `TotalPositionsAmount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `TotalPositionsAmount` | `passthrough` | (Tier 2 — Fact_SnapshotEquity) | cp.TotalPositionsAmount |
| 51 | `PositionPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `PositionPnL` | `passthrough` | (Tier 2 — Fact_CustomerUnrealized_PnL) | cp.PositionPnL |
| 52 | `Credit` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Credit` | `passthrough` | (Tier 2 — Fact_SnapshotEquity via V_Liabilities) | cp.Credit |
| 53 | `NumOfCopiers` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `NumOfCopiers` | `passthrough` | (Tier 2 — etoroGeneral_History_GuruCopiers) | cp.NumOfCopiers |
| 54 | `CopyAUC` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `CopyAUC` | `passthrough` | (Tier 2 — etoroGeneral_History_GuruCopiers) | cp.CopyAUC |
| 55 | `CopyPnL` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `CopyPnL` | `passthrough` | (Tier 2 — etoroGeneral_History_GuruCopiers) | cp.CopyPnL |
| 56 | `MI` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `MI` | `passthrough` | (Tier 2 — Fact_CustomerAction) | cp.MI |
| 57 | `MO` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `MO` | `passthrough` | (Tier 2 — Fact_CustomerAction) | cp.MO |
| 58 | `NetMI` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `NetMI` | `passthrough` | (Tier 2 — Fact_CustomerAction) | cp.NetMI |
| 59 | `Trades` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Trades` | `passthrough` | (Tier 2 — Dim_Position) | cp.Trades |
| 60 | `Top_3_Traded_Instruments` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Top_3_Traded_Instruments` | `passthrough` | (Tier 2 — Dim_Position / Dim_Instrument) | cp.Top_3_Traded_Instruments |
| 61 | `Top3TradedIndustries` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Top3TradedIndustries` | `passthrough` | (Tier 2 — Dim_Position / Dim_Instrument) | cp.Top3TradedIndustries |
| 62 | `Lev_weighted_average` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Lev_weighted_average` | `passthrough` | (Tier 2 — BI_DB_PositionPnL) | cp.Lev_weighted_average |
| 63 | `BuyPercent` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `BuyPercent` | `passthrough` | (Tier 2 — Dim_Position) | cp.BuyPercent |
| 64 | `SellPercent` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `SellPercent` | `passthrough` | (Tier 2 — Dim_Position) | cp.SellPercent |
| 65 | `HoldsHighLevPosition` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `HoldsHighLevPosition` | `passthrough` | (Tier 2 — Dim_Position) | cp.HoldsHighLevPosition |
| 66 | `Classification` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Classification` | `passthrough` | (Tier 2 — Dim_Position) | cp.Classification |
| 67 | `Largest_Asset_Class` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Largest_Asset_Class` | `passthrough` | (Tier 2 — Dim_Position / Dim_Instrument) | cp.Largest_Asset_Class |
| 68 | `AvgerageHoldingTime` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `AvgerageHoldingTime` | `passthrough` | (Tier 2 — Dim_Position / Dim_Mirror) | cp.AvgerageHoldingTime |
| 69 | `TraderType` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `TraderType` | `passthrough` | (Tier 2 — SP_DailyPanel_Copy) | cp.TraderType |
| 70 | `HighLevHoldingDetail` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `HighLevHoldingDetail` | `passthrough` | (Tier 2 — Dim_Position / Dim_Instrument) | cp.HighLevHoldingDetail |
| 71 | `Value_percenet` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Value_percenet` | `passthrough` | (Tier 2 — BI_DB_PositionPnL / V_Liabilities) | cp.Value_percenet |
| 72 | `Last_Day_Performance` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Last_Day_Performance` | `passthrough` | (Tier 2 — DWH_GainDaily) | cp.Last_Day_Performance |
| 73 | `Gain_YTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Gain_YTD` | `passthrough` | (Tier 2 — DWH_GainDaily) | cp.Gain_YTD |
| 74 | `Gain_QTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Gain_QTD` | `passthrough` | (Tier 2 — DWH_GainDaily) | cp.Gain_QTD |
| 75 | `Gain_MTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `Gain_MTD` | `passthrough` | (Tier 2 — DWH_GainDaily) | cp.Gain_MTD |
| 76 | `MonthsSinceFirstOpen` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailypanel_copy` | `MonthsSinceFirstOpen` | `passthrough` | (Tier 2 — Fact_FirstCustomerAction) | cp.MonthsSinceFirstOpen |

## Cross-check vs system.access.column_lineage

- Total target columns: **76**
- OK: **76**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **22**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN bi_output.bi_output_vg_date AS dd ON cp.DateID = dd.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dcu ON cp.CID = dcu.RealCID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fsc.RealCID = cp.CID AND fsc.FromDateID <= cp.DateID AND fsc.ToDateID >= cp.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus AS ast ON fsc.AccountStatusID = ast.AccountStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype AS act ON fsc.AccountTypeID = act.AccountTypeID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus AS pst ON fsc.PlayerStatusID = pst.PlayerStatusID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons AS psr ON fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons AS pssr ON fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
