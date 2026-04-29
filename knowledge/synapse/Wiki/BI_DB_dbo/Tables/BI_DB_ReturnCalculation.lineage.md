# BI_DB_dbo.BI_DB_ReturnCalculation — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_ReturnCalculation` — daily TRUNCATE+INSERT (Phase 2: full refresh)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | BI_DB_dbo | Aggregated daily NetProfit, RealizedEquity, Revenue per CID |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Open position PnL for mark-to-market adjustment |
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Population (IsValidCustomer=1, IsDepositor=1, PlayerLevelID<>4) + IsCreditReportValidCB |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name |
| DWH_dbo.Dim_Country | DWH_dbo | Country name |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Club tier name |
| DWH_dbo.Dim_Customer | DWH_dbo | RegisteredReal, FirstDepositDate |
| BI_DB_dbo.BI_DB_CID_DailyCluster | BI_DB_dbo | ClusterDetail (date-bounded) |
| BI_DB_dbo.BI_DB_LTV_Predictions | BI_DB_dbo | LTV_8Y_VolFix |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | Q9_AnswerText (risk appetite) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| ReportDate | (parameter) | @Date | passthrough |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | RegulationName | dim-lookup |
| Country | DWH_dbo.Dim_Country | CountryName | dim-lookup |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | PlayerLevelName | dim-lookup |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | date-bounded lookup |
| LTV | BI_DB_dbo.BI_DB_LTV_Predictions | LTV_8Y_VolFix | passthrough |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | passthrough |
| RiskApetite | BI_DB_dbo.BI_DB_KYC_Panel | Q9_AnswerText | passthrough; ISNULL → 'N/A' |
| Return_Last30Days | (computed) | — | NetProfitPnL_Last30Days / NULLIF(AverageRealizedEquity_Last30Days, 0), ISNULL → 0 |
| Return_YearToDate | (computed) | — | NetProfitPnL_YearToDate / NULLIF(AverageRealizedEquity_YearToDate, 0), ISNULL → 0 |
| Return_Last12Months | (computed) | — | NetProfitPnL_Last12Months / NULLIF(AverageRealizedEquity_Last12Months, 0), ISNULL → 0 |
| Return_Last24Months | (computed) | — | NetProfitPnL_Last24Months / NULLIF(AverageRealizedEquity_Last24Months, 0), ISNULL → 0 |
| Return_Lifetime | (computed) | — | NetProfitPnL_Lifetime / NULLIF(AverageRealizedEquity_Lifetime, 0), ISNULL → 0 |
| TotalRevenue_Last30Days | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Revenue | SUM where DateID in last 30 days |
| TotalRevenue_YearToDate | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Revenue | SUM where DateID in YTD |
| TotalRevenue_Last12Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Revenue | SUM where DateID in last 12 months |
| TotalRevenue_Last24Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Revenue | SUM where DateID in last 24 months |
| TotalRevenue_Lifetime | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Revenue | SUM all dates |
| NetProfitPnL_Last30Days | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_PositionPnL | NetProfit + PnL | SUM(NetProfit in window) + open PnL |
| NetProfitPnL_YearToDate | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_PositionPnL | NetProfit + PnL | SUM(NetProfit in window) + open PnL |
| NetProfitPnL_Last12Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_PositionPnL | NetProfit + PnL | SUM(NetProfit in window) + open PnL |
| NetProfitPnL_Last24Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_PositionPnL | NetProfit + PnL | SUM(NetProfit in window) + open PnL |
| NetProfitPnL_Lifetime | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data + BI_DB_PositionPnL | NetProfit + PnL | SUM(NetProfit in window) + open PnL |
| AverageRealizedEquity_Last30Days | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | RealizedEquity | AVG excluding IsZeroRealizedEquity=1 and IsNegativeRealizedEquity=1 rows, last 30 days |
| AverageRealizedEquity_YearToDate | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | RealizedEquity | AVG excluding zero/negative, YTD |
| AverageRealizedEquity_Last12Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | RealizedEquity | AVG excluding zero/negative, last 12 months |
| AverageRealizedEquity_Last24Months | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | RealizedEquity | AVG excluding zero/negative, last 24 months |
| AverageRealizedEquity_Lifetime | BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | RealizedEquity | AVG excluding zero/negative, all dates |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
