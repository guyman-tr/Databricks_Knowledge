# Lineage: BI_DB_dbo.BI_DB_DailyPanel_Copy

## Source Objects

| # | Source Object | Schema | Type | Relationship | Join Condition |
|---|--------------|--------|------|-------------|----------------|
| 1 | Fact_SnapshotCustomer | DWH_dbo | Table | INNER JOIN | sc.RealCID = CID; DateRangeID filtered by @date_int |
| 2 | Dim_Range | DWH_dbo | Table | INNER JOIN | dr.DateRangeID = sc.DateRangeID |
| 3 | Dim_PlayerLevel | DWH_dbo | Table | INNER JOIN | sc.PlayerLevelID = dpl.PlayerLevelID |
| 4 | Dim_Language | DWH_dbo | Table | INNER JOIN | sc.LanguageID = dl.LanguageID |
| 5 | Dim_Country | DWH_dbo | Table | INNER JOIN | sc.CountryID = dc2.CountryID |
| 6 | Dim_Manager | DWH_dbo | Table | INNER JOIN | sc.AccountManagerID = dm.ManagerID |
| 7 | Dim_GuruStatus | DWH_dbo | Table | INNER JOIN | gs.GuruStatusID = sc.GuruStatusID |
| 8 | Dim_Regulation | DWH_dbo | Table | INNER JOIN | sc.RegulationID = reg.ID |
| 9 | Dim_PlayerStatus | DWH_dbo | Table | INNER JOIN | sc.PlayerStatusID = dps.PlayerStatusID |
| 10 | Dim_Customer | DWH_dbo | Table | LEFT JOIN | dc.CID = dc1.RealCID |
| 11 | Dim_Fund | DWH_dbo | Table | LEFT JOIN | tf.FundAccountID = dc.CID AND IsPublic=1 |
| 12 | Dim_FundType | DWH_dbo | Table | LEFT JOIN | dft.FundTypeID = tf.FundType |
| 13 | V_Liabilities | DWH_dbo | View | LEFT JOIN | vl.CID = dc.CID AND vl.DateID = @date_int |
| 14 | Dim_Position | DWH_dbo | Table | LEFT JOIN (via #BI_DB_PI_Positions) | dp.CID = p.CID; MirrorID=0, filtered by dates |
| 15 | Dim_Instrument | DWH_dbo | Table | LEFT JOIN | dp.InstrumentID = di.InstrumentID |
| 16 | Fact_FirstCustomerAction | DWH_dbo | Table | INNER JOIN | fca.RealCID = p.CID; ActionTypeID IN (1,2,17) |
| 17 | DWH_CIDsDailyRisk | BI_DB_dbo | Table | LEFT JOIN | cdr.CID = dc.CID; FullDate = @date |
| 18 | External_etoro_Internal_RiskScore | BI_DB_dbo | Table | LEFT JOIN | AvgSTD BETWEEN MinValue AND MaxValue |
| 19 | Fact_CustomerAction | DWH_dbo | Table | JOIN | ca.MirrorID = dm.MirrorID; ActionTypeID IN (15,16,17,18) |
| 20 | Dim_Mirror | DWH_dbo | Table | JOIN | ca.MirrorID = dm.MirrorID |
| 21 | etoroGeneral_History_GuruCopiers | general | Table | JOIN | p.CID = gc.ParentCID; Timestamp = @datetimeToday |
| 22 | BI_DB_PositionPnL | BI_DB_dbo | Table | JOIN | pp.CID = p.CID; pp.DateID = @date_int |
| 23 | DWH_GainDaily | BI_DB_dbo | Table | JOIN | a.CID = p.CID; Date = @date |
| 24 | External_UserApiDB_dbo_Publications | BI_DB_dbo | Table | JOIN | CID match |
| 25 | External_etoroGeneral_Customer_Settings | BI_DB_dbo | Table | INNER JOIN | aa.CID match; ValidFrom/ValidTo window |
| 26 | External_etoro_History_BlockedCustomerOperations | BI_DB_dbo | Table | JOIN | bco.CID; OperationTypeID=2 |
| 27 | External_etoro_Customer_BlockedCustomerOperations | BI_DB_dbo | Table | JOIN | bco.CID; OperationTypeID=2 |
| 28 | External_etoro_Dictionary_BlockUnBlockReason | BI_DB_dbo | Table | LEFT JOIN | BlockReasonID = ID |
| 29 | Dim_Date | DWH_dbo | Table | JOIN | d.DateKey = dr.FromDateID |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | Date | SP parameter | @date | Passthrough | Tier 2 — SP_DailyPanel_Copy |
| 2 | DateID | SP parameter | @date | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 2 — SP_DailyPanel_Copy |
| 3 | CID | Fact_SnapshotCustomer | RealCID | Passthrough | Tier 2 — Fact_SnapshotCustomer |
| 4 | UserName | Dim_Customer | UserName | Passthrough (dim-lookup) | Tier 1 — Customer.CustomerStatic |
| 5 | Gender | Dim_Customer | Gender | Passthrough (dim-lookup) | Tier 1 — Customer.CustomerStatic |
| 6 | Manager | Dim_Manager | FirstName + ' ' + LastName | Concatenation | Tier 2 — Dim_Manager |
| 7 | Country | Dim_Country | Name | Passthrough (dim-lookup) | Tier 1 — Dictionary.Country |
| 8 | Region | Dim_Country | MarketingRegionManualName | Passthrough (dim-lookup) | Tier 1 — Ext_Dim_Country |
| 9 | Language | Dim_Language | Name | Passthrough (dim-lookup) | Tier 1 — Dictionary.Language |
| 10 | Club | Dim_PlayerLevel | Name | Passthrough (dim-lookup) | Tier 1 — Dictionary.PlayerLevel |
| 11 | Regulation | Dim_Regulation | Name | Passthrough (dim-lookup) | Tier 1 — Dictionary.Regulation |
| 12 | Seniority | Dim_Customer | FirstDepositDate | DATEDIFF(MONTH, FirstDepositDate, ...) | Tier 2 — Dim_Customer |
| 13 | DaysAsPI | Fact_SnapshotCustomer | GuruStatusID >= 2 rows | DATEDIFF(DAY, MIN(FullDate), @date) | Tier 2 — Fact_SnapshotCustomer |
| 14 | CopyType | Fact_SnapshotCustomer | AccountTypeID / GuruStatusID | CASE WHEN AccountTypeID=9 THEN 'Portfolio' / 'PI' / 'RemovedPI' | Tier 2 — Fact_SnapshotCustomer |
| 15 | PortfolioType | Dim_FundType | FundTypeName | Passthrough (dim-lookup via Dim_Fund) | Tier 1 — Dictionary.FundType |
| 16 | GuruStatusID | Fact_SnapshotCustomer | GuruStatusID | Passthrough | Tier 2 — Fact_SnapshotCustomer |
| 17 | GuruStatus | Dim_GuruStatus | GuruStatusName | Passthrough (dim-lookup) | Tier 1 — Dictionary.GuruStatus |
| 18 | PreviousGuruStatus | Fact_SnapshotCustomer | GuruStatusID | ROW_NUMBER partition by CID, filter different status | Tier 2 — Fact_SnapshotCustomer |
| 19 | TotalDaysInCurrentStatus | Fact_SnapshotCustomer | DateRangeID | SUM(DATEDIFF(DAY, FromDate, ToDate/today)) | Tier 2 — Fact_SnapshotCustomer |
| 20 | BIO_Len | External_UserApiDB_dbo_Publications | AboutMe | LEN(AboutMe) | Tier 2 — External_UserApiDB_dbo_Publications |
| 21 | IsPrivate | Dim_Customer | PrivacyPolicyID | CASE WHEN PrivacyPolicyID=2 THEN 0 ELSE 1 | Tier 2 — Dim_Customer |
| 22 | AllowDisplayFullName | External_etoroGeneral_Customer_Settings | AllowDisplayFullName | Passthrough (windowed) | Tier 2 — External_etoroGeneral_Customer_Settings |
| 23 | HasAvatar | Dim_Customer | HasAvatar | Passthrough (dim-lookup) | Tier 2 — Dim_Customer |
| 24 | RiskScore | DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore | AvgSTD -> RiskScore | MAX(RiskScore) via range lookup | Tier 2 — DWH_CIDsDailyRisk |
| 25 | PlayerStatus | Dim_PlayerStatus | Name | Passthrough (dim-lookup) | Tier 1 — Dictionary.PlayerStatus |
| 26 | LastBlockedDate | External_etoro_Customer_BlockedCustomerOperations / History | Occurred / BlockStart | Most recent block date (ROW_NUMBER) | Tier 2 — External_etoro_Customer_BlockedCustomerOperations |
| 27 | BlockReason | External_etoro_Dictionary_BlockUnBlockReason | Reason | Passthrough (lookup) | Tier 2 — External_etoro_Dictionary_BlockUnBlockReason |
| 28 | TotalEquity | V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) | Tier 2 — V_Liabilities |
| 29 | RealizedEquity | V_Liabilities | RealizedEquity | Passthrough | Tier 1 — V_Liabilities (Fact_SnapshotEquity) |
| 30 | TotalPositionsAmount | V_Liabilities | TotalPositionsAmount | Passthrough | Tier 1 — V_Liabilities (Fact_SnapshotEquity) |
| 31 | PositionPnL | V_Liabilities | PositionPnL | Passthrough | Tier 1 — V_Liabilities (Fact_CustomerUnrealized_PnL) |
| 32 | Credit | V_Liabilities | Credit | Passthrough | Tier 1 — V_Liabilities (Fact_SnapshotEquity) |
| 33 | NumOfCopiers | etoroGeneral_History_GuruCopiers | COUNT(CID) | COUNT of copiers (valid depositors only) | Tier 2 — etoroGeneral_History_GuruCopiers |
| 34 | CopyAUC | etoroGeneral_History_GuruCopiers | Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL | SUM of components | Tier 2 — etoroGeneral_History_GuruCopiers |
| 35 | CopyPnL | etoroGeneral_History_GuruCopiers | PnL + DetachedPosInvestment + Dit_PnL | SUM of PnL components | Tier 2 — etoroGeneral_History_GuruCopiers |
| 36 | MI | Fact_CustomerAction + Dim_Mirror | Amount | SUM where ActionTypeID IN (15,17) (mirror-in) | Tier 2 — Fact_CustomerAction |
| 37 | MO | Fact_CustomerAction + Dim_Mirror | Amount | SUM where ActionTypeID IN (16,18) (mirror-out) | Tier 2 — Fact_CustomerAction |
| 38 | NetMI | Fact_CustomerAction + Dim_Mirror | Amount | SUM(-Amount) for all mirror actions | Tier 2 — Fact_CustomerAction |
| 39 | Trades | Dim_Position | PositionID | COUNT of manual positions opened on @date | Tier 2 — Dim_Position |
| 40 | Top_3_Traded_Instruments | Dim_Position + Dim_Instrument | Symbol | STRING_AGG of top 3 by amount | Tier 2 — Dim_Position |
| 41 | Top3TradedIndustries | Dim_Position + Dim_Instrument | Industry | STRING_AGG of top 3 by amount | Tier 2 — Dim_Position |
| 42 | Lev_weighted_average | BI_DB_PositionPnL | Leverage, Amount | SUM(Leverage*Amount)/SUM(Amount) | Tier 2 — BI_DB_PositionPnL |
| 43 | BuyPercent | Dim_Position + Dim_Instrument | IsBuy | Sell % of high-lev positions (>30 day, lev>=5) | Tier 2 — Dim_Position |
| 44 | SellPercent | Dim_Position + Dim_Instrument | IsBuy | 1 - BuyPercent | Tier 2 — Dim_Position |
| 45 | HoldsHighLevPosition | Dim_Position + Dim_Instrument | Leverage, InstrumentTypeID | 1 if any high-lev position held >30 days | Tier 2 — Dim_Position |
| 46 | Classification | Dim_Position | Volume by InstrumentTypeID | CASE on asset-class percentages | Tier 2 — Dim_Position |
| 47 | Largest_Asset_Class | Dim_Position + Dim_Instrument | InstrumentType | Top asset class by total amount | Tier 2 — Dim_Position |
| 48 | AvgerageHoldingTime | Dim_Position + Dim_Mirror | OpenOccurred, CloseOccurred | AVG holding time in days (2yr window) | Tier 2 — Dim_Position / Dim_Mirror |
| 49 | TraderType | Dim_Position + Dim_Mirror | Holding time | CASE: <22 days = 'Short term', else 'Long term' | Tier 2 — SP_DailyPanel_Copy |
| 50 | HighLevHoldingDetail | Dim_Position + Dim_Instrument | Leverage + InstrumentType | STRING_AGG of high-lev instrument types | Tier 2 — Dim_Position |
| 51 | Value_percenet | BI_DB_PositionPnL + V_Liabilities | Position_Value, Total + Credit | ROUND(Position_Value / (Total + Credit), 3) | Tier 2 — BI_DB_PositionPnL |
| 52 | UpdateDate | SP_DailyPanel_Copy | GETDATE() | ETL timestamp | Tier 2 — SP_DailyPanel_Copy |
| 53 | Last_Day_Performance | DWH_GainDaily | Gain_d | ISNULL(Gain_d, 0) | Tier 2 — DWH_GainDaily |
| 54 | Gain_YTD | DWH_GainDaily | Gain_YTD | ISNULL(Gain_YTD, 0) | Tier 2 — DWH_GainDaily |
| 55 | Gain_QTD | DWH_GainDaily | Gain_QTD | ISNULL(Gain_QTD, 0) | Tier 2 — DWH_GainDaily |
| 56 | Gain_MTD | DWH_GainDaily | Gain_MTD | ISNULL(Gain_MTD, 0) | Tier 2 — DWH_GainDaily |
| 57 | MonthsSinceFirstOpen | Fact_FirstCustomerAction | FirstOccurred | DATEDIFF(Month, MIN(FirstOccurred), @date) | Tier 2 — Fact_FirstCustomerAction |
