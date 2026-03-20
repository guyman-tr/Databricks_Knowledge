# Column Lineage: DWH_dbo.Fact_BillingRedeem

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_BillingRedeem` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `Billing.Redeem` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Fact_BillingRedeem_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Billing.Redeem (etoroDB-REAL)
  |
  v [Generic Pipeline — hourly, 60 min, Override, parquet]
Bronze/etoro/Billing/Redeem/
  |
  v [staging]
DWH_staging.etoro_Billing_Redeem
  |
  v [SP_Fact_BillingRedeem_DL_To_Synapse — 7-day rolling window]
    Step 1: DELETE Ext_FBR (7-day window)
    Step 2: INSERT Ext_FBR from staging
    Step 3: DELETE Fact_BillingRedeem (7-day window)
    Step 4: INSERT Fact_BillingRedeem from Ext_FBR
DWH_dbo.Fact_BillingRedeem (1.4M rows)
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
| CID | Billing.Redeem | CID | passthrough | Customer ID |
| RedeemID | Billing.Redeem | RedeemID | passthrough | Distribution key (HASH) |
| PositionID | Billing.Redeem | PositionID | passthrough | bigint — large position ID space |
| RedeemStatusID | Billing.Redeem | RedeemStatusID | passthrough | FK to Dim_RedeemStatus |
| RedeemReasonID | Billing.Redeem | RedeemReasonID | passthrough | NULL = no reason recorded |
| AmountOnRequest | Billing.Redeem | AmountOnRequest | passthrough | Position value at request time |
| AmountOnClose | Billing.Redeem | AmountOnClose | passthrough | Actual settlement amount |
| FundingID | Billing.Redeem | FundingID | passthrough | Payment instrument for payout |
| RequestDate | Billing.Redeem | RequestDate | passthrough | Redeem submission datetime |
| LastModificationDate | Billing.Redeem | LastModificationDate | passthrough | Last modification datetime |
| ModificationDateID | Billing.Redeem | LastModificationDate | ETL-computed | CONVERT(INT, LastModificationDate) → YYYYMMDD |
| UpdateDate | — | — | ETL-computed | GETDATE() at SP execution time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 10 |
| **ETL-computed** | 2 |
| **Total** | 12 |
