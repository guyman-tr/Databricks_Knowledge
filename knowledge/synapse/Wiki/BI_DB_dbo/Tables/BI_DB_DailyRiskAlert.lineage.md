# BI_DB_dbo.BI_DB_DailyRiskAlert — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_DailyRiskAlert |
| **Writer SP** | BI_DB_dbo.SP_DailyRiskAlert |
| **Author** | Bar (2024-03-01) |
| **Load Pattern** | Daily TRUNCATE + INSERT |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | ReportTime | SP computation | GETDATE() | ETL timestamp | Tier 2 |
| 2 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (renamed) | Tier 1 |
| 3 | UserName | DWH_dbo.Dim_Customer | UserName | Passthrough | Tier 1 |
| 4 | AUM | general.etoroGeneral_History_GuruCopiers | Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL | SUM via #BI_DB_Guru_Copiers | Tier 2 |
| 5 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough via #vl | Tier 2 |
| 6 | Tier | BI_DB_dbo.BI_DB_DailyPanel_Copy | GuruStatus | Renamed to Tier via #ParentUserName | Tier 2 |
| 7 | Country | DWH_dbo.Dim_Country | Name | JOIN Dim_Customer.CountryID → Dim_Country.Name | Tier 2 |
| 8 | Region | DWH_dbo.Dim_Country | Region | JOIN Dim_Customer.CountryID → Dim_Country.Region | Tier 2 |
| 9 | Manager | DWH_dbo.Dim_Manager | FirstName + LastName | JOIN Dim_Customer.AccountManagerID → Dim_Manager, concatenated | Tier 2 |
| 10 | RiskScore | BI_DB_dbo.DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore | AvgSTD → RiskScore | AvgSTD BETWEEN MinValue AND MaxValue → band score | Tier 2 |
| 11 | RiskScore_prev2 | BI_DB_dbo.DWH_CIDsDailyRisk (prev day) | AvgSTD → RiskScore | Same risk banding for @prevdate | Tier 2 |
| 12 | CopiedBlock | External_etoro_Customer_BlockedCustomerOperations | OperationTypeID | CASE WHEN CID has OperationTypeID=2 THEN 1 ELSE 0 | Tier 2 |
| 13 | Copiers | general.etoroGeneral_History_GuruCopiers | COUNT(*) | Copier count via #BI_DB_Guru_Copiers | Tier 2 |
| 14 | BlockReason | External_etoro_Dictionary_BlockUnBlockReason | Reason | JOIN on BlockReasonID | Tier 2 |
| 15 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |
| 16 | RiskJumpOver3 | SP computation | RiskScore, RiskScore_prev2 | CASE WHEN ABS(RiskScore-RiskScore_prev2) >= 3 THEN 1 | Tier 2 |
| 17 | InactiveLoginner | DWH_dbo.Fact_CustomerAction | ActionTypeID=14 | NOT IN last 30 days login events | Tier 2 |
| 18 | InactiveFeedPoster | BI_DB_dbo.BI_DB_CIDFirstDates | LastPublishedPostDate | CASE WHEN @date > DATEADD(MONTH,6,ISNULL(LastPublishedPostDate,'1900-01-01')) | Tier 2 |
| 19 | InactiveTrader | DWH_dbo.Dim_Position | CloseDateID | NOT IN positions closed/open in last 30 days | Tier 2 |
| 20 | EliteClassificationChange | BI_DB_dbo.BI_DB_DailyPanel_Copy | Classification | Today vs yesterday classification change for Elite/Elite Pro | Tier 2 |
| 21 | Lost10Percent | BI_DB_dbo.DWH_GainDaily | Gain_d | CASE WHEN Gain_d < -0.1 THEN 1 | Tier 2 |
| 22 | HoldsHighLevPosition | DWH_dbo.Dim_Position + Dim_Instrument | Leverage, InstrumentTypeID | Stocks/ETF>=5x, Indices>=10x, FX/Commodities>=20x, open >30 days | Tier 2 |
| 23 | HighLevHoldingDetail | DWH_dbo.Dim_Position + Dim_Instrument | Leverage + InstrumentType | STRING_AGG of "{Leverage}-{InstrumentType}" | Tier 2 |
| 24 | InvestedValueover30 | BI_DB_dbo.BI_DB_PositionPnL | Position_Value / total | CASE WHEN top instrument > 30% of portfolio THEN 1 | Tier 2 |
| 25 | Value_percenet | BI_DB_dbo.BI_DB_PositionPnL + V_Liabilities | Position_Value, Credit | Position_Value / (SUM(Position_Value) + Credit) for top instrument | Tier 2 |
| 26 | MostInvestedInstrument | DWH_dbo.Dim_Instrument | SymbolFull | Top instrument by Value_percenet | Tier 2 |
| 27 | FromClassification | BI_DB_dbo.BI_DB_DailyPanel_Copy (yesterday) | Classification | Previous day classification | Tier 2 |
| 28 | CurrentClassification | BI_DB_dbo.BI_DB_DailyPanel_Copy (today) | Classification | Current day classification | Tier 2 |
| 29 | LastLoggedIn | DWH_dbo.Fact_CustomerAction + BI_DB_CIDFirstDates | LastLogin / LastLoggedIn | ISNULL(LastLogin from FA, LastLoggedIn from CIDFirstDates) | Tier 2 |
| 30 | LastPosOpenDate | BI_DB_dbo.BI_DB_CIDFirstDates | LastPosOpenDate | Passthrough | Tier 2 |
| 31 | LastPublishedPostDate | BI_DB_dbo.BI_DB_CIDFirstDates | LastPublishedPostDate | Passthrough | Tier 2 |
| 32 | DaysAsPI | BI_DB_dbo.BI_DB_DailyPanel_Copy | DaysAsPI | Passthrough via #copydata | Tier 2 |
| 33 | Equity | BI_DB_dbo.BI_DB_DailyPanel_Copy | TotalEquity | Renamed to Equity via #copydata | Tier 2 |
| 34 | ClosedAllPositions | BI_DB_dbo.BI_DB_PositionPnL + V_Liabilities | NbPos, Credit, RealizedEquity | CASE WHEN had >5 positions yesterday AND Credit=RealizedEquity THEN 1 | Tier 2 |
| 35 | BlockedOccurred | External_etoro_Customer_BlockedCustomerOperations | Occurred | MAX(Occurred) for OperationTypeID=2 | Tier 2 |
| 36 | BuyPercent | DWH_dbo.Dim_Position | IsBuy | % of high-lev positions that are Buy (IsBuy=0) | Tier 2 |
| 37 | SellPercent | DWH_dbo.Dim_Position | IsBuy | % of high-lev positions that are Sell (IsBuy=1) | Tier 2 |
| 38 | LastAvgRiskScore | BI_DB_dbo.DWH_CIDsDailyRisk | AvgSTD | AVG(RiskScore) for previous month | Tier 2 |
| 39 | MaxRisckScore2Months | BI_DB_dbo.DWH_CIDsDailyRisk | AvgSTD | MAX(RiskScore) over last 2 months | Tier 2 |
| 40 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN Dim_Customer.PlayerStatusID → Dim_PlayerStatus.Name | Tier 2 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| DWH_dbo.Dim_Customer | Dimension | PI population base (GuruStatusID>=2, IsValidCustomer=1, IsDepositor=1) |
| DWH_dbo.Dim_Country | Dimension | Country name and region |
| DWH_dbo.Dim_Manager | Dimension | Account manager name |
| DWH_dbo.Dim_PlayerStatus | Dimension | Player status name |
| DWH_dbo.V_Liabilities | View | RealizedEquity, Credit |
| DWH_dbo.Dim_Position | Dimension | Active positions, leverage, IsBuy |
| DWH_dbo.Dim_Instrument | Dimension | InstrumentType for leverage thresholds, SymbolFull |
| DWH_dbo.Fact_CustomerAction | Fact | Login events (ActionTypeID=14) |
| BI_DB_dbo.DWH_CIDsDailyRisk | Table | AvgSTD risk volatility data |
| BI_DB_dbo.External_etoro_Internal_RiskScore | External | Risk score banding (AvgSTD → score) |
| BI_DB_dbo.BI_DB_PositionPnL | Table | Position P&L for concentration analysis |
| BI_DB_dbo.BI_DB_DailyPanel_Copy | Table | PI tier (GuruStatus), classification, DaysAsPI, equity |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | Last login, last post, last position open dates |
| BI_DB_dbo.DWH_GainDaily | Table | Daily gain for 10% loss detection |
| general.etoroGeneral_History_GuruCopiers | External | Copy relationship data for AUM and copier count |
| External_etoro_Customer_BlockedCustomerOperations | External | Block events (OperationTypeID=2) |
| External_etoro_Dictionary_BlockUnBlockReason | External | Block reason text |
