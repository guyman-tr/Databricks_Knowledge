# dbo.MultipleInsertColumnValuesV2

> Enhanced dynamic SQL utility with batch-size limiting (999 rows per INSERT) for large multi-row inserts. Current production version replacing MultipleInsertColumnValues.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batched dynamic multi-row INSERT from MultipleColumnValueType TVP (999-row batches) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MultipleInsertColumnValuesV2 is the current production version of the multi-row dynamic INSERT utility. It improves on MultipleInsertColumnValues by processing rows in batches of 999 (SQL Server's maximum VALUES clause limit for parameterized queries). Uses a WHILE loop to iterate through RowIds in batch-sized chunks.

---

## 2. Business Logic

### 2.1 Batched Multi-Row Dynamic SQL

**What**: Processes rows in 999-row batches to avoid SQL Server limits.

**Rules**:
- @BatchSize = 999 (hardcoded)
- WHILE loop: processes RowId ranges [@RowId, @RowId + @BatchSize)
- Each iteration builds and executes one INSERT statement
- Same STRING_AGG approach as V1 within each batch
- sp_executesql for execution

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TableName | nvarchar(max) | NO | - | CODE-BACKED | Target table name. |
| 2 | @MultipleColumnValueType | MultipleColumnValueType | NO | READONLY | CODE-BACKED | TVP with RowId + column-name/value triples. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | Any table (dynamic) | Write | Batched dynamic INSERT |
| @param | dbo.MultipleColumnValueType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.MultipleInsertColumnValuesV2 (procedure)
└── dbo.MultipleColumnValueType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.MultipleColumnValueType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. @BatchSize hardcoded to 999.

---

## 8. Sample Queries

### 8.1 Large batch insert
```sql
DECLARE @data dbo.MultipleColumnValueType;
-- Populate with > 999 rows...
EXEC dbo.MultipleInsertColumnValuesV2 @TableName = 'dbo.FiatMerchants', @MultipleColumnValueType = @data;
-- Automatically batches into 999-row chunks
```

### 8.2 Small batch (same as V1)
```sql
DECLARE @data dbo.MultipleColumnValueType;
INSERT INTO @data VALUES (1, 'Description', 'Merchant A'), (2, 'Description', 'Merchant B');
EXEC dbo.MultipleInsertColumnValuesV2 @TableName = 'dbo.FiatMerchants', @MultipleColumnValueType = @data;
```

### 8.3 Verify batch processing
```sql
-- Check row count before and after
SELECT COUNT(*) AS Before FROM dbo.FiatMerchants WITH (NOLOCK);
EXEC dbo.MultipleInsertColumnValuesV2 @TableName = 'dbo.FiatMerchants', @MultipleColumnValueType = @data;
SELECT COUNT(*) AS After FROM dbo.FiatMerchants WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MultipleInsertColumnValuesV2 | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.MultipleInsertColumnValuesV2.sql*
