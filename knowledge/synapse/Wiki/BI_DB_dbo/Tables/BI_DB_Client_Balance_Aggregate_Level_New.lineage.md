# Column Lineage: BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` (expected) |
| **Primary source** | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` (via `#CIDAgg` / `#RegAgg`) |
| **ETL SP** | `BI_DB_dbo.SP_Client_Balance_New` |
| **Generated** | 2026-03-20 |

## Source summary

| Layer | Object | Role |
|-------|--------|------|
| Temp | `#RegAgg` | `SELECT ... SUM(cast(x AS decimal(18,4))) ... FROM #CIDAgg GROUP BY` (all grain keys) |
| Writer | `SP_Client_Balance_New` | `DELETE` + `INSERT` for `@dateID`; `ISNULL` / `GETDATE()` / `NULL` on select list |
| Upstream table | `BI_DB_Client_Balance_CID_Level_New` | Same-day CID grain; see its `.lineage.md` for DWH facts and dimensions |

## Lineage chain

```
DWH Facts / Views / Dims
  -> SP_Client_Balance_New (#CIDAgg = CID-equivalent rowset)
    -> #RegAgg (SUM grouped by dimension columns + TanganyStatus + US_State)
      -> INSERT BI_DB_Client_Balance_Aggregate_Level_New
```

## Column lineage

### Legend

| Transform | Meaning |
|-----------|--------|
| **group-by-key** | Dimension carried from CID; not summed. |
| **aggregate-sum** | `SUM` in `#RegAgg` over CID rows sharing the grain; then `ISNULL(...,0)` on insert unless noted. |
| **insert-literal** | Not from `#RegAgg`; set in outer `INSERT..SELECT`. |

| Aggregate column | Immediate source table | Immediate source column | Transform | Tier note |
|------------------|------------------------|-------------------------|-----------|----------|
| TransferDirection | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TransferDirection` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Regulation | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Regulation` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| IsCreditReportValidCB | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsCreditReportValidCB` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| DidRegulationTransfer | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `DidRegulationTransfer` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| DidCBValidTransfer | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `DidCBValidTransfer` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| IsEtoroTradingCID | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsEtoroTradingCID` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| eToroTradingGroupUser | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `eToroTradingGroupUser` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| IsGlenEagleAccount | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsGlenEagleAccount` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Region | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Region` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| FromRegulation | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `FromRegulation` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| ToRegulation | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ToRegulation` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| AccountType | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `AccountType` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Label | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Label` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Country | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Country` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| MifidCategory | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `MifidCategory` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Club | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Club` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| PlayerStatus | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PlayerStatus` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| DateID | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `DateID` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| OpeningBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `OpeningBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Deposits | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Deposits` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationDeposit | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationDeposit` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Bonus | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Bonus` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Compensation | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Compensation` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationPI | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationPI` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationToAffiliate | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationToAffiliate` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NWAAdjustment | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NWAAdjustment` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NegativeRefill | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NegativeRefill` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Cashouts | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Cashouts` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CashoutsIncludingRedeem | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CashoutsIncludingRedeem` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationCashouts | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationCashouts` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CashoutFee | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CashoutFee` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Chargeback | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Chargeback` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Refund | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Refund` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| OvernightFee | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `OvernightFee` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| LostDebt | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `LostDebt` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ChargebackLoss | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ChargebackLoss` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| OtherNegatives | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `OtherNegatives` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| Foreclosure | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Foreclosure` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationPnLAdjustments | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationPnLAdjustments` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationDormantFee | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationDormantFee` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnL | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnL` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnLCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnLCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnLRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnLRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnLRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnLRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TransferCoins | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TransferCoins` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TransferCoinFees | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TransferCoinFees` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| realizedEquity | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `realizedEquity` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealCryptoOpenBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealCryptoOpenBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealCryptoClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealCryptoClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientMoneyOpenBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientMoneyOpenBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientMoneyClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientMoneyClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealStocksOpeningBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealStocksOpeningBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealStocksClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealStocksClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommission | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommission` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommission | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommission` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommissionCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommissionCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommissionCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommissionCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommissionRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommissionRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommissionRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommissionRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommissionRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommissionRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommissionRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommissionRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| DividendsPaid | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `DividendsPaid` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalLiability | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalLiability` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalNegativeLiability | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalNegativeLiability` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| WithdrawableLiability | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `WithdrawableLiability` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NegativeWithdrawableLiability | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NegativeWithdrawableLiability` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| LiabilityInUsedMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `LiabilityInUsedMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NegativeLiabilityInUsedMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NegativeLiabilityInUsedMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| InProcessCashout | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `InProcessCashout` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NegativeInProcessCashout | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NegativeInProcessCashout` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOPCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOPCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOPCryptoCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOPCryptoCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOPStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOPStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOPStocksCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOPStocksCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealCryptoLoan | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealCryptoLoan` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPNLCryptoReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPNLCryptoReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPNLStocksReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPNLStocksReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPNL | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPNL` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| AvailableCash | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `AvailableCash` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CashInCopy | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CashInCopy` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOP | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOP` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionAmount | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionAmount` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| StockOrders | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `StockOrders` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| actualNWA | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `actualNWA` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UsedBonus | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UsedBonus` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedCommissionChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedCommissionChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChangeCFD | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChangeCFD` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChangeCryptoReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChangeCryptoReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChangeStocksReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChangeStocksReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalNetTransfers | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalNetTransfers` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalTransfersInvestedRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalTransfersInvestedRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalTransfersInvestedRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalTransfersInvestedRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersNWA | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersNWA` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersUnrealizedPnL | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersUnrealizedPnL` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersLiability | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersLiability` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetLiabilityTransferStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetLiabilityTransferStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetUnrealizedPnLTransferStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetUnrealizedPnLTransferStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UpdateDate | `—` | `—` | insert-literal (`GETDATE()`) | Tier 3 -- computed |
| PositionPnLCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPnLCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPnLStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPnLStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalCryptoPositionAmount | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalCryptoPositionAmount` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalStocksPositionAmount | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalStocksPositionAmount` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| IsGermanBaFin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsGermanBaFin` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| IsValidCustomer | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsValidCustomer` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Date | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Date` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| YearMonth | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `YearMonth` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| YearQuarter | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `YearQuarter` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| Year | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `Year` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| UnrealizedCommissionChangeRealStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedCommissionChangeRealStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealStocksEquityChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealStocksEquityChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CompensationsApexUSStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationsApexUSStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeCFDStocks | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeCFDStocks` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeCFDCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeCFDCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TRSCryptoOpeningBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TRSCryptoOpeningBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TRSCryptoClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TRSCryptoClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChangeCryptoTRS | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChangeCryptoTRS` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalCryptoPositionAmountTRS | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalCryptoPositionAmountTRS` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnLRealCryptoTRS | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnLRealCryptoTRS` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommissionTRSCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommissionTRSCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommissionTRSCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommissionTRSCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeTRSCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeTRSCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOPCryptoTRS | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOPCryptoTRS` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPNLCryptoTRS | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPNLCryptoTRS` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalTRSCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalTRSCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| CashoutRollback | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CashoutRollback` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ReverseDeposit | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ReverseDeposit` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| DepositConversionFee | `—` | `—` | insert-literal (`NULL`) | Tier 3 -- computed |
| WithdrawConversionFee | `—` | `—` | insert-literal (`NULL`) | Tier 3 -- computed |
| SDRT | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `SDRT` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TanganyStatus | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TanganyStatus` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| TradingFees | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TradingFees` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| InternalTransferDeposits | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `InternalTransferDeposits` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| InternalTransferWithdraws | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `InternalTransferWithdraws` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedCommissionChangeRealCrypto | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedCommissionChangeRealCrypto` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TicketFee | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TicketFee` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealCryptoEquityChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealCryptoEquityChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersUnrealizedPnLCryptoReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersUnrealizedPnLCryptoReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersLiabilityCryptoReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersLiabilityCryptoReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| DidDLTTransfer | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `DidDLTTransfer` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| IsDLTUser | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `IsDLTUser` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| CompensationCryptoTransferOut | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `CompensationCryptoTransferOut` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceRealizedPnLRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceRealizedPnLRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealFuturesOpenBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealFuturesOpenBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| RealFuturesClosingBalance | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `RealFuturesClosingBalance` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceFullCommissionRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceFullCommissionRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| ClientBalanceCommissionRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `ClientBalanceCommissionRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NOP_FuturesReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOP_FuturesReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPNLFuturesReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPNLFuturesReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedPnLChangeFuturesReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedPnLChangeFuturesReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalTransfersInvestedRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalTransfersInvestedRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedFullCommissionChangeRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedFullCommissionChangeRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| UnrealizedCommissionChangeRealFutures | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `UnrealizedCommissionChangeRealFutures` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalRealFuturesEquityChange | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalRealFuturesEquityChange` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersUnrealizedPnLFuturesReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersUnrealizedPnLFuturesReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransfersLiabilityFuturesReal | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransfersLiabilityFuturesReal` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalFuturesProviderMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalFuturesProviderMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalFuturesLockedCash | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalFuturesLockedCash` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TicketFeeByPercent | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TicketFeeByPercent` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| US_State | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `US_State` | group-by-key | Tier 2 -- SP_Client_Balance_New |
| NOP_StocksMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NOP_StocksMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| PositionPnLStocksMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `PositionPnLStocksMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalStocksMargin | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalStocksMargin` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| TotalStockMarginLoanValue | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `TotalStockMarginLoanValue` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| NetTransferCommission | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `NetTransferCommission` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |
| C2P | `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` | `C2P` | aggregate-sum | Tier 2 -- SP_Client_Balance_New (transitive via CID lineage) |

## Summary

| Category | Count |
|----------|-------|
| group-by-key | 28 |
| aggregate-sum | 142 |
| insert-literal | 3 |
| **Total** | 173 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 6.*
