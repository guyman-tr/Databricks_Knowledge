# Column Lineage — DWH_dbo.Fact_SnapshotEquity

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| CID | Ext_FSE_Real_History_Credit.CID | Direct passthrough from History.ActiveCredit |
| DateRangeID | Computed | `CONVERT(BIGINT, CONVERT(VARCHAR, @date, 112) + RIGHT(CONVERT(VARCHAR, @largedate, 112), 4))` — encodes FromDate + ToDate |
| TotalPositionsAmount | Ext_FSE_TotalPositionAmount.TotalPositionAmount | `ISNULL(pa.TotalPositionAmount, 0)` |
| TotalCash | Computed | `ISNULL(tcap.TotalCashPreviousDate, 0) + ISNULL(tca.TotalCashChangeAll, 0)` — running balance |
| InProcessCashouts | Ext_FSE_InProcessCashouts.InProcessCashouts | `ISNULL(ic.InProcessCashouts, 0)` — from SP_Fact_SnapshotEquity_InProcessCashouts |
| TotalMirrorPositionsAmount | Ext_FSE_TotalPositionAmount.TotalMirrorPositionAmount | `ISNULL(pa.TotalMirrorPositionAmount, 0)` |
| TotalMirrorCash | Computed | `TotalCash − Credit` |
| TotalStockOrders | Hardcoded | `0` (legacy, removed 2019-03-03) |
| TotalMirrorStockOrders | Hardcoded | `0` (legacy, removed 2019-03-03) |
| RealizedEquity | Ext_FSE_Real_History_Credit.RealizedEquity | Fallback: `TotalCash + TotalPositionAmount + InProcessCashouts` when source = 0 |
| Credit | Ext_FSE_Real_History_Credit.Credit | `ISNULL(hc.Credit, 0)` — last credit event per CID per day |
| AUM | Computed | `TotalMirrorPositionAmount + TotalCash − Credit` |
| BonusCredit | Ext_FSE_Real_History_Credit.BonusCredit | `ISNULL(hc.BonusCredit, 0)` |
| CreditID | Ext_FSE_Real_History_Credit.CreditID | Last CreditID per CID per day (ROW_NUMBER) |
| UpdateDate | System | `GETDATE()` at MERGE/INSERT time |
| TotalStockPositionAmount | Ext_FSE_TotalPositionAmount.TotalStockPositionAmount | `ISNULL(pa.TotalStockPositionAmount, 0)` |
| TotalMirrorStockPositionAmount | Ext_FSE_TotalPositionAmount.TotalMirrorStockPositionAmount | `ISNULL(pa.TotalMirrorStockPositionAmount, 0)` |
| TotalCryptoPositionAmount | Ext_FSE_TotalPositionAmount.TotalCryptoPositionAmount | `ISNULL(pa.TotalCryptoPositionAmount, 0)` |
| TotalMirrorCryptoPositionAmount | Ext_FSE_TotalPositionAmount.TotalMirrorCryptoPositionAmount | `ISNULL(pa.TotalMirrorCryptoPositionAmount, 0)` |
| TotalRealStocks | Ext_FSE_TotalPositionAmount.TotalRealStocks | Updated via IsSettled change tracking |
| TotalRealCrypto | Ext_FSE_TotalPositionAmount.TotalRealCrypto | Updated via IsSettled change tracking |
| TotalRealCryptoLoan | Ext_FSE_TotalPositionAmount.TotalRealCryptoLoan | `ISNULL(pa.TotalRealCryptoLoan, 0)` |
| TotalCashCalculation | Computed | Same as TotalCash — `previousDay + TotalCashChangeAll` |
| TotalCryptoPositionAmount_TRS | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalCryptoPositionAmount_TRS, 0)` |
| TotalMirrorCryptoPositionAmount_TRS | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalMirrorCryptoPositionAmount_TRS, 0)` |
| Total_TRSCrypto | Ext_FSE_TotalPositionAmount | `ISNULL(pa.Total_TRSCrypto, 0)` |
| TotalMirrorRealFuturesPositionAmount | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalMirrorRealFuturesPositionAmount, 0)` |
| TotalRealFutures | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalRealFutures, 0)` |
| TotalFuturesProviderMargin | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalFuturesProviderMargin, 0)` |
| TotalFuturesLockedCash | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalFuturesLockedCash, 0)` |
| TotalStocksMargin | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalStocksMargin, 0)` |
| TotalStockMarginLoanValue | Ext_FSE_TotalPositionAmount | `ISNULL(pa.TotalStockMarginLoanValue, 0)` |

## Production Source Tables

| DWH Staging Table | Production Source | Server |
|-------------------|-------------------|--------|
| DWH_staging.etoro_History_ActiveCredit | History.ActiveCredit | etoroDB-REAL |
| DWH_staging.etoro_History_ClosePositionEndOfDay | History.ClosePositionEndOfDay | etoroDB-REAL |
| DWH_staging.etoro_Trade_OpenPositionEndOfDay | Trade.OpenPositionEndOfDay | etoroDB-REAL |
| DWH_staging.etoro_History_PositionChangeLog | History.PositionChangeLog | etoroDB-REAL |
| DWH_staging.etoro_History_Credit | History.Credit | etoroDB-REAL |
| DWH_staging.etoro_Billing_Withdraw | Billing.Withdraw | etoroDB-REAL |
| DWH_staging.etoro_History_WithdrawAction | History.WithdrawAction | etoroDB-REAL |
| DWH_staging.etoro_History_WithdrawToFundingAction | History.WithdrawToFundingAction | etoroDB-REAL |
| DWH_staging.etoro_Billing_WithdrawToFunding | Billing.WithdrawToFunding | etoroDB-REAL |
| DWH_staging.etoro_Trade_GetInstrument | Trade.GetInstrument | etoroDB-REAL |

## Data Lake / UC Mapping

| Path | UC Table | Notes |
|------|----------|-------|
| Gold/sql_dp_prod_we/DWH_dbo/V_Fact_SnapshotEquity/ | (via view export) | Fact_SnapshotEquity itself is not directly exported; views V_Fact_SnapshotEquity and V_Fact_SnapshotEquity_FromDateID are exported to Gold |

## Dependency Graph

```
Ext_FSE_Real_History_Credit ─┐
Ext_FSE_InProcessCashouts ───┤
Ext_FSE_TotalPositionAmount ─┤─→ Ext_FSE_Fact_SnapshotEquity ─→ MERGE → Fact_SnapshotEquity
Ext_FSE_TotalCashChangeAll ──┤                                        ↓
#TotalCashPreviousDate ──────┘                                   Dim_Range (INSERT new ranges)
```
