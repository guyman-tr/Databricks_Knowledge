# Review Needed: BI_DB_dbo.BI_DB_AML_Daily_Alerts_History

**Batch**: 81 | **Date**: 2026-04-23 | **Priority**: 0 (not in OpsDB)

## Tier 4 Items (Low Confidence — Needs Expert Review)

| Column | Current Description | Question |
|--------|-------------------|----------|
| AlertID | External AML tool identifier | What AML system generated these IDs? (NICE Actimize, Oracle FCCM, internal tool?) |
| AlertType | AML rule/mechanism type | What are the actual enum values? (table empty — confirm with AML ops team) |
| AlertCategory | Higher-level alert grouping | What are the actual enum values? |
| AlertDate | Alert generation datetime | Is this the time the alert was generated or the time it was processed? |
| RelatedAccounts | Multi-value string of related CIDs | Confirm format (comma-separated? space-separated? JSON?) |
| AlertStatus | Investigation lifecycle status | What are the exact workflow states? (Open, Closed, etc.) |
| Assigned | AML analyst name string | Should this have a FK to a people table? |
| AlertDetails | Free-text alert description | Bounded at 2048 chars — are there known truncation cases from the main table? |
| AlertCategory | alert_category from AML tool | What values were used? ('MIMO ', 'Screening', etc.?) |

## Key Questions for Data Owners

1. **Archival mechanism**: No SSDT stored procedure writes to this table. How was data archived from `BI_DB_AML_Daily_Alerts` to `BI_DB_AML_Daily_Alerts_History`? Was it a manual script, a job outside SSDT, or a deprecated SP?

2. **AlertDetails truncation**: The History table has `AlertDetails nvarchar(2048)` while the main `BI_DB_AML_Daily_Alerts` has `nvarchar(max)`. Were any alert details truncated when archiving?

3. **Active status**: All three tables in the cluster (From_oglesheet, Daily_Alerts, Daily_Alerts_History) are empty. Is this pipeline decommissioned, migrated to another system, or temporarily suspended?

4. **CID type change**: CID was `bigint` in the Nov 2024 backup. Was there a data cleanup when changing to `int`? Were any CIDs > 2.1B affected?

5. **AML system identity**: What specific AML monitoring product generates these alerts? This affects the Tier 4 attributions throughout.

## Cross-Object Consistency Check

Confirmed: Column descriptions for overlapping columns (Name, Country, AccountType, Regulation, PlayerStatus, PreviousStatus, UpdateDate) are identical to `BI_DB_AML_Daily_Alerts.md` descriptions. Same production source → same description. ✓

## Known Limitations

- **0 rows**: Cannot verify enum values or data distribution from live sampling. All Tier 3/4 descriptions are inferred from sibling table docs and DDL.
- **No writer SP**: Cannot trace exact source-to-target column mapping.
- **AlertDetails bounded**: Truncation risk acknowledged in wiki — needs validation when/if data returns.
