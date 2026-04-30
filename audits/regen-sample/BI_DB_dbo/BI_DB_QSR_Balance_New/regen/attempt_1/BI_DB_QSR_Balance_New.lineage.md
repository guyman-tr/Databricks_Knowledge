# Lineage: BI_DB_dbo.BI_DB_QSR_Balance_New

## Source Objects

| Source Object | Schema | Type | Relationship |
|---|---|---|---|
| SP_Q_QSR_New | BI_DB_dbo | Stored Procedure | Writer SP — DELETE+INSERT per quarter |
| V_Liabilities | DWH_dbo | View | Client balance end, liabilities (stock real, crypto real, total stock) |
| Fact_SnapshotCustomer | DWH_dbo | Table | Customer snapshot for regulation, MiFID, player status, country, IsCreditReportValidCB |
| Dim_Range | DWH_dbo | Table | DateRangeID decode for snapshot date matching |
| Dim_Regulation | DWH_dbo | Table | Regulation name lookup |
| Dim_MifidCategorization | DWH_dbo | Table | MiFID category name lookup |
| Dim_PlayerStatus | DWH_dbo | Table | Player status name lookup |
| Dim_Country | DWH_dbo | Table | Country name and abbreviation lookup |
| Fact_CustomerUnrealized_PnL | DWH_dbo | Table | End-of-quarter unrealized PnL (total, crypto real, stocks real) |
| Dim_Position | DWH_dbo | Table | Position-level data for realized PnL aggregation |
| Fact_CustomerAction | DWH_dbo | Table | Rollover fee aggregation (ActionTypeID=35, IsFeeDividend=1) |
| BI_DB_PositionPnL | BI_DB_dbo | Table | Position-level equity for sustainability ratio computation |
| BI_DB_EquitiesWithSustainabilityStamp | BI_DB_dbo | Table | Sustainability stamp lookup for equities |
| Dim_Instrument | DWH_dbo | Table | InstrumentTypeID for asset class classification |
| BI_DB_ECB_RateExtractFromAPI | BI_DB_dbo | Table | ECB EUR/USD exchange rate for quarter-end |

## Column Lineage

| Target Column | Source Object(s) | Source Column(s) | Transform |
|---|---|---|---|
| Quarter | SP_Q_QSR_New | @QuarterStartDate | ETL-computed: YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate) |
| ReportCurrency | SP_Q_QSR_New | — | ETL-computed: literal 'USD' or 'EURO' (rows duplicated for both currencies) |
| Rate | BI_DB_ECB_RateExtractFromAPI | ECBRate | Passthrough — ECB EUR/USD rate for quarter-end date |
| CID | V_Liabilities | CID | Passthrough via #relevantCIDs → #pnlCIDFinal |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE WHEN = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid' (int→varchar) |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerStatusID |
| Country | Dim_Country | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID |
| CountryFormatted | Dim_Country | Name, Abbreviation | CONCAT(Name, ',', Abbreviation) |
| IsEtoroBVI | SP_Q_QSR_New | — | CASE WHEN CID IN (2244852,2283663,2283668) THEN 'eToro Group' WHEN CID IN (5969868,5969870,5969875,5969866) THEN 'eToro Trading Group' ELSE 'RealUser' |
| ClientBalanceEnd | V_Liabilities | Liabilities | ISNULL(Liabilities, 0); EURO rows divided by ECB Rate |
| RealizedPnL | Dim_Position | NetProfit | SUM(NetProfit) for positions closed in quarter; EURO rows divided by ECB Rate |
| UnrealizedEnd | Fact_CustomerUnrealized_PnL | PositionPnL | ISNULL(PositionPnL, 0) at quarter-end DateModified; EURO rows divided by ECB Rate |
| ClientBalanceEndRealCrypto | V_Liabilities | LiabilitiesCryptoReal | ISNULL(LiabilitiesCryptoReal, 0); EURO rows divided by ECB Rate |
| ClientBalanceEnd_CFD | V_Liabilities | Liabilities, LiabilitiesCryptoReal, LiabilitiesStockReal | ISNULL(Liabilities,0) - ISNULL(LiabilitiesCryptoReal,0) - ISNULL(LiabilitiesStockReal,0) |
| RealizedCFD | Dim_Position | NetProfit | QuarterRealizedPnL - QuarterRealizedPnLRealCrypto - QuarterRealizedPnLRealStocks |
| UnrealizedCFDEnd | Fact_CustomerUnrealized_PnL | PositionPnL, PositionPnLStocksReal, PositionPnLCryptoReal | ISNULL(PnL,0) - ISNULL(pnlStocksReal,0) - ISNULL(PnLCryptoReal,0) |
| LiabilitiesStocksSustainable | V_Liabilities, BI_DB_PositionPnL | TotalStockLiabilities, sustainability ratio | TotalStockLiabilities × SustainablesRatio (from BI_DB_PositionPnL equity breakdown) |
| LiabilitiesStocksNonSustainable | V_Liabilities, BI_DB_PositionPnL | TotalStockLiabilities, sustainability ratio | TotalStockLiabilities × NotSustainablesRatio |
| LiabilitiesStocksRealSustainable | V_Liabilities, BI_DB_PositionPnL | LiabilitiesStockReal, sustainability ratio | LiabilitiesStockReal × SustainablesRatio |
| LiabilitiesStocksRealNonSustainable | V_Liabilities, BI_DB_PositionPnL | LiabilitiesStockReal, sustainability ratio | LiabilitiesStockReal × NotSustainablesRatio |
| TotalStockLiabilities | V_Liabilities | TotalStockPositionAmount, StocksPositionPnL | ISNULL(TotalStockPositionAmount,0) + ISNULL(StocksPositionPnL,0) |
| IsZeroBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE WHEN ClientBalanceEnd = 0 OR IS NULL THEN 'ZeroBalanceEndPeriod' ELSE 'NonZeroBalanceEndPeriod' |
| IsNegativeBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE WHEN < 0 THEN 'NegativeBalanceEndPeriod' WHEN > 0 THEN 'PositiveBalanceEndPeriod' ELSE 'ZeroBalanceEndPeriod' |
| HasSustainableEquityEOP | SP_Q_QSR_New | LiabilitiesTotalStockSustainable | CASE WHEN > 0 THEN 'HasSustainableEquity' ELSE 'DoesntHaveSustainableEquity' |
| UpdateDate | SP_Q_QSR_New | — | GETDATE() at INSERT time |
| MifidCategory | Dim_MifidCategorization | Name | Dim-lookup passthrough via Fact_SnapshotCustomer.MifidCategorizationID |
| RealizedPnLRealCrypto | Dim_Position | NetProfit | SUM(NetProfit) WHERE InstrumentTypeID=10 AND IsSettled=1 AND ClosedInPeriod; EURO divided by Rate |
| RealizedPnLRealStocks | Dim_Position | NetProfit | SUM(NetProfit) WHERE InstrumentTypeID IN (5,6) AND IsSettled=1 AND ClosedInPeriod; EURO divided by Rate |
| UnrealizedRealCryptoEnd | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | ISNULL(PnLCryptoReal, 0) at quarter-end; EURO divided by Rate |
| UnrealizedRealCryptoChange | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | Quarter-end PnLCryptoReal minus prior-quarter-end PnLCryptoReal |
| UnrealizedRealStocksEnd | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | ISNULL(pnlStocksReal, 0) at quarter-end; EURO divided by Rate |
| UnrealizedRealStocksChange | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | Quarter-end pnlStocksReal minus prior-quarter-end pnlStocksReal |
| RealizedCFDWithBugPre2021Q2 | Dim_Position | NetProfit | QuarterRealizedPnLRealStocks - QuarterRealizedPnLRealCrypto - QuarterRealizedPnLRealStocks (known bug: subtracts stocks twice) |
| StockMargin | Dim_Position | SettlementTypeID | CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END; added 2025-10 (Markos Ch) |
