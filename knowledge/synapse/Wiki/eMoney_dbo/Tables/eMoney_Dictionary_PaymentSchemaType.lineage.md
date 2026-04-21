# Column Lineage: eMoney_dbo.eMoney_Dictionary_PaymentSchemaType

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Dictionary_PaymentSchemaType |
| **Source System** | FiatDwhDB |
| **Source Object** | FiatDwhDB.Dictionary.PaymentSchemaType |
| **ETL Pattern** | Generic Pipeline Bronze export (no writer SP) |
| **Writer SP** | None — Generic Pipeline |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype |
| **Row Count (live)** | 8 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | PaymentSchemaTypeID | int NULL | FiatDwhDB.Dictionary.PaymentSchemaType | Id (tinyint NOT NULL) | Rename + type widen (tinyint→int); passthrough value | Tier 1 |
| 2 | PaymentSchemaType | varchar(50) NULL | FiatDwhDB.Dictionary.PaymentSchemaType | Name (nvarchar) | Rename + type narrow (nvarchar→varchar); passthrough value | Tier 1 |
| 3 | UpdateDate | datetime NULL | ETL metadata | — | Timestamp of Generic Pipeline ETL load | Tier 2 |

## ETL Pipeline

```
FiatDwhDB.Dictionary.PaymentSchemaType (source — 8 rows: 0=Unknown through 7=SEPAdirectDebit)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze parquet (ADLS Gen2: Bronze/FiatDwhDB/Dictionary/PaymentSchemaType/)
  |-- External Table: External_FiatDwhDB_Dictionary_PaymentSchemaType ---|
  v
eMoney_dbo.eMoney_Dictionary_PaymentSchemaType (8 rows, REPLICATE, HEAP)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | PaymentSchemaTypeID, PaymentSchemaType |
| Tier 2 | 1 | UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 3 | |

*Generated: 2026-04-21 | Phase 10B*
