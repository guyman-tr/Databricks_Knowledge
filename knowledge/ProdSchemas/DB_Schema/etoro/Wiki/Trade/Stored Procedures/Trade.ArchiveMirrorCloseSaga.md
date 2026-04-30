# Trade.ArchiveMirrorCloseSaga

> Archives a completed mirror (copy-trading) close saga by atomically deleting from the active table and inserting into history, with a computed SagaCloseReason based on mirror existence.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID (INT), @CID (INT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure archives a completed mirror close saga. When a CopyTrader relationship is being closed (copier stops copying a leader), the close process is managed as a multi-step saga in `Trade.MirrorCloseSaga`. Once all copied positions are closed and the mirror relationship is deactivated, this procedure moves the saga to `History.MirrorCloseSaga`.

The procedure adds a computed `SagaCloseReason` column: if the mirror still exists in Trade.Mirror at archive time (LEFT JOIN finds a match), SagaCloseReason = 1 (mirror persists); if the mirror has been removed, SagaCloseReason = 0 (mirror fully deleted). This distinguishes normal closes (mirror deactivated but row kept) from full removals.

---

## 2. Business Logic

### 2.1 Atomic Archive with Close Reason Computation

**What**: DELETE...OUTPUT...INTO with a computed column based on mirror existence.

**Columns/Parameters Involved**: `MirrorID`, `CID`, `CurrentStepIndex`, `InitialRequestGuid`, `MirrorCloseActionType`, `CreateDate`, `ClientRequestId`

**Rules**:
- DELETE WHERE saga.MirrorID = @MirrorID AND saga.CID = @CID
- LEFT JOIN to Trade.Mirror to check if the mirror record still exists
- SagaCloseReason = CASE WHEN mirror.MirrorID IS NULL THEN 0 ELSE 1 END
- History table renames CurrentStepIndex to LastStepIndex

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror (copy-trading) relationship ID whose close saga is complete. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the copier. Used with MirrorID to uniquely identify the saga. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | Trade.MirrorCloseSaga | DELETER | Removes completed saga from active table |
| LEFT JOIN | Trade.Mirror | READER | Checks if mirror still exists for SagaCloseReason |
| OUTPUT INTO | History.MirrorCloseSaga | WRITER | Archives saga with LastStepIndex and SagaCloseReason |

### 5.2 Referenced By (other objects point to this)

Called by the mirror close orchestration service after saga completion.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ArchiveMirrorCloseSaga (procedure)
+-- Trade.MirrorCloseSaga (table)
+-- Trade.Mirror (table)
+-- History.MirrorCloseSaga (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorCloseSaga | Table | DELETE - removes completed saga |
| Trade.Mirror | Table | LEFT JOIN - checks mirror existence for close reason |
| History.MirrorCloseSaga | Table | INSERT via OUTPUT - archives with close metadata |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Archive a completed mirror close saga

```sql
EXEC Trade.ArchiveMirrorCloseSaga @MirrorID = 12345, @CID = 67890;
```

### 8.2 Check active mirror close sagas

```sql
SELECT * FROM Trade.MirrorCloseSaga WITH (NOLOCK) ORDER BY CreateDate DESC;
```

### 8.3 Review archived mirror close history

```sql
SELECT  TOP 20 MirrorID, CID, LastStepIndex, MirrorCloseActionType, CreateDate, SagaCloseReason
FROM    History.MirrorCloseSaga WITH (NOLOCK)
ORDER BY CreateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ArchiveMirrorCloseSaga | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ArchiveMirrorCloseSaga.sql*
