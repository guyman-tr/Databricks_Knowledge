# Review Sidecar: BI_DB_dbo.BI_DB_UsageTracking_SF

## Verification Status

| Item | Status | Notes |
|------|--------|-------|
| Data source | Verified via SP code | ADLS Gold/CRM/UsageTracking parquet, originated from Salesforce |
| Full refresh pattern | Verified | TRUNCATE + INSERT, no date param |
| CreatedByManagerID duplication | Verified | = ManagerID in INSERT statement |
| CreatedDate dedup | Verified | MIN(CreatedDate) with GROUP BY all other columns |

## Unverified Items

| Column | Tier | Issue |
|--------|------|-------|
| ID | T4 | Not in INSERT — assumed IDENTITY but DDL shows no IDENTITY keyword |
| ManagerID | T4 | Source of internal manager ID mapping unknown — may come from DLT-CRM pipeline enrichment |
| ActionName values | T4 | No enumeration of valid ActionName values available without live data |

## Quality Notes

- 17+ consumer SPs — very high downstream impact table
- ActionName truncation risk (200→50 chars) — may cause data loss
- Synapse MCP unavailable — no live data sampling performed
