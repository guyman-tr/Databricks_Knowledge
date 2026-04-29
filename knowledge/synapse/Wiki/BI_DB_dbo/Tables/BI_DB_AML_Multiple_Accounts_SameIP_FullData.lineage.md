# Lineage — BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP_FullData

## Source Objects

| Source Object | Schema | Alias | Role |
|--------------|--------|-------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | dc | Customer master — provides RealCID (→ CID) and IP address for same-IP grouping |
| BI_DB_dbo.SP_AML_Multiple_Accounts | BI_DB_dbo | — | Writer SP: Steps 7-8 compute same-IP clusters, Step 17 TRUNCATE+INSERT |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (renamed RealCID → CID) | Tier 1 — Customer.CustomerStatic |
| HashIP | DWH_dbo.Dim_Customer | IP | CHECKSUM(IP) — integer hash of registration IP for privacy-safe grouping | Tier 2 — SP_AML_Multiple_Accounts |
| UpdateDate | — | — | GETDATE() at SP execution time | Tier 2 — SP_AML_Multiple_Accounts |
