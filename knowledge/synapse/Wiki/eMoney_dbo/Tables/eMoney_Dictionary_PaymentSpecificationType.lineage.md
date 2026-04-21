# Column Lineage: eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.PaymentSpecificationTypes |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype |
| **Row Count (live)** | 2 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | PaymentSpecificationTypeID | int NULL | FiatDwhDB.Dictionary.PaymentSpecificationTypes | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | PaymentSpecificationType | varchar(50) NULL | FiatDwhDB.Dictionary.PaymentSpecificationTypes | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.PaymentSpecificationTypes (source — 2 rows: 0=Unknown, 1=DirectDebit)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/PaymentSpecificationTypes/)
  |-- External Table: External_FiatDwhDB_Dictionary_PaymentSpecificationTypes ---|
  v
eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType (2 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | PaymentSpecificationTypeID, PaymentSpecificationType |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
