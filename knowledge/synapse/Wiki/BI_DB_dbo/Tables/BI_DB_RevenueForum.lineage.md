# BI_DB_dbo.BI_DB_RevenueForum — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_DDR_Customer_Daily_Status | BI_DB_dbo | Customer dimension state per day (funded status, FTD, deposits, validity) |
| BI_DB_DDR_Fact_Revenue_Generating_Actions | BI_DB_dbo | Revenue events by CID/instrument/action type |
| BI_DB_DDR_Fact_MIMO_AllPlatforms | BI_DB_dbo | Deposit/withdraw transactions |
| BI_DB_DDR_Fact_AUM | BI_DB_dbo | Daily equity (AUA/AUM) per CID |
| External_Fivetran_gsheet_costfinance | BI_DB_dbo | Marketing cost per region (Google Sheet via Fivetran) |
| Dim_Country | DWH_dbo | Country name + MarketingRegionManualName (dim lookup) |
| Dim_PlayerLevel | DWH_dbo | Club tier name (dim lookup) |
| Dim_Regulation | DWH_dbo | Regulation name (dim lookup) |
| Dim_Customer | DWH_dbo | Fake FTD exclusion filter |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| FirstDayOfMonth | BI_DB_DDR_Customer_Daily_Status | Date | DATEFROMPARTS(YEAR, MONTH, 1) — first of run month |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough (JOIN on CountryID) |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Dim-lookup passthrough (JOIN on CountryID) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough (JOIN on PlayerLevelID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough (JOIN on RegulationID) |
| Funded | BI_DB_DDR_Customer_Daily_Status | IsFunded | COUNT DISTINCT CIDs WHERE IsFunded=1 |
| ClubMember | BI_DB_DDR_Customer_Daily_Status | IsDepositor | COUNT DISTINCT CIDs WHERE IsDepositor=1 |
| FTD | BI_DB_DDR_Customer_Daily_Status | Global_FTD_Date | COUNT CIDs WHERE FTD month = current month |
| FTDA | BI_DB_DDR_Customer_Daily_Status | Global_FTDA | SUM of FTDA for FTD-month customers |
| Churn | BI_DB_DDR_Customer_Daily_Status | IsFunded | COUNT: was funded last month, unfunded this month |
| Cost | External_Fivetran_gsheet_costfinance | cost | SUM by region from Google Sheet (Fivetran sync) |
| AUA | BI_DB_DDR_Fact_AUM | EquityGlobal | SUM of EquityGlobal for run date |
| TotalRevenue | BI_DB_DDR_Fact_Revenue_Generating_Actions | Amount | SUM WHERE IncludedInTotalRevenue=1, month range |
| ARPU | Computed | TotalRevenue / COUNT DISTINCT CIDs | Revenue per unique customer |
| CIDs_Distinct | BI_DB_DDR_Fact_Revenue_Generating_Actions | RealCID | COUNT DISTINCT revenue-generating CIDs |
| ActiveOpenCFD | BI_DB_DDR_Fact_Revenue_Generating_Actions | RealCID | COUNT DISTINCT WHERE ActionTypeID IN(1,2,3,39) AND IsCopy=0 AND IsSettled=0 |
| ActiveCustomers | BI_DB_DDR_Fact_Revenue_Generating_Actions | RealCID | COUNT DISTINCT WHERE ActionTypeID IN(1,2,3,39) AND IsCopy=0 AND CountAsActiveTrade=1 |
| DepositAmount | BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountUSD | SUM WHERE MIMOAction='Deposit' AND IsInternalTransfer=0 |
| WithdrawAmount | BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountUSD | SUM WHERE MIMOAction='Withdraw' AND IsInternalTransfer=0 |
| WithdrawCount | BI_DB_DDR_Fact_MIMO_AllPlatforms | TransactionID | COUNT WHERE MIMOAction='Withdraw' |
| WithdrawCIDs_Distinct | BI_DB_DDR_Fact_MIMO_AllPlatforms | RealCID | COUNT DISTINCT WHERE MIMOAction='Withdraw' |
| DepositCount | BI_DB_DDR_Fact_MIMO_AllPlatforms | TransactionID | COUNT WHERE MIMOAction='Deposit' |
| DepositCIDs_Distinct | BI_DB_DDR_Fact_MIMO_AllPlatforms | RealCID | COUNT DISTINCT WHERE MIMOAction='Deposit' |
| CopyAmount | — | — | NOT POPULATED (SP code commented out) |
| ManualAmount | — | — | NOT POPULATED (SP code commented out) |
| RealAmount | — | — | NOT POPULATED (SP code commented out) |
| CFDAmount | — | — | NOT POPULATED (SP code commented out) |
| ForexAmount | — | — | NOT POPULATED (SP code commented out) |
| CommodityAmount | — | — | NOT POPULATED (SP code commented out) |
| IndicesAmount | — | — | NOT POPULATED (SP code commented out) |
| StocksAmount | — | — | NOT POPULATED (SP code commented out) |
| ETFAmount | — | — | NOT POPULATED (SP code commented out) |
| BondsAmount | — | — | NOT POPULATED (SP code commented out) |
| TrustFundsAmount | — | — | NOT POPULATED (SP code commented out) |
| OptionsAmount | — | — | NOT POPULATED (SP code commented out) |
| CryptoAmount | — | — | NOT POPULATED (SP code commented out) |
| UnknownInstrumentAmount | — | — | NOT POPULATED (SP code commented out) |
| UpdateDate | — | GETDATE() | ETL timestamp |

## ETL Pattern

- **SP**: BI_DB_dbo.SP_RevenueForum
- **Schedule**: Daily (SB_Daily, Priority 0)
- **Load**: DELETE WHERE FirstDayOfMonth = @BeginOfMonth, then INSERT aggregated results for the month-to-date
- **Author**: Ofir Chloe Gal (created 2025-09-01)
- **Filters**: IsValidCustomer=1, IsCreditReportValidCB=1, PlayerLevelID<>4 (excludes Internal), excludes fake FTDs from 2025-08-19 to 2025-08-21 with Amount=1
