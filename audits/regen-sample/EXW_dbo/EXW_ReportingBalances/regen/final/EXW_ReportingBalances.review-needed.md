# EXW_dbo.EXW_ReportingBalances — Review Needed

## Summary

All 40 columns are Tier 3 (grounded in DDL + domain context). No upstream wiki, no SP code, and no generic pipeline mapping were found. The table is dormant (0 rows).

## Items Requiring Human Review

### 1. Production Source Unknown

The table has no writer SP, is not in the generic pipeline mapping, and is not in the dependency order. The data loading mechanism is entirely unknown. A SME should clarify:
- Was this table loaded via SSIS, Excel import, or an external script?
- Is this table deprecated in favor of `EXW_EOMReportingBalances`?
- Should this table be dropped or archived?

### 2. Relationship to EXW_EOMReportingBalances

`EXW_EOMReportingBalances` shares nearly identical columns (plus 3 extra: IsValidCustomer, VerificationLevelID, PlayerLevelID) but uses a HEAP instead of a clustered index. A SME should clarify:
- Are these the same dataset at different granularities (monthly vs end-of-month)?
- Is EXW_ReportingBalances the predecessor that was replaced by the EOM variant?

### 3. Column Semantics Needing Clarification

| Column | Question |
|--------|----------|
| Test accounting classifier | What values distinguish test vs production accounts? Is this an FK to a lookup table? |
| UserWalletAllowance | What are the valid values? Does this represent withdrawal limits, wallet tiers, or something else? |
| KnownIssueWallet | What values are used? Is 0 = no issues, 1 = known issue, or are there multiple issue categories? |
| Closed Country AND Regulation | What are the valid two-character codes? (Y/N? Yes/No? Country codes?) |
| User was Compensated during Country Closure | Same question — what are the valid two-character codes? |
| DevReportBalance For 'KnownIssueWallets' | What is the "dev" prefix? Development environment balance? Developer-team-computed balance? |
| Reporting Balance vs Closing Units Balance | What adjustments are applied to derive the reporting balance from the closing balance? |

### 4. Data Quality Observations (from DDL)

- **Typos in column names**: "Recieved" (should be "Received"), "Occured" (should be "Occurred") — these are baked into the DDL.
- **Leading space**: `[ Closing Balance Date]` has a leading space character in the column name.
- **Embedded quotes**: `[DevReportBalance For 'KnownIssueWallets']` contains single quotes.
- **Inconsistent NOT NULL**: Most balance columns are nullable, but KnownIssueWallet, Closed Country AND Regulation, and User was Compensated during Country Closure are NOT NULL with no obvious defaults.

### 5. UC Migration Status

Table is not migrated to Unity Catalog. Given the dormant status (0 rows, no ETL), migration priority should be assessed by a SME.
