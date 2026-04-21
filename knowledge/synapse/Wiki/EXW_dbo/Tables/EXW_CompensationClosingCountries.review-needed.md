---
object: EXW_dbo.EXW_CompensationClosingCountries
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_CompensationClosingCountries

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 22 columns are Tier 2 (SP code analysis + Fivetran/Google Sheets source). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — Legacy Project Loading Mechanism

**Observation**: The table contains 15 project values (FrenchTerr, Germany_Tangany_AirDrop, Russia, Netherlands, etc.) that are NOT produced by the current SP_EXW_CompensationClosingCountries. These account for 137,887 rows out of 140,638 total (98%). The current SP only handles AML, AML_US, AML_EEA.
**Question**: How were the legacy country-closure rows originally loaded? Is there an older version of this SP or a separate loading mechanism? Are these rows considered static/frozen historical data, or could they be updated in the future?

### Q2 — ReportFromDate and ReportId for Legacy Projects

**Column**: ReportFromDate (#13), ReportId (#14)
**Observation**: These are hardcoded NULL for AML* projects in the current SP, but live data shows 6,973 non-NULL ReportId values and 3,353 non-NULL ReportFromDate values. These come from legacy project rows.
**Question**: What do ReportFromDate and ReportId refer to in the legacy context? Are they IDs from a legacy reporting system (e.g., EXW_FinanceReportsBalancesNew.ReportID)? This would be important for analysts trying to understand the original balance snapshots used for compensation.

### Q3 — NBSP Sanitization in CID/GCID

**Column**: CID (#1), GCID (#2)
**Observation**: The SP uses `CAST(CAST(REPLACE(value, CHAR(160), '') AS FLOAT) AS INT)` to handle non-breaking spaces from Google Sheets. This is a fragile input pattern.
**Question**: Have there been cases where this sanitization failed (e.g., NULL GCIDs in the table due to unexpected formatting)? Is there monitoring on the Fivetran pipeline to detect bad rows?

### Q4 — Project Typo: 'Poject' in SP

**Observation**: The SP code uses the alias `'AML' AS Poject` (missing 'r'), `'AML_US' AS Poject`, `'AML_EEA' AS Poject`. The column is correctly named 'Project' in the INSERT target. The typo is harmless but could confuse future SP maintainers.
**Question**: Is there a known ticket to fix this typo? Should it be flagged in code review?

### Q5 — AMLStatus Values for Non-AML Projects

**Column**: AMLStatus (#21)
**Observation**: AMLStatus is NULL for all non-AML project rows (legacy country-closure projects). The downstream filter in EXW_ReimbursementFollowUp uses `LOWER(AMLStatus) IN ('compensated','reimbursed','completed')` only for AML* projects. Non-AML projects use all rows unconditionally.
**Question**: Is there any user-facing status field for legacy country-closure projects (FrenchTerr, Germany, etc.)? If not, how does the reimbursement team track completion of those events?

### Q6 — USD_FinalBalance as UPSERT Key

**Column**: USD_FinalBalance (#8)
**Observation**: The UPSERT uniqueness check uses `ROUND(USD_FinalBalance, 8) = c.USD_FinalBalance`. This is unusual — using a balance amount (which could change) as an idempotency key rather than a stable ID.
**Question**: What happens if a user's compensation amount changes in the Google Sheet (e.g., a correction)? The UPDATE logic handles this per GCID + CryptoId + Project — but the INSERT guard uses USD_FinalBalance equality. Could a changed compensation amount result in a duplicate row being inserted before the old one is deleted?

---

## Cross-Object Consistency Notes

### Note 1 — AMLClosureEvent Connection to EXW_FinanceReportsBalancesNew

The wiki documents that SP_EXW_FinanceReportsBalancesNew uses this table for AMLClosureEvent condition 4. The relationship is:
```sql
WHERE GCID IN (SELECT GCID FROM EXW_CompensationClosingCountries) AND SelectedValue = 0
```
This correctly matches the documentation in EXW_FinanceReportsBalancesNew.md (Section 2.2, condition 4). CONSISTENT.

### Note 2 — EXW_ReimbursementFollowUp Relationship

The SP populates both EXW_CompensationClosingCountries AND EXW_ReimbursementFollowUp in a single run. The wiki documents EXW_ReimbursementFollowUp as a consumer of this table, which is accurate — the SP first builds EXW_CompensationClosingCountries then uses it as input for EXW_ReimbursementFollowUp. CONSISTENT.

---

## Known Limitations in This Wiki

1. **Legacy project origins undocumented**: 98% of rows come from legacy projects whose loading mechanism is unknown from the current SP code. This wiki cannot fully explain how FrenchTerr, Germany, Russia, and other historical projects were loaded.
2. **Google Sheets schema not documented**: The Fivetran source table schemas (column names, types) are inferred from the SP code. If the Google Sheets columns change (e.g., renamed), the SP and this wiki would both need updating.
3. **No row count stability guarantee**: Since the SP runs on-demand without a date parameter, the row count and project distribution could change significantly after any SP run. The statistics in the wiki (140,638 rows, 18 projects) reflect a point-in-time snapshot.
