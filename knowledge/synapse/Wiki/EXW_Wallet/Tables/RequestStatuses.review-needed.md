# Review Needed: EXW_Wallet.RequestStatuses

## 1. Missing Upstream Wiki

- **No upstream wiki exists** for `WalletDB.Wallet.RequestStatuses`. All 5 business columns (Id, RequestId, RequestStatusId, Timestamp, DetailsJson) are Tier 3 — descriptions are grounded in DDL structure, live data samples, and consuming SP code but lack authoritative production documentation.
- **Action**: If a WalletDB wiki is created in the future, upgrade these columns to Tier 1 with verbatim descriptions.

## 2. DetailsJson Content Structure

- `DetailsJson` is non-empty in ~7.2M rows (~15%) but its JSON schema is unknown. A sample of non-empty values should be reviewed to determine whether structured fields should be documented.
- **Action**: Run `SELECT TOP 20 DetailsJson FROM EXW_Wallet.RequestStatuses WHERE DetailsJson IS NOT NULL AND DetailsJson <> '' ORDER BY Timestamp DESC` to inspect the JSON schema.

## 3. etr_* Column Partial Population

- The `etr_y`, `etr_ym`, `etr_ymd` columns are partially populated — older rows have values, newer rows are often empty. This may reflect a change in the Generic Pipeline configuration.
- **Action**: Confirm whether the etr_* columns are deprecated in favor of `partition_date`.

## 4. RequestStatusId Coverage

- 23 of 29 known dictionary values appear in live data. Six values have zero rows: 25 (WaitingForManualApproval), 26 (ManuallyApproved), 27 (ManuallyRejected), 34 (OperationRejected), 39 (TravelRuleFlowInitiated), 40 (TravelRuleCompleted).
- These may be newer statuses not yet exercised or deprecated values.

## 5. Id Column Nullability

- `Id` is defined as `bigint NULL` in the DDL but likely serves as a surrogate key from production. Confirm whether NULLs actually occur.

## 6. No Writer SP

- This table has no Synapse writer SP — it is loaded entirely by the Generic Pipeline. If the ingestion mechanism changes, the lineage documentation should be updated.
