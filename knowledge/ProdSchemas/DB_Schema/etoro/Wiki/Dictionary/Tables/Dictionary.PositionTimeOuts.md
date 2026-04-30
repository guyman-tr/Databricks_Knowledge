# Dictionary.PositionTimeOuts

> Operational tracking table recording the last execution time of 3 timeout-based trading procedures — PositionClose, PositionEditSL, and PositionOpen with timeout handling.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT, no PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 0 active (no PK, no indexes) |

---

## 1. Business Meaning

Dictionary.PositionTimeOuts tracks the last execution timestamp of three critical trading procedures that implement timeout-based execution. These procedures handle position operations (open, close, edit stop-loss) with built-in timeout protection — if the operation doesn't complete within a defined window, it fails gracefully rather than hanging indefinitely.

This table exists as an operational heartbeat monitor. By recording when each timeout-protected procedure last ran, the operations team can detect if a procedure has stopped executing (stalled execution engine) or if timeouts are occurring more frequently than expected. The LastExecute timestamps provide a quick health check for the trading engine's timeout subsystem.

The table is read and updated by Trade.PositionCloseWithTimeout, Trade.PositionEditSLWithTimeout, and Trade.PositionOpenWithTimeout. It has synonyms in both the Dictionary and Trade schemas (Dictionary.SynPositionTimeOuts, Trade.SynPositionTimeOuts) for cross-schema access.

---

## 2. Business Logic

### 2.1 Timeout Procedure Monitoring

**What**: Three trading procedures with timeout protection record their last execution time for operational monitoring.

**Columns/Parameters Involved**: `ID`, `ProcName`, `LastExecute`

**Rules**:
- **PositionCloseWithTimeout (1)** — Monitors the last execution of the position close operation with timeout protection.
- **PositionEditSLWithTimeout (2)** — Monitors the last execution of the stop-loss edit operation with timeout protection.
- **PositionOpenWithTimeout (3)** — Monitors the last execution of the position open operation with timeout protection.
- Each procedure updates its LastExecute timestamp upon execution. A stale timestamp (significantly older than expected) indicates the procedure is no longer running.
- All three procedures last executed on 2021-03-07, suggesting this monitoring mechanism may be deprecated or the timeout wrappers are no longer actively used.

**Diagram**:
```
Timeout Procedure Monitor
├── 1 = Trade.PositionCloseWithTimeout  → LastExecute tracks close operations
├── 2 = Trade.PositionEditSLWithTimeout → LastExecute tracks SL edits
└── 3 = Trade.PositionOpenWithTimeout   → LastExecute tracks open operations
         │
         └── Stale timestamp? → Alert: execution engine may be stalled
```

---

## 3. Data Overview

| ID | ProcName | LastExecute | Meaning |
|---|---|---|---|
| 1 | Trade.PositionCloseWithTimeout | 2021-03-07 08:40:34 | Last recorded execution of the timeout-protected position close procedure. The 2021 date suggests this monitoring path may be deprecated. |
| 2 | Trade.PositionEditSLWithTimeout | 2021-03-07 08:40:34 | Last recorded execution of the timeout-protected stop-loss edit procedure. Same date as other entries, indicating all three were last used simultaneously. |
| 3 | Trade.PositionOpenWithTimeout | 2021-03-07 08:40:34 | Last recorded execution of the timeout-protected position open procedure. All three procedures appear to have been decommissioned on the same date. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | - | VERIFIED | Identifier for the timeout procedure. 1=PositionCloseWithTimeout, 2=PositionEditSLWithTimeout, 3=PositionOpenWithTimeout. No PK constraint — the table relies on the consuming procedures to maintain data integrity. |
| 2 | ProcName | varchar(100) | NO | - | VERIFIED | Full qualified name of the trading procedure being monitored (e.g., "Trade.PositionCloseWithTimeout"). Used for display and identification in operational dashboards. |
| 3 | LastExecute | datetime | NO | - | VERIFIED | Timestamp of the last successful execution of the procedure. Updated each time the procedure runs. A stale value indicates the procedure is no longer executing. All currently show 2021-03-07, indicating likely deprecation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.SynPositionTimeOuts | - | Synonym | Cross-schema access synonym in Dictionary schema |
| Trade.SynPositionTimeOuts | - | Synonym | Cross-schema access synonym in Trade schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionCloseWithTimeout | Stored Procedure | Reads and updates LastExecute for close operations |
| Trade.PositionEditSLWithTimeout | Stored Procedure | Reads and updates LastExecute for SL edit operations |
| Trade.PositionOpenWithTimeout | Stored Procedure | Reads and updates LastExecute for open operations |
| Dictionary.SynPositionTimeOuts | Synonym | Cross-schema reference |
| Trade.SynPositionTimeOuts | Synonym | Cross-schema reference |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table has no primary key constraint.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all timeout procedures with last execution
```sql
SELECT  ID,
        ProcName,
        LastExecute
FROM    [Dictionary].[PositionTimeOuts] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find procedures that haven't run recently
```sql
SELECT  ProcName,
        LastExecute,
        DATEDIFF(DAY, LastExecute, GETDATE()) AS DaysSinceLastRun
FROM    [Dictionary].[PositionTimeOuts] WITH (NOLOCK)
WHERE   DATEDIFF(DAY, LastExecute, GETDATE()) > 30
ORDER BY LastExecute;
```

### 8.3 Check operational health of timeout procedures
```sql
SELECT  ProcName,
        LastExecute,
        CASE WHEN DATEDIFF(HOUR, LastExecute, GETDATE()) <= 1 THEN 'HEALTHY'
             WHEN DATEDIFF(DAY, LastExecute, GETDATE()) <= 1 THEN 'WARNING'
             ELSE 'STALE (likely deprecated)'
        END AS HealthStatus
FROM    [Dictionary].[PositionTimeOuts] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PositionTimeOuts | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PositionTimeOuts.sql*
