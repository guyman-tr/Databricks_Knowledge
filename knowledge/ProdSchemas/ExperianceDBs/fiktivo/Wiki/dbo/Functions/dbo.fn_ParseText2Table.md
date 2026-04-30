# dbo.fn_ParseText2Table

> Table-valued function that parses a delimited string into a table with integer, numeric, and text columns, supporting multi-type value extraction from comma-separated lists.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE (Position int, Int_Value int, Num_value numeric(18,3), txt_value varchar(2000)) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.fn_ParseText2Table parses a delimited string into a table with automatic type detection - each value is stored as integer, numeric, and text simultaneously. This is more versatile than fn_Split as it provides pre-cast numeric values, avoiding the need for CAST/CONVERT in the consuming query. Originally by Clayton Groom (2003), adapted for SQL Server 2000+.

Used when procedures need to accept comma-separated lists and work with the values as numbers (e.g., list of AffiliateIDs, list of CountryIDs).

---

## 2. Business Logic

### 2.1 Multi-Type Parsing

**What**: Each parsed value is stored in three typed columns simultaneously.

**Columns/Parameters Involved**: `@p_SourceText`, `@p_Delimeter`

**Rules**:
- For numeric values: Int_Value = integer cast, Num_value = decimal cast, txt_value = original text
- For non-numeric values: Int_Value = NULL, Num_value = NULL, txt_value = original text
- Uses ISNUMERIC() for type detection
- Default delimiter is comma (',')
- Handles multi-character delimiters

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @p_SourceText | varchar(8000) | NO | - | VERIFIED | The delimited string to parse. |
| 2 | @p_Delimeter | varchar(100) | NO | ',' | VERIFIED | Delimiter character(s). Default comma. Supports multi-character delimiters. |
| 3 | Position (return) | int IDENTITY | NO | - | VERIFIED | 1-based ordinal position of each parsed value. |
| 4 | Int_Value (return) | int | YES | - | VERIFIED | Integer cast of the value. NULL if value is not numeric. |
| 5 | Num_value (return) | numeric(18,3) | YES | - | VERIFIED | Decimal cast of the value with 3 decimal places. NULL if not numeric. |
| 6 | txt_value (return) | varchar(2000) | YES | - | VERIFIED | Original text value after trimming. Always populated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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

### 8.1 Parse comma-separated numbers
```sql
SELECT Position, Int_Value, Num_value, txt_value
FROM dbo.fn_ParseText2Table('100,200,300', ',')
```

### 8.2 Use as ID filter
```sql
SELECT a.*
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.fn_ParseText2Table(@IDList, ',') p ON a.AffiliateID = p.Int_Value
```

### 8.3 Mixed type parsing
```sql
SELECT Position, Int_Value, txt_value
FROM dbo.fn_ParseText2Table('123,hello,456.78,world', ',')
-- Row 1: Int_Value=123, txt_value='123'
-- Row 2: Int_Value=NULL, txt_value='hello'
-- Row 3: Int_Value=456, txt_value='456.78'
-- Row 4: Int_Value=NULL, txt_value='world'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.fn_ParseText2Table | Type: Multi-Statement TVF | Source: fiktivo/dbo/Functions/dbo.fn_ParseText2Table.sql*
