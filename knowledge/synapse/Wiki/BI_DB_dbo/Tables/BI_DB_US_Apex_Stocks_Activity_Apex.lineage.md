# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| BI_DB_dbo.External_Sodreconciliation_apex_EXT870_StockActivity | External Table | Primary — Apex SOD 870 stock activity records |
| DWH_dbo.Sodreconciliation_apex_SodFiles | Table | SOD file validation (valid file filter) |
| BI_DB_dbo.External_USABroker_Apex_ApexData | External Table | Apex account lookup |
| BI_DB_dbo.External_USABroker_Apex_UserData | External Table | CID resolution via GCID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| AccountNumber | EXT870_StockActivity | AccountNumber | Passthrough (filtered: AccountType='2', not '3ET00001') |
| CID | External_USABroker_Apex_UserData | CID | JOIN via ApexData.GCID → UserData.GCID |
| EntryDate | EXT870_StockActivity | EntryDate | Passthrough (filtered to @Date) |
| CUSIP | EXT870_StockActivity | Cusip | Passthrough |
| Category | EXT870_StockActivity | TradeSettleBasis | CASE: 'R'→'Recieved', 'D'→'Delivered' |
| Trailer | EXT870_StockActivity | Trailer | Passthrough |
| TerminalID | EXT870_StockActivity | TerminalID | Passthrough (filtered: NOT IN 'MGJNL','RGJNL') |
| Units | EXT870_StockActivity | Quantity | SUM aggregation |
| UpdateDate | ETL | GETDATE() | Insert timestamp |
