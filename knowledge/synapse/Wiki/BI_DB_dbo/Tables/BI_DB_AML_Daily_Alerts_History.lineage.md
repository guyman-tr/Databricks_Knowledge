# BI_DB_dbo.BI_DB_AML_Daily_Alerts_History — Column Lineage

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_AML_Daily_Alerts_History
**Writer SP**: None found in SSDT repo (archive/historical store, no active ETL)
**Load Pattern**: Historical archive — data copied from BI_DB_AML_Daily_Alerts before archival. Currently empty (0 rows as of 2026-04-23).

---

## ETL Pipeline

```
AML monitoring system (NICE Actimize / Oracle FCCM / equivalent)
  |-- Alert export → Google Sheet (AML team reviews/augments) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_From_oglesheet (staging; bounded nvarchar)
  |-- ETL transfer ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts (main; nvarchar(max))
  |-- Archive process (no SSDT SP found) ---|
  v
BI_DB_dbo.BI_DB_AML_Daily_Alerts_History (historical archive; AlertDetails nvarchar(2048))
  |-- No UC Gold target ---|
  v
_Not_Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | AlertID | External AML tool | alert_id | Passthrough | Tier 4 |
| 2 | AlertType | External AML tool | alert_type | Passthrough | Tier 4 |
| 3 | CID | External AML tool | customer_id | Passthrough; type bigint→int (schema change Nov 2024) | Tier 4 |
| 4 | Name | DWH_dbo.Dim_Customer | FullName | Denormalized snapshot at load time | Tier 3 |
| 5 | Country | DWH_dbo.Dim_Customer | CountryName | Denormalized snapshot at load time | Tier 3 |
| 6 | AccountType | DWH_dbo.Dim_Customer | AccountTypeName | Denormalized snapshot at load time | Tier 3 |
| 7 | AlertDate | External AML tool | alert_date | Passthrough; cluster key | Tier 4 |
| 8 | Regulation | DWH_dbo.Dim_Customer | RegulationName | Denormalized snapshot at load time | Tier 3 |
| 9 | RelatedAccounts | External AML tool | related_accounts | Passthrough; multi-value string | Tier 4 |
| 10 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Denormalized name at load time (string, not ID) | Tier 3 |
| 11 | AlertStatus | External AML tool / Google Sheet | alert_status | Passthrough; analyst-maintained | Tier 4 |
| 12 | Assigned | Google Sheet | analyst_name | Passthrough; analyst name string | Tier 4 |
| 13 | AlertDetails | External AML tool / Google Sheet | alert_details | Passthrough; bounded nvarchar(2048) in History vs max in main table | Tier 4 |
| 14 | PreviousStatus | DWH_dbo.Dim_PlayerStatus | Name | Denormalized prior status name at load time | Tier 3 |
| 15 | UpdateDate | ETL metadata | GETDATE() | Pipeline run timestamp | Tier 5 |
| 16 | AlertCategory | External AML tool | alert_category | Passthrough | Tier 4 |

## Notes

- **AlertDetails size difference**: History has AlertDetails nvarchar(2048) vs nvarchar(max) in AML_Daily_Alerts main table. This suggests History was created from the From_oglesheet staging (same 2048 bound) or is an older DDL version predating the unbounded change.
- **0 rows**: Table is empty as of 2026-04-23. Historical data existed through Nov 2024 (backup confirms schema with CID as bigint).
- **No Tier 1**: No upstream production wiki exists for the external AML monitoring system.
- **Cross-object consistency**: Column descriptions MUST match AML_Daily_Alerts verbatim (same production source, same tier assignments).
