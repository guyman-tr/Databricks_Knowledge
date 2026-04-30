# Hedge.IDs

> Memory-optimized table-valued parameter type for passing a set of integer IDs to stored procedures that need to filter by a caller-provided list.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type - MEMORY_OPTIMIZED) |
| **Key Identifier** | ID (PRIMARY KEY NONCLUSTERED) |
| **Partition** | N/A |
| **Indexes** | 1 (PK NONCLUSTERED on ID) |

---

## 1. Business Meaning

`Hedge.IDs` is a minimalist, memory-optimized Table-Valued Parameter (TVP) type for passing a set of integer IDs to a stored procedure. The `MEMORY_OPTIMIZED = ON` flag means this TVP lives entirely in SQL Server in-memory OLTP structures, eliminating I/O overhead for the parameter passing operation.

This pattern - a single-column ID TVP - is commonly used instead of a comma-separated string or XML parameter for set-based filtering. The caller populates it with a list of IDs, and the SP joins or filters against it using standard set operations.

The only known consumer is `Hedge.GetAggregatedAccountTransactionsByType`, which uses the TVP to filter account transactions by a caller-provided set of IDs. The memory-optimized nature suits high-frequency calls where parameter marshalling overhead matters.

---

## 2. Business Logic

### 2.1 Memory-Optimized ID Passing Pattern

**What**: Passing a variable-length list of integers to a stored procedure without string parsing.

**Columns/Parameters Involved**: `ID`

**Rules**:
- The PK NONCLUSTERED constraint ensures O(log n) lookup performance within the TVP.
- `MEMORY_OPTIMIZED = ON` means the TVP data never hits disk - it is held entirely in DRAM, making parameter passing nearly zero-cost.
- The caller must pass this TVP using a memory-optimized table variable (`DECLARE @ids [Hedge].[IDs]`).
- The consumer SP uses `JOIN @ids i ON ... = i.ID` or `WHERE ... IN (SELECT ID FROM @ids)`.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | An integer identifier value. The semantic meaning depends on the consumer SP - in Hedge.GetAggregatedAccountTransactionsByType, this is a transaction type ID or account ID used to filter the aggregation. PK ensures no duplicate IDs in the set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (generic ID container - semantic meaning is context-dependent).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetAggregatedAccountTransactionsByType | @IDs parameter | TVP parameter | Uses this type to pass a set of IDs for filtering account transaction aggregation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetAggregatedAccountTransactionsByType | Stored Procedure | Passes a set of integer IDs for filtering account transactions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (inline) | NONCLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MEMORY_OPTIMIZED | Storage | TVP lives entirely in DRAM - no disk I/O for parameter passing |
| PK (inline) | PRIMARY KEY NONCLUSTERED | Guarantees no duplicate ID values in the set |

---

## 8. Sample Queries

### 8.1 Declare and use the TVP for set-based filtering
```sql
DECLARE @FilterIDs [Hedge].[IDs]
INSERT INTO @FilterIDs (ID) VALUES (1), (2), (5), (10)

EXEC [Hedge].[GetAggregatedAccountTransactionsByType]
    @HedgeServerID = 1,
    @IDs = @FilterIDs
```

### 8.2 Check account transaction types available for filtering
```sql
SELECT DISTINCT TransactionTypeID
FROM [Hedge].[AccountTransactions] WITH (NOLOCK)
ORDER BY TransactionTypeID
```

### 8.3 Verify the type is memory-optimized
```sql
SELECT name, is_memory_optimized
FROM sys.table_types WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('Hedge')
  AND name = 'IDs'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.IDs | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.IDs.sql*
