# Review Notes — BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert

Generated: 2026-04-23 | Batch: 65 | Phase 16 Score: 8.0 / 10

## Status: PASS — alert table fully documented; column types need verification

---

## Items Requiring Human Review

### 1. Column Data Types for CBZero, TreesizeZero, PercentDiff
- **Issue**: The DDL for `BI_DB_CBZero_TreesizeZero_Alert` was read and shows columns `DateID`, `CBZero`, `TreesizeZero`, `PercentDiff` but the exact data types (decimal(18,2)? float? bigint?) were not confirmed from the DDL read in this session. The Elements table uses "decimal or float" as a placeholder.
- **Action**: Read `DB_Schema/BI_DB_dbo/Tables/BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert.sql` to confirm exact column types and update Section 4.
- **Severity**: Medium — affects type-safe usage in queries.

### 2. Source Table Aggregation Logic Not Confirmed
- **Issue**: The wiki documents that CBZero is aggregated from `BI_DB_Client_Balance_CID_Level_New` and TreesizeZero from `BI_DB_DailyZero_TreeSize_NEW`. The exact aggregation expressions (SUM of which column) were read from SP code but the exact column names in the source tables were not fully verified.
- **Action**: Verify source column names in the SP: `SP_Client_Balance_and_DailyZero_TreeSize_Alert`.
- **Severity**: Low — pipeline direction is correct; exact column mapping could be more precise.

### 3. Alert History Not Available
- **Issue**: The TRUNCATE pattern means no historical alerts are stored. If the team needs to investigate past alert days, they would need to use the SP's source tables or a monitoring log outside of this table.
- **Action**: Consider whether a history-preserving variant (using date-keyed INSERT without TRUNCATE) would be more useful for monitoring purposes. This is a design suggestion, not a documentation error.
- **Severity**: Low — informational.

### 4. Change History Unknown
- **Issue**: Creation date and author are unknown. The SP name suggests it relates to client balance reconciliation, but no Atlassian reference was found.
- **Action**: Check Atlassian or SP git history for creation context.
- **Severity**: Low.

---

## Confidence Assessment

| Section | Confidence | Notes |
|---------|-----------|-------|
| Business Meaning | High | Alert table purpose is clear from name and SP logic |
| Business Logic | High | SP code read directly; TRUNCATE+INSERT+threshold confirmed |
| Query Advisory | High | Empty = healthy is a key insight; documented correctly |
| Elements | Medium | Column types need DDL verification |
| Lineage | High | Source tables and SP confirmed |
| Relationships | Medium | Source tables identified; no downstream consumers found |
| Sample Queries | High | Standard patterns for alert table |
