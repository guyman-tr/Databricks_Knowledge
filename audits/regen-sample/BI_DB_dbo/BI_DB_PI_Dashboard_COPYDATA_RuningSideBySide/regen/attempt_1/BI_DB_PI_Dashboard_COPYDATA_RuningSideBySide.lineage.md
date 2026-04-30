# Lineage: BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide

## Source Objects

| Source Object | Schema | Role | Wiki |
|--------------|--------|------|------|
| Dim_Customer | DWH_dbo | PI population, identity columns (RealCID, UserName, FirstName, LastName, CountryID, GuruStatusID, AccountTypeID, FirstDepositDate, IsValidCustomer, PlayerStatusID) | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| Dim_GuruStatus | DWH_dbo | PI tier name lookup (GuruStatusName) | [Dim_GuruStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_GuruStatus.md) |
| Dim_Country | DWH_dbo | Country name, Region, Desk lookup | [Dim_Country.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md) |
| Dim_PlayerStatus | DWH_dbo | Player status lookup (population filter) | [Dim_PlayerStatus.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md) |
| Dim_Position | DWH_dbo | Position data for holding time, asset class, instruments (via BI_DB_PI_Positions) | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| Dim_Instrument | DWH_dbo | Instrument type, symbol, industry lookup | [Dim_Instrument.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| Dim_Mirror | DWH_dbo | Mirror holding time calculation | [Dim_Mirror.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md) |
| DWH_GainDaily | BI_DB_dbo | Daily gain metrics (YTD, QTD, MTD, daily, monthly, yearly) via BI_DB_PI_GainDaily | [DWH_GainDaily.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/DWH_GainDaily.md) |
| V_Dim_Date | DWH_dbo | Day-of-year filter for past years gain snapshot | [V_Dim_Date.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Views/V_Dim_Date.md) |
| BI_DB_PastYearsGain | BI_DB_dbo | Historical yearly gain for average yearly gain calculation | [BI_DB_PastYearsGain.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PastYearsGain.md) |
| BI_DB_CID_WeeklyPanel_FullData | BI_DB_dbo | Weekly trade counts (via BI_DB_PI_WeeklyTrades) | [BI_DB_CID_WeeklyPanel_FullData.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CID_WeeklyPanel_FullData.md) |
| BI_DB_CopyDailyData | BI_DB_dbo | PI_Level, CopyType, Acc_RiskIndex, NumOfCopiers, TotalEquity, CopyAUM | [BI_DB_CopyDailyData.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CopyDailyData.md) |
| BI_DB_DailyCopyRevenue | BI_DB_dbo | Daily copy revenue for past year commission calculation | [BI_DB_DailyCopyRevenue.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DailyCopyRevenue.md) |
| DWH_CIDsDailyRisk | BI_DB_dbo | Daily portfolio risk (AvgSTD) for risk score and monthly risk | [DWH_CIDsDailyRisk.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/DWH_CIDsDailyRisk.md) |
| External_etoro_Internal_RiskScore | BI_DB_dbo | Risk score band mapping (MinValue/MaxValue to RiskScore) | — |
| BI_DB_PI_Positions | BI_DB_dbo | Incremental PI position cache (shadow of Dim_Position for PIs) | — |
| BI_DB_PI_GainDaily | BI_DB_dbo | Incremental PI gain cache (shadow of DWH_GainDaily for PIs) | — |
| BI_DB_PI_WeeklyTrades | BI_DB_dbo | Incremental PI weekly trades cache | — |
| BI_DB_PI_Dashboard | BI_DB_dbo | Prior day's Past_Year_Commission for rolling calculation | — |
| External_etoro_Customer_BlockedCustomerOperations | BI_DB_dbo | Blocked PI detection (OperationTypeID=2) | — |
| etoroGeneral_History_GuruCopiers | general | Active PI copier detection for blocked check | — |

## Column Lineage

| Target Column | Source Table(s) | Source Column(s) | Transform | Tier |
|--------------|----------------|-----------------|-----------|------|
| Date | SP parameter | @yesterday | Passthrough | 2 |
| CID | Dim_Customer | RealCID | Passthrough | 1 |
| UserName | Dim_Customer | UserName | Passthrough (dim-lookup) | 1 |
| Name | Dim_Customer | FirstName, LastName | Concatenation: FirstName + ' ' + LastName | 2 |
| PI_level | Dim_GuruStatus | GuruStatusName | Passthrough (dim-lookup via Dim_Customer.GuruStatusID) | 1 |
| Country | Dim_Country | Name | Passthrough (dim-lookup via Dim_Customer.CountryID) | 1 |
| Region | Dim_Country | Region | Passthrough (dim-lookup via Dim_Customer.CountryID) | 1 |
| Desk | Dim_Country | Desk | Passthrough (dim-lookup via Dim_Customer.CountryID) | 1 |
| PI/CP | Dim_Customer | AccountTypeID | CASE WHEN AccountTypeID=9 THEN 'CopyFund' ELSE 'PI' | 2 |
| Largest_Asset_Class | Dim_Instrument | InstrumentType | ROW_NUMBER by SUM(Amount) DESC per CID, top 1 | 2 |
| Top_3_Traded_Instruments | Dim_Instrument | Symbol | STRING_AGG of top 3 by Amount (all history, manual only) | 2 |
| YTD | DWH_GainDaily | Gain_YTD | Passthrough via BI_DB_PI_GainDaily | 2 |
| MTD | DWH_GainDaily | Gain_MTD | Passthrough via BI_DB_PI_GainDaily | 2 |
| Last_Day_Performance | DWH_GainDaily | Gain_d | Passthrough via BI_DB_PI_GainDaily | 2 |
| Positive_Months_percent | BI_DB_PI_GainDaily | Gain_m | COUNT(months where Gain_m > 0) / COUNT(total months) | 2 |
| Avg_weekly_trades | BI_DB_PI_WeeklyTrades | NewTrades | AVG(NewTrades) WHERE last year | 2 |
| Avgerage_Holding_Time | BI_DB_PI_Positions, Dim_Mirror | OpenOccurred, CloseOccurred | AVG(DATEDIFF(mi, Open, Close)) / 60 / 24, last 2 years, manual + mirrors | 2 |
| Acc_RiskIndex | DWH_CIDsDailyRisk, External_etoro_Internal_RiskScore | AvgSTD | AVG(RiskScore) over last 7 days, RiskScore from band mapping | 2 |
| Highest_AVG_12Months_Risk | DWH_CIDsDailyRisk, External_etoro_Internal_RiskScore | AvgSTD | MAX(monthly AVG(RiskScore)) over last 12 months | 2 |
| AUM | BI_DB_CopyDailyData | CopyAUM | Passthrough from CopyDailyData at @yesterday | 2 |
| Total_Equity | BI_DB_CopyDailyData | TotalEquity | Passthrough from CopyDailyData at @yesterday | 2 |
| Past_Year_Commission | BI_DB_PI_Dashboard, BI_DB_DailyCopyRevenue | Past_Year_Commission, Revenue_Copy | Rolling: prior_365d_commission + yesterday's Revenue_Copy | 2 |
| UpdateDate | SP | GETDATE() | ETL timestamp | 2 |
| Top_3_Traded_Instruments_yesteday | Dim_Instrument | Symbol | STRING_AGG of top 3 by Amount (open positions only) | 2 |
| Avg_Yearly_gain | BI_DB_PastYearsGain, DWH_GainDaily | Gain_y, Gain_YTD | AVG(yearly gains) across all completed years + current YTD | 2 |
| Classification | BI_DB_PI_Positions, Dim_Instrument | Amount, InstrumentTypeID, IsBuy | CASE on asset class percentages of open positions | 2 |
| TraderType | BI_DB_PI_Positions, Dim_Mirror | OpenOccurred, CloseOccurred | CASE on AVG holding time: <3d=Day trader, 3-22d=Swing, 22-94d=Medium, 94+=Long term | 2 |
| IsBlocked | External_etoro_Customer_BlockedCustomerOperations, etoroGeneral_History_GuruCopiers | BlockReasonID, OperationTypeID | 'Yes' if CID in blocked ops with active copiers, else 'No' | 2 |
| Top3TradedIndustries | Dim_Instrument | Industry | STRING_AGG of top 3 industries by Amount (open positions only) | 2 |
| QTD | DWH_GainDaily | Gain_QTD | Passthrough via BI_DB_PI_GainDaily | 2 |
| Last_Month_Performance | DWH_GainDaily | Gain_m | Passthrough via BI_DB_PI_GainDaily | 2 |
| AvgRiskScore_CurrentMonth | DWH_CIDsDailyRisk, External_etoro_Internal_RiskScore | AvgSTD | AVG(RiskScore) for current calendar month | 2 |
