# Column Lineage — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs

**Generated**: 2026-04-21 | **Writer SP**: SP_CID_Compliance_CID_And_Country_Risk_Lists | **Batch**: 18

## Source Chain

```
AML team Google Sheets spreadsheet (manual AML risk list data)
  |-- Fivetran (Google Sheets connector) ---|
  v
Azure Data Lake: Silver/SharePoint/compliance_help_cids (Parquet)
  |-- External Table: External_Fivetran_gsheets_compliance_help_cids
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | External_Fivetran_gsheets_compliance_help_cids | cid (nvarchar) | Implicit cast nvarchar → int | Tier 2 |
| 2 | List | External_Fivetran_gsheets_compliance_help_cids | list | Passthrough | Tier 2 |
| 3 | FromDate | External_Fivetran_gsheets_compliance_help_cids | from_date (nvarchar) | Implicit cast nvarchar → date | Tier 2 |
| 4 | ToDate | External_Fivetran_gsheets_compliance_help_cids | to_date (nvarchar) | Implicit cast nvarchar → date | Tier 2 |
| 5 | UpdateDate | ETL | GETDATE() | Set at INSERT time | Tier 2 |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
