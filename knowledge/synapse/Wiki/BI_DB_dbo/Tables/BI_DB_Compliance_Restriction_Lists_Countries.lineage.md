# Column Lineage — BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries

**Generated**: 2026-04-21 | **Writer SP**: SP_CID_Compliance_CID_And_Country_Risk_Lists | **Batch**: 18

## Source Chain

```
AML team Google Sheets spreadsheet (manual AML risk list data)
  |-- Fivetran (Google Sheets connector) ---|
  v
Azure Data Lake: Silver/SharePoint/compliance_help_countries (Parquet)
  |-- External Table: External_Fivetran_gsheets_compliance_help_countries
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Country | External_Fivetran_gsheets_compliance_help_countries | country | Passthrough | Tier 2 |
| 2 | CountryID | External_Fivetran_gsheets_compliance_help_countries | country_id (nvarchar) | Implicit cast nvarchar → int. NULL when country has no DWH CountryID mapping. | Tier 2 |
| 3 | List | External_Fivetran_gsheets_compliance_help_countries | list | Passthrough | Tier 2 |
| 4 | FromDate | External_Fivetran_gsheets_compliance_help_countries | from_date | Passthrough | Tier 2 |
| 5 | ToDate | External_Fivetran_gsheets_compliance_help_countries | to_date | Passthrough | Tier 2 |
| 6 | UpdateDate | ETL | GETDATE() | Set at INSERT time | Tier 2 |
| 7 | UsedIn | NOT POPULATED | — | SP does NOT insert this column — always NULL. External table has used_in but SP INSERT omits it. | Tier 2 |
| 8 | Source | NOT POPULATED | — | SP does NOT insert this column — always NULL. External table has source but SP INSERT omits it. | Tier 2 |

## UC External Lineage

UC Target: `_Not_Migrated`

*No UC lineage entries — table not migrated to Unity Catalog.*
