# Column Lineage: DWH_dbo.Dim_BillingDepot

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_BillingDepot` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Billing.Depot` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Billing.Depot (etoroDB-REAL, 163 rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min, parquet]
Bronze/etoro/Billing/Depot/
  |
  v [staging]
DWH_staging.etoro_Billing_Depot
  |
  v [SP_Dictionaries_DL_To_Synapse - TRUNCATE + INSERT]
DWH_dbo.Dim_BillingDepot (163 rows)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **excluded** | Column exists in production source but not loaded into DWH. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DepotID | Billing.Depot | DepotID | passthrough | Primary key |
| FundingTypeID | Billing.Depot | FundingTypeID | passthrough | Payment method type |
| PaymentTypeID | Billing.Depot | PaymentTypeID | passthrough | 1=Deposit, 2=Cashout, 3=Refund |
| ProtocolID | Billing.Depot | ProtocolID | passthrough | Gateway protocol |
| Name | Billing.Depot | Name | passthrough | Unique depot name |
| IsActive | Billing.Depot | IsActive | passthrough | bit, NULL treated as inactive |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time |
| *(not in DWH)* | Billing.Depot | PayoutGeneration | excluded | Automated payout file generation flag -- excluded from DWH ETL |
| *(not in DWH)* | Billing.Depot | Features | excluded | Per-depot JSON/XML configuration -- excluded from DWH ETL |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 6 |
| **ETL-computed** | 1 |
| **Excluded (not loaded)** | 2 |
| **Total (DWH columns)** | 7 |
