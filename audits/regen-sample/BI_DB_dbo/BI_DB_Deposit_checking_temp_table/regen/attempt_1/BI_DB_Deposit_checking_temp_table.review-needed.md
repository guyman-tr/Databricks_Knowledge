# Review Needed — BI_DB_dbo.BI_DB_Deposit_checking_temp_table

## Open Questions

- **Error_Message empty vs NULL**: The sampled row shows an empty string for `Error_Message` when the check passes. The SP sets `@v_error_message_deposit` only on failure — it is possible the column stores NULL (not empty string) in some runs. Verify whether downstream monitors check `IS NULL` or `= ''`.

- **UTC vs local time for UpdateDate**: `GETDATE()` is used rather than `GETUTCDATE()`. If the Synapse server time zone is not UTC, `UpdateDate` will drift from UTC-timestamped columns in other tables. Confirm server timezone for cross-table time comparisons.

- **Caller chain**: The bundle confirms `SP_Client_Balance_Check_Opening_Balance` is the writer. The SP header says it is called from `SP_Client_Balance_New`. Verify the exact OpsDB schedule/priority to confirm daily cadence and the date parameter passed (appears to be `DATEADD(DAY,-1,GETDATE())`).

- **Non-fatal deposit mismatch behavior**: When `Balance_diff_deposit <> 0`, the SP issues `PRINT` (not `RAISERROR`) for deposits, meaning pipeline does not fail. Confirm whether there is a downstream alerting mechanism that reads `Error_Message` from this table, or if mismatches go undetected until manual review.

- **HASH(UpdateDate) on a 1-row HEAP table**: Distribution key appears to be a DDL artifact from an original CTAS pattern. No functional impact, but worth noting in a future ALTER review.
