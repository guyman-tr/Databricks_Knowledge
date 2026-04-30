# dbo.fn_Split

> Table-valued function that splits a delimited string into a table of individual values, used for parsing comma-separated parameter lists in stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE (position int, value varchar(8000)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.fn_Split splits a delimited string into individual rows, enabling stored procedures to accept comma-separated lists as parameters and process each value individually. This is a common SQL Server utility pattern predating STRING_SPLIT (SQL Server 2016+). Written by Guy Mansano (2011-12-13).

Used throughout the affiliate system wherever procedures need to accept multiple IDs or values as a single string parameter (e.g., "1,2,3,4" -> 4 rows).

---

## 2. Business Logic

### 2.1 String Splitting Algorithm

**What**: Iterative CHARINDEX-based parsing that extracts values between delimiters.

**Columns/Parameters Involved**: `@text`, `@delimiter`

**Rules**:
- Default delimiter is space (' ')
- Returns rows with auto-incrementing position (1-based) and the extracted value
- Handles leading/trailing delimiters
- Empty segments between consecutive delimiters are skipped
- Maximum input length: 8000 characters (varchar limit)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @text | varchar(8000) | NO | - | VERIFIED | The delimited string to split. |
| 2 | @delimiter | varchar(20) | NO | ' ' | VERIFIED | The delimiter character(s). Default is space. Common usage: ',' for comma-separated lists. |
| 3 | position (return) | int IDENTITY | NO | - | VERIFIED | 1-based ordinal position of each extracted value. PK of the return table. |
| 4 | value (return) | varchar(8000) | YES | - | VERIFIED | The extracted value at this position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure string manipulation, no tables).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by procedures that accept comma-separated list parameters.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

### 8.1 Split comma-separated list
```sql
SELECT position, value FROM dbo.fn_Split('10,20,30,40', ',')
```

### 8.2 Use in JOIN to filter by list of IDs
```sql
SELECT a.*
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.fn_Split(@AffiliateIDList, ',') s ON a.AffiliateID = CAST(s.value AS INT)
```

### 8.3 Split with custom delimiter
```sql
SELECT position, value FROM dbo.fn_Split('apple|banana|cherry', '|')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.fn_Split | Type: Multi-Statement TVF | Source: fiktivo/dbo/Functions/dbo.fn_Split.sql*
