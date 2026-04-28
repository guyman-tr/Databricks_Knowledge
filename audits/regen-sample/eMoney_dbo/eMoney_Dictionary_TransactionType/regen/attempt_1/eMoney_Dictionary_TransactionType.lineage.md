# Lineage — eMoney_dbo.eMoney_Dictionary_TransactionType

## Source Objects

| # | Source Object | Type | Relationship | Evidence |
|---|--------------|------|-------------|----------|
| 1 | FiatDwhDB.Dictionary.TransactionTypes | Production Table | Primary source (Generic Pipeline Bronze export) | Generic Pipeline mapping ID 524; DDL column alignment; live data 15 rows match upstream |

## Column Lineage

| # | Synapse Column | Source Object | Source Column | Transform | Tier |
|---|---------------|--------------|---------------|-----------|------|
| 1 | TransactionTypeID | FiatDwhDB.Dictionary.TransactionTypes | Id | Rename Id→TransactionTypeID; type widen tinyint→int | Tier 1 |
| 2 | TransactionType | FiatDwhDB.Dictionary.TransactionTypes | Name | Rename Name→TransactionType; type narrow nvarchar(32-50)→varchar(50) | Tier 1 |
| 3 | UpdateDate | Generic Pipeline ETL | — | ETL metadata timestamp; populated by Generic Pipeline load process | Tier 2 |
