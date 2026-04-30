# Trade.DeleteDelayedOrderForCloseJob

> Nightly archive-and-purge job that moves completed/removed delayed close orders (StatusID 2=FILLED or 3=REMOVED) from Trade to History, then deletes from Trade.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | StatusID filter (processes FILLED and REMOVED orders) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteDelayedOrderForCloseJob is a nightly maintenance procedure that archives completed delayed close orders from the memory-optimized Trade.DelayedOrderForClose table into History.DelayedOrderForClose. The delayed close order queue holds limit/stop close orders that are pending execution. Once orders reach a terminal state (FILLED=2 when executed, or REMOVED=3 when cancelled), they no longer need to be in the hot memory-optimized table.

This procedure exists to keep the memory-optimized DelayedOrderForClose table lean. Memory-optimized tables consume server memory proportional to row count, so purging completed orders is essential for resource management. The archive to History preserves the full audit trail for compliance and investigation.

Data flow: (1) SELECT all rows with StatusID IN (2, 3) into a temp table. (2) MERGE into History.DelayedOrderForClose (INSERT if new, UPDATE if exists) with 30-day partition elimination. (3) DELETE from Trade.DelayedOrderForClose using the temp table's RequestIdentifier. Error handling captures and returns any errors via SELECT ERROR_MESSAGE().

---

## 2. Business Logic

### 2.1 Terminal Status Selection

**What**: Only FILLED and REMOVED orders are archived. PLACED orders are left in the queue.

**Columns/Parameters Involved**: `StatusID`

**Rules**:
- StatusID = 2 (FILLED): order executed successfully, no longer pending
- StatusID = 3 (REMOVED): order cancelled or expired, no longer pending
- StatusID = 1 (PLACED): order still awaiting execution, NOT archived

### 2.2 Archive-Then-Delete Pattern

**What**: MERGE ensures idempotent archival before deletion from the source table.

**Columns/Parameters Involved**: `RequestIdentifier`

**Rules**:
- MERGE matches on RequestIdentifier with 30-day partition elimination on OccurredAsDate
- INSERT for new records, UPDATE for existing (handles re-runs safely)
- DELETE only after successful MERGE (@@ROWCOUNT > 0)
- All 12 columns preserved in History: RequestIdentifier, OrderID, OriginalOrderID, CID, PositionID, InstrumentID, RequestOccurred, LastUpdate, ActionType, StatusID, RequestGuid, UnitsToDeduct

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure takes no parameters. It runs as a scheduled nightly job, automatically selecting all terminal-state rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT/DELETE) | Trade.DelayedOrderForClose | READ+DELETE | Reads FILLED/REMOVED rows, then deletes after archiving |
| (MERGE) | History.DelayedOrderForClose | WRITER | Archives rows via MERGE (INSERT or UPDATE) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteDelayedOrderForCloseJob (procedure)
+-- Trade.DelayedOrderForClose (table, memory-optimized)
+-- History.DelayedOrderForClose (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForClose | Table | Source - SELECT terminal rows then DELETE |
| History.DelayedOrderForClose | Table | Archive target via MERGE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the nightly archive job

```sql
EXEC Trade.DeleteDelayedOrderForCloseJob
```

### 8.2 Preview rows pending archival

```sql
SELECT  RequestIdentifier, OrderID, CID, PositionID, StatusID, RequestOccurred
FROM    Trade.DelayedOrderForClose WITH (NOLOCK)
WHERE   StatusID IN (2, 3)
```

### 8.3 Verify archival in History

```sql
SELECT  TOP 10 RequestIdentifier, OrderID, StatusID, RequestOccurred
FROM    History.DelayedOrderForClose WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 1 AS DATE)
ORDER BY RequestIdentifier DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteDelayedOrderForCloseJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteDelayedOrderForCloseJob.sql*
