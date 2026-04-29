# Lineage — DWH_dbo.Dim_ContractType

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|--------------|------|--------|----------|--------------|
| 1 | DWH_Migration.Dim_ContractType | Table | DWH_Migration | sql_dp_prod_we | Migration load (static) |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|--------------|-----------|------|
| 1 | ContractTypeID | DWH_Migration.Dim_ContractType | ContractTypeID | Passthrough | Tier 3 |
| 2 | Name | DWH_Migration.Dim_ContractType | Name | Passthrough | Tier 3 |
| 3 | InsertDate | DWH_Migration.Dim_ContractType | InsertDate | Passthrough | Tier 3 |
| 4 | UpdateDate | DWH_Migration.Dim_ContractType | UpdateDate | Passthrough | Tier 3 |

## Notes

- No dedicated writer SP exists for this table. Data was loaded via a one-time migration from `DWH_Migration.Dim_ContractType`.
- No upstream production wiki was found. All columns are Tier 3 — grounded in DDL structure, live data sample, and SP_Dim_Affiliate usage context.
- The table serves as a static lookup for affiliate contract types, referenced by `Dim_Affiliate.ContractType` and resolved in `SP_Marketing_Cube`.
