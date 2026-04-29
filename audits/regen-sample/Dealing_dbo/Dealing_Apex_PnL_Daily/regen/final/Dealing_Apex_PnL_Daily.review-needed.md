# Review Needed — Dealing_dbo.Dealing_Apex_PnL_Daily

## Summary

All 21 columns are Tier 2 (SP code / DDL). This table's columns are entirely ETL-computed from external Apex LP staging files and internal price/instrument sources — no production upstream wiki exists for the Apex LP staging tables themselves.

## Items for Human Review

### 1. Stale Pipeline — Confirm Operational Status
- **Issue**: Last data load was 2024-06-08. The Apex LP pipeline has been dormant for ~2 years.
- **Action**: Confirm with Middle Office / Dealing whether Apex Clearing remains the active US equities LP, or if the pipeline has been permanently decommissioned.

### 2. AccountNumber → HedgeServerID Mapping
- **Issue**: The SP contains a hardcoded mapping (3EU05026→9, 3EU05025→112, 3EU05027→102, 3EU00101→223, 3EU05028→3). If a new Apex account is onboarded, the SP must be manually updated.
- **Action**: Verify this mapping is still current and complete.

### 3. NULL InstrumentID Coverage
- **Issue**: ~497 rows on the last loaded date (2024-06-07) have NULL InstrumentID — Apex symbols that could not be matched to `Dim_Instrument`.
- **Action**: Review whether these represent delisted instruments, ADRs, or gaps in the eToro instrument dimension that should be addressed.

### 4. No Downstream Consumers Identified
- **Issue**: No views, SPs, or tables were found that read from this table. It may be a terminal reporting artifact.
- **Action**: Confirm whether any dashboards or reports consume this data directly (e.g., via direct SQL queries from BI tools).

### 5. UC Target Pending
- **Issue**: No Unity Catalog target has been configured for this table.
- **Action**: Determine if migration to UC is planned given the stale status of the pipeline.

---

*Generated: 2026-04-28 | Regen harness attempt 1*
