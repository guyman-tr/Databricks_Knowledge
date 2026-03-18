# Column Lineage: DWH_dbo.Fact_Withdraw_Fees

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_Withdraw_Fees` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_withdraw_fees` (expected) |
| **Primary Source** | `BackOffice.GetProcessedWithdrawPCIVersion` (SP) via `DWH_staging.etoro_BackOffice_GetProcessedWithdrawPCIVersion` (staging - no longer exists) |
| **ETL SP** | `DWH_dbo.SP_Fact_Withdraw_Fees_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
BackOffice.GetProcessedWithdrawPCIVersion (production SP - processed withdrawals report)
  -> DWH_staging.etoro_BackOffice_GetProcessedWithdrawPCIVersion (materialized staging, NOW GONE)
       -> SP_Fact_Withdraw_Fees_DL_To_Synapse (@dt daily param)
            DELETE WHERE ModificationDateID in @dt range
            INSERT WHERE StatusModificationTime in @dt range
            -> DWH_dbo.Fact_Withdraw_Fees (6.6M rows, frozen 2024-06-30)

NOTE: Pipeline stopped ~July 2024. Staging table dropped.
      ETL uses proper DELETE+INSERT incremental (WHERE clause active - different from Fact_Deposit_Fees).
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived by ETL, not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | BackOffice.GetProcessedWithdrawPCIVersion | CID | passthrough | int |
| PaymentOrderStatus | BackOffice.GetProcessedWithdrawPCIVersion | PaymentOrderStatus | passthrough | nvarchar |
| ProcessTime | BackOffice.GetProcessedWithdrawPCIVersion | ProcessTime | passthrough | datetime2(7); range 2021-2024 |
| RequestTime | BackOffice.GetProcessedWithdrawPCIVersion | RequestTime | passthrough | datetime2(7) |
| StatusModificationTime | BackOffice.GetProcessedWithdrawPCIVersion | StatusModificationTime | passthrough | datetime2(7); ETL filter key |
| WithdrawStatus | BackOffice.GetProcessedWithdrawPCIVersion | WithdrawStatus | passthrough | nvarchar; 6 values including "Partialy Reversed" typo |
| NetCashoutDollarAmount | BackOffice.GetProcessedWithdrawPCIVersion | NetCashoutDollarAmount | passthrough | decimal(38,18) |
| FundingMethod | BackOffice.GetProcessedWithdrawPCIVersion | FundingMethod | passthrough | nvarchar; 16 methods |
| FundingID | BackOffice.GetProcessedWithdrawPCIVersion | FundingID | passthrough | int |
| WithdrawProcessingID | BackOffice.GetProcessedWithdrawPCIVersion | WithdrawProcessingID | passthrough | int |
| WithdrawID | BackOffice.GetProcessedWithdrawPCIVersion | WithdrawID | passthrough | int |
| DepositID | BackOffice.GetProcessedWithdrawPCIVersion | DepositID | passthrough | int; original deposit for card-match |
| ExchangeRate | BackOffice.GetProcessedWithdrawPCIVersion | ExchangeRate | passthrough | decimal(38,18) |
| FeeInPIPs | BackOffice.GetProcessedWithdrawPCIVersion | FeeInPIPs | passthrough | int |
| PIPsinUSD | BackOffice.GetProcessedWithdrawPCIVersion | PIPsinUSD | passthrough | decimal(38,18) |
| NetAmountinOrigCurrency | BackOffice.GetProcessedWithdrawPCIVersion | NetAmountinOrigCurrency | passthrough | decimal(38,18) |
| Currency | BackOffice.GetProcessedWithdrawPCIVersion | Currency | passthrough | nvarchar |
| Brand | BackOffice.GetProcessedWithdrawPCIVersion | Brand | passthrough | nvarchar |
| Depot | BackOffice.GetProcessedWithdrawPCIVersion | Depot | passthrough | nvarchar |
| ProcessorValueDate | BackOffice.GetProcessedWithdrawPCIVersion | ProcessorValueDate | passthrough | datetime2(7) |
| VerificationCode | BackOffice.GetProcessedWithdrawPCIVersion | VerificationCode | passthrough | nvarchar |
| VendorCode | BackOffice.GetProcessedWithdrawPCIVersion | VendorCode | passthrough | nvarchar |
| CashoutType | BackOffice.GetProcessedWithdrawPCIVersion | CashoutType | passthrough | nvarchar |
| BackOfficeWithdrawReason | BackOffice.GetProcessedWithdrawPCIVersion | BackOfficeWithdrawReason | passthrough | nvarchar |
| WhiteLabel | BackOffice.GetProcessedWithdrawPCIVersion | WhiteLabel | passthrough | nvarchar |
| Regulation | BackOffice.GetProcessedWithdrawPCIVersion | Regulation | passthrough | nvarchar |
| MIDName | BackOffice.GetProcessedWithdrawPCIVersion | MIDName | passthrough | nvarchar |
| MID | BackOffice.GetProcessedWithdrawPCIVersion | MID | passthrough | nvarchar |
| CustomerStatus | BackOffice.GetProcessedWithdrawPCIVersion | CustomerStatus | passthrough | nvarchar |
| CustomerLevel | BackOffice.GetProcessedWithdrawPCIVersion | CustomerLevel | passthrough | nvarchar |
| PaymentDetails | BackOffice.GetProcessedWithdrawPCIVersion | PaymentDetails | passthrough | nvarchar |
| PreparationType | BackOffice.GetProcessedWithdrawPCIVersion | PreparationType | passthrough | nvarchar |
| Executedby | BackOffice.GetProcessedWithdrawPCIVersion | Executedby | passthrough | nvarchar |
| ExecutionType | BackOffice.GetProcessedWithdrawPCIVersion | ExecutionType | passthrough | nvarchar |
| ModificationDateID | ETL from StatusModificationTime | - | ETL-computed | convert(int,convert(varchar,dateadd(day,datediff(day,0,StatusModificationTime),0),112)) -> YYYYMMDD |
| UpdateDate | ETL execution time | - | ETL-computed | getdate() |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 36 (all source columns) |
| **ETL-computed** | 2 (ModificationDateID, UpdateDate) |
| **Total** | 38 |
