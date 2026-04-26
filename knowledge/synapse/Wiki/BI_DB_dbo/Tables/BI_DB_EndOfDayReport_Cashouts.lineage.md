# BI_DB_dbo.BI_DB_EndOfDayReport_Cashouts — Column Lineage

## Writer SP
`BI_DB_dbo.SP_H_EndOfDayReport_Cashouts`

## Source Objects
- `BI_DB_dbo.External_etoro_Billing_Withdraw` — withdrawal/cashout requests
- `DWH_dbo.Dim_CashoutStatus` — cashout status names

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| ID | IDENTITY | auto-increment | IDENTITY(1,1) |
| NoOfCashouts | External_Billing_Withdraw | WithdrawID | COUNT(DISTINCT) per status/timeframe group |
| COStatus | Dim_CashoutStatus | Name | Direct (Processed, Pending, InProcess, etc.) |
| CashoutStatus | Computed | Dim_CashoutStatus.Name | CASE: Processed→'Cashout Processed', Pending/Partially Processed/InProcess→'Cashouts Pending - Payment Sent', else→'Cashouts Pending -Payment Not Sent' |
| TimeFrame | Computed | RequestDate | CASE: T (today), T-1 (yesterday), T-2 to T-7, T-7 to T-15, Over 15 days |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
