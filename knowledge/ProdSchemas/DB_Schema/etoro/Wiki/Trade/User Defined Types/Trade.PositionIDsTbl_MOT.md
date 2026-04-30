# Trade.PositionIDsTbl_MOT

> A memory-optimized table-valued parameter type for passing batches of position IDs to procedures, optimized for high-throughput close-order and context-data operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | IX_PositionID (NONCLUSTERED) |

---

## 1. Business Meaning

Trade.PositionIDsTbl_MOT is a memory-optimized TVP type for passing sets of position IDs into stored procedures. It is the MOT counterpart of Trade.PositionIDsTbl - same single-column design but with MEMORY_OPTIMIZED=ON and a nonclustered index on PositionID for fast lookups in JOINs. It is used when procedures need to filter or scope operations to specific positions with minimal latency.

This type exists for close-order and context-data flows that run at high volume. GetOrderForCloseContextData and GetOrderForCloseContextData_EladTest accept this type to retrieve close context for a batch of positions. The memory-optimized design reduces contention and I/O compared to disk-based TVPs.

Application or trading services collect position IDs, populate this type, and pass it READONLY to the procedure. The procedure JOINs against the TVP to scope its query to the specified positions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column position ID list with index for efficient JOINs.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position ID - identifies a trading position in Trade.PositionTbl. Used for bulk filtering in close-order context and related operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID semantically references Trade.PositionTbl.PositionID; no declared FK.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderForCloseContextData | @PositionIDs | Parameter (TVP) | Retrieves close-order context for specified positions |
| Trade.GetOrderForCloseContextData_EladTest | @PositionIDs | Parameter (TVP) | Test version of close-order context retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderForCloseContextData | Stored Procedure | READONLY parameter for close-order context |
| Trade.GetOrderForCloseContextData_EladTest | Stored Procedure | READONLY parameter for close-order context (test) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns |
|-----------|------|-------------|
| IX_PositionID | NONCLUSTERED | PositionID ASC |

Memory-optimized (MEMORY_OPTIMIZED = ON).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for close-order context

```sql
DECLARE @PositionIDs Trade.PositionIDsTbl_MOT;
INSERT INTO @PositionIDs (PositionID)
SELECT PositionID FROM Trade.OrderForClose WITH (NOLOCK) WHERE Status = 1;

EXEC Trade.GetOrderForCloseContextData @CID = 12345, @PositionIDs = @PositionIDs;
```

### 8.2 Build from open positions for a customer

```sql
DECLARE @Positions Trade.PositionIDsTbl_MOT;
INSERT INTO @Positions (PositionID)
SELECT PositionID FROM Trade.PositionTbl WITH (NOLOCK)
WHERE CID = 12345 AND IsOpen = 1;
```

### 8.3 Single position test

```sql
DECLARE @Ids Trade.PositionIDsTbl_MOT;
INSERT INTO @Ids (PositionID) VALUES (900000001);
EXEC Trade.GetOrderForCloseContextData_EladTest @CID = 1, @PositionIDs = @Ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionIDsTbl_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionIDsTbl_MOT.sql*
