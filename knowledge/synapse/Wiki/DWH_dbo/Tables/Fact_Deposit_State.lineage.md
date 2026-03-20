# Lineage: DWH_dbo.Fact_Deposit_State

> Column-level lineage from Billing BI staging source to DWH Synapse table.

## Source Chain

```
eToro Billing System
  -> DWH_staging.etoro_Billing_BI_Deposit_State_Report
  -> SP_Fact_Deposit_State(@dt)
  -> DWH_dbo.Fact_Deposit_State
```

## Generic Pipeline Mapping

Not found in _generic_pipeline_mapping.json. Custom Billing pipeline.

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Notes |
|---|-----------|---------------|---------------|-----------|-------|
| 1 | CreditID | etoro_Billing_BI_Deposit_State_Report | CreditID | Passthrough | bigint |
| 2 | FromDate | etoro_Billing_BI_Deposit_State_Report | FromDate | Passthrough | datetime2(7) - day window start |
| 3 | EndDate | etoro_Billing_BI_Deposit_State_Report | EndDate | Passthrough | datetime2(7) - day window end |
| 4 | CID | etoro_Billing_BI_Deposit_State_Report | CID | Passthrough | Customer ID |
| 5 | CurrencyID | etoro_Billing_BI_Deposit_State_Report | CurrencyID | Passthrough | FK to Dim_Currency |
| 6 | DepositID | etoro_Billing_BI_Deposit_State_Report | DepositID | Passthrough | Business key |
| 7 | DepotID | etoro_Billing_BI_Deposit_State_Report | DepotID | Passthrough | FK to Dim_BillingDepot |
| 8 | FundingID | etoro_Billing_BI_Deposit_State_Report | FundingID | Passthrough | |
| 9 | PaymentStatusID | etoro_Billing_BI_Deposit_State_Report | PaymentStatusID | Passthrough | FK to Dim_PaymentStatus |
| 10 | CardType | etoro_Billing_BI_Deposit_State_Report | CardType | Passthrough | |
| 11 | CardCategory | etoro_Billing_BI_Deposit_State_Report | CardCategory | Passthrough | |
| 12 | MID | etoro_Billing_BI_Deposit_State_Report | MID | Passthrough | Merchant ID code |
| 13 | MIDName | etoro_Billing_BI_Deposit_State_Report | MIDName | Passthrough | |
| 14 | BaseExchangeRate | etoro_Billing_BI_Deposit_State_Report | BaseExchangeRate | Passthrough | Pre-fee rate |
| 15 | ExchangeFee | etoro_Billing_BI_Deposit_State_Report | ExchangeFee | Passthrough | [UNVERIFIED] bps or code |
| 16 | ExchangeRate | etoro_Billing_BI_Deposit_State_Report | ExchangeRate | Passthrough | Post-fee rate |
| 17 | ModificationDate | etoro_Billing_BI_Deposit_State_Report | ModificationDate | Passthrough | ETL window key |
| 18 | AmountInUSD | etoro_Billing_BI_Deposit_State_Report | AmountInUSD | Passthrough | |
| 19 | Amount | etoro_Billing_BI_Deposit_State_Report | Amount | Passthrough | In CurrencyID currency |
| 20 | ProtocolMIDSettingsID | etoro_Billing_BI_Deposit_State_Report | ProtocolMIDSettingsID | Passthrough | FK to Dim_BillingProtocolMIDSettingsID |
| 21 | MerchantAccountID | etoro_Billing_BI_Deposit_State_Report | MerchantAccountID | Passthrough | |
| 22 | ExTransactionID | etoro_Billing_BI_Deposit_State_Report | ExTransactionID | Passthrough | External txn ID |
| 23 | DepositStatus | etoro_Billing_BI_Deposit_State_Report | DepositStatus | Passthrough | 7 values |
| 24 | PreviousStatus | etoro_Billing_BI_Deposit_State_Report | PreviousStatus | Passthrough | State before modification |
| 25 | TransactionType | etoro_Billing_BI_Deposit_State_Report | TransactionType | Passthrough | 10 values |
| 26 | PIPsInUSD | etoro_Billing_BI_Deposit_State_Report | PIPsInUSD | Passthrough | [UNVERIFIED] purpose |
| 27 | FeeInPercentage | etoro_Billing_BI_Deposit_State_Report | FeeInPercentage | Passthrough | Fee % |
| 28 | ModificationDateID | ETL-computed | ModificationDate | CONVERT(INT,CONVERT(VARCHAR,DATEADD(DAY,DATEDIFF(DAY,0,ModificationDate),0),112)) | YYYYMMDD int |
| 29 | UpdateDate | ETL-computed | N/A | GETDATE() | ETL load timestamp |

## Upstream Wiki

No upstream wiki available. DWH_staging.etoro_Billing_BI_Deposit_State_Report is a custom Billing BI staging view, not documented in DB_Schema etoro wiki.
