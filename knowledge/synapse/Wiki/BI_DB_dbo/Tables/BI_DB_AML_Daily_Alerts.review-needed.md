---
object: BI_DB_dbo.BI_DB_AML_Daily_Alerts
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AML_Daily_Alerts

## Tier 4 Items / Uncertainties

1. **AlertID (Tier 4)**: The alert identifier format is unknown — is it a UUID, a sequential integer, or a composite key from the AML tool? Confirm format and whether it uniquely identifies an alert across the full history (including the _History archive table).

2. **AlertType / AlertCategory (Tier 4)**: Exact values for AlertType and AlertCategory are unknown (table is empty). Are these controlled vocabularies from the AML tool, or free-text entered by analysts? What specific values should analysts expect to see (e.g., 'Transaction Monitoring', 'Sanctions', 'PEP', 'KYC Failure')?

3. **CID type change (Tier 4)**: CID was `bigint` in the Nov 2024 backup DDL but is `int` in the current SSDT DDL. Was this a deliberate schema change, or was the table recreated incorrectly? If historical data from the backup is ever restored, there will be a type mismatch.

4. **AlertStatus values (Tier 4)**: Exact AlertStatus values are unknown. What lifecycle states does the AML workflow support? (e.g., 'Open', 'In Review', 'Pending Closure', 'Closed', 'Escalated', 'False Positive') — confirm with AML compliance team.

5. **AlertDetails format (Tier 4)**: Is AlertDetails free-text typed by the analyst, or is it a structured output from the AML monitoring tool? Understanding the format would enable structured extraction for analytics.

6. **RelatedAccounts format (Tier 4)**: Stored as nvarchar(max) — assumed to be comma-separated CIDs but the delimiter and format are unconfirmed. Confirm with the AML team or ETL owner.

7. **Assigned (Tier 4)**: Is the analyst stored by display name (e.g., 'John Smith') or username (e.g., 'jsmith')? Is there a mapping table to employee IDs or emails?

8. **PlayerStatus / PreviousStatus stored as string**: These columns store PlayerStatus as a name string, not an integer ID. This is inconsistent with the companion AML Benchmarks tables (which use PlayerStatusID). Confirm: is this intentional for the Google Sheet import use case?

9. **Population mechanism currently inactive**: The table is empty as of 2026-04-23. Was the Google Sheet → From_oglesheet → Daily_Alerts pipeline decommissioned, paused, or migrated to a new system? Confirm current status with the AML team.

## Questions for Domain Experts

- What AML monitoring system generates the alerts that populate this table? (NICE Actimize, Oracle FCCM, Themis, other?)
- Is the Google Sheet → Synapse pipeline still active, or was it replaced by a different integration?
- What happened to the historical data — was it archived, deleted, or migrated?
- What are the valid AlertType, AlertCategory, and AlertStatus values?
- What does RelatedAccounts contain — CIDs, GCIDs, or account numbers? What is the delimiter?
- Why was CID changed from bigint to int between Nov 2024 and now?

## No Cross-Object Corrections Needed

No live data available for validation. Backup DDL (Nov 2024) confirms schema consistency with the From_oglesheet staging table structure (minus the AlertCatery typo). Dim_PlayerStatus values not applicable here since PlayerStatus/PreviousStatus are stored as strings.
