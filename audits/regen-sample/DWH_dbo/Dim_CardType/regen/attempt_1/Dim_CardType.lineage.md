# Lineage: DWH_dbo.Dim_CardType

## Source Objects

| # | Source Object | Source Type | Relationship | Database | Evidence |
|---|--------------|-------------|--------------|----------|----------|
| 1 | Dictionary.CardType | Production Table | Primary source — all card type data originates here | etoro (production) | Migration staging table DWH_Migration.Dim_CardType; upstream wiki at DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CardType.md |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CardTypeID | Dictionary.CardType | CardTypeID | Passthrough (int → int) | Tier 1 |
| 2 | CarTypeName | Dictionary.CardType | Name | Rename (Name → CarTypeName), type preserved varchar(50) | Tier 1 |
| 3 | IsActive | Dictionary.CardType | IsActive | Passthrough, type widened (bit → int) | Tier 1 |
| 4 | UpdateDate | — | — | ETL-added metadata timestamp (getdate() at migration load time) | Tier 2 |
