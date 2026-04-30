# Review Needed: BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits

## 1. Dormant Table

- **Issue**: Table contains only 1 row with UpdateDate = 2024-02-05 (over 2 years ago). The SP may no longer be scheduled or may have been superseded by another monitoring mechanism.
- **Action**: Confirm whether SP_H_OPS_HighCompensationsVsDeposits is still scheduled for execution. If dormant, consider blacklisting from documentation backlog.

## 2. Type Mismatch: DepositAmount$24hrs

- **Issue**: DDL defines `DepositAmount$24hrs` as `varchar(max)`, but the SP computes it as `SUM(fbd.Amount*fbd.ExchangeRate)` which produces a money/numeric value. The ISNULL(...,0) coercion to varchar is lossy for downstream arithmetic.
- **Action**: Verify whether this type mismatch is intentional or a DDL bug. If unintentional, an ALTER TABLE to money would be appropriate.

## 3. Unresolved External Tables

- **Issue**: Three source external tables have no wiki documentation:
  - `BI_DB_dbo.External_etoro_Billing_Deposit` — maps to etoro.Billing.Deposit production table
  - `BI_DB_dbo.External_etoro_Billing_Funding_Datafactory` — maps to etoro.Billing.Funding production table
  - `BI_DB_dbo.External_etoro_history_credit_Pavlina` — dynamically created by SP_Create_External_etoro_history_credit
- **Action**: No action needed for this wiki. These are BI_DB external tables proxying production data; their upstream production sources (Billing.Deposit, Billing.Funding, History.Credit) are the authoritative documentation targets.

## 4. CompensationAmount NULL Pattern

- **Issue**: CompensationAmount and Compensation$/Deposits$ are NULL when a customer is flagged solely for the 24hr deposit frequency rule (the LEFT JOIN to #comps yields NULL). This is by design but may confuse consumers.
- **Action**: Confirm this NULL pattern is expected and documented for downstream consumers.

## 5. UC Target Unknown

- **Issue**: No Unity Catalog target documented for this table. It may not be migrated to Databricks.
- **Action**: Check if this OPS monitoring table is in scope for UC migration.

## 6. SP_Create_External_etoro_history_credit Dependency

- **Issue**: The writer SP calls `EXEC [BI_DB_dbo].[SP_Create_External_etoro_history_credit] @dt, 'Pavlina'` to materialize credit history data before aggregation. This dynamic external table creation pattern means the data source is ephemeral.
- **Action**: No action for wiki purposes. Note for operational awareness.
