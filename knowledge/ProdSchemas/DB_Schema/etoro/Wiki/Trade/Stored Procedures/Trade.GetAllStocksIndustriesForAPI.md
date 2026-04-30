# Trade.GetAllStocksIndustriesForAPI

> Returns all stock industry classifications from the Dictionary.StocksIndustry lookup table for the API layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns IndustryID and IndustryName for all stock industries |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete list of stock industry sectors available on the platform. Industries (e.g., Technology, Healthcare, Financial Services, Consumer Goods) are used to classify stock instruments and enable industry-based filtering and navigation in the trading platform.

The procedure exists to feed the API's industry catalog for stock instrument filtering. The client uses these industry labels to build filter dropdowns in the stock discovery interface.

Data is a simple full read of `Dictionary.StocksIndustry` - a small reference table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct read of the industry dictionary. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IndustryID | INT | NO | - | CODE-BACKED | Primary key of the stock industry. FK target for InstrumentMetaData.StocksIndustryID. |
| 2 | IndustryName | NVARCHAR | NO | - | CODE-BACKED | Display name of the industry (e.g., "Technology", "Healthcare", "Financial Services"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.StocksIndustry | SELECT FROM | Source dictionary table for industry classifications |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllStocksIndustriesForAPI (procedure)
+-- Dictionary.StocksIndustry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.StocksIndustry | Table | SELECT FROM - reads all industry records |

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
EXEC Trade.GetAllStocksIndustriesForAPI;
```

### 8.2 Count instruments per industry
```sql
SELECT  si.IndustryID, si.IndustryName, COUNT(imd.InstrumentID) AS InstrumentCount
FROM    Dictionary.StocksIndustry si WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON si.IndustryID = imd.StocksIndustryID
GROUP BY si.IndustryID, si.IndustryName
ORDER BY InstrumentCount DESC;
```

### 8.3 Find instruments in a specific industry
```sql
SELECT  imd.InstrumentID, imd.InstrumentDisplayName, si.IndustryName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Dictionary.StocksIndustry si WITH (NOLOCK) ON imd.StocksIndustryID = si.IndustryID
WHERE   si.IndustryName = 'Technology';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllStocksIndustriesForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllStocksIndustriesForAPI.sql*
