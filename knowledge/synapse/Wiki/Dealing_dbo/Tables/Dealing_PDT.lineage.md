# Column Lineage: Dealing_dbo.Dealing_PDT

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_PDT` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `ExternalOperations.Trade.PdtOperations` (production) |
| **ETL SP** | `SP_PDT` |
| **Secondary Sources** | `ExternalOperations.Dictionary.PdtStatus`, `etoro.Customer.CustomerStatic` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
ExternalOperations.Trade.PdtOperations ─┐
ExternalOperations.Dictionary.PdtStatus ┼──► Dealing_staging ──► SP_PDT ──► Dealing_PDT
etoro.Customer.CustomerStatic ──────────┘
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | DWH_dbo.Dim_Date | FullDate | ETL-computed | LEFT JOIN ensures row exists even with no PDT data | Report date |
| RoundTripsCounter | PdtOperations | TotalRoundTrips | passthrough | WHERE TotalRoundTrips >= 3 | Round trip count (3+ only) |
| CID | PdtOperations | Cid | passthrough | — | Customer ID |
| ApexID | CustomerStatic | ApexID | join-enriched | Via CID join to etoro_Customer_CustomerStatic | Apex clearing broker ID |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |
| Status | PdtStatus dictionary | Name | join-enriched | Via PdtStatusId. Filtered: Name <> 'OK'. | PDT status label |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 2 |
| **Join-enriched** | 2 |
| **Total** | 6 |
