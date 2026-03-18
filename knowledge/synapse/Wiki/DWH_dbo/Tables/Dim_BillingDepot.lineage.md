# Lineage — DWH_dbo.Dim_BillingDepot

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Billing.Depot` |
| **Source Server** | etoroDB-REAL |
| **Generic Pipeline ID** | 634 |
| **Copy Strategy** | Override |
| **Frequency** | Every 60 minutes |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| DepotID | Billing.Depot.DepotID | Passthrough |
| FundingTypeID | Billing.Depot.FundingTypeID | Passthrough |
| PaymentTypeID | Billing.Depot.PaymentTypeID | Passthrough |
| ProtocolID | Billing.Depot.ProtocolID | Passthrough |
| Name | Billing.Depot.Name | Passthrough |
| IsActive | Billing.Depot.IsActive | Passthrough |
| UpdateDate | — | ETL-generated: `GETDATE()` at load time |

## Columns Pruned from Source

| Production Column | Type | Reason |
|-------------------|------|--------|
| PayoutGeneration | int | Operational flag — not needed for analytics |
| Features | nvarchar(4000) | Gateway-specific configuration — not needed for analytics |

## ETL Chain

```
etoro.Billing.Depot (etoroDB-REAL)
  → Generic Pipeline (ID 634, hourly, Override)
    → DWH_staging.etoro_Billing_Depot
      → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
        → DWH_dbo.Dim_BillingDepot
```

---

*Generated: 2026-03-18*
