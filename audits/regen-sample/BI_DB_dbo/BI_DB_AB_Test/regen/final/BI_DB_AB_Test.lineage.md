# BI_DB_dbo.BI_DB_AB_Test — Lineage

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship | Evidence |
|---|---------------|------|--------|----------|--------------|----------|
| 1 | Unknown (manual load) | External | — | — | Writer | No SP found; table created via DS-1703; data loaded manually or via external process |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier | Confidence |
|---|------------|---------------|---------------|-----------|------|------------|
| 1 | DateID | Unknown (manual load) | — | None (integer date key, YYYYMMDD format) | Tier 3 | Grounded in DDL + data sample |
| 2 | Date | Unknown (manual load) | — | None (calendar date corresponding to DateID) | Tier 3 | Grounded in DDL + data sample |
| 3 | RealCID | Dim_Customer (local wiki) | RealCID | Passthrough — same customer identifier used across DWH | Tier 1 | Inherited from Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) |
| 4 | IsControl | Unknown (manual load) | — | None (binary flag: 0=treatment, 1=control) | Tier 3 | Grounded in DDL + data distribution |
| 5 | BI_Owner | Unknown (manual load) | — | None (person name, BI analyst who owns the test) | Tier 3 | Grounded in DDL + data sample |
| 6 | Business_Owner | Unknown (manual load) | — | None (person name, business stakeholder for the test) | Tier 3 | Grounded in DDL + data sample |
| 7 | Name | Unknown (manual load) | — | None (test identifier string) | Tier 3 | Grounded in DDL + data sample |
| 8 | UpdateDate | Unknown (manual load) | — | None (row insert/update timestamp) | Tier 3 | Grounded in DDL + data sample |
