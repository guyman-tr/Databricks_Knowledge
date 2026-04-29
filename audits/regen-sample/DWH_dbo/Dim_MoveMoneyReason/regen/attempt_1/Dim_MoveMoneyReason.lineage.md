# Lineage: DWH_dbo.Dim_MoveMoneyReason

## Source Objects

| # | Source Object | Source Type | Database | Relationship | Evidence |
|---|--------------|-------------|----------|--------------|----------|
| 1 | Dictionary.MoveMoneyReason | Table | etoro (etoroDB-REAL) | Primary production source | Generic Pipeline mapping #305, staging table DWH_staging.etoro_Dictionary_MoveMoneyReason |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | MoveMoneyReasonID | Dictionary.MoveMoneyReason | MoveMoneyReasonID | Passthrough | Tier 1 |
| 2 | MoveMoneyReason | Dictionary.MoveMoneyReason | MoveMoneyReason | Passthrough (varchar(30) in DWH vs varchar(30) in production, nvarchar(max) in staging) | Tier 1 |
| 3 | UpdateDate | — | — | ETL-added timestamp; not present in production source or staging table. Likely GETDATE() at load time. | Tier 2 |
