# dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints

> Table-valued function that converts a comma-delimited string of integers into a table of int values using a recursive CTE approach, optimized for large lists up to 8000 characters.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Multi-Statement Table-Valued Function |
| **Key Identifier** | Returns TABLE (Value int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints converts a comma-separated string of integers (e.g., "1,2,3,4,5") into a table with one row per integer value. Unlike fn_Split and fn_ParseText2Table which use iterative parsing, this function uses a recursive CTE that generates position numbers 1-8000 and uses CHARINDEX to find comma boundaries.

Used when stored procedures need to accept a list of integer IDs as a single varchar parameter and JOIN against them.

---

## 2. Business Logic

### 2.1 Recursive CTE Integer Parser

**What**: High-performance comma-to-table conversion for integer lists.

**Columns/Parameters Involved**: `@List`

**Rules**:
- Input must be comma-separated integers (no spaces)
- Uses OPTION (MAXRECURSION 0) to support lists up to 8000 characters
- Returns only int values - non-integer segments will cause conversion errors
- More performant than iterative approaches for large lists

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @List | varchar(8000) | NO | - | VERIFIED | Comma-delimited string of integers to parse. E.g., "1,2,3,100,200". |
| 2 | Value (return) | int | YES | - | VERIFIED | Each parsed integer value as a separate row. |

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

### 8.1 Basic integer list parsing
```sql
SELECT Value FROM dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints('10,20,30,40,50')
```

### 8.2 Use as IN-list replacement for affiliate filtering
```sql
SELECT a.*
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
JOIN dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints(@AffiliateIDs) ids ON a.AffiliateID = ids.Value
```

### 8.3 Count parsed values
```sql
SELECT COUNT(*) AS ItemCount
FROM dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints('1,2,3,4,5,6,7,8,9,10')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints | Type: Multi-Statement TVF | Source: fiktivo/dbo/Functions/dbo.Ufn_Turn_Var_List_Into_Table_Of_Ints.sql*
