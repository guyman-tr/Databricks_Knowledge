# Column Lineage: DWH_dbo.CustomerStatic

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.CustomerStatic` |
| **UC Target** | `pii_data.bronze_etoro_customer_customerstatic` (source) / DWH target not determined |
| **Primary Source** | `Customer.CustomerStatic` (`etoro`) |
| **ETL SP** | None - no SP writes to this table |
| **Secondary Sources** | None identified |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
etoro.Customer.CustomerStatic (etoroDB-REAL, 18.7M rows)
  |
  v [Generic Pipeline - daily, Override, 1440 min]
Bronze/etoro/Customer/CustomerStatic/
  |
  v [lake staging]
DWH_staging.etoro_Customer_CustomerStatic (85 columns)
  |
  v [NO SP IMPLEMENTED]
DWH_dbo.CustomerStatic (0 rows - ABANDONED)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **cast/convert** | Type conversion only. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **unknown** | Source not determinable - table has 0 rows, no ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | Customer.CustomerStatic | CID | passthrough | Primary customer identifier |
| Registered | Customer.CustomerStatic | Registered | passthrough | Registration datetime, NOT NULL |
| IsReal | Customer.CustomerStatic | IsReal | cast/convert | bit (prod) -> tinyint (DWH) |
| ActionTypeID | - | - | unknown | Not in Customer.CustomerStatic; likely intended join from action event |
| PlatformTypeID | - | - | unknown | Not in Customer.CustomerStatic; DWH-specific |
| Amount | - | - | unknown | Not in Customer.CustomerStatic; purpose undetermined |
| DateID | Customer.CustomerStatic | Registered | ETL-computed | CONVERT(INT, CONVERT(VARCHAR, Registered, 112)) - YYYYMMDD integer |
| TimeID | Customer.CustomerStatic | Registered | ETL-computed | DATEPART(HOUR, Registered) - hour 0-23 |
| StatusID | - | - | unknown | Not in Customer.CustomerStatic with this name; likely AccountStatusID or PlayerStatusID |
| PlatformID | Customer.CustomerStatic | PlatformID | passthrough | 0=Undefined, 1=Web, 2=IOS, 3=Android |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Cast/Convert** | 1 |
| **ETL-computed** | 2 |
| **Unknown (no ETL)** | 4 |
| **Total** | 10 |

**Note**: This table has 0 rows and no active ETL writer. The lineage above represents the INTENDED design inferred from column names, DDL structure, and related SP patterns. Actual data flow was never implemented.
