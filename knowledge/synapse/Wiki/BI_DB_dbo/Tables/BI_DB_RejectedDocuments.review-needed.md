# Review Needed: BI_DB_dbo.BI_DB_RejectedDocuments

## Known Anomalies

- **Ghost columns (Manager, CustomerName)**: Both columns are in the DDL but the SP INSERT list does not include them. All live data shows NULL for both (confirmed in Phase 2 data sampling). These are legacy/abandoned schema additions. Do not reference in analytics.

- **Column name with space**: `[Classification comment]` has a literal space. Must always be referenced with double square brackets: `[[Classification comment]]`. This is a non-standard Synapse column name and will cause syntax errors without proper quoting.

- **FirstDepositDate = NULL for non-depositors**: Unlike other BI_DB tables that use '1900-01-01' as a sentinel, this table uses NULL for non-depositors. Queries that compare FTD dates across BI_DB tables must account for this inconsistency.

- **Demographic columns reflect current state, not rejection-time state**: `VerificationLevelID`, `PlayerStatus`, `Language`, `Country`, `Region` are joined from current Dim_Customer/Dim_Country data at the time of the SP run. A customer's status at the time their document was rejected may have been different (e.g., they were not yet verified, but now they are).

- **SP_Create_External dependency**: If `SP_Create_External_etoro_backoffice_customerdocument` fails before the main SP runs, the external table may be stale. The main SP will then re-insert stale data for @Date without error. No built-in error handling for external table staleness.

## Tier 4 / Low-Confidence Items

- **Manager**: Always NULL. Ghost column. (T4)
- **CustomerName**: Always NULL. Ghost column. (T4)

## Reviewer Questions

1. **Ghost columns — intentional?**: Why are `Manager` and `CustomerName` in the DDL if they are never populated? Were they planned features that were abandoned, or are they leftovers from a previous schema version where they were populated? Should they be formally dropped from the DDL?

2. **[Classification comment] content**: Is the content in this free-text field PII or sensitive? It appears to be internal agent notes about the rejection. If it contains agent names, internal case references, or partial customer identification information, it may need PII tagging before UC migration.

3. **Dim_Manager vs. Dim_Customer.AccountManagerID**: The SP LEFT JOINs to Dim_Manager but then doesn't include Manager in the INSERT. Was the intention to record which verification agent/manager rejected the document? If so, this feature was never completed. The relevant data would be in Dim_Manager via Dim_Customer.AccountManagerID if needed.

4. **Fact_BillingDeposit vs. Dim_Customer.FirstDepositDate for FTD**: This SP sources FTD date from `MIN(Fact_BillingDeposit.BillingDate)` per CID rather than from `Dim_Customer.FirstDepositDate`. Are there known cases where these two values differ? Using different FTD sources across BI_DB tables creates join ambiguities in cross-table cohort analysis.

5. **Rejection history completeness before 2022-07-01**: The table starts from 2022-07-01. Were there rejection events before this date that were not migrated? If reporting requires pre-2022 rejection history, confirm whether it's available in any other source.

6. **No purge mechanism for deleted customers**: If a customer's account is deleted (GDPR right to erasure), their rejection history rows will persist. Is there a separate GDPR purge process that removes rows from this table for deleted customers?

7. **VerificationLevelID semantics at rejection time**: Since VerificationLevelID is joined from current Dim_Customer (not historical), for old rejections this represents the customer's CURRENT verification level, not their level at the time of the rejection. This may lead to incorrect cohort analysis if analysts assume VerificationLevelID reflects the state at rejection time.
