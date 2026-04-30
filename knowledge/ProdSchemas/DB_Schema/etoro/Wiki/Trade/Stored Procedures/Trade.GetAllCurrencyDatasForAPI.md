# Trade.GetAllCurrencyDatasForAPI

> Returns all currencies with their abbreviation and symbol for the Meta Data API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All currencies from Dictionary.Currency where CurrencyID > 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure feeds the public Meta Data API with the platform's supported currencies. It returns the CurrencyID, abbreviation (e.g., "USD", "EUR"), and display symbol (e.g., "$", "€") for every currency in the dictionary, excluding the sentinel row (CurrencyID = 0).

This is part of a family of "GetAll...ForAPI" procedures that populate the platform's public instrument metadata API. The currency data is used in client UIs for displaying monetary values in the correct currency format.

---

## 2. Business Logic

### 2.1 Full Dictionary Read

**What**: Returns all valid currencies from the dictionary.

**Columns/Parameters Involved**: `Dictionary.Currency.CurrencyID`, `Dictionary.Currency.Abbreviation`, `Dictionary.Currency.CurrencySymbol`

**Rules**:
- Filters out CurrencyID = 0 (sentinel/unknown row)
- CurrencySymbol is ISNULL-coalesced to empty string to avoid NULL in the API response
- Uses NOLOCK hint for non-blocking reads

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
| 1 | CurrencyID | INT | CODE-BACKED | Unique identifier for the currency. |
| 2 | Abbreviation | VARCHAR | CODE-BACKED | ISO currency code (e.g., "USD", "EUR", "GBP"). |
| 3 | CurrencySymbol | VARCHAR | CODE-BACKED | Display symbol for the currency (e.g., "$", "€"). Empty string if not defined. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Dictionary.Currency | Direct Read | Currency dictionary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllCurrencyDatasForAPI (procedure)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Currency lookup dictionary |

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

### 8.1 Get all currencies

```sql
EXEC Trade.GetAllCurrencyDatasForAPI;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllCurrencyDatasForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllCurrencyDatasForAPI.sql*
