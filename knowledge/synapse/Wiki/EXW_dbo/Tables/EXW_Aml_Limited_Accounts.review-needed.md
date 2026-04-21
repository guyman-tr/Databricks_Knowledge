---
object: EXW_dbo.EXW_Aml_Limited_Accounts
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_Aml_Limited_Accounts

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 14 columns are Tier 2 (DDL analysis + MCP live data). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — Original Loading Mechanism

**Observation**: No SSDT stored procedure writes to this table. The only SP referencing it (`SP_EXW_CompensationClosingCountries`) is a reader, not a writer. The `UpdateDate` column shows a last write of 2023-11-13, strongly suggesting the table is frozen.
**Question**: What was the original loading mechanism? Was this loaded by a now-deleted SP, an ADF pipeline, a manual SSMS import, or a legacy Google Sheet export prior to the Fivetran integration? Is there a Jira ticket or runbook describing the decommission of this load process?

### Q2 — LatestStatus Code Semantics

**Column**: LatestStatus (#5)
**Observation**: Live data shows values 0 (1,797 rows), 1 (1,000 rows), 2 (212 rows), NULL (641 rows). No SP code or DDL comment documents what these integers mean. The wiki interprets them as: 0 = watchlist/no restriction, 1 = read-only, 2 = fully blocked — based on the presence of `SetToReadOnlyDate` and `SetToBlockedDate` columns as corroborating context.
**Question**: Is this interpretation correct? Are there other LatestStatus values that could appear if the table were ever updated again (e.g., 3 = compensated/closed)? Is there a source system (AML case management tool) that defines these codes?

### Q3 — Units and USD as nvarchar

**Column**: Units (#8), USD (#9)
**Observation**: Both balance columns are stored as `nvarchar` rather than `numeric` or `float`. This is unusual for financial data. The type implies the original data source (possibly a Google Sheet or CSV) provided these as text.
**Question**: Are there known non-numeric values in these columns (e.g., 'N/A', 'unknown', empty strings)? Has any downstream analysis attempted to cast these to numeric and encountered errors? Is there a plan to fix the data type if this table is ever reactivated?

### Q4 — Relationship to External_Fivetran_google_sheets_exw_aml_limited_accounts

**Observation**: `SP_EXW_CompensationClosingCountries` unions this table with `BI_DB_dbo.External_Fivetran_google_sheets_exw_aml_limited_accounts` to construct `#Aml_Limited` (the combined AML-limited user set). The wiki documents that this table is the legacy predecessor to the Fivetran feed.
**Question**: Is there row overlap between the two sources (same GCIDs in both)? If so, does the UNION (without DISTINCT) result in duplicate GCIDs in `#Aml_Limited`? Could this inflate the AML-limited population count in `EXW_ReimbursementSumTable`? The SP code uses a basic `UNION ALL` or `UNION` — clarification needed.

### Q5 — SarSubmitted: Boolean vs Free-Text

**Column**: SarSubmitted (#12)
**Observation**: Column is `nvarchar(256)` but semantically represents a yes/no fact (whether a SAR was filed). Without live data query on this column's distinct values, the wiki cannot confirm whether it stores 'Yes'/'No', '1'/'0', or analyst free-text.
**Question**: What are the actual distinct values in `SarSubmitted`? If there are inconsistent representations (e.g., 'yes', 'Yes', 'YES', 'Y', 'N/A'), downstream analysts filtering on this column may get incorrect results.

### Q6 — 1899-12-30 Date Sentinel Scope

**Column**: LastUpdateDate (#1), and potentially SetToReadOnlyDate (#6), SetToBlockedDate (#7), DateSubmitted (#13)
**Observation**: MCP confirmed 1899-12-30 values in `LastUpdateDate`. This is the SQL Server representation of Excel date serial 0 (or a zero-date from a legacy system).
**Question**: Do the other date columns (`SetToReadOnlyDate`, `SetToBlockedDate`, `DateSubmitted`) also contain 1899-12-30 sentinel values? Analysts filtering on these dates (e.g., `WHERE SetToBlockedDate >= '2020-01-01'`) may inadvertently exclude or include sentinel rows depending on whether they filter for this value.

---

## Cross-Object Consistency Notes

### Note 1 — SP_EXW_CompensationClosingCountries UNION Usage

The wiki documents that `SP_EXW_CompensationClosingCountries` creates `#Aml_Limited` as a UNION of this table and the Fivetran external table. This is consistent with the SP code observed during Object #3 (EXW_CompensationClosingCountries) documentation. CONSISTENT.

### Note 2 — EXW_ReimbursementSumTable Dependency

The downstream use of `#Aml_Limited` in `EXW_ReimbursementSumTable` population is documented in the SP code for `SP_EXW_CompensationClosingCountries`. The EXW_ReimbursementSumTable wiki (Object #5, pending) should cross-reference this table as an indirect upstream source. FLAGGED FOR OBJECT #5.

---

## Known Limitations in This Wiki

1. **Origin completely unknown**: The loading mechanism for all 14 columns cannot be determined from SSDT code. All columns are classified T2 based on DDL analysis and MCP data, but "external source (unknown)" is the honest attribution.
2. **LatestStatus semantics are inferred**: The 0/1/2 interpretation is based on domain context and the presence of date columns; it is not confirmed by any code comment or documentation.
3. **No live data query on free-text columns**: Distinct values for `SarSubmitted`, `Reason`, `TradingRestriction`, `AmlComment` were not queried. The wiki describes these as free-text without knowing the actual value distribution.
4. **1899-12-30 scope uncertain**: Only `LastUpdateDate` was confirmed to have the sentinel. Other date columns may also contain it.
