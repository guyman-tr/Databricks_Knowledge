# Review Needed: BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide

## Items for Human Review

### 1. Data Freshness — Table Appears Stale
- **Issue**: Latest data is 2024-04-14. The table has not been refreshed in over 2 years based on live sampling.
- **Action needed**: Confirm whether this SP is still scheduled in production. The SP may have been decommissioned or replaced by a different dashboard pipeline.

### 2. Past_Year_Commission Hardcoded Date
- **Issue**: The SP's `#Past_Year_Commission` calculation uses `WHERE ptc1.Date = '2021-03-14'` — a hardcoded date filter that appears to be a bug or legacy artifact. This means Past_Year_Commission may not be computing correctly for dates far from 2021-03-14.
- **Action needed**: Confirm with the BI team whether this is intentional or a leftover from development.

### 3. DMV Permission Denied
- **Issue**: `sys.dm_pdw_nodes_db_partition_stats` query failed with permission error. Row count estimated from date range (1,501 dates x ~3,400 rows = ~5.1M total rows).
- **Impact**: Row count in the wiki is an estimate.

### 4. Unresolved Upstream Wikis
The following source tables do not have wikis and their columns are documented as Tier 2:
- `BI_DB_dbo.BI_DB_PI_Positions` — incremental position shadow cache
- `BI_DB_dbo.BI_DB_PI_GainDaily` — incremental gain shadow cache
- `BI_DB_dbo.BI_DB_PI_WeeklyTrades` — incremental weekly trades cache
- `BI_DB_dbo.BI_DB_PI_Dashboard` — prior version of PI dashboard (used for rolling commission)
- `BI_DB_dbo.External_etoro_Internal_RiskScore` — risk band mapping table
- `BI_DB_dbo.External_etoro_Customer_BlockedCustomerOperations` — blocked PI operations
- `general.etoroGeneral_History_GuruCopiers` — active copier detection

### 5. Desk Column Tier
- **Issue**: `Desk` in Dim_Country is sourced from `Ext_Dim_Country_Region_Desk` (Tier 3 in Dim_Country wiki). Documented as Tier 2 here since it passes through from a non-Tier-1 source. Could arguably be Tier 3.

### 6. Column Count Verified
- **Note**: DDL has 32 columns. Elements table has 32 rows. Parity confirmed.
