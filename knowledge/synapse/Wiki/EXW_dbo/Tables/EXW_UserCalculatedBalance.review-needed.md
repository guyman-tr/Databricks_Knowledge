# EXW_dbo.EXW_UserCalculatedBalance — Review Needed

**Generated**: 2026-04-20 | **Batch**: 5 | **Type**: Table | **Status**: DEPRECATED

## Tier 4 / Unverified Items

No Tier 4 or Tier 5 columns. All 27 columns resolved to T1/T2 from the commented-out SP code.

## Open Questions for Reviewer

1. **Deprecation rationale**: SP body commented out without explanation. Same question as EXW_Transactions_Monthly — was this an intentional decommission? Was there a known accuracy issue with the cumulative calculation approach that motivated the switch to the direct-snapshot model (EXW_FinanceReportsBalancesNew)?

2. **1.27 billion rows — storage cost**: This is the largest table in EXW_dbo by row count (vs EXW_FactBalance at 2.37B). CCI should be providing compression, but the table is no longer updated. Is there a plan to archive or drop it? Confirm with data engineering.

3. **EOM column type**: The DDL shows EOM as int, but the SP code computed it as varchar '1'/'0' (CASE WHEN ... THEN '1' ELSE '0' END). This discrepancy means actual data might be stored as int (1/0) if an implicit conversion occurred, or varchar ('1'/'0'). Verify actual data values before filtering: `SELECT DISTINCT EOM FROM EXW_dbo.EXW_UserCalculatedBalance WHERE BalanceDateId = 20231231`.

4. **XRP reserve (0.0225)**: The XRP minimum ledger reserve has changed since the table was last populated. Historical values correctly applied 0.0225 at the time. Analysts should not use this balance for current XRP regulatory reporting.

5. **GCID/RealCID bigint vs int**: Both are bigint in EXW_UserCalculatedBalance (vs int in EXW_DimUser). Joins to EXW_DimUser.GCID will require implicit cast. Verify no performance regression for historical analysis queries.

6. **Balance can be negative**: Due to fee accounting, some balances may be negative. Confirm whether negative balances were treated as zero or as legitimate data in the original reporting.

## Cross-Object Consistency

- Balance computation (ReceivedAmount - SentAmount - fee) differs from EXW_FinanceReportsBalancesNew which uses direct snapshot ✓ (documented as intentional — different approach)
- Club = Dim_PlayerLevel.Name matches pattern in EXW_FinanceReportsBalancesNew ✓
- IsTestAccount, IsValidCustomer flags match EXW_DimUser and EXW_FinanceReportsBalancesNew definitions ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
