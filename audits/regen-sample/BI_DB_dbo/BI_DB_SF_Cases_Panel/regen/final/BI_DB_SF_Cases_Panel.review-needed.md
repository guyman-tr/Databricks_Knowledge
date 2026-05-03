# BI_DB_dbo.BI_DB_SF_Cases_Panel — Review Needed

## Summary

All 83 columns are Tier 3 — no upstream wiki was found and the writer SP (SP_SF_Cases) is not present in the SSDT repository. Column descriptions are grounded in DDL column names, data types, and live data sample evidence.

## Items Requiring Human Review

### 1. Writer SP Missing from SSDT

- **SP_SF_Cases** is registered in OpsDB as the writer SP for this table (ProcessType=SQL, ProcessName=COPY DATA) but its `.sql` file does not exist in the DataPlatform SSDT repository.
- **Action needed**: Locate the SP_SF_Cases source code (may be in a Salesforce ETL pipeline, Azure Data Factory, or external system) to enable Tier 2 column tracing.

### 2. Table Appears Dormant

- Max `CreatedDate` is 2024-04-07; max `UpdateDate` is 2024-04-08.
- **Action needed**: Confirm whether this table is still actively loaded or has been superseded. There is also a `BI_DB_Migration.JUNK_BI_DB_SF_Cases_Panel` migration table suggesting possible deprecation.

### 3. Column Name Typos and Inconsistencies

- `NumberOfTocuhes` — should be "NumberOfTouches" (typo preserved from source).
- `IsVisitor_Atopen`, `ActiveAgentID_Atopen`, `Owner_Atopen` — mixed casing `_Atopen` vs `_AtOpen` used by all other snapshot columns.
- `IsKYcMonitoring` — mixed casing `KYc` instead of `KYC`.
- **Action needed**: Determine if these are intentional (matching Salesforce field names) or bugs to be corrected in a future ALTER.

### 4. IsTechnicalRefund and IsGoodwill Type Mismatch

- These boolean-semantic columns are `numeric(18,0)` instead of `bit` like all other `Is*` flags.
- **Action needed**: Confirm whether these columns carry values beyond 0/1 or if the type should be standardized to `bit`.

### 5. CID_Last Without CID_AtOpen

- Customer ID is only captured in the `_Last` snapshot. There is no `CID_AtOpen` column.
- **Action needed**: Confirm whether CID at case open is intentionally omitted or available in a different field (e.g., tied to HistoryID_AtOpen).

### 6. FK Targets Not Resolved

- `VerificationLevelID_AtOpen` / `VerificationLevelID_Last` — no matching Dim or Dictionary table found in SSDT.
- `AccountManagerID_AtOpen` / `AccountManagerID_Last` — likely FK to an internal manager table but no match found.
- **Action needed**: Identify the lookup tables for these ID columns.

### 7. CSAT Score Scale Unknown

- `FirstCSAT` and `LastCSAT` are integer columns. The CSAT scale (1-5, 1-10, NPS-style, etc.) cannot be determined from DDL alone.
- **Action needed**: Confirm the CSAT score scale from the Salesforce survey configuration.

### 8. TotalTimeSpent Units Unknown

- `TotalTimeSpent` is `numeric(18,0)`. Unit (seconds, minutes, or other) is not determinable from the DDL. Sample data shows mostly 0 values.
- **Action needed**: Confirm the unit of measurement from the Salesforce case configuration.
