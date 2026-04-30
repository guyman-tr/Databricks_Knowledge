# Lineage: BI_DB_dbo.BI_DB_QSR_Balance_New

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| Fact_SnapshotCustomer | DWH_dbo | Customer attributes at quarter-end (RegulationID, MifidCategorizationID, PlayerStatusID, IsCreditReportValidCB, CountryID) |
| Dim_Range | DWH_dbo | Expands DateRangeID to resolve which snapshot row covers the quarter-end date |
| Dim_Regulation | DWH_dbo | Regulation name lookup (Name column) |
| Dim_MifidCategorization | DWH_dbo | MiFID II classification name lookup (Name column) |
| Dim_PlayerStatus | DWH_dbo | Player status name lookup (Name column) |
| Dim_Country | DWH_dbo | Country name and abbreviation lookup |
| V_Liabilities | DWH_dbo | Quarter-end client balance (Liabilities, LiabilitiesCryptoReal, LiabilitiesStockReal, TotalStockLiabilities, StocksPositionPnL, TotalStockPositionAmount, TotalCryptoPositionAmount, CryptoPositionPnL) |
| Fact_CustomerUnrealized_PnL | DWH_dbo | Unrealized PnL at quarter start and end (PositionPnL, PositionPnLCryptoReal, PositionPnLStocksReal) |
| Dim_Position | DWH_dbo | Closed positions for realized PnL (NetProfit, IsSettled, InstrumentTypeID, SettlementTypeID) |
| BI_DB_PositionPnL | BI_DB_dbo | Open position equity at quarter-end for sustainability ratio calculation |
| BI_DB_EquitiesWithSustainabilityStamp | BI_DB_dbo | Sustainability stamp lookup for equity instruments |
| Dim_Instrument | DWH_dbo | Instrument type classification (InstrumentTypeID) |
| BI_DB_ECB_RateExtractFromAPI | BI_DB_dbo | ECB EUR/USD exchange rate for currency conversion |
| Fact_CustomerAction | DWH_dbo | Rollover fees (ActionTypeID=35, IsFeeDividend=1) — used for volume table only, not balance |

## Column Lineage

| Target Column | Source Object(s) | Source Column(s) | Transform | Tier |
|--------------|-----------------|-----------------|-----------|------|
| Quarter | SP_Q_QSR_New | @sdate parameter | YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate) | Tier 2 |
| ReportCurrency | SP_Q_QSR_New | — | Literal 'USD' or 'EURO' (each row duplicated in both currencies) | Tier 2 |
| Rate | BI_DB_ECB_RateExtractFromAPI | ECBRate | ECB EUR/USD rate for the quarter-end date | Tier 2 |
| CID | V_Liabilities / Fact_SnapshotCustomer | CID / RealCID | Passthrough (customer identifier) | Tier 2 |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE WHEN = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' | Tier 2 |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID | Tier 1 |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerStatusID | Tier 1 |
| Country | Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID | Tier 1 |
| CountryFormatted | Dim_Country | Name + Abbreviation | CONCAT(dc.Name, ',', dc.Abbreviation) | Tier 2 |
| IsEtoroBVI | SP_Q_QSR_New | CID | CASE on hardcoded CID list: eToro Group / eToro Trading Group / RealUser | Tier 2 |
| ClientBalanceEnd | V_Liabilities | Liabilities | ISNULL(Liabilities, 0); divided by ECB rate for EURO rows | Tier 2 |
| RealizedPnL | Dim_Position | NetProfit | SUM(NetProfit) for positions closed in quarter | Tier 2 |
| UnrealizedEnd | Fact_CustomerUnrealized_PnL | PositionPnL | ISNULL(PositionPnL, 0) at quarter-end DateModified | Tier 2 |
| ClientBalanceEndRealCrypto | V_Liabilities | LiabilitiesCryptoReal | ISNULL(LiabilitiesCryptoReal, 0); divided by ECB rate for EURO rows | Tier 2 |
| ClientBalanceEnd_CFD | V_Liabilities | Liabilities, LiabilitiesCryptoReal, LiabilitiesStockReal | Liabilities - LiabilitiesCryptoReal - LiabilitiesStockReal | Tier 2 |
| RealizedCFD | Dim_Position | NetProfit | QuarterRealizedPnL - RealCrypto - RealStocks | Tier 2 |
| UnrealizedCFDEnd | Fact_CustomerUnrealized_PnL | PositionPnL, PositionPnLStocksReal, PositionPnLCryptoReal | PnL - pnlStocksReal - PnLCryptoReal | Tier 2 |
| LiabilitiesStocksSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities, sustainability ratio | TotalStockLiabilities * SustainablesRatio | Tier 2 |
| LiabilitiesStocksNonSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities, sustainability ratio | TotalStockLiabilities * NotSustainablesRatio | Tier 2 |
| LiabilitiesStocksRealSustainable | V_Liabilities + BI_DB_PositionPnL | LiabilitiesStockReal, sustainability ratio | LiabilitiesStockReal * SustainablesRatio | Tier 2 |
| LiabilitiesStocksRealNonSustainable | V_Liabilities + BI_DB_PositionPnL | LiabilitiesStockReal, sustainability ratio | LiabilitiesStockReal * NotSustainablesRatio | Tier 2 |
| TotalStockLiabilities | V_Liabilities | TotalStockPositionAmount, StocksPositionPnL | ISNULL(TotalStockPositionAmount,0) + ISNULL(StocksPositionPnL,0) | Tier 2 |
| IsZeroBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE WHEN ClientBalanceEnd = 0 OR IS NULL THEN 'ZeroBalanceEndPeriod' ELSE 'NonZeroBalanceEndPeriod' | Tier 2 |
| IsNegativeBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE: Negative/Positive/ZeroBalanceEndPeriod | Tier 2 |
| HasSustainableEquityEOP | SP_Q_QSR_New | LiabilitiesTotalStockSustainable | CASE WHEN > 0 THEN 'HasSustainableEquity' ELSE 'DoesntHaveSustainableEquity' | Tier 2 |
| UpdateDate | SP_Q_QSR_New | — | GETDATE() at INSERT time | Tier 2 |
| MifidCategory | Dim_MifidCategorization | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.MifidCategorizationID | Tier 1 |
| RealizedPnLRealCrypto | Dim_Position | NetProfit | SUM(NetProfit) WHERE InstrumentTypeID=10 AND IsSettled=1 for closed positions in quarter | Tier 2 |
| RealizedPnLRealStocks | Dim_Position | NetProfit | SUM(NetProfit) WHERE InstrumentTypeID IN (5,6) AND IsSettled=1 for closed positions in quarter | Tier 2 |
| UnrealizedRealCryptoEnd | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | ISNULL(PositionPnLCryptoReal, 0) at quarter-end | Tier 2 |
| UnrealizedRealCryptoChange | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | Quarter-end minus quarter-start | Tier 2 |
| UnrealizedRealStocksEnd | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | ISNULL(PositionPnLStocksReal, 0) at quarter-end | Tier 2 |
| UnrealizedRealStocksChange | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | Quarter-end minus quarter-start | Tier 2 |
| RealizedCFDWithBugPre2021Q2 | Dim_Position | NetProfit | Pre-2021Q2 bug: QuarterRealizedPnLRealStocks - RealCrypto - RealStocks (subtracts stocks from stocks). Post-2021Q2 corrected in RealizedCFD. | Tier 2 |
| StockMargin | Dim_Position / SP_Q_QSR_New | SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END | Tier 2 |
