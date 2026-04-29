# Review Needed — BI_DB_dbo.BI_DB_Deposit_checking_temp_table

## Open Questions

- **Error_Message NULL vs empty string**: The MCP sample shows `Error_Message` as blank (rendered as empty in the result set) when `Balance_diff_deposit = 0`. The SP source confirms `@v_error_message_deposit` is declared but never SET in the success branch — `CAST(NULL AS VARCHAR(MAX))` should insert NULL. Verify whether downstream monitors check `IS NULL` or `= ''` and whether the blank rendering is NULL or empty string at the storage level.

- **UTC vs local time for UpdateDate**: `GETDATE()` is used rather than `GETUTCDATE()`. Confirm Synapse server time zone for cross-table time comparisons against UTC-timestamped columns.

- **Staleness detection**: No mechanism found to detect that `UpdateDate` is stale (i.e., the table contains data from a prior run because `RAISERROR(severity 18)` aborted the opening-balance check). Recommend adding an OpsDB alerting step or a freshness check (`UpdateDate < CAST(GETDATE()-1 AS DATE)`).

- **Caller chain**: The SP header confirms `SP_Client_Balance_Check_Opening_Balance` is called from `SP_Client_Balance_New`. Verify exact OpsDB schedule/priority and the date parameter passed (appears to be `DATEADD(DAY,-1,GETDATE())`).

- **HASH(UpdateDate) on a 1-row HEAP table**: Distribution key is a DDL artifact from the original CTAS pattern. No functional impact but should be addressed in a future ALTER review.
