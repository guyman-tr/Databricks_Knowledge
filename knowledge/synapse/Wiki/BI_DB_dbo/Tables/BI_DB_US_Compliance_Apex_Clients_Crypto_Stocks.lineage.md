# Column Lineage: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks

## Source Objects

| Source Object | Type | Role | Join Condition |
|---------------|------|------|----------------|
| DWH_dbo.Dim_Customer (dc) | Dimension | Primary — CID, depositor filter | WHERE CountryID=219 AND IsValidCustomer=1 AND IsDepositor=1 |
| DWH_dbo.V_Liabilities (vl) | View | Financial balances — stocks, crypto, equity, cash | dc.RealCID = vl.CID AND vl.DateID = @Date (LEFT JOIN) |
| DWH_dbo.Dim_State_and_Province (dst) | Dimension | State name lookup | dc.RegionID = dst.RegionByIP_ID AND dc.CountryID = dst.CountryID |
| DWH_dbo.Dim_AccountStatus (das) | Dimension | Account status name lookup | das.AccountStatusID = dc.AccountStatusID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | Dim_Customer | RealCID | Rename |
| Address_State | Dim_State_and_Province | Name | Dim-lookup passthrough via RegionID+CountryID |
| AccountStatusName | Dim_AccountStatus | AccountStatusName | Dim-lookup passthrough via AccountStatusID |
| StocksBalance | V_Liabilities | TotalStockPositionAmount + StocksPositionPnL | MAX(ISNULL(amount,0) + ISNULL(pnl,0)) — stock position value + unrealized PnL |
| CryptoBalance | V_Liabilities | TotalCryptoPositionAmount + CryptoPositionPnL | MAX(ISNULL(amount,0) + ISNULL(pnl,0)) — crypto position value + unrealized PnL |
| RealizedEquity | V_Liabilities | RealizedEquity | MAX(ISNULL(val,0)) — aggregated for GROUP BY |
| TotalLiability | V_Liabilities | Liabilities | MAX(ISNULL(val,0)) — aggregated for GROUP BY |
| AvailableCash | V_Liabilities | Credit | MAX(ISNULL(val,0)) — available credit/cash |
| CashInCopy | V_Liabilities | TotalCash - Credit | MAX(ISNULL(TotalCash,0) - ISNULL(Credit,0)) — cash allocated to copy trading |
| UpdateDate | — | — | ETL metadata: GETDATE() |
