# DWH_dbo.Fact_BillingDeposit -- Review Needed

> Follow-up questions after Speckit refresh (2026-05-14). Tier-3 `[UNVERIFIED]` flags in Elements require domain SME only where noted.

## Reviewer Corrections

| Column / Topic | Current | Correction | Reviewer | Date |
|----------------|---------|------------|----------|------|
| *(none logged)* | | | | |

## Items Still Open / Sloppy Areas

| # | Topic | Why |
|---|-------|-----|
| 1 | Duplicate `ClientBankNameAsString` into `v` | Confirm whether dashboards still reference `v` or whether column can be ignored. |
| 2 | `ExpirationDateID` edge formats | CASE assumes specific string layout; non-card funding may produce misleading IDs. |
| 3 | Orchestration ordering | Validate `Fact_CustomerAction` refresh vs `SP_Fact_BillingDeposit_DL_To_Synapse` pass-2 to avoid PlatformID NULL drift. |
| 4 | `sys.dm_pdw_nodes_db_partition_stats` denied | Approx row counts now via `sp_spaceused`; DMV access would be preferable for batch automation. |

## Structural Notes (non-blocking)

- Synapse `INFORMATION_SCHEMA` + SSDT DDL both show **136** physical columns; treat “139” expectations as stale unless UC adds computed columns.
- `IsAft*` flags are **only** read from `PaymentData` XML in `SP_Fact_BillingDeposit_DL_To_Synapse` (not Funding table columns).
