# DWH_dbo.Dim_Language

> Small 29-row dictionary table mapping LanguageID to the language name, ISO 639-1 code, and IETF BCP 47 culture code -- representing the 28 languages supported by the eToro platform for customer UI localization and communication preferences.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Language (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP (no clustered index) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (29 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Language` is the platform's language reference table, mapping each LanguageID to the human-readable language name, its ISO 639-1 two-letter code, and its IETF BCP 47 culture code. The 29 rows cover 28 supported platform languages plus a LanguageID=0 null-sentinel (`N/A`). Customer profiles and events carry a LanguageID indicating the customer's selected UI language and preferred communication locale.

The table includes two Chinese variants (LanguageID=4 `Chinese`/zh-CN for Simplified, LanguageID=18 `ChineseTraditional`/zh-TW for Traditional) and two English variants (LanguageID=1 `English`/en-GB for British, LanguageID=25 `EnglishUS`/en-US for American). Both variants share the same IsoCode but differ in CultureCode.

ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Language`. The table is HEAP-indexed (no clustered index) because at 29 rows, index overhead is negligible.

---

## 2. Business Logic

### 2.1 IsoCode vs CultureCode

**What**: `IsoCode` is a 2-letter ISO 639-1 language code; `CultureCode` is a 5-character IETF BCP 47 locale tag combining language and region.

**Rules**:
- Use `IsoCode` for language-only grouping (e.g., all Portuguese speakers regardless of region).
- Use `CultureCode` for locale-specific formatting, currency, and routing (e.g., pt-BR for Brazilian Portuguese vs pt-PT for European Portuguese).
- Two CultureCodes share the same IsoCode=`zh`: zh-CN (Chinese Simplified) and zh-TW (Chinese Traditional). When aggregating by IsoCode, `zh` will include both.
- Two CultureCodes share IsoCode=`en`: en-GB and en-US. For global English aggregation, use `IsoCode = 'en'`.
- Two CultureCodes share IsoCode=`pt`: pt-BR (Brazilian) and pt-PT (European Portuguese).

### 2.2 LanguageID=0 Null-Sentinel

**Rule**: LanguageID=0 has Name='N/A', IsoCode='N/A', CultureCode='N/A'. This is the DWH standard placeholder for missing/unknown language data. Always filter `WHERE LanguageID > 0` for language analytics.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (29 rows), HEAP. Zero JOIN overhead on any node. HEAP is acceptable at this row count -- no scan benefit from a clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get language name for customer | `JOIN Dim_Language ON LanguageID; SELECT Name, IsoCode` |
| Group customers by language | `GROUP BY l.IsoCode, l.Name` |
| Find all English-language customers | `WHERE IsoCode = 'en'` (includes both en-GB and en-US) |
| Distinguish British vs American English | `WHERE CultureCode IN ('en-GB', 'en-US')` |

### 3.3 Gotchas

- **HEAP index**: Full table scans on all queries. Acceptable at 29 rows; zero performance concern.
- **IsoCode is nchar(10)**: Padded with spaces. When comparing, use TRIM() or LIKE pattern if needed.
- **CultureCode is nchar(10)**: Same padding issue.
- **Shared IsoCode for zh and pt**: Grouping by IsoCode merges Simplified/Traditional Chinese and BR/EU Portuguese. Use CultureCode for differentiation.
- **StatusID is always 1**: ETL hardcodes it. No informational value.
- **Name column is char(50)**: Fixed-width with space padding (e.g., 'English' appears as 'English   ...'). Use RTRIM(Name) in display queries.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- Upstream dictionary | `(Tier 1 — Dictionary.Language)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LanguageID | int | NO | Primary key identifying the language. 1=English(UK), 2=German, 3=Arabic, 4=Chinese, 5=Russian, 6=Spanish, 7=French, 8=Italian, 9=Japanese, 10=Portuguese(BR), 11=Turkish, 12=Greek, 13=Korean, 14=Swedish, 15=Norwegian, 16=Hungarian, 17=Polish, 18=ChineseTraditional, 19=Dutch, 20=EuropeanPortuguese, 21=Czech, 22=Malay, 23=Danish, 24=Romanian, 25=EnglishUS, 26=Vietnamese, 27=Thai, 28=Finnish. Referenced by Dictionary.Country.LanguageID. (Tier 1 — Dictionary.Language) |
| 2 | Name | char(50) | NO | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. (Tier 1 — Dictionary.Language) |
| 3 | DWHLanguageID | int | YES | Always equal to LanguageID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time, same as UpdateDate. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 7 | IsoCode | nchar(10) | YES | ISO 639-1 two-letter language code (e.g., 'en', 'de', 'ar'). Used for URL routing, API locale headers, and content management. (Tier 1 — Dictionary.Language) |
| 8 | CultureCode | nchar(10) | YES | .NET culture code for full locale specification (e.g., 'en-GB', 'de-DE', 'zh-CN'). Used for number formatting, date formatting, and currency display. (Tier 1 — Dictionary.Language) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| LanguageID | etoro.Dictionary.Language | LanguageID | passthrough |
| Name | etoro.Dictionary.Language | Name | passthrough |
| DWHLanguageID | etoro.Dictionary.Language | LanguageID | rename (= LanguageID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| IsoCode | etoro.Dictionary.Language | IsoCode | passthrough |
| CultureCode | etoro.Dictionary.Language | CultureCode | passthrough |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Language  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Language
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Language  (29 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Language/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer profile dimension tables | LanguageID | Customer's selected platform language |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 List all supported languages with locale codes

```sql
SELECT LanguageID, RTRIM(Name) AS Language, RTRIM(IsoCode) AS IsoCode, RTRIM(CultureCode) AS CultureCode
FROM [DWH_dbo].[Dim_Language]
WHERE LanguageID > 0
ORDER BY LanguageID;
```

### 7.2 Group customer registrations by language family

```sql
SELECT
    RTRIM(l.IsoCode) AS IsoCode,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Language] l ON f.LanguageID = l.LanguageID
WHERE l.LanguageID > 0
GROUP BY l.IsoCode
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 4 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/8, Logic: 8/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Language | Type: Table | Production Source: etoro.Dictionary.Language*
