# Dictionary.StocksIndustry

> Classifies stock instruments by industry sector for platform categorization, filtering, and API display.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | IndustryID (int, PK) |
| **Row Count** | 9 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.StocksIndustry is a lookup table containing the standard industry sector classifications for stock instruments on the eToro platform.

### Why It Exists
Stock instruments need to be categorized by industry sector for platform features including browse/filter by industry, API data display, instrument metadata configuration, and reporting. This table provides the canonical list of 9 industry sectors used across the trading platform.

### How It Works
The `IndustryID` is stored in `Trade.InstrumentMetaData` (and `History.InstrumentMetaData`) to tag each stock instrument with its industry. Multiple API procedures and views join against this table to return industry names for display. The view `Trade.GetDictionaryStocksIndustry` provides a dedicated access layer, while `Trade.GetInstrumentMetaData` and related views expose it as part of broader instrument data.

---

## 2. Business Logic

### Value Map (Complete — 9 rows)

| IndustryID | IndustryName | Business Meaning |
|------------|-------------|------------------|
| 1 | Basic Materials | Mining, chemicals, forestry, metals — raw material producers |
| 2 | Conglomerates | Diversified multi-sector holding companies |
| 3 | Consumer Goods | Food, beverages, apparel, household products |
| 4 | Financial | Banks, insurance, asset management, fintech |
| 5 | Healthcare | Pharma, biotech, hospitals, medical devices |
| 6 | Industrial Goods | Aerospace, defense, machinery, construction |
| 7 | Services | Retail, restaurants, media, transportation |
| 8 | Technology | Software, hardware, semiconductors, internet |
| 9 | Utilities | Electric, gas, water, renewable energy |

### Classification Standard
The 9 sectors follow a simplified industry classification scheme (similar to ICB/GICS but condensed). IDs are sequential with no gaps.

---

## 3. Data Overview

| IndustryID | IndustryName | Example Stocks |
|------------|-------------|----------------|
| 1 | Basic Materials | BHP, Rio Tinto, Dow |
| 4 | Financial | JPMorgan, Goldman Sachs, PayPal |
| 5 | Healthcare | Pfizer, Johnson & Johnson, Moderna |
| 8 | Technology | Apple, Microsoft, NVIDIA |
| 9 | Utilities | NextEra Energy, Duke Energy |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IndustryID | int | NO | — | HIGH | Primary key identifying the industry sector. Sequential 1-9. Referenced by `Trade.InstrumentMetaData.IndustryID` and `History.InstrumentMetaData.IndustryID`. |
| 2 | IndustryName | varchar(50) | NO | — | HIGH | Human-readable industry sector label. Variable-length, no trailing spaces. Used in API responses and platform UI for stock categorization. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Trade.InstrumentMetaData | IndustryID | Implicit FK → IndustryID | DDL column match, joined in 20+ procedures |
| History.InstrumentMetaData | IndustryID | Implicit FK → IndustryID | Historical archive of instrument metadata |
| Trade.InsertedInstrument | IndustryID | Implicit FK → IndustryID | Staging table for new instrument insertion |

### View Consumers

| View | Purpose |
|------|---------|
| Trade.GetDictionaryStocksIndustry | Direct full-table access for API |
| Trade.GetInstrumentMetaData | Joins to return IndustryName with instrument data |
| Trade.GetInstrumentMetaDataExtend | Extended instrument metadata with industry |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Trade.GetAllStocksIndustriesForAPI | SELECT | Returns full industry list for API consumers |
| Trade.GetAllInstrumentDisplayDatasForAPI | SELECT (via JOIN) | Includes IndustryName in instrument display data |
| Trade.GetInstrumentDataForAPI | SELECT (via JOIN) | Returns instrument data with industry classification |
| Trade.InsertInstrumentMetaData | INSERT (target table) | Writes IndustryID when creating instrument metadata |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | INSERT | SecurityOps instrument metadata creation |
| Trade.InsertInstrumentRealTable | INSERT | Real instrument creation with IndustryID |
| Trade.CheckValidInstruments | SELECT (validation) | Validates IndustryID during instrument checks |
| Trade.GetAllInstrumentData | SELECT (via JOIN) | Full instrument data retrieval |
| Trade.GetAllInstrumentCategoriesForAPI | SELECT | Category/industry API endpoint |
| Trade.UpdateInstrumentsMetaDataConfigurations | UPDATE | Updates instrument metadata including industry |
| Internal.Newcurrency | INSERT | New currency/instrument creation flow |
| Price.GetAllInstrumentsDataByInstrumentTypeID | SELECT (via JOIN) | Price feed instrument data with industry |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Trade.InstrumentMetaData` — primary consumer, stores IndustryID per instrument
- `History.InstrumentMetaData` — historical archive
- 12+ stored procedures for API and instrument management

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DictionaryStocksInsdustry | CLUSTERED PK | IndustryID ASC | Note: PK name has typo "Insdustry" (extra 's') |

---

## 8. Sample Queries

```sql
-- Get all industry sectors
SELECT  IndustryID,
        IndustryName
FROM    Dictionary.StocksIndustry WITH (NOLOCK)
ORDER BY IndustryID;

-- Count instruments by industry
SELECT  si.IndustryName,
        COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.StocksIndustry si WITH (NOLOCK)
        ON imd.IndustryID = si.IndustryID
GROUP BY si.IndustryName
ORDER BY InstrumentCount DESC;

-- Find all Technology stocks
SELECT  imd.InstrumentID,
        si.IndustryName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.StocksIndustry si WITH (NOLOCK)
        ON imd.IndustryID = si.IndustryID
WHERE   si.IndustryName = 'Technology';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| SecurityQuery.cs (Confluence) | Code reference | References StocksIndustry in API query context |
| Watchlist API Real Response Objects | API docs | Industry field in watchlist API response |

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.StocksIndustry | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.StocksIndustry.sql*
