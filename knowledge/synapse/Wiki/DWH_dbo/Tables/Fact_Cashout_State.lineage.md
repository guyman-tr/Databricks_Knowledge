# Column Lineage: DWH_dbo.Fact_Cashout_State

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_Cashout_State` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Billing.BI_Cashout_State_Report` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Fact_Cashout_State` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Billing.BI_Cashout_State_Report (etoroDB-REAL — custom BI report table)
  |
  v [Custom pipeline — daily, NOT in _generic_pipeline_mapping.json]
DWH_staging.etoro_Billing_BI_Cashout_State_Report
  |
  v [SP_Fact_Cashout_State — DELETE today + INSERT]
DWH_dbo.Fact_Cashout_State (9.95M rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | Billing.BI_Cashout_State_Report | CID | passthrough | Clustered index key |
| TransactionType | Billing.BI_Cashout_State_Report | TransactionType | passthrough | Withdrawal method label |
| PreviousStatus | Billing.BI_Cashout_State_Report | PreviousStatus | passthrough | Prior status for transition tracking |
| WithdrawID | Billing.BI_Cashout_State_Report | WithdrawID | passthrough | |
| WPID | Billing.BI_Cashout_State_Report | WPID | passthrough | Withdrawal payment processing ID |
| DepositID | Billing.BI_Cashout_State_Report | DepositID | passthrough | Linked deposit (refund/chargeback) |
| FundingID | Billing.BI_Cashout_State_Report | FundingID | passthrough | Payment instrument |
| DepotID | Billing.BI_Cashout_State_Report | DepotID | passthrough | Acquirer/gateway |
| CashoutStatusID | Billing.BI_Cashout_State_Report | CashoutStatusID | passthrough | Numeric status code |
| CashoutStatus | Billing.BI_Cashout_State_Report | CashoutStatus | passthrough | Denormalized status string |
| Amount | Billing.BI_Cashout_State_Report | Amount | passthrough | In CurrencyID |
| CurrencyID | Billing.BI_Cashout_State_Report | CurrencyID | passthrough | |
| AmountInUSD | Billing.BI_Cashout_State_Report | AmountInUSD | passthrough | Pre-computed USD equivalent |
| BaseExchangeRate | Billing.BI_Cashout_State_Report | BaseExchangeRate | passthrough | Rate before fee markup |
| ExchangeFee | Billing.BI_Cashout_State_Report | ExchangeFee | passthrough | Fee in basis points |
| ExchangeRate | Billing.BI_Cashout_State_Report | ExchangeRate | passthrough | Applied rate with markup |
| ExTransactionID | Billing.BI_Cashout_State_Report | ExTransactionID | passthrough | Provider transaction ID |
| ModificationDate | Billing.BI_Cashout_State_Report | ModificationDate | passthrough | datetime2(7) |
| RequestDate | Billing.BI_Cashout_State_Report | RequestDate | passthrough | datetime2(7) |
| ProtocolMIDSettingsID | Billing.BI_Cashout_State_Report | ProtocolMIDSettingsID | passthrough | MID config profile |
| MerchantAccountID | Billing.BI_Cashout_State_Report | MerchantAccountID | passthrough | Legal entity routing |
| PIPsInUSD | Billing.BI_Cashout_State_Report | PIPsInUSD | passthrough | Fee value in USD |
| ExchaFeeInPercentage | Billing.BI_Cashout_State_Report | ExchaFeeInPercentage | passthrough | Fee as % (note: typo in column name) |
| MID | Billing.BI_Cashout_State_Report | MID | passthrough | MID identifier string |
| MIDName | Billing.BI_Cashout_State_Report | MIDName | passthrough | MID display name |
| ModificationDateID | Billing.BI_Cashout_State_Report | ModificationDate | ETL-computed | CONVERT(INT, ModificationDate) → YYYYMMDD |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |
| CreditID | Billing.BI_Cashout_State_Report | CreditID | passthrough | Added 2025-08-13 by guym |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 26 |
| **ETL-computed** | 2 |
| **Total** | 28 |

*Note: DDL shows 30 columns but CashoutStatus (denormalized string) + ModificationDate/RequestDate are counted separately above. Verify exact source column count matches 30 DDL columns.*
