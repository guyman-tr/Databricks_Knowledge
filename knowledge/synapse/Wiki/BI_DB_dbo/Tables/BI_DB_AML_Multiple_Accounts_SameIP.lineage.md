# Lineage: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_SameIP

## Source Objects

| Source Object | Schema | Alias | Role |
|---------------|--------|-------|------|
| DWH_dbo.Dim_Customer | DWH_dbo | dc | Source of IP addresses and customer validity filters (IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|---------------|---------------|-----------|------|
| NumOfClientsSameIP | DWH_dbo.Dim_Customer | RealCID | COUNT(DISTINCT dc.RealCID) grouped by IP, HAVING count > 1 | Tier 2 — SP_AML_Multiple_Accounts |
| IP | DWH_dbo.Dim_Customer | IP | Passthrough (GROUP BY key); filtered to IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3 | Tier 1 — Customer.CustomerStatic |
| UpdateDate | — | — | GETDATE() at SP execution time | Tier 2 — SP_AML_Multiple_Accounts |
