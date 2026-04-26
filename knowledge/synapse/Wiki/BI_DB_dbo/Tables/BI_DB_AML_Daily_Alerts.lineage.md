---
object: BI_DB_dbo.BI_DB_AML_Daily_Alerts
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AML_Daily_Alerts

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | External AML monitoring system / Google Sheet (AML analysts) — no SSDT writer SP |
| **Writer SP** | None found in SSDT repo |
| **ETL Pattern** | Google Sheet → BI_DB_AML_Daily_Alerts_From_oglesheet (staging) → BI_DB_AML_Daily_Alerts (main) → BI_DB_AML_Daily_Alerts_History (archive) |
| **UC Target** | _Not_Migrated |
| **Staging Table** | BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet (Google Sheet import — bounded nvarchar lengths) |
| **Archive Table** | BI_DB_dbo.BI_DB_AML_Daily_Alerts_History (historical archive of this table) |
| **Schema Note** | CID was bigint in Nov 2024 backup; changed to int in current DDL — schema modified post-Nov 2024 |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AlertID | External AML monitoring tool | alert_id | Unique identifier for the AML alert | Tier 4 |
| 2 | AlertType | External AML monitoring tool | alert_type | Type/category of the AML alert (e.g., Transaction Monitoring, Sanctions, PEP) | Tier 4 |
| 3 | CID | External AML monitoring tool / Google Sheet | customer_id | Customer ID of the alerted customer (was bigint in Nov 2024 backup; changed to int) | Tier 4 |
| 4 | Name | DWH_dbo.Dim_Customer (denormalized) | FullName | Customer's full name — denormalized at population time for reporting convenience | Tier 3 |
| 5 | Country | DWH_dbo.Dim_Customer (denormalized) | Country | Customer's country — denormalized at population time | Tier 3 |
| 6 | AccountType | DWH_dbo.Dim_Customer (denormalized) | AccountType | Customer account type (e.g., Retail, Corporate) — denormalized at population time | Tier 3 |
| 7 | AlertDate | External AML monitoring tool | alert_date | Date the AML alert was generated — cluster key for date-based access | Tier 4 |
| 8 | Regulation | DWH_dbo.Dim_Customer (denormalized) | Regulation | Regulatory jurisdiction applicable to the customer (e.g., FCA, CySEC) — denormalized at population time | Tier 3 |
| 9 | RelatedAccounts | External AML monitoring tool | related_accounts | Other CIDs related to this AML alert — stored as free-text (likely comma-separated list) | Tier 4 |
| 10 | PlayerStatus | DWH_dbo.Dim_PlayerStatus (denormalized) | PlayerStatusName | Customer's PlayerStatus at time of alert (stored as name, not ID) | Tier 3 |
| 11 | AlertStatus | External AML monitoring tool / Google Sheet | alert_status | Current investigation status of the alert (e.g., Open, Closed, In Review, Escalated) | Tier 4 |
| 12 | Assigned | External AML monitoring tool / Google Sheet | assigned_analyst | Name of the AML analyst assigned to investigate this alert | Tier 4 |
| 13 | AlertDetails | External AML monitoring tool / Google Sheet | alert_details | Free-text description of why the AML alert was triggered (nvarchar(max) — can be lengthy) | Tier 4 |
| 14 | PreviousStatus | DWH_dbo.Dim_PlayerStatus (denormalized) | PlayerStatusName (prior) | Customer's PlayerStatus before any action triggered by this alert | Tier 3 |
| 15 | UpdateDate | ETL metadata | GETDATE() | ETL run timestamp — last update to this row | Tier 5 |
| 16 | AlertCategory | External AML monitoring tool | alert_category | Higher-level category grouping of the alert (e.g., Screening, TM, Regulatory) | Tier 4 |

## Notes

- Empty table (0 rows as of 2026-04-23). Active through at least Nov 2024 (backup_20241117 exists).
- Population pipeline: Google Sheet (AML analyst-maintained) → BI_DB_AML_Daily_Alerts_From_oglesheet → BI_DB_AML_Daily_Alerts → BI_DB_AML_Daily_Alerts_History.
- CID type changed from bigint (Nov 2024 backup) to int (current DDL) — schema modification occurred between Nov 2024 and Apr 2026.
- All columns nullable — consistent with Google Sheet import pattern where not all fields are always populated.
- RelatedAccounts stored as nvarchar(max) — likely a comma-separated or pipe-separated list of related CIDs, not a normalized FK.
- "oglesheet" in sibling table name = "Googlesheet" (Google Sheet) — confirmed by bounded nvarchar lengths in that table.
