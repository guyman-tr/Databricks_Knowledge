# Review Needed — BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New_Blocked

**Batch**: 70 | **Generated**: 2026-04-23 | **Quality**: 8.0/10

## Tier 2 Items (Require Human Verification)

| Column | Current Description | Question |
|---|---|---|
| PlayerStatusReasonID | Always = 6 (AML-Account Closed) | Confirm: is PlayerStatusReasonID=6 ALWAYS and ONLY "AML-Account Closed"? If this reason ID can be reassigned in production, the table's semantic meaning may change silently. |
| BlockedTime | MIN(FullDate) where Fact_SnapshotCustomer.PlayerStatusID matches | Does this capture the FIRST time ever in this status, or the start of the most recent continuous block? If a customer was unblocked and re-blocked, does BlockedTime reset to the re-block date or stay at the original block date? |
| PlayerStatus (base col #18) | Passthrough from BI_DB_Client_Balance_CID_Level_New | What values appear for PlayerStatus in this table? All blocked customers should have a specific PlayerStatus value — confirm what it is. |

## Known Data Quality Issues

- **Only 5 rows**: All customers are "Over 2 Months" blocked with near-zero balances. Some have been blocked since October 2022. This table is extremely sparse and likely rarely changes.
- **Column set frozen at Jan 2022**: The SP was created in January 2022 and has never been updated. Post-2022 base table columns (TRS crypto, futures, DLT, stocks margin, etc.) are absent. Analysts must use the base table directly for full column coverage.
- **No history**: TRUNCATE before INSERT means only the most recent run's data is visible. For historical analysis of blocked customers, query `BI_DB_Client_Balance_CID_Level_New` directly with `dc.PlayerStatusReasonID=6`.
- **TimeBucket computed at SP run time**: The aging bucket reflects time-since-block as of the ETL run (not the data date GETDATE()-2). The 2-day lag between data date and run date is negligible but may affect the "Under 24h" and "Under 48h" buckets.
- **UpdateDate at end vs. base UpdateDate**: The base table's UpdateDate (column 105) is not explicitly excluded in the SP — it may appear as a passthrough. The final UpdateDate (col 129) is GETDATE() from the SP. Verify whether both exist or only the final GETDATE() one.

## No Tier 4 Items

All source tables are documented DWH objects.
