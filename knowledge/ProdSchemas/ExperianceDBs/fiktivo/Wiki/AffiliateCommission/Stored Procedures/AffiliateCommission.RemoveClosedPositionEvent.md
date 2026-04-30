# AffiliateCommission.RemoveClosedPositionEvent

> Deletes a single closed position event by ID after commission calculation has completed, keeping the event table clean of already-processed records.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from ClosedPositionEvent by ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveClosedPositionEvent is the final cleanup step in the closed-position commission pipeline. After a closed position event has been fully evaluated - its commission calculated, persisted via SaveClosedPositionCommission, and any downstream aggregation completed - the event record is no longer needed. This procedure removes that spent event row so the table stays lean and the next pickup cycle (GetClosedPositionTriggeredEvents) does not re-process it.

Without this removal, the ClosedPositionEvent table would grow unboundedly. Each trade closure generates an event, and high-volume trading platforms can close thousands of positions per day. Prompt deletion after processing ensures the triggered-events query remains fast and the table does not become a bottleneck for the commission pipeline.

The procedure accepts a single @ID parameter, targeting one specific event row. This one-at-a-time pattern lets the calling service confirm processing success before issuing the delete, providing a transactional guarantee that no event is lost before its commission is saved.

---

## 2. Business Logic

### 2.1 Single-Row Event Deletion

**What**: Removes exactly one processed closed position event by its primary key.

**Columns/Parameters Involved**: `@ID`, `ClosedPositionEvent.ID`

**Rules**:
- DELETE FROM ClosedPositionEvent WHERE ID = @ID
- Only one row is affected per call (ID is the primary key)
- Called only after commission calculation completes successfully
- If the ID does not exist, the DELETE is a no-op (no error raised)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | bigint (IN) | NO | - | CODE-BACKED | Primary key of the ClosedPositionEvent row to delete. Corresponds to the ID returned by GetClosedPositionTriggeredEvents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | AffiliateCommission.ClosedPositionEvent | WRITE (DELETE) | Removes the event row by primary key |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after SaveClosedPositionCommission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveClosedPositionEvent (procedure)
+-- AffiliateCommission.ClosedPositionEvent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionEvent | Table | DELETE by primary key |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Removes processed events after commission is saved |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed closed position event
```sql
EXEC [AffiliateCommission].[RemoveClosedPositionEvent] @ID = 42001
```

### 8.2 Verify the event was removed
```sql
SELECT ID, ClosedPositionID, AffiliateID, Occurred, [Source]
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
WHERE ID = 42001
```

### 8.3 Count remaining unprocessed events
```sql
SELECT [Source], COUNT(*) AS RemainingEvents
FROM [AffiliateCommission].[ClosedPositionEvent] WITH (NOLOCK)
GROUP BY [Source]
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveClosedPositionEvent | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveClosedPositionEvent.sql*
