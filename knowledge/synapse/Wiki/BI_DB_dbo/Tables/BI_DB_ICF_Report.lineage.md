# BI_DB_dbo.BI_DB_ICF_Report — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | BI_DB Table | Primary source — CID-level daily client balance |
| BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI | BI_DB Table | ECB EUR/USD exchange rate |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| Date | BI_DB_Client_Balance_CID_Level_New | Date | EOMONTH — end-of-month date |
| DateID | BI_DB_Client_Balance_CID_Level_New | DateID | Passthrough (filtered to @DateID) |
| Regulation | BI_DB_Client_Balance_CID_Level_New | Regulation | Passthrough (filtered to FCA/CySEC/BVI/NFA/None) |
| PlayerStatus | BI_DB_Client_Balance_CID_Level_New | PlayerStatus | Passthrough |
| MifidCategory | BI_DB_Client_Balance_CID_Level_New | MifidCategory | Passthrough |
| IsCreditReportValidCB | BI_DB_Client_Balance_CID_Level_New | IsCreditReportValidCB | Passthrough |
| ECBRate | BI_DB_ECB_RateExtractFromAPI | ECBRate | Latest rate on or before report date (ROW_NUMBER DESC) |
| Total Cash | BI_DB_Client_Balance_CID_Level_New | AvailableCash, CashInCopy, TotalNegativeLiability, InProcessCashout, actualNWA | SUM(AvailableCash + CashInCopy - TotalNegativeLiability + InProcessCashout - actualNWA) aggregated by group |
| EquityCFD | BI_DB_Client_Balance_CID_Level_New | PositionAmount, PositionPNL, TotalRealCrypto, TotalRealStocks, TotalRealFutures, PositionPNLCryptoReal, PositionPNLStocksReal, PositionPNLFuturesReal | SUM((PositionAmount+PositionPNL) - (RealCrypto+PNLCryptoReal) - (RealStocks+PNLStocksReal) - (RealFutures+PNLFuturesReal)) — CFD residual |
| Equity Real Stocks | BI_DB_Client_Balance_CID_Level_New | TotalRealStocks, PositionPNLStocksReal | SUM(TotalRealStocks + PositionPNLStocksReal) |
| Total - USD | Computed | Total Cash, EquityCFD, Equity Real Stocks, EquityRealFutures | CySEC/BVI/NFA/None: Cash+CFD+Stocks+Futures; FCA: CFD only |
| Total in EUR (Using ECB Rate) | Computed | Total - USD, ECBRate | Total-USD / ECBRate |
| Balance exceeding 20k EUR | Computed | Total in EUR | MAX(0, Total-in-EUR - 20000) |
| UpdateDate | — | — | GETDATE() — ETL timestamp |
| EquityRealFutures | BI_DB_Client_Balance_CID_Level_New | TotalRealFutures, PositionPNLFuturesReal | SUM(TotalRealFutures + PositionPNLFuturesReal) |
| RealFuturesProviderMargin | BI_DB_Client_Balance_CID_Level_New | TotalFuturesProviderMargin | SUM(TotalFuturesProviderMargin) |
| FuturesLockedCash | BI_DB_Client_Balance_CID_Level_New | TotalFuturesLockedCash | SUM(TotalFuturesLockedCash) |
| EquityStocksMargin | BI_DB_Client_Balance_CID_Level_New | TotalStocksMargin, PositionPnLStocksMargin | SUM(TotalStocksMargin + PositionPnLStocksMargin) |
| TotalStockMarginLoanValue | BI_DB_Client_Balance_CID_Level_New | TotalStockMarginLoanValue | SUM(TotalStockMarginLoanValue) |

## Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (CID-level daily balance, Priority 99)
  + BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI (EUR/USD rate)
    |-- SP_ICF_Report @Date (monthly end-of-month, delete-insert by DateID) --|
    |   Filter: Regulation IN (FCA, CySEC, BVI, NFA, None)                    |
    |   Aggregate: SUM by Regulation/PlayerStatus/MifidCategory/IsCreditValid  |
    |   Convert: USD → EUR via ECB rate, flag >20K EUR                        |
    v
BI_DB_dbo.BI_DB_ICF_Report (15.4K rows, monthly)
```
