# Trade.GetAllInstrumentCategoriesForAPI

> Returns distinct instrument category combinations (asset type, exchange, industry) for the trading platform's category navigation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns distinct CurrencyTypeID + ExchangeID + StocksIndustryID combinations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the category navigation/filtering in the trading platform UI. It returns the distinct set of instrument categories that exist in the system - combinations of asset type (CurrencyTypeID), exchange (ExchangeID, only for stocks), and industry sector (StocksIndustryID). This allows the UI to build category trees and filter dropdowns dynamically based on actual data rather than hardcoded lists.

The procedure exists because instrument categories are dynamic - new exchanges, industries, and asset types are added as the platform expands. The API needs the current set of valid categories to render navigation menus.

Data is assembled by joining `Trade.InstrumentMetaData` (instrument properties), `Trade.Instrument` (currency pairs), and `Dictionary.Currency` (asset type classification via BuyCurrencyID). The DISTINCT ensures no duplicate category combinations.

---

## 2. Business Logic

### 2.1 Conditional Exchange Assignment

**What**: ExchangeID is only included for stock-type instruments (CurrencyTypeID = 5); all others get NULL.

**Columns/Parameters Involved**: `CurrencyTypeID`, `ExchangeID`

**Rules**:
- `CASE dc.CurrencyTypeID WHEN 5 THEN imd.ExchangeID ELSE NULL END AS ExchangeID`
- CurrencyTypeID = 5 represents Stocks - the only asset type where exchange matters for category grouping
- For non-stock types (currencies, commodities, crypto, indices), exchange is irrelevant for categorization so NULL is returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyTypeID | INT | NO | - | CODE-BACKED | Asset type category. FK to Dictionary.CurrencyType. Derived from the instrument's BuyCurrencyID via Dictionary.Currency. Common values: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto, 12=ETFs. |
| 2 | ExchangeID | INT | YES | - | CODE-BACKED | Exchange identifier, only populated for Stocks (CurrencyTypeID=5). NULL for all other asset types. FK to exchange lookup. |
| 3 | StocksIndustryID | INT | YES | - | CODE-BACKED | Industry sector classification. FK to Dictionary.StocksIndustry. Used for sub-filtering within asset types (e.g., Technology, Healthcare within Stocks). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentMetaData | INNER JOIN | Source for instrument properties (ExchangeID, StocksIndustryID, InstrumentID) |
| (body) | Trade.Instrument | INNER JOIN | Links InstrumentMetaData to currency pairs for asset type lookup |
| (body) | Dictionary.Currency | INNER JOIN | Provides CurrencyTypeID from BuyCurrencyID to classify the asset type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInstrumentCategoriesForAPI (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.Instrument (table)
+-- Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument properties |
| Trade.Instrument | Table | INNER JOIN - BuyCurrencyID for asset type derivation |
| Dictionary.Currency | Table | INNER JOIN - maps BuyCurrencyID to CurrencyTypeID (asset type) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllInstrumentCategoriesForAPI;
```

### 8.2 Get category names by joining to dictionary tables
```sql
SELECT  DISTINCT ct.Name AS AssetType, imd.StocksIndustryID, si.IndustryName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Trade.Instrument inst WITH (NOLOCK) ON imd.InstrumentID = inst.InstrumentID
        INNER JOIN Dictionary.Currency dc WITH (NOLOCK) ON inst.BuyCurrencyID = dc.CurrencyID
        INNER JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON dc.CurrencyTypeID = ct.CurrencyTypeID
        LEFT JOIN Dictionary.StocksIndustry si WITH (NOLOCK) ON imd.StocksIndustryID = si.IndustryID;
```

### 8.3 Count instruments per asset type
```sql
SELECT  dc.CurrencyTypeID, ct.Name, COUNT(*) AS InstrumentCount
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Trade.Instrument inst WITH (NOLOCK) ON imd.InstrumentID = inst.InstrumentID
        INNER JOIN Dictionary.Currency dc WITH (NOLOCK) ON inst.BuyCurrencyID = dc.CurrencyID
        INNER JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON dc.CurrencyTypeID = ct.CurrencyTypeID
GROUP BY dc.CurrencyTypeID, ct.Name
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInstrumentCategoriesForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInstrumentCategoriesForAPI.sql*
