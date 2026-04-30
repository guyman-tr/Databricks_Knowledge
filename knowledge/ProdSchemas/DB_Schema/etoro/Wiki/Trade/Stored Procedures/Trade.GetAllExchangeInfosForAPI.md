# Trade.GetAllExchangeInfosForAPI

> Returns all stock exchanges with their description for the Meta Data API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full dump of Dictionary.ExchangeInfo |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure feeds the public Meta Data API with the platform's stock exchange reference data. It returns the ExchangeID and description for every exchange defined in the dictionary (e.g., "NYSE", "NASDAQ", "LSE").

This is part of a family of "GetAll...ForAPI" procedures that populate the platform's public instrument metadata API. Exchange data is used in client UIs to display which exchange a stock or ETF is traded on.

---

## 2. Business Logic

### 2.1 Full Dictionary Read

**What**: Returns all exchanges from the dictionary.

**Columns/Parameters Involved**: `Dictionary.ExchangeInfo.ExchangeID`, `Dictionary.ExchangeInfo.ExchangeDescription`

**Rules**:
- No filtering - returns all rows
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
| 1 | ExchangeID | INT | CODE-BACKED | Unique identifier for the stock exchange. |
| 2 | ExchangeDescription | NVARCHAR | CODE-BACKED | Display name of the exchange (e.g., "New York Stock Exchange", "NASDAQ"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.ExchangeInfo | Direct Read | Exchange dictionary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllExchangeInfosForAPI (procedure)
└── Dictionary.ExchangeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExchangeInfo | Table | Exchange lookup dictionary |

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

### 8.1 Get all exchanges

```sql
EXEC Trade.GetAllExchangeInfosForAPI;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllExchangeInfosForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllExchangeInfosForAPI.sql*
