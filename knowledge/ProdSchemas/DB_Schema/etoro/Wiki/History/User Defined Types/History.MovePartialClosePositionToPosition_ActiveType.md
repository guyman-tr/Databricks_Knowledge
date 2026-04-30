# History.MovePartialClosePositionToPosition_ActiveType

> Memory-optimized table-valued parameter type used to capture the PositionID and partition key of positions moved from History.PositionClosePartial to History.Position_Active, enabling the subsequent delete of migrated rows within the same transaction.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | User Defined Type |
| **Key Identifier** | (PositionID, PartitionCol) composite NONCLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (NONCLUSTERED composite PK on PositionID, PartitionCol) |

---

## 1. Business Meaning

This UDT is a purpose-built OUTPUT buffer for the procedure `History.MovePartialClosePositionToPosition_Active`. It holds exactly two columns - PositionID and its partition column (PartitionCol = PositionID % 50) - sufficient to uniquely identify each position row in the partitioned `History.PositionClosePartial` table. The type is declared inside the procedure and populated via the OUTPUT clause of the INSERT INTO `History.Position_Active`, then immediately used to drive the matching DELETE from `History.PositionClosePartial`.

The type exists to solve a specific transactional integrity problem: when migrating a batch of partially-closed positions from the staging table to the active history table, the procedure must delete exactly the same rows it just inserted - no more, no fewer. The MEMORY_OPTIMIZED flag enables this to work in lock-free, high-throughput batch migration jobs without contention on the staging table.

Data flows in one direction: `History.PositionClosePartial` -> (INSERT INTO) `History.Position_Active` -> (OUTPUT INTO @MovePositionID) -> (DELETE FROM) `History.PositionClosePartial`. The TVP variable acts as the transient "what was moved" manifest that powers the cleanup step.

---

## 2. Business Logic

### 2.1 INSERT-OUTPUT-DELETE Pattern for Atomic Batch Migration

**What**: Ensures that exactly the positions inserted into History.Position_Active are deleted from History.PositionClosePartial in the same transaction.

**Columns/Parameters Involved**: `PositionID`, `PartitionCol`

**Rules**:
- The INSERT ... OUTPUT clause populates `@MovePositionID` with (PositionID, PositionID%50) for every row inserted
- The DELETE then JOINs `History.PositionClosePartial` to `@MovePositionID` on both PositionID AND PartitionCol, AND applies the same `@StartPartitionID / @EndPartitionID` range filter
- The triple JOIN condition prevents accidental deletion of rows outside the batch's partition range
- Both operations are inside a single BEGIN TRAN / COMMIT, making the move atomic

**Diagram**:
```
History.PositionClosePartial (staging)
  WHERE PartitionCol BETWEEN @Start AND @End
         |
         | INSERT TOP(@Batch)
         v
History.Position_Active
         |
         | OUTPUT inserted.PositionID, inserted.PositionID%50
         v
@MovePositionID (this type)
         |
         | INNER JOIN on (PositionID, PartitionCol, partition range)
         v
DELETE from History.PositionClosePartial
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key component. The unique position identifier from History.Position_Active. Captured from `inserted.PositionID` in the OUTPUT clause. Used to drive the matching DELETE from History.PositionClosePartial. Part of composite PK (PositionID, PartitionCol). |
| 2 | PartitionCol | bigint | NO | - | CODE-BACKED | Partition routing key. Computed as `PositionID % 50` in the OUTPUT clause (`inserted.PositionID % 50`). History.PositionClosePartial is physically partitioned on this column (50 partition buckets, 0-49). Included in the DELETE JOIN condition to ensure the correct physical partition shard is targeted, preventing cross-partition false matches. Part of composite PK (PositionID, PartitionCol). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position_Active | Implicit | Identifies the position that was just inserted into the active history table |
| PositionID + PartitionCol | History.PositionClosePartial | Implicit | Used to DELETE the source row after successful migration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.MovePartialClosePositionToPosition_Active | @MovePositionID | Local variable | Declared and populated via OUTPUT clause of INSERT into History.Position_Active |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.MovePartialClosePositionToPosition_Active | Stored Procedure | Sole consumer - declares `@MovePositionID` of this type; uses OUTPUT clause to populate it during batch INSERT, then JOINs it for the cleanup DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | NONCLUSTERED composite (memory-optimized) | PositionID ASC, PartitionCol ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY on (PositionID, PartitionCol) | PRIMARY KEY NONCLUSTERED | Required by SQL Server for MEMORY_OPTIMIZED table types. Composite key ensures uniqueness per (position, partition) pair within the migration batch. |
| MEMORY_OPTIMIZED = ON | Table Option | Enables lock-free in-memory operation. Critical for high-throughput batch migration jobs processing History.PositionClosePartial across 50 partition buckets. |

---

## 8. Sample Queries

### 8.1 Typical usage pattern inside a migration procedure

```sql
DECLARE @MovePositionID History.MovePartialClosePositionToPosition_ActiveType;

INSERT INTO History.Position_Active (PositionID, ...)
OUTPUT inserted.PositionID, inserted.PositionID % 50
INTO @MovePositionID (PositionID, PartitionCol)
SELECT TOP (1000) PositionID, ...
FROM History.PositionClosePartial WITH (NOLOCK)
WHERE PartitionCol BETWEEN 0 AND 9;

DELETE a
FROM History.PositionClosePartial a
INNER JOIN @MovePositionID b
    ON a.PositionID = b.PositionID
    AND a.PartitionCol = b.PartitionCol
    AND a.PartitionCol BETWEEN 0 AND 9;
```

### 8.2 Inspect the type definition

```sql
SELECT c.name, t.name AS type_name, c.is_nullable, c.column_id
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON c.user_type_id = t.user_type_id
WHERE tt.schema_id = SCHEMA_ID('History')
  AND tt.name = 'MovePartialClosePositionToPosition_ActiveType'
ORDER BY c.column_id;
```

### 8.3 Check partition distribution of PositionClosePartial (source table)

```sql
SELECT PartitionCol, COUNT(*) AS RowCount
FROM History.PositionClosePartial WITH (NOLOCK)
GROUP BY PartitionCol
ORDER BY PartitionCol;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MovePartialClosePositionToPosition_ActiveType | Type: User Defined Type | Source: etoro/etoro/History/User Defined Types/History.MovePartialClosePositionToPosition_ActiveType.sql*
