# EXW_dbo.EXW_WalletLogins — Review Needed

**Generated**: 2026-04-20 | **Batch**: 8 | **Object**: #5 of 6

## Tier 2 Items (Require SP Confirmation — SP Found, Items for Verification)

| # | Column | Question | Current Assumption |
|---|--------|----------|-------------------|
| RN-001 | EnvironmentDetails | SP hardcodes NULL. Was there an intent to populate this from STS_Audit_UserOperationsData? Is it expected to always remain NULL? | Assumed: intentionally NULL in current implementation; field reserved for future population |
| RN-002 | ApplicationIdentifier | SP hardcodes 'retoro'. Are there ever executions with a different application identifier, or is this table strictly for the main eToro wallet app? | Assumed: always 'retoro'; single-application scope |
| RN-003 | ALL | What is the historical retention policy? Does SP_WalletLogins load all dates back to wallet launch, or is there a rolling window? | Assumed: growing rolling history; no truncation observed |
| RN-004 | GCID | GCID is defined as nullable (int NULL) in DDL. Under what conditions would GCID be NULL for a login event? | Assumed: rare data quality gap; filter WHERE GCID IS NOT NULL for analysis |

## Cross-Object Consistency

- `HasWallet=1` filter via `Dim_Customer` means this table should be a subset of all eToro login events in Fact_CustomerAction (ActionTypeID=14). Verify that GCID values here all exist in EXW_DimUser.
- `EXW_FCA_UserLogin` (separate table in EXW_dbo) also captures wallet user logins with FCA context — check for overlap and confirm whether FCA users appear in both tables.
- `EXW_WalletLogins_Backup_20241216` in SSDT: investigate what prompted the backup (potential production data issue or schema change in Dec 2024).

## SP Behavior Notes

- **Delete-insert**: SP is idempotent for a given @date — safe to re-run. The delete targets `CAST(LoggedInOn AS DATE) = @date`.
- **Scheduling**: SP is scheduled externally (ADF or Databricks orchestration) — not self-scheduling.
- **@dateID**: Converts @date to YYYYMMDD integer (CONVERT(CHAR(8), @date, 112)) for Fact_CustomerAction DateID partition filter — efficient partition pruning.
- **#logins temp table**: SP uses a temp table with HASH(GCID) distribution for staging — same distribution as target table.
