# Trade.OrpanedPositionDetailsType

> A table-valued parameter type for passing orphaned position details (PositionID, ParentPositionID, and Cmd) to procedures that close or reconcile orphaned positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID, ParentPositionID (semantic) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.OrpanedPositionDetailsType is a table-valued parameter type that carries details for orphaned positions - positions whose parent linkage is broken or inconsistent. Each row holds PositionID, ParentPositionID, and a Cmd (command or instruction string) describing the action or reason for the orphaned-position handling.

This type exists to support CloseOrpahnedPositions, which accepts a set of orphaned positions and their associated commands. The procedure processes each row to close or reconcile the position according to the Cmd.

The application or reconciliation job builds a table of orphaned position details and passes it as a READONLY parameter to Trade.CloseOrpahnedPositions. The procedure iterates or JOINs against the TVP to process each orphan.

---

## 2. Business Logic

PositionID + ParentPositionID + Cmd form a triple: the orphan position, its (broken) parent reference, and the command/instruction for handling. Cmd may contain SQL, description, or operation code depending on procedure expectations.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | The orphan position identifier. |
| 2 | ParentPositionID | bigint | NO | - | CODE-BACKED | The parent position ID (may be invalid or missing). |
| 3 | Cmd | nvarchar(4000) | NO | - | NAME-INFERRED | Command or instruction for handling this orphan (e.g. close reason, SQL fragment, or operation code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. PositionID and ParentPositionID semantically reference Trade.PositionTbl; no declared FK on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseOrpahnedPositions | @orpanedPositionsToCloseDetails | Parameter (TVP) | Processes orphaned positions for close/reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseOrpahnedPositions | Stored Procedure | READONLY parameter for orphan close processing |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass orphan details

```sql
DECLARE @Orphans Trade.OrpanedPositionDetailsType;
INSERT INTO @Orphans (PositionID, ParentPositionID, Cmd)
VALUES (100001, 99999, 'Close orphan - parent missing'),
       (100002, 99998, 'Close orphan - parent closed');
EXEC Trade.CloseOrpahnedPositions @orpanedPositionsToCloseDetails = @Orphans;
```

### 8.2 Build from reconciliation query

```sql
DECLARE @Orphans Trade.OrpanedPositionDetailsType;
INSERT INTO @Orphans (PositionID, ParentPositionID, Cmd)
SELECT p.PositionID, p.ParentPositionID, 'Reconcile - parent not found'
FROM Trade.PositionTbl p
LEFT JOIN Trade.PositionTbl parent ON p.ParentPositionID = parent.PositionID
WHERE p.ParentPositionID IS NOT NULL AND parent.PositionID IS NULL;
EXEC Trade.CloseOrpahnedPositions @orpanedPositionsToCloseDetails = @Orphans;
```

### 8.3 Single orphan

```sql
DECLARE @Orphan Trade.OrpanedPositionDetailsType;
INSERT INTO @Orphan (PositionID, ParentPositionID, Cmd)
VALUES (50001, 0, 'Manual close orphan');
EXEC Trade.CloseOrpahnedPositions @orpanedPositionsToCloseDetails = @Orphan;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrpanedPositionDetailsType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrpanedPositionDetailsType.sql*
