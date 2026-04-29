# BI_DB_dbo.BI_DB_rsk_DailyRiskAgg — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | DWH_dbo.V_Liabilities | DWH_dbo | Realized equity, total equity | CID = RealCID, DateID = @yesterdayID |
| 2 | general.etoroGeneral_History_GuruCopiers | general | Copy AUM, PnL by copier | CID = RealCID, Timestamp = @eed |
| 3 | DWH_dbo.Dim_Customer | DWH_dbo | Valid customer filter, copyfund identification | IsValidCustomer=1, AccountTypeID=9 for copyfunds |
| 4 | BI_DB_dbo.BI_DB_rsk_Portfolio | BI_DB_dbo | Net open position (NOP) per instrument | Date = @eed |
| 5 | DWH_dbo.Dim_Instrument_Correlation | DWH_dbo | Instrument covariance matrix | Latest DateID |
| 6 | DWH_dbo.Dim_Mirror | DWH_dbo | Identify copyfund vs regular mirrors | MirrorID join |
| 7 | DWH_dbo.Fact_CustomerAction | DWH_dbo | MIMO money in/out by mirror type | DateID = @yesterdayID, ActionTypeID IN (15,16,17,18) |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @eed = @sd + 1 day | Computed — next day after input |
| 2 | UnWeighted_STD_h | BI_DB_rsk_Portfolio + Dim_Instrument_Correlation | NOP × Covariance | SQRT(ABS(SUM(weighted_COV))) — all segments |
| 3 | Copy_UnWeighted_STD_h | Same | CopyWeighted_COV | SQRT(ABS(SUM)) — copy segment only |
| 4 | Copyfund_UnWeighted_STD_h | Same | CopyfundWeight_COV | SQRT(ABS(SUM)) — copyfund segment |
| 5 | CopytraderWeight_UnWeighted_STD_h | Same | CopytraderWeight_COV | SQRT(ABS(SUM)) — copytrader (excl copyfund) |
| 6 | FX_UnWeighted_STD_h | Same | FXWeighted_COV | SQRT(ABS(SUM)) — FX/manual segment |
| 7 | STD | Computed | UnWeighted_STD_h × 1000 / RealizedEquity | Normalized portfolio risk |
| 8 | CopySTD | Computed | Copy_UnWeighted_STD_h × 1000 / AUM | Copy-specific risk |
| 9 | FXSTD | Computed | FX_UnWeighted_STD_h × 1000 / (RealizedEquity-AUM) | Manual/FX risk |
| 10 | CopytraderSTD | Computed | CopytraderWeight_UnWeighted_STD_h × 1000 / Traders_AUM | Copytrader risk |
| 11 | CopyfundSTD | Computed | Copyfund_UnWeighted_STD_h × 1000 / Copyfund_AUM | Copyfund risk |
| 12 | RealizedEquity | V_Liabilities | RealizedEquity | SUM across valid customers |
| 13 | ManualEquity | Computed | RealizedEquity - AUM | Non-copy equity |
| 14 | CopyAUM | etoroGeneral_History_GuruCopiers | Cash+Investment+DetachedPosInvestment | SUM (all copy) |
| 15 | Traders_AUM | etoroGeneral_History_GuruCopiers | Same, excl copyfunds | SUM WHERE parent.AccountTypeID != 9 |
| 16 | Copyfund_AUM | etoroGeneral_History_GuruCopiers | Same, copyfunds only | SUM WHERE parent.AccountTypeID = 9 |
| 17 | Traders_PnL | etoroGeneral_History_GuruCopiers | PnL+Dit_PnL | SUM WHERE parent.AccountTypeID != 9 |
| 18 | Copyfund_PnL | etoroGeneral_History_GuruCopiers | PnL+Dit_PnL | SUM WHERE parent.AccountTypeID = 9 |
| 19 | AUMIncUnPnL | etoroGeneral_History_GuruCopiers | Cash+Investment+DetachedPosInvestment+PnL+Dit_PnL | SUM (all copy AUM + unrealized PnL) |
| 20 | Equity | V_Liabilities | ActualNWA + Liabilities | SUM across valid customers |
| 21 | Copyfund_AUMIncUnPnL | Computed | Copyfund_AUM + Copyfund_PnL | ISNULL sum |
| 22 | Traders_AUMIncUnPnL | Computed | Traders_AUM + Traders_PnL | ISNULL sum |
| 23 | UpdateDate | ETL | GETDATE() | Row insert timestamp |
| 24 | NetMoneyIn - Copyfund | Fact_CustomerAction + Dim_Mirror | MoneyIn+MoneyOut for Copyfund type | SUM (negative = net inflow) via UPDATE |
| 25 | NetMoneyIn - Traders | Fact_CustomerAction + Dim_Mirror | MoneyIn+MoneyOut for Regular type | SUM via UPDATE |
| 26 | NetMoneyIn - CopyAll | Fact_CustomerAction + Dim_Mirror | MoneyIn+MoneyOut all types | SUM via UPDATE |
