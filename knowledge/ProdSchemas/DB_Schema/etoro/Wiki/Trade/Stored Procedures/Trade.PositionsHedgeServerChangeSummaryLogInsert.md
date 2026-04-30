# Trade.PositionsHedgeServerChangeSummaryLogInsert

> Inserts a new hedge server change summary log entry with a UTC start timestamp and returns the generated SummaryID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT: SummaryID (IDENTITY from Trade.PositionsHedgeServerChangeSummaryLog) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionsHedgeServerChangeSummaryLogInsert is the write entry-point for logging the start of a hedge server change operation. When positions are bulk-migrated between hedge servers (e.g., during infrastructure changes, load balancing, or hedge server decommissioning), a summary log record is created to track the operation. This SP inserts the initial record with a UTC start timestamp and an operator comment, returning the generated SummaryID so the caller can associate individual position change records with this summary.

The SummaryID is used by downstream calls to link individual position-level hedge server changes to the parent operation record in Trade.PositionsHedgeServerChangeSummaryLog.

---

## 2. Business Logic

### 2.1 Summary Log Insert

**What**: Inserts one row into Trade.PositionsHedgeServerChangeSummaryLog and returns the IDENTITY value.

**Columns/Parameters Involved**: Trade.PositionsHedgeServerChangeSummaryLog.StartTime, Comments, @SummaryID OUTPUT

**Rules**:
- StartTime = GETUTCDATE() (always UTC, not local time)
- Comments = @Comments (operator-provided description of the operation)
- @SummaryID = SCOPE_IDENTITY() immediately after INSERT - returns the auto-generated PK
- No transaction wrapping; no error handling block; minimal SP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Comments | VARCHAR(250) | NO | - | CODE-BACKED | Description of the hedge server change operation. Stored in Trade.PositionsHedgeServerChangeSummaryLog.Comments. |
| 2 | @SummaryID | INT | NO | - | CODE-BACKED | OUTPUT. IDENTITY value of the inserted summary log row. Returned via SCOPE_IDENTITY(). Caller uses this to link individual position changes to this summary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Trade.PositionsHedgeServerChangeSummaryLog | DML write | Creates new hedge server change summary log entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repo. Called by hedge server migration tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsHedgeServerChangeSummaryLogInsert (procedure)
+-- Trade.PositionsHedgeServerChangeSummaryLog (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsHedgeServerChangeSummaryLog | Table | INSERT StartTime, Comments; read SCOPE_IDENTITY() for SummaryID |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No error handling; failures propagate to caller
- StartTime is always GETUTCDATE() - cannot be overridden by caller

---

## 8. Sample Queries

### 8.1 Start a hedge server change log entry

```sql
DECLARE @SummaryID INT;
EXEC Trade.PositionsHedgeServerChangeSummaryLogInsert
    @Comments  = 'Migrating positions from HedgeServer-7 to HedgeServer-12 for maintenance window',
    @SummaryID = @SummaryID OUTPUT;
SELECT @SummaryID AS NewSummaryID;
```

### 8.2 Check recent summary log entries

```sql
SELECT SummaryID, StartTime, Comments
FROM Trade.PositionsHedgeServerChangeSummaryLog WITH (NOLOCK)
ORDER BY StartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsHedgeServerChangeSummaryLogInsert | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionsHedgeServerChangeSummaryLogInsert.sql*
