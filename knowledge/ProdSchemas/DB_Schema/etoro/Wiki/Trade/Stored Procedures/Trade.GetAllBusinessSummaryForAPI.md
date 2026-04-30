# Trade.GetAllBusinessSummaryForAPI

> Returns industry classification and company description for all instruments that have business summary data, for the Meta Data API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Instruments with Industry or CompanyInfo populated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure feeds the public Meta Data API with business summary information for tradeable instruments. It returns the instrument's industry classification and company description text for every instrument that has at least one of these fields populated.

This is part of a family of "GetAll...ForAPI" procedures (alongside GetAllCurrencyDatasForAPI, GetAllExchangeInfosForAPI) that serve as data providers for the platform's public instrument metadata API. The API exposes this data to clients for displaying company and industry information in the trading UI.

---

## 2. Business Logic

### 2.1 Non-Null Filter

**What**: Returns only instruments where Industry or CompanyInfo is populated.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.Industry`, `Trade.InstrumentMetaData.CompanyInfo`

**Rules**:
- Filters with `WHERE (Industry IS NOT NULL OR CompanyInfo IS NOT NULL)`
- Instruments without any business summary data are excluded
- No ordering specified

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Output Columns

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | InstrumentID | INT | CODE-BACKED | Unique identifier for the tradeable instrument. |
| 2 | Industry | NVARCHAR | CODE-BACKED | Industry classification of the instrument (e.g., "Technology", "Financial Services"). |
| 3 | CompanyInfo | NVARCHAR | CODE-BACKED | Description or summary of the company/asset behind the instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentMetaData | Direct Read | Instrument business summary data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllBusinessSummaryForAPI (procedure)
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Source of industry and company info |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all business summaries

```sql
EXEC Trade.GetAllBusinessSummaryForAPI;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllBusinessSummaryForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllBusinessSummaryForAPI.sql*
