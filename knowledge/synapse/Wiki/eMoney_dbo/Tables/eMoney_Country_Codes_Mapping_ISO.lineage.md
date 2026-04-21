# Column Lineage: eMoney_dbo.eMoney_Country_Codes_Mapping_ISO

## Object Summary

| Property | Value |
|----------|-------|
| **DWH Object** | eMoney_dbo.eMoney_Country_Codes_Mapping_ISO |
| **Source System** | ISO 3166-1 (manually maintained) |
| **Source Object** | Static reference — no upstream DB source |
| **ETL Pattern** | Manual bulk load; no writer SP |
| **Writer SP** | None — manually maintained |
| **UC Target** | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso |
| **Row Count (live)** | 248 |

## Column Lineage

| # | DWH Column | DWH Type | Source Table | Source Column | Transform | Tier |
|---|-----------|----------|-------------|--------------|-----------|------|
| 1 | CountryName | varchar(200) NULL | ISO 3166-1 | country_name | Manual entry; full country name | Tier 2 |
| 2 | CountryAlphaTwoCode | varchar(20) NULL | ISO 3166-1 | alpha-2 | Manual entry; 2-letter ISO code | Tier 2 |
| 3 | CountryAlphaThreeCode | varchar(20) NULL | ISO 3166-1 | alpha-3 | Manual entry; 3-letter ISO code | Tier 2 |
| 4 | CountryNumericCode_ISO | varchar(20) NULL | ISO 3166-1 | numeric | Manual entry; 3-digit ISO numeric code; FK key from FiatTransactions.TransactionCountryIso | Tier 2 |
| 5 | eToroDWHCountryID | int NULL | DWH_dbo.Dim_Country | CountryID | Manual mapping; bridges ISO numeric → DWH country dimension | Tier 2 |
| 6 | UpdateDate | datetime NULL | Manual load | — | Bulk-load timestamp; all rows = 2024-06-24 | Tier 2 |

## ETL Pipeline

```
ISO 3166-1 reference data (external standard)
  |-- Manual bulk load (2024-06-24) ---|
  v
eMoney_dbo.eMoney_Country_Codes_Mapping_ISO (248 rows, HASH(eToroDWHCountryID), HEAP)

Used by:
  SP_eMoney_Customer_Risk_Assessment → country HRC lookups (country risk scoring)
  SP_eMoney_DimFact_Transaction → TransactionCountryIso (numeric) → eToroDWHCountryID
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 6 | CountryName, CountryAlphaTwoCode, CountryAlphaThreeCode, CountryNumericCode_ISO, eToroDWHCountryID, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
| Total | 6 | |

*Generated: 2026-04-21 | Phase 10B*
