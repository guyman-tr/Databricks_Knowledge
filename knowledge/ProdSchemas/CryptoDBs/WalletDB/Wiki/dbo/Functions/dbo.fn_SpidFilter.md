# dbo.fn_SpidFilter

> Natively compiled inline table-valued function that provides session isolation by filtering rows to only those matching the current session's @@SPID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Inline TVF |
| **Key Identifier** | Returns: fn_SpidFilter (int, always 1 when matched) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function is a native-compiled, schema-bound inline table-valued function that acts as a session isolation filter for memory-optimized tables. It returns a single row with value 1 when the provided `@SpidFilter` parameter matches the current session's `@@spid`, and returns no rows otherwise. This is used as a security predicate pattern for memory-optimized tables where traditional row-level security is not available.

The function exists specifically to support `dbo.GetTransactionRequests`, the memory-optimized session-scoped temporary result table. By constraining that table's SpidFilter column to `@@spid` via a CHECK constraint and providing this function for query filtering, the system ensures complete session isolation without transaction-based locking.

The NATIVE_COMPILATION and SCHEMABINDING hints make this function extremely fast - it executes as compiled C code rather than interpreted T-SQL, which is critical since it runs on every access to the memory-optimized table.

---

## 2. Business Logic

### 2.1 Session Isolation Predicate

**What**: Returns a match only when the input SPID matches the calling session, enabling per-session data isolation.

**Columns/Parameters Involved**: `@SpidFilter` (input), `fn_SpidFilter` (output)

**Rules**:
- Input: @SpidFilter (smallint) - the SPID value to check
- Output: Single column `fn_SpidFilter` = 1 when @SpidFilter = @@spid
- Returns empty result set when @SpidFilter does not match current session
- NATIVE_COMPILATION: Runs as compiled code, not interpreted T-SQL
- SCHEMABINDING: Cannot be dropped while referenced by constraints

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpidFilter (IN) | smallint | NO | - | CODE-BACKED | Session process ID to validate. Compared against @@spid to determine if the calling session matches. |
| 2 | fn_SpidFilter (RETURN) | int | NO | - | CODE-BACKED | Returns 1 when the input @SpidFilter matches @@spid. Empty result set when no match. The return column name matches the function name by convention. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.GetTransactionRequests | SpidFilter | Used with | Memory-optimized table uses this function pattern for session isolation via CHECK constraint on @@spid |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetTransactionRequests | Table | Session isolation pattern - CHECK constraint enforces SpidFilter = @@spid |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | Binding | Function is schema-bound - referenced objects cannot be altered without dropping the function first |
| NATIVE_COMPILATION | Compilation | Compiled to native C code for maximum performance on memory-optimized table access |

---

## 8. Sample Queries

### 8.1 Test the function with current session
```sql
SELECT * FROM dbo.fn_SpidFilter(@@spid)
-- Returns: fn_SpidFilter = 1
```

### 8.2 Test with a different SPID (should return empty)
```sql
SELECT * FROM dbo.fn_SpidFilter(0)
-- Returns: empty result set (0 does not match @@spid)
```

### 8.3 Use in a cross apply pattern
```sql
SELECT gtr.*
FROM dbo.GetTransactionRequests gtr WITH (NOLOCK)
CROSS APPLY dbo.fn_SpidFilter(gtr.SpidFilter) f
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.fn_SpidFilter | Type: Inline TVF | Source: WalletDB/dbo/Functions/dbo.fn_SpidFilter.sql*
