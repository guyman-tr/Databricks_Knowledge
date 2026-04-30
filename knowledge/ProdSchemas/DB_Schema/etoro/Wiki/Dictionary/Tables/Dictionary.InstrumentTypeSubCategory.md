# Dictionary.InstrumentTypeSubCategory

> Configuration table defining instrument sub-categories within each asset class — providing granular classification (Coins, Crypto Crosses, Major Indices, FX Futures, etc.) for trading configuration, SEO content, and regulatory bucketing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeSubCategoryID (INT, no PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 0 (no indexes — heap table) |

---

## 1. Business Meaning

Dictionary.InstrumentTypeSubCategory provides a second-level classification of trading instruments within each major asset class (InstrumentTypeID). While the parent Dictionary.CurrencyType defines broad categories like Forex (1), Commodities (2), Indices (4), Stocks (5), and Crypto (10), this table adds granular sub-categories: "Major currency pairs" vs "Non Major currency pairs" within Forex, "Coins" vs "Crypto Crosses" vs "Crypto Futures" within Crypto, "Futures Energy" vs "Futures Metals" within Commodities.

This table exists because different sub-categories within the same asset class require different trading configurations (leverage limits, fee structures, margin requirements), different SEO/marketing content, and different regulatory treatment. For example, major forex pairs may have different leverage caps than exotic pairs under ESMA regulations.

The table is heavily consumed by the Trade schema — Trade.InstrumentMetaData stores the sub-category per instrument, and multiple procedures (GetInstrumentDataForAPI, GetAllInstrumentDisplayDatasForAPI, InsertInstrumentRealTable, CheckValidInstruments, etc.) use it for instrument validation and API responses.

---

## 2. Business Logic

### 2.1 Asset Class Hierarchy

**What**: Two-level instrument classification: InstrumentTypeID (broad asset class) → InstrumentTypeSubCategoryID (granular sub-category).

**Columns/Parameters Involved**: `InstrumentTypeSubCategoryID`, `InstrumentTypeSubCategoryName`, `InstrumentTypeID`, `InstrumentTypeNameForSEO`

**Rules**:
- **Crypto (Type 10)**: Coins (1001), Currency Crosses (1002), Crypto Crosses (1003), Commodity Crosses (1004), Crypto Futures (1005, 1014), Experimental (1010)
- **Forex (Type 1)**: Major currency pairs (1006), Non Major currency pairs (1007), FX Futures (1016)
- **Indices (Type 4)**: Major Indices (1008), Non Major Indices (1009), Futures Capital Markets (1013), Interest Rates Futures (1015)
- **Commodities (Type 2)**: Test (1010 duplicate), Futures Energy (1011), Futures Metals (1012)
- This is a heap table (no PK) — InstrumentTypeSubCategoryID 1010 appears twice (for Crypto "Experimental" and Commodities "test"), indicating non-unique IDs
- InstrumentTypeNameForSEO provides SEO-friendly display names for web content generation

### 2.2 SEO Content Mapping

**What**: Each sub-category has a dedicated SEO name for web content and marketing pages.

**Columns/Parameters Involved**: `InstrumentTypeNameForSEO`

**Rules**:
- SEO names are human-readable labels optimized for search engines
- Used in URL slugs, page titles, and meta descriptions on the eToro website
- Some SEO names match the sub-category name exactly; others are customized for marketing

---

## 3. Data Overview

| SubCategoryID | SubCategoryName | TypeID | SEO Name | Meaning |
|---|---|---|---|---|
| 1001 | Coins | 10 | Cryptocurrencies | Core cryptocurrency assets (Bitcoin, Ethereum, etc.) — the primary crypto trading sub-category for spot crypto positions. |
| 1006 | Major currency pairs | 1 | Major currency pairs | High-liquidity forex pairs (EUR/USD, GBP/USD, USD/JPY, etc.) that typically have the tightest spreads and highest leverage limits under regulation. |
| 1008 | Major Indices | 4 | Major Indices | Primary stock market indices (S&P 500, NASDAQ, DAX, etc.) — high-liquidity instruments with specialized trading hours and dividend adjustment rules. |
| 1011 | Futures Energy | 2 | Futures Energy | Energy commodity futures (Oil, Natural Gas) — instruments with specific expiry dates, rollover mechanics, and commodity-specific overnight fee patterns. |
| 1016 | FX Futures | 1 | FX Futures | Foreign exchange futures contracts — forex instruments with expiry dates rather than rolling spot positions. Subject to different margin and fee rules than spot forex. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeSubCategoryID | int | NO | - | VERIFIED | Sub-category identifier within an asset class. Values in 1001-1016 range. NOT unique — ID 1010 appears for both Crypto "Experimental" and Commodities "test". No PK constraint (heap table). Referenced by Trade.InstrumentMetaData. |
| 2 | InstrumentTypeSubCategoryName | varchar(50) | NO | - | VERIFIED | Human-readable name of the sub-category. Used in BackOffice configuration screens and API responses. Examples: "Coins", "Major currency pairs", "Futures Energy". |
| 3 | InstrumentTypeID | int | NO | - | VERIFIED | Parent asset class. FK to Dictionary.CurrencyType (InstrumentTypeID). 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto. Groups sub-categories under their asset class. |
| 4 | InstrumentTypeNameForSEO | varchar(100) | YES | - | CODE-BACKED | SEO-optimized display name for web content generation. Used in URL slugs, page titles, and marketing content on the eToro website. May differ from InstrumentTypeSubCategoryName for marketing purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Implicit FK | Parent asset class classification (1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentMetaData | InstrumentTypeSubCategoryID | Implicit FK | Stores sub-category per instrument |
| Trade.GetInstrumentDataForAPI | - | Lookup | Returns sub-category in instrument API response |
| Trade.GetAllInstrumentDisplayDatasForAPI | - | Lookup | Returns sub-category for display data API |
| Trade.InsertInstrumentRealTable | - | Lookup | Validates sub-category during instrument creation |
| Trade.CheckValidInstruments | - | Lookup | Validates sub-category during instrument validation |
| Trade.GetAllInstrumentTypeSubCategoryForAPI | - | Reader | Returns all sub-categories for API |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Stores InstrumentTypeSubCategoryID per instrument |
| Trade.GetInstrumentDataForAPI | Stored Procedure | Reads — instrument API data |
| Trade.GetAllInstrumentDisplayDatasForAPI | Stored Procedure | Reads — display data API |
| Trade.InsertInstrumentRealTable | Stored Procedure | Reads — instrument creation validation |
| Trade.CheckValidInstruments | Stored Procedure | Reads — instrument validation |
| Trade.GetAllInstrumentTypeSubCategoryForAPI | Stored Procedure | Reads — returns all sub-categories |
| Trade.InsertInstrumentMetaData | Stored Procedure | Reads — metadata insertion |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. This is a **heap table** (no clustered index, no primary key constraint).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all sub-categories grouped by asset class
```sql
SELECT  InstrumentTypeID,
        InstrumentTypeSubCategoryID,
        InstrumentTypeSubCategoryName,
        InstrumentTypeNameForSEO
FROM    [Dictionary].[InstrumentTypeSubCategory] WITH (NOLOCK)
ORDER BY InstrumentTypeID, InstrumentTypeSubCategoryID;
```

### 8.2 Join to CurrencyType for parent asset class names
```sql
SELECT  ct.CurrencyTypeName AS AssetClass,
        sc.InstrumentTypeSubCategoryName AS SubCategory,
        sc.InstrumentTypeNameForSEO AS SEOName
FROM    [Dictionary].[InstrumentTypeSubCategory] sc WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK)
        ON sc.InstrumentTypeID = ct.CurrencyTypeID
ORDER BY ct.CurrencyTypeName, sc.InstrumentTypeSubCategoryName;
```

### 8.3 Find instruments by sub-category
```sql
SELECT  imd.InstrumentID,
        c.SymbolFull,
        sc.InstrumentTypeSubCategoryName
FROM    [Trade].[InstrumentMetaData] imd WITH (NOLOCK)
JOIN    [Dictionary].[InstrumentTypeSubCategory] sc WITH (NOLOCK)
        ON imd.InstrumentTypeSubCategoryID = sc.InstrumentTypeSubCategoryID
JOIN    [Dictionary].[Currency] c WITH (NOLOCK)
        ON imd.InstrumentID = c.InstrumentID
WHERE   sc.InstrumentTypeSubCategoryName = 'Coins'
ORDER BY c.SymbolFull;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InstrumentTypeSubCategory | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.InstrumentTypeSubCategory.sql*
