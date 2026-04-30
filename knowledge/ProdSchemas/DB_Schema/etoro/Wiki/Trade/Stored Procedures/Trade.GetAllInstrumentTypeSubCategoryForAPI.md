# Trade.GetAllInstrumentTypeSubCategoryForAPI

> Returns all instrument type sub-categories from the Dictionary for the API layer's instrument classification hierarchy.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentTypeSubCategoryID, Name, InstrumentTypeID, SEO name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the second level of the instrument classification hierarchy. While `Trade.GetAllInstrumentTypesForAPI` returns the top-level categories (Stocks, Crypto, etc.), this procedure returns the sub-categories within each type (e.g., within Stocks: "Large Cap", "Technology", "Financials"; within Crypto: "DeFi", "Layer 1", "Stablecoins"). These sub-categories enable finer-grained filtering and navigation in the trading platform.

The procedure exists to feed the API's sub-category catalog. The platform uses this alongside the parent types to build a two-level category tree for instrument discovery.

Data is a simple full read of `Dictionary.InstrumentTypeSubCategory` - a small reference table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct read of the sub-category dictionary. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeSubCategoryID | INT | NO | - | CODE-BACKED | Primary key of the sub-category. FK target for InstrumentMetaData.InstrumentTypeSubCategoryID. |
| 2 | InstrumentTypeSubCategoryName | NVARCHAR | NO | - | CODE-BACKED | Display name of the sub-category shown in the UI (e.g., "Large Cap", "DeFi", "Precious Metals"). |
| 3 | InstrumentTypeID | INT | NO | - | CODE-BACKED | FK to Dictionary.CurrencyType. Links this sub-category to its parent asset class (e.g., 5=Stocks, 10=Crypto). |
| 4 | InstrumentTypeNameForSEO | NVARCHAR | YES | - | CODE-BACKED | SEO-friendly slug for the sub-category. Used in URL generation for the web platform (e.g., "large-cap-stocks"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.InstrumentTypeSubCategory | SELECT FROM | Source dictionary table for all sub-categories |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInstrumentTypeSubCategoryForAPI (procedure)
+-- Dictionary.InstrumentTypeSubCategory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InstrumentTypeSubCategory | Table | SELECT FROM - reads all sub-categories |

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
EXEC Trade.GetAllInstrumentTypeSubCategoryForAPI;
```

### 8.2 Get sub-categories with their parent type names
```sql
SELECT  sc.InstrumentTypeSubCategoryID, sc.InstrumentTypeSubCategoryName, ct.Name AS ParentTypeName
FROM    Dictionary.InstrumentTypeSubCategory sc WITH (NOLOCK)
        INNER JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON sc.InstrumentTypeID = ct.CurrencyTypeID
ORDER BY ct.Name, sc.InstrumentTypeSubCategoryName;
```

### 8.3 Count instruments per sub-category
```sql
SELECT  sc.InstrumentTypeSubCategoryID, sc.InstrumentTypeSubCategoryName, COUNT(imd.InstrumentID) AS InstrumentCount
FROM    Dictionary.InstrumentTypeSubCategory sc WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON sc.InstrumentTypeSubCategoryID = imd.InstrumentTypeSubCategoryID
GROUP BY sc.InstrumentTypeSubCategoryID, sc.InstrumentTypeSubCategoryName
ORDER BY InstrumentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInstrumentTypeSubCategoryForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInstrumentTypeSubCategoryForAPI.sql*
