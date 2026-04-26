# Review Needed — BI_DB_dbo.BI_DB_ClientBalance_DDR_Data_Integrity_Alert

**Batch**: 70 | **Generated**: 2026-04-23 | **Quality**: 8.0/10

## Tier 2 Items (Require Human Verification)

| Column | Current Description | Question |
|---|---|---|
| FCADeposits | SUM(Amount) WHERE ActionTypeID IN (7,44) | The 2024-04-16 update added ActionTypeID=44 to the CB-track comparison but NOT to the DDR-track (DepositDDR uses ActionTypeID=7 only). Is this intentional and permanent? If the DDR pipeline is eventually updated to include ActionTypeID=44, the SP will need a corresponding change. |
| DataIntegrityProblem | Triggers if DDR sources return NULL for the date | Confirm: is there a secondary alert mechanism if this table fires? The TRUNCATE pattern means historical alert data is lost after each daily run — is alert history captured elsewhere (e.g., job logs, monitoring dashboards)? |

## Tier 4 Items (Blacklisted Sources)

| Column | Blacklisted Source | Note |
|---|---|---|
| DDRCIDLevelDeposits | BI_DB_DDR_CID_Level | Blacklisted — description reflects SP logic only; confirm DDR pipeline still populates this table daily |
| DDRDailyAggLevelDeposits | BI_DB_DDR_Daily_Aggregated | Blacklisted — same caveat |
| DDRAggLevelDeposits | BI_DB_DDR_TimeRange_Aggregated_Country_Level | Blacklisted — confirm TimeRange='Yesterday' is the correct filter for daily reconciliation |

## Known Data Quality Issues

- **Table is always empty in healthy state**: A COUNT(*) = 0 result is normal. Do not treat an empty result as a pipeline failure.
- **DepositDDR is not stored**: The ActionTypeID=7-only benchmark for DDR comparisons is computed internally but excluded from the INSERT. The stored `FCADeposits` includes both 7 and 44 — analysts using this table to reconstruct DDR alert logic must re-query Fact_CustomerAction with ActionTypeID=7 only.
- **No history**: TRUNCATE before each daily INSERT destroys prior alert data. Only the most recent alert run date is visible in this table.
- **HEAP + ROUND_ROBIN**: No index, no distribution key — appropriate for a normally-empty table, but queries against a populated table will be full scans.
