# Trade.SynPositionEndedWithTOError

> Synonym pointing to the PositionEndedWithTOError table on the AO-REAL-DB linked server, enabling the Trade schema to log positions that ended with timeout errors during open, close, or SL edit operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB].[etoro].[Trade].[PositionEndedWithTOError] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynPositionEndedWithTOError is a synonym that provides local access to the PositionEndedWithTOError table on the AO-REAL-DB linked server. This table logs trading operations (position open, close, or stop-loss edit) that completed but experienced a timeout error during execution. These are positions where the database operation succeeded but the calling service did not receive a timely response, creating a potential inconsistency between the application state and the database state.

The synonym exists because timeout error tracking is centralized on the AO-REAL-DB server, which serves as a cross-datacenter operational monitoring endpoint. The Trade schema writes to this table when a position operation exceeds its configured timeout threshold, enabling operations teams to identify and reconcile positions that may need manual intervention.

The primary consumers are Trade.PositionOpenWithTimeout, Trade.PositionCloseWithTimeout, and Trade.PositionEditSLWithTimeout - three procedures that wrap standard position operations with timeout detection and error logging.

---

## 2. Business Logic

### 2.1 Timeout Error Tracking Pattern

**What**: Position operations (open/close/SL edit) that exceed their timeout threshold are logged for operational monitoring and reconciliation.

**Columns/Parameters Involved**: N/A (synonym targets a remote table)

**Rules**:
- When a position operation completes but the response exceeds the timeout from SynPositionTimeOuts, the error is logged here
- The companion synonym Trade.SynPositionTimeOuts provides the timeout configuration thresholds
- Operations teams use this data to identify positions that may have succeeded in the DB but failed at the application layer

**Diagram**:
```
Position Operation (Open/Close/EditSL)
    |
    +-- Check timeout from SynPositionTimeOuts
    |
    +-- If timeout exceeded:
          +-- INSERT into SynPositionEndedWithTOError
          +-- Raise timeout alert
```

---

## 3. Data Overview

N/A for synonym (targets a table on a linked server).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [AO-REAL-DB].[etoro].[Trade].[PositionEndedWithTOError]. A table logging position operations that completed with timeout errors, used for reconciliation between application and database states. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [AO-REAL-DB].[etoro].[Trade].[PositionEndedWithTOError] | Synonym target | Linked server reference to the timeout error logging table on AO-REAL-DB |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpenWithTimeout | INSERT | Writer | Logs position open operations that exceeded timeout thresholds |
| Trade.PositionCloseWithTimeout | INSERT | Writer | Logs position close operations that exceeded timeout thresholds |
| Trade.PositionEditSLWithTimeout | INSERT | Writer | Logs stop-loss edit operations that exceeded timeout thresholds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynPositionEndedWithTOError (synonym)
  +-- [AO-REAL-DB].[etoro].[Trade].[PositionEndedWithTOError] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB].[etoro].[Trade].[PositionEndedWithTOError] | Remote Table (Linked Server) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpenWithTimeout | Stored Procedure | Writes timeout error records for position opens |
| Trade.PositionCloseWithTimeout | Stored Procedure | Writes timeout error records for position closes |
| Trade.PositionEditSLWithTimeout | Stored Procedure | Writes timeout error records for SL edits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SynPositionEndedWithTOError'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynPositionEndedWithTOError') AS ObjectID
```

### 8.3 Preview recent timeout errors (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynPositionEndedWithTOError WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynPositionEndedWithTOError | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynPositionEndedWithTOError.sql*
