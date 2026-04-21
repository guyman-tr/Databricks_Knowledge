# EXW_dbo.EXW_TestUsers — Column Lineage

Generated: 2026-04-20 | Pipeline: DWH Semantic Doc Phase 10B

## ETL Summary

| Property | Value |
|----------|-------|
| **Synapse Target** | EXW_dbo.EXW_TestUsers |
| **Writer SP** | EXW_dbo.SP_EXW_TestUsers |
| **ETL Type** | Incremental merge — INSERT new + UPDATE changed + DELETE duplicates |
| **Production Source** | DWH_dbo.Dim_Customer (relay) → etoro.Customer.CustomerStatic (origin) |
| **Refresh Pattern** | Periodic refresh; UpdateDate range 2020-09-29 to 2026-03-20 |
| **UC Target** | _Not_Migrated |

## Column Lineage

| # | Synapse Column | Source Type | Source Table | Source Column | Transform | Confidence Tier |
|---|---------------|-------------|--------------|---------------|-----------|-----------------|
| 1 | RealCID | Passthrough | DWH_dbo.Dim_Customer | RealCID | Direct passthrough; filtered to test users only | Tier 1 — Customer.CustomerStatic |
| 2 | GCID | Passthrough | DWH_dbo.Dim_Customer | GCID | Direct passthrough; HASH distribution key | Tier 1 — Customer.CustomerStatic |
| 3 | UserName | Passthrough | DWH_dbo.Dim_Customer | UserName | Direct passthrough; no transformation | Tier 1 — Customer.CustomerStatic |
| 4 | Email | Passthrough | DWH_dbo.Dim_Customer | Email | Direct passthrough; no transformation | Tier 1 — Customer.CustomerStatic |
| 5 | UpdateDate | Computed | — | — | GETDATE() at INSERT time; refreshed on UPDATE when UserName or Email changes | Tier 2 — SP_EXW_TestUsers |

## Source Objects

| Source | Object | Role |
|--------|--------|------|
| DWH_dbo.Dim_Customer | Primary source of all customer attributes; filtered to test users by username pattern / email / PlayerLevelID | Writer source |

## Filter Logic (SP_EXW_TestUsers)

```sql
-- Test user identification criteria (UNION of two sets):
-- Set A: username pattern matching
WHERE LOWER(UserName) LIKE '%redeemprod%'
   OR LOWER(UserName) LIKE '%betatester%'
   OR LOWER(UserName) LIKE '%walletprod%'
   OR LOWER(UserName) LIKE '%internalprod%'
   OR LOWER(UserName) LIKE '%nowalletprod'
   OR UserName = 'RonaMaltz'
   OR UserName = 'DanGanon'
   OR GCID = 43163939

-- Set B: Beta users
WHERE LOWER(Email) LIKE '%test@test.com%'
  AND PlayerLevelID = 4
```

## Consumers (Downstream)

| SP / Object | Usage |
|-------------|-------|
| EXW_dbo.SP_DimUser | LEFT JOIN on GCID to flag test users in EXW_DimUser (IsTestAccount column) |
