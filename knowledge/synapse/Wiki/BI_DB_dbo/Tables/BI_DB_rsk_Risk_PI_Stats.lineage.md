# BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | general.etoroGeneral_History_GuruCopiers | general | Copy AUM, copier counts (today + yesterday) | Timestamp = @Date+1 and @Date |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | Valid customer filter, copyfund identification | RealCID join |
| 3 | DWH_dbo.V_Liabilities | DWH_dbo | RealizedEquity, StandardDeviation | CID = ParentCID |
| 4 | DWH_dbo.Dim_Position | DWH_dbo | Closed position NetProfit | MirrorID join, CloseDateID range |
| 5 | DWH_dbo.Dim_Mirror | DWH_dbo | Mirror relationship | MirrorID, MirrorTypeID=1 |
| 6 | DWH_dbo.Fact_CustomerAction | DWH_dbo | MIMO money in/out | DateID, ActionTypeID 15-18 |
| 7 | BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | IsBuy equity proportion | CID = ParentCID, MirrorID=0, DateID |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @Date | Direct |
| 2 | ParentCID | GuruCopiers | ParentCID | Top 100 PI |
| 3 | ParentUserName | GuruCopiers | ParentUserName | Passthrough |
| 4 | Type | Dim_Customer | AccountTypeID | CASE 9='Copyfund' else 'Regular' |
| 5 | Timestamp | GuruCopiers | Timestamp | Passthrough |
| 6 | Copiers | GuruCopiers | COUNT(*) | Aggregate |
| 7 | eCopiers | GuruCopiers | COUNT WHERE equity>=100 | Aggregate |
| 8 | AUM | GuruCopiers | Cash+Investment+PnL+DetachedPos+Dit_PnL | SUM |
| 9 | Cash | GuruCopiers | Cash | SUM |
| 10 | Investment | GuruCopiers | Investment | SUM |
| 11 | PnL | GuruCopiers | PnL | SUM |
| 12 | DetachedPosInvestment | GuruCopiers | DetachedPosInvestment | SUM |
| 13 | Dit_PnL | GuruCopiers | Dit_PnL | SUM |
| 14 | rn_AUM | Computed | ROW_NUMBER PARTITION BY Type ORDER BY AUM DESC | Rank |
| 15 | rn_eCopiers | Computed | ROW_NUMBER PARTITION BY Type ORDER BY eCopiers DESC | Rank |
| 16 | %AUM | Computed | AUM / total_AUM | Proportion |
| 17 | RealizedEquity | V_Liabilities | RealizedEquity | Passthrough |
| 18 | STD | V_Liabilities | StandardDeviation | Passthrough |
| 19 | RealizedAUM | GuruCopiers | Cash+Investment+DetachedPos | SUM (no PnL) |
| 20 | TotalProfit | Computed | PnL+Dit_PnL-Yesterday(PnL+Dit_PnL)+NetProfit(closed) | Daily profit |
| 21 | YesterdayAUM | GuruCopiers (yesterday) | AUM | Previous day SUM |
| 22 | MoneyIn | Fact_CustomerAction | Amount × -1 WHERE ActionTypeID IN (15,17) | Mirror money-in |
| 23 | MoneyOut | Fact_CustomerAction | Amount WHERE ActionTypeID IN (16,18) | Mirror money-out |
| 24 | UpdateDate | ETL | GETDATE() | Metadata |
| 25 | IsBuyPercent | BI_DB_PositionPnL | UnrealizedEquity(Buy) / Total | Manual position buy ratio |
