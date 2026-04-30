# Trade.GetDictionaryStocksIndustry

> Stocks industry lookup with a default row. Passthrough from Dictionary.StocksIndustry plus a synthetic (0, '') row for instruments without an industry classification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | IndustryID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDictionaryStocksIndustry exposes the stock industry classification lookup from Dictionary.StocksIndustry, augmented with a default row (IndustryID=0, IndustryName='') for instruments that have no industry assigned. The view answers: "What industry sectors exist for stock classification, and what value represents 'none'?"

The view exists so callers can safely JOIN on IndustryID without handling NULL - instruments with NULL StocksIndustryID can map to 0, and the empty string provides a display label. Trade.UpdateInstrumentsMetaDataConfigurations and Trade.UpdateInstrumentsMetaDataConfigurationsExtend JOIN to this view when validating or updating industry assignments on instrument metadata.

Data flows: The view reads from Dictionary.StocksIndustry (real industries) and UNION ALL adds the synthetic row. No write path. Consuming procedures use the view as a lookup source for industry validation and display.

---

## 2. Business Logic

### 2.1 Default Row for Unclassified Instruments

**What**: IndustryID=0 with empty IndustryName provides a safe fallback when an instrument has no industry.

**Columns/Parameters Involved**: `IndustryID`, `IndustryName`

**Rules**:
- Real rows: IndustryID > 0, IndustryName from Dictionary.StocksIndustry (e.g., 1=Basic Materials, 3=Consumer Goods).
- Synthetic row: IndustryID=0, IndustryName=''. Used when ISNULL(IndustryID, 0) or similar patterns need a display value.
- Trade.UpdateInstrumentsMetaDataConfigurations: `left join Trade.GetDictionaryStocksIndustry TGDSI on IMDCT.IndustryID = TGDSI.IndustryID` - validates industry exists or maps to default.

**Diagram**:
```
Dictionary.StocksIndustry (1..N industries)
         |
         v
   SELECT IndustryID, IndustryName
         |
         +---- UNION ALL ---- SELECT 0, ''
         |
         v
   Trade.GetDictionaryStocksIndustry (all industries + default)
```

---

## 3. Data Overview

| IndustryID | IndustryName | Meaning |
|---|---|---|
| 1 | Basic Materials | Real industry from lookup. Used for commodities, mining, chemicals stocks. |
| 2 | Conglomerates | Diversified holding companies. |
| 3 | Consumer Goods | Consumer products and retail. |
| 4 | Financial | Banks, insurance, financial services. |
| 5 | Healthcare | Pharmaceuticals, biotech, healthcare providers. |
| 0 | (empty) | Synthetic default row. Instruments without industry (forex, crypto, or unclassified stocks) map here. |

**Selection criteria**: First 5 real rows from live sample plus the default row (0,'') from DDL. Shows variety of industry classifications.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IndustryID | int | NO | - | CODE-BACKED | Industry identifier. From Dictionary.StocksIndustry; 0 = synthetic default for unclassified instruments. (Source: Dictionary.StocksIndustry) |
| 2 | IndustryName | varchar | NO | - | CODE-BACKED | Human-readable industry label (e.g., "Basic Materials", "Healthcare"). Empty string ('') for IndustryID=0. (Source: Dictionary.StocksIndustry) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IndustryID | Dictionary.StocksIndustry | Lookup | Base table for real industry rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsMetaDataConfigurations | TGDSI | LEFT JOIN | Validates industry when updating metadata. |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | TGDSI | LEFT JOIN | Same validation in extended config flow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDictionaryStocksIndustry (view)
└── Dictionary.StocksIndustry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.StocksIndustry | Table | FROM - base lookup plus UNION ALL default row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsMetaDataConfigurations | Procedure | LEFT JOIN for industry validation |
| Trade.UpdateInstrumentsMetaDataConfigurationsExtend | Procedure | LEFT JOIN for industry validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all industries including default
```sql
SELECT IndustryID, IndustryName
  FROM Trade.GetDictionaryStocksIndustry WITH (NOLOCK)
 ORDER BY IndustryID;
```

### 8.2 Resolve instrument metadata industry to name
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.StocksIndustryID,
       tgdsi.IndustryName
  FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
  LEFT JOIN Trade.GetDictionaryStocksIndustry tgdsi WITH (NOLOCK)
    ON imd.StocksIndustryID = tgdsi.IndustryID
 WHERE imd.InstrumentTypeID = 5
 ORDER BY imd.InstrumentID;
```

### 8.3 Instruments with no industry (default 0)
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.StocksIndustryID
  FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
  JOIN Trade.GetDictionaryStocksIndustry tgdsi WITH (NOLOCK)
    ON ISNULL(imd.StocksIndustryID, 0) = tgdsi.IndustryID
 WHERE tgdsi.IndustryID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDictionaryStocksIndustry | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetDictionaryStocksIndustry.sql*
