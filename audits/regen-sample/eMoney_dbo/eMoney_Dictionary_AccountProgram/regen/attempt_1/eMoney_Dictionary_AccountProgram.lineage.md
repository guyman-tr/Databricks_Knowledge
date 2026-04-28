# Lineage: eMoney_dbo.eMoney_Dictionary_AccountProgram

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object** | eMoney_Dictionary_AccountProgram |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB.Dictionary.AccountPrograms (prod-banking-fiat) |
| **ETL Pattern** | Generic Pipeline (Override, daily) |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram |

---

## Source Objects

| # | Source Object | Source Type | Database | Schema | Relationship |
|---|-------------|------------|----------|--------|-------------|
| 1 | Dictionary.AccountPrograms | Table | FiatDwhDB | Dictionary | Production source (prod-banking-fiat) |
| 2 | External_FiatDwhDB_Dictionary_AccountPrograms | External Table | Synapse | eMoney_dbo | Lake-to-Synapse bridge |
| 3 | CopyFromLake.FiatDwhDB_Dictionary_AccountPrograms | Staging Table | Synapse | CopyFromLake | Staging layer |

---

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|--------------|-----------|------|
| 1 | AccountProgramID | Dictionary.AccountPrograms | Id | Rename (Id → AccountProgramID), type widened tinyint → int | Tier 1 |
| 2 | AccountProgram | Dictionary.AccountPrograms | Name | Rename (Name → AccountProgram), type narrowed nvarchar → varchar(50) | Tier 1 |
| 3 | UpdateDate | CopyFromLake.FiatDwhDB_Dictionary_AccountPrograms | SynapseUpdateDate | ETL-managed timestamp (SynapseUpdateDate → UpdateDate) | Tier 2 |

---

## ETL Pipeline

```
FiatDwhDB.Dictionary.AccountPrograms (prod-banking-fiat)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze/FiatDwhDB/Dictionary/AccountPrograms (Parquet, Data Lake)
  |-- External Table bridge ---|
  v
eMoney_dbo.External_FiatDwhDB_Dictionary_AccountPrograms
  |-- CopyFromLake load ---|
  v
CopyFromLake.FiatDwhDB_Dictionary_AccountPrograms
  |-- Migration / load ---|
  v
eMoney_dbo.eMoney_Dictionary_AccountProgram (3 rows, REPLICATE)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram
```

---

*Generated: 2026-04-27 | Object: eMoney_dbo.eMoney_Dictionary_AccountProgram*
