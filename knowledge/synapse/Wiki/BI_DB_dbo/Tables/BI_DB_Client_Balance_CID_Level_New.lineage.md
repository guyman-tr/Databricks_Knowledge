# Column Lineage: BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` |
| **Primary Source** | Multi-source aggregate (no single production source) |
| **ETL SP** | `BI_DB_dbo.SP_Client_Balance_New` |
| **Secondary Sources** | Fact_SnapshotCustomer, Fact_SnapshotEquity, V_Liabilities, Fact_CustomerAction, 8 Dim tables, V_GermanBaFin |
| **Generated** | 2026-03-20 (rerun) |

## Source Summary

| Source Layer | Table/Object | Role |
|---|---|---|
| Writer SP | BI_DB_dbo.SP_Client_Balance_New | Sole writer. Priority 99 (FinanceReportSPS — runs LAST). Daily DELETE+INSERT per DateID. 9,574 lines of SQL. |
| DWH Fact | DWH_dbo.Fact_SnapshotCustomer | Customer attributes: RegulationID, PlayerStatusID, CountryID, LabelID, PlayerLevelID, MifidCategorizationID, AccountTypeID, IsCreditReportValidCB, IsValidCustomer, DltStatusID, RegionID |
| DWH Fact | DWH_dbo.Fact_SnapshotEquity | Balance/equity metrics: TotalCash, RealizedEquity, InProcessCashouts, TotalPositionsAmount, TotalRealStocks, TotalRealCrypto, etc. |
| DWH Fact | DWH_dbo.Fact_CustomerAction | Cash flow metrics: Deposits (AT=7), Cashouts (AT=8/2), Compensation (AT=36), Chargebacks (AT=11), Refunds (AT=12), Fees (AT=35), etc. |
| DWH View | DWH_dbo.V_Liabilities | Opening/closing balances, NOP, AvailableCash, PositionAmount, liability breakdowns |
| DWH Dim | DWH_dbo.Dim_Regulation | Regulation name from RegulationID. **Wiki: Tier 1 from Dictionary.Regulation** |
| DWH Dim | DWH_dbo.Dim_Country | Country name, Region. **Wiki: Name is Tier 1 from Dictionary.Country; Region is Tier 2** |
| DWH Dim | DWH_dbo.Dim_Label | Label name. **Wiki: Tier 1 from Dictionary.Label** |
| DWH Dim | DWH_dbo.Dim_PlayerStatus | PlayerStatus name. **Wiki: Tier 1 from Dictionary.PlayerStatus** |
| DWH Dim | DWH_dbo.Dim_PlayerLevel | Club name (PlayerLevel). **Wiki: Tier 1 from Dictionary.PlayerLevel** |
| DWH Dim | DWH_dbo.Dim_MifidCategorization | MifidCategory name. **Wiki: Tier 1 from Dictionary.MifidCategorization** |
| DWH Dim | DWH_dbo.Dim_AccountType | AccountType name. **Wiki: Tier 1 from Dictionary.AccountType** |
| DWH Dim | DWH_dbo.Dim_Customer | UserName (for eToro trading group accounts), TanganyStatusID |
| DWH Dim | DWH_dbo.Dim_Range | DateRangeID decode for Fact_SnapshotCustomer SCD |
| DWH Dim | DWH_dbo.Dim_State_and_Province | US state ShortName |
| BI_DB Ext | BI_DB_dbo.External_UserApiDB_Dictionary_TanganyStatus | Tangany wallet status name |
| BI_DB View | BI_DB_dbo.V_GermanBaFin | German BaFin regulatory flag |

## Lineage Chain

```
Production Sources (History.ActiveCredit, Trade.OpenPositionEndOfDay, History.ClosePositionEndOfDay, History.Credit, Billing.Withdraw, etc.)
  → DWH_staging (etoro_* tables)
    → DWH_dbo ETL SPs (SP_Fact_SnapshotEquity, SP_Fact_CustomerAction, SP_Fact_SnapshotCustomer)
      → DWH_dbo Fact/View tables (Fact_SnapshotEquity, Fact_CustomerAction, Fact_SnapshotCustomer, V_Liabilities)
        → SP_Client_Balance_New (aggregation + dimension denormalization + transfer logic)
          → BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from upstream DWH table. |
| **join-enriched** | Joined from a Dim/lookup table during ETL. |
| **ETL-computed** | Derived/calculated by SP_Client_Balance_New. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Upstream Wiki Tier |
|---|---|---|---|---|
| CID | Fact_SnapshotCustomer | RealCID | passthrough | Tier 2 — SP_Fact_SnapshotCustomer |
| TransferDirection | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Regulation | Dim_Regulation | Name | join-enriched | **Tier 1 — Dictionary.Regulation** |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | passthrough | Tier 2 — SP_Fact_SnapshotCustomer |
| DidRegulationTransfer | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| DidCBValidTransfer | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| IsEtoroTradingCID | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| eToroTradingGroupUser | Dim_Customer | UserName | join-enriched | Tier 2 — SP_Dim_Customer |
| IsGlenEagleAccount | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Region | Dim_Country | Region | join-enriched | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| FromRegulation | Dim_Regulation | Name | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ToRegulation | Dim_Regulation | Name | ETL-computed | Tier 2 — SP_Client_Balance_New |
| AccountType | Dim_AccountType | Name | join-enriched | **Tier 1 — Dictionary.AccountType** |
| Label | Dim_Label | Name | join-enriched | **Tier 1 — Dictionary.Label** |
| Country | Dim_Country | Name | join-enriched | **Tier 1 — Dictionary.Country** |
| MifidCategory | Dim_MifidCategorization | Name | join-enriched | **Tier 1 — Dictionary.MifidCategorization** |
| Club | Dim_PlayerLevel | Name | join-enriched | **Tier 1 — Dictionary.PlayerLevel** |
| PlayerStatus | Dim_PlayerStatus | Name | join-enriched | **Tier 1 — Dictionary.PlayerStatus** |
| DateID | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| OpeningBalance | V_Liabilities | ClosingBalance (prev day) | passthrough | Tier 2 — SP_Client_Balance_New |
| Deposits | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationDeposit | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Bonus | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Compensation | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationPI | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationToAffiliate | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NWAAdjustment | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NegativeRefill | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Cashouts | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CashoutsIncludingRedeem | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationCashouts | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CashoutFee | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Chargeback | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Refund | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| OvernightFee | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| LostDebt | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ChargebackLoss | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| OtherNegatives | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Foreclosure | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationPnLAdjustments | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationDormantFee | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceRealizedPnL | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceRealizedPnLCFD | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceRealizedPnLRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceRealizedPnLRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TransferCoins | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TransferCoinFees | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClosingBalance | V_Liabilities | ClosingBalance | passthrough | Tier 2 — SP_Client_Balance_New |
| realizedEquity | Fact_SnapshotEquity | RealizedEquity | passthrough | Tier 2 — SP_Fact_SnapshotEquity |
| RealCryptoOpenBalance | Fact_SnapshotEquity | TotalRealCrypto (prev) | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| RealCryptoClosingBalance | Fact_SnapshotEquity | TotalRealCrypto | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| ClientMoneyOpenBalance | V_Liabilities | ActualNWA (prev) | passthrough | Tier 2 — SP_Client_Balance_New |
| ClientMoneyClosingBalance | V_Liabilities | ActualNWA | passthrough | Tier 2 — SP_Client_Balance_New |
| RealStocksOpeningBalance | Fact_SnapshotEquity | TotalRealStocks (prev) | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| RealStocksClosingBalance | Fact_SnapshotEquity | TotalRealStocks | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| ClientBalanceFullCommission | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommission | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceFullCommissionCFD | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommissionCFD | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceFullCommissionRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommissionRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceFullCommissionRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommissionRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| DividendsPaid | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalLiability | V_Liabilities | Liabilities | passthrough | Tier 2 — SP_Client_Balance_New |
| TotalNegativeLiability | V_Liabilities | Liabilities | ETL-computed | Tier 2 — SP_Client_Balance_New |
| WithdrawableLiability | V_Liabilities | WithdrawableLiability | passthrough | Tier 2 — SP_Client_Balance_New |
| NegativeWithdrawableLiability | V_Liabilities | WithdrawableLiability | ETL-computed | Tier 2 — SP_Client_Balance_New |
| LiabilityInUsedMargin | V_Liabilities | LiabilityInUsedMargin | passthrough | Tier 2 — SP_Client_Balance_New |
| NegativeLiabilityInUsedMargin | V_Liabilities | LiabilityInUsedMargin | ETL-computed | Tier 2 — SP_Client_Balance_New |
| InProcessCashout | Fact_SnapshotEquity | InProcessCashouts | passthrough | Tier 2 — SP_Fact_SnapshotEquity_InProcessCashouts |
| NegativeInProcessCashout | Fact_SnapshotEquity | InProcessCashouts | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NOPCrypto | V_Liabilities | NOPCrypto | passthrough | Tier 2 — SP_Client_Balance_New |
| NOPCryptoCFD | V_Liabilities | NOPCryptoCFD | passthrough | Tier 2 — SP_Client_Balance_New |
| NOPStocks | V_Liabilities | NOPStocks | passthrough | Tier 2 — SP_Client_Balance_New |
| NOPStocksCFD | V_Liabilities | NOPStocksCFD | passthrough | Tier 2 — SP_Client_Balance_New |
| TotalRealCryptoLoan | Fact_SnapshotEquity | TotalRealCryptoLoan | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TotalRealCrypto | Fact_SnapshotEquity | TotalRealCrypto | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TotalRealStocks | Fact_SnapshotEquity | TotalRealStocks | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| PositionPNLCryptoReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| PositionPNLStocksReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| PositionPNL | V_Liabilities | PositionPnL | passthrough | Tier 2 — SP_Client_Balance_New |
| AvailableCash | V_Liabilities | AvailableCash | passthrough | Tier 2 — SP_Client_Balance_New |
| CashInCopy | V_Liabilities | CashInCopy | passthrough | Tier 2 — SP_Client_Balance_New |
| NOP | V_Liabilities | NOP | passthrough | Tier 2 — SP_Client_Balance_New |
| PositionAmount | Fact_SnapshotEquity | TotalPositionsAmount | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| StockOrders | Fact_SnapshotEquity | TotalStockOrders | passthrough | Tier 2 — SP_Fact_SnapshotEquity |
| actualNWA | V_Liabilities | ActualNWA | passthrough | Tier 2 — SP_Client_Balance_New |
| UsedBonus | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedCommissionChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedPnLChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedPnLChangeCFD | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedPnLChangeCryptoReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedPnLChangeStocksReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalNetTransfers | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalTransfersInvestedRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalTransfersInvestedRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersNWA | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersUnrealizedPnL | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersLiability | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetLiabilityTransferStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetUnrealizedPnLTransferStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UpdateDate | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| PositionPnLCrypto | V_Liabilities | PositionPnLCrypto | passthrough | Tier 2 — SP_Client_Balance_New |
| PositionPnLStocks | V_Liabilities | PositionPnLStocks | passthrough | Tier 2 — SP_Client_Balance_New |
| TotalCryptoPositionAmount | Fact_SnapshotEquity | TotalCryptoPositionAmount | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TotalStocksPositionAmount | Fact_SnapshotEquity | TotalStockPositionAmount | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| IsGermanBaFin | V_GermanBaFin | CID presence | ETL-computed | Tier 2 — SP_Client_Balance_New |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | passthrough | Tier 2 — SP_Fact_SnapshotCustomer |
| Date | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| YearMonth | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| YearQuarter | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| Year | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedCommissionChangeRealStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalRealStocksEquityChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| CompensationsApexUSStocks | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeCFDStocks | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeCFDCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TRSCryptoOpeningBalance | Fact_SnapshotEquity | Total_TRSCrypto (prev) | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TRSCryptoClosingBalance | Fact_SnapshotEquity | Total_TRSCrypto | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| UnrealizedPnLChangeCryptoTRS | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalCryptoPositionAmountTRS | Fact_SnapshotEquity | TotalCryptoPositionAmount_TRS | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| ClientBalanceRealizedPnLRealCryptoTRS | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceFullCommissionTRSCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommissionTRSCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeTRSCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NOPCryptoTRS | V_Liabilities | NOPCryptoTRS | passthrough | Tier 2 — SP_Client_Balance_New |
| PositionPNLCryptoTRS | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalTRSCrypto | Fact_SnapshotEquity | Total_TRSCrypto | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| CashoutRollback | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ReverseDeposit | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| DepositConversionFee | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| WithdrawConversionFee | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| SDRT | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TanganyStatus | Ext_Dictionary_TanganyStatus | Name | join-enriched | Tier 2 — SP_Client_Balance_New |
| TradingFees | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| InternalTransferDeposits | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| InternalTransferWithdraws | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedCommissionChangeRealCrypto | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TicketFee | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalRealCryptoEquityChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersUnrealizedPnLCryptoReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersLiabilityCryptoReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| DidDLTTransfer | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| IsDLTUser | Fact_SnapshotCustomer | DltStatusID | ETL-computed | Tier 2 — SP_Fact_SnapshotCustomer |
| CompensationCryptoTransferOut | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceRealizedPnLRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| RealFuturesOpenBalance | Fact_SnapshotEquity | TotalRealFutures (prev) | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| RealFuturesClosingBalance | Fact_SnapshotEquity | TotalRealFutures | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| ClientBalanceFullCommissionRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| ClientBalanceCommissionRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NOP_FuturesReal | V_Liabilities | NOP_FuturesReal | passthrough | Tier 2 — SP_Client_Balance_New |
| TotalRealFutures | Fact_SnapshotEquity | TotalRealFutures | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| PositionPNLFuturesReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedPnLChangeFuturesReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalTransfersInvestedRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedFullCommissionChangeRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| UnrealizedCommissionChangeRealFutures | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalRealFuturesEquityChange | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersUnrealizedPnLFuturesReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| NetTransfersLiabilityFuturesReal | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalFuturesProviderMargin | Fact_SnapshotEquity | TotalFuturesProviderMargin | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TotalFuturesLockedCash | Fact_SnapshotEquity | TotalFuturesLockedCash | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TicketFeeByPercent | Fact_CustomerAction | Amount | ETL-computed | Tier 2 — SP_Client_Balance_New |
| US_State | Dim_State_and_Province | ShortName | join-enriched | Tier 2 — SP_Dictionaries_DL_To_Synapse |
| NOP_StocksMargin | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| PositionPnLStocksMargin | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| TotalStocksMargin | Fact_SnapshotEquity | TotalStocksMargin | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| TotalStockMarginLoanValue | Fact_SnapshotEquity | TotalStockMarginLoanValue | passthrough | Tier 2 — SP_Fact_SnapshotEquity_TotalPositionAmount |
| NetTransferCommission | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |
| C2P | — | — | ETL-computed | Tier 2 — SP_Client_Balance_New |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough (from FSE/FSC/V_Liabilities)** | 42 |
| **Join-enriched (from Dim tables)** | 11 |
| **ETL-computed (by SP_Client_Balance_New)** | 121 |
| **Total** | 174 |

## Generic Pipeline (Outbound)

| Property | Value |
|---|---|
| generic_id | 943 |
| source_type | PROD (Synapse is the source) |
| copy_strategy | Append |
| frequency | 1440 minutes (daily) |
| UC table | bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new |
| datalake_path | Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_Client_Balance_CID_Level_New/ |

---
*Generated: 2026-03-20 (rerun) | Phases: 1,2,5,8,9,9B,10,10.5,13*
