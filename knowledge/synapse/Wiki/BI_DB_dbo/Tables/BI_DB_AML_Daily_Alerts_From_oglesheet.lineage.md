---
object: BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AML_Daily_Alerts_From_oglesheet

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | Google Sheet maintained by AML compliance analysts — direct import/push to Synapse |
| **Writer SP** | None found in SSDT repo — external script or connector pushes Google Sheet data |
| **ETL Pattern** | Google Sheet → this table (staging) → BI_DB_AML_Daily_Alerts (main) → BI_DB_AML_Daily_Alerts_History (archive) |
| **UC Target** | _Not_Migrated |
| **Downstream Table** | BI_DB_dbo.BI_DB_AML_Daily_Alerts (main reporting table with nvarchar(max) widths) |
| **Archive Table** | BI_DB_dbo.BI_DB_AML_Daily_Alerts_History |
| **Typo Note** | Column `AlertCatery` is a DDL typo for `AlertCategory` — present since at least Nov 2024 (confirmed in backup DDL) |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AlertID | Google Sheet | AlertID column | Alert identifier from the AML monitoring system — copied into the Google Sheet | Tier 4 |
| 2 | AlertCatery | Google Sheet | AlertCatery / AlertCategory column | **Typo column**: DDL name is `AlertCatery` — maps to AlertCategory in the Google Sheet. Higher-level category grouping for the alert. | Tier 4 |
| 3 | AlertType | Google Sheet | AlertType column | Specific alert type/rule that triggered the alert | Tier 4 |
| 4 | CID | Google Sheet | CID column | Customer ID of the alerted customer — entered/confirmed in the Google Sheet | Tier 4 |
| 5 | Name | Google Sheet (sourced from Dim_Customer) | Name column | Customer full name — pre-populated from AML tool or Dim_Customer lookup | Tier 3 |
| 6 | Country | Google Sheet (sourced from Dim_Customer) | Country column | Customer country — pre-populated at alert generation | Tier 3 |
| 7 | AccountType | Google Sheet (sourced from Dim_Customer) | AccountType column | Customer account type — pre-populated at alert generation | Tier 3 |
| 8 | AlertDate | Google Sheet | AlertDate column | Date of the AML alert — cluster key | Tier 4 |
| 9 | Regulation | Google Sheet (sourced from Dim_Customer) | Regulation column | Regulatory jurisdiction — pre-populated at alert generation | Tier 3 |
| 10 | RelatedAccounts | Google Sheet | RelatedAccounts column | Other CIDs related to the alert — free-text (nvarchar(256) limit) | Tier 4 |
| 11 | PlayerStatus | Google Sheet (sourced from Dim_PlayerStatus) | PlayerStatus column | Customer PlayerStatus at alert time — stored as name string | Tier 3 |
| 12 | AlertStatus | Google Sheet (analyst-entered) | AlertStatus column | Alert investigation lifecycle status — entered/updated by AML analyst | Tier 4 |
| 13 | Assigned | Google Sheet (analyst-entered) | Assigned column | AML analyst name assigned to this alert — entered by AML team lead | Tier 4 |
| 14 | AlertDetails | Google Sheet (analyst-entered) | AlertDetails column | Free-text alert description (nvarchar(2048) limit in staging vs nvarchar(max) in main table) | Tier 4 |
| 15 | PreviousStatus | Google Sheet (sourced from Dim_PlayerStatus) | PreviousStatus column | Prior PlayerStatus before any action — stored as name string (nvarchar(512) limit) | Tier 3 |
| 16 | UpdateDate | ETL metadata | GETDATE() | ETL run timestamp — when the Google Sheet data was pushed to Synapse | Tier 5 |

## Notes

- Empty table (0 rows as of 2026-04-23). Backup DDL from Nov 2024 confirms historical data existed.
- "oglesheet" = Google Sheet (colloquial/abbreviated form of "Googlesheet") — confirmed by bounded nvarchar lengths matching typical Google Sheet column constraints.
- `AlertCatery` is a DDL typo for `AlertCategory` present since at least Nov 2024 backup — the column has never been renamed. Code referencing this table must use `AlertCatery`.
- Bounded nvarchar lengths (256/512/2048) differ from nvarchar(max) in the main table (BI_DB_AML_Daily_Alerts) — data length validation happens at the main table level.
- This is the staging layer: AML analysts fill in/review data in the Google Sheet, which is then pushed to this table, then transferred to the main BI_DB_AML_Daily_Alerts table.
