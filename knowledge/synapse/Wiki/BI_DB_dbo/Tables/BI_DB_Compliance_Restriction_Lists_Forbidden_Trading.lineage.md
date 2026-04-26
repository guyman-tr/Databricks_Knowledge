# Column Lineage — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading

**Generated**: 2026-04-21 | **Writer SP**: SP_CID_Compliance_CID_And_Country_Risk_Lists | **Batch**: 18

## Source Chain

```
AML/Compliance team Google Sheets spreadsheet (manual forbidden trading data)
  |-- Fivetran (Google Sheets connector) ---|
  v
Azure Data Lake: Silver/SharePoint/forbiddentrading (Parquet)
  |-- External Table: External_Fivetran_google_sheets_forbiddentrading
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CountryID | External_Fivetran_google_sheets_forbiddentrading | country_id (nvarchar) | Implicit cast nvarchar → int. NULL when country has no DWH CountryID mapping. | Tier 2 |
| 2 | Country | External_Fivetran_google_sheets_forbiddentrading | country | Passthrough | Tier 2 |
| 3 | List | External_Fivetran_google_sheets_forbiddentrading | list | Passthrough | Tier 2 |
| 4 | UpdateDate | ETL | GETDATE() | Set at INSERT time | Tier 2 |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
