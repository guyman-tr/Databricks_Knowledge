# BI_DB_dbo.BI_DB_EndOfDayReport_Redeems — Column Lineage

## Writer SP
`BI_DB_dbo.SP_H_EndOfDayReport_Redeems`

## Source Objects
- `BI_DB_dbo.External_etoro_Billing_Redeem` — redeem requests
- `DWH_dbo.Dim_RedeemStatus` — redeem status names

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| ID | IDENTITY | auto-increment | IDENTITY(1,1) |
| NoOfRedees | External_Billing_Redeem | RedeemID | COUNT(DISTINCT) per status/date/timeframe group |
| RedeemStatus | Dim_RedeemStatus | DisplayName | Direct (TransactionDone, Pending, Approved, ReadyToRedeem, etc.) |
| RequestDate | External_Billing_Redeem | RequestDate | CAST to date |
| Redeem Status Group | Computed | Dim_RedeemStatus.DisplayName | CASE: TransactionDone→'Redeem Processed', else→'Redeem Pending' |
| TimeFrame | Computed | RequestDate | CASE: Today, Past 7 days, Past 15 days, Over 30 days |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
