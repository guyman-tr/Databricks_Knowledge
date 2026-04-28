---
object: EXW_dbo.EXW_ReportingBalances
review_date: 2026-04-20
batch: 12
priority: HIGH — empty table with unknown ETL source
---

# Review Notes — EXW_ReportingBalances

## Critical Issues (HIGH Priority)

1. **EMPTY TABLE — 0 rows**: This table has never been populated. All documentation is inferred from DDL structure and EXW_EOMReportingBalances patterns. Needs verification from the data engineering team: Is this table still in use? Was the ETL pipeline abandoned?

2. **No writer SP in SSDT**: No stored procedure found that writes to this table anywhere in the Dataplatform SSDT repo. The loading mechanism is completely unknown from the repo perspective. Possible sources: ADF pipeline, Python script, SQL Agent job, or SSIS package outside SSDT scope.

3. **All 40 columns Tier 4**: Without a SP or upstream wiki, all column documentation is at Tier 4 (inferred). Quality score of 7.5 reflects this limitation.

## Tier 4 Items Needing Clarification

4. **[Reporting Balance] vs [Closing Units Balance]**: What is the exact rule for when these differ? The EXW_EOMReportingBalances data shows they are identical for most rows (KnownIssueWallet=0). For KnownIssueWallet=1 rows, [DevReportBalance For 'KnownIssueWallets'] is used instead. Confirm this rule.

5. **[TrackerBalance] source**: Is this BitGo (as in EXW_FinanceReportsBalancesNew) or a different provider? The column semantics are identical to the tracker balance in EXW_FinanceReportsBalancesNew.

6. **[UserWalletAllowance] values**: In EXW_EOMReportingBalances, values include 'Allowed' and 'NotAllowed' with trailing spaces (nchar(50) padding). Confirm whether additional values exist.

7. **[Test accounting classifier]**: What values are valid? In EXW_EOMReportingBalances, 0 = production account, 1 = test. Are other non-zero values used?

## DDL Observations vs EXW_EOMReportingBalances

This table appears to be the successor to EXW_EOMReportingBalances with these schema differences:

| Column | This table | EXW_EOMReportingBalances |
|--------|-----------|--------------------------|
| ReportingDate | NOT NULL | NULL |
| [eToro Wallet Identifier] | NULL | NOT NULL |
| [Public Wallet Address] | nvarchar(100) | nvarchar(max) |
| [KnownIssueWallet] | NOT NULL | NULL |
| [Has Dif...] | NULL | NOT NULL |
| [MTD Balance Change -MTD Units Total Flag] | NULL | NOT NULL |
| [Closed Country AND Regulation] | NOT NULL | NULL |
| [User was Compensated...] | NOT NULL | NULL |
| UpdateDate | NULL | NOT NULL |
| ReportingDateID | MISSING | Present |
| IsValidCustomer | MISSING | Present |
| VerificationLevelID | MISSING | Present |
| PlayerLevelID | MISSING | Present |

Note: `[ Closing Balance Date]` has a leading space in both tables — DDL typo.

## Recommendation

Escalate to the eToro Wallet finance/data engineering team to confirm:
- Is this table the planned replacement for EXW_EOMReportingBalances?
- Where is the ETL pipeline that would populate it?
- Should it be considered deprecated/abandoned?
