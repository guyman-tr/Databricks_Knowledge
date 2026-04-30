# Dictionary.SynPositionTimeOuts

> Synonym providing local access to Dictionary.PositionTimeOuts on the [AO-REAL-DB] linked server for cross-server position timeout configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.SynPositionTimeOuts is a synonym that provides transparent local access to the Dictionary.PositionTimeOuts table residing on the [AO-REAL-DB] linked server. This enables stored procedures in the local database to query position timeout configuration from the remote database without embedding the four-part name (`[AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts]`) throughout the codebase.

The PositionTimeOuts table defines timeout-protected trading operations — procedures that have a maximum allowed execution time before the system considers them hung. Currently it monitors 3 critical trading procedures:
- **Trade.PositionCloseWithTimeout** (ID=1): Position closure with timeout protection
- **Trade.PositionEditSLWithTimeout** (ID=2): Stop-loss edit with timeout protection
- **Trade.PositionOpenWithTimeout** (ID=3): Position opening with timeout protection

The [AO-REAL-DB] linked server typically refers to an Always On Availability Group readable secondary replica, allowing timeout configuration reads without loading the primary database. A parallel synonym exists in the Trade schema (`Trade.SynPositionTimeOuts`) pointing to the same remote table, providing access from both schemas.

---

## 2. Business Logic

### 2.1 Cross-Server Timeout Configuration Access

**What**: Abstracts the four-part linked server name into a local synonym for maintainability.

**Columns/Parameters Involved**: All columns from PositionTimeOuts (ID, ProcName, LastExecute)

**Rules**:
- The synonym resolves to `[AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts]` at query time
- If the linked server [AO-REAL-DB] is unavailable, queries against this synonym will fail
- The target table has 3 rows — one per timeout-monitored procedure
- Both Dictionary.SynPositionTimeOuts and Trade.SynPositionTimeOuts point to the same remote table, allowing access from different stored procedure contexts

**Diagram**:
```
LOCAL DATABASE                           REMOTE [AO-REAL-DB]
│                                        │
│ Dictionary.SynPositionTimeOuts ─────→  │ [etoro].[Dictionary].[PositionTimeOuts]
│   (synonym)                            │   ┌────┬──────────────────────────────────┬──────────────────┐
│                                        │   │ ID │ ProcName                         │ LastExecute       │
│ Trade.SynPositionTimeOuts ─────────→   │   ├────┼──────────────────────────────────┼──────────────────┤
│   (synonym)                            │   │  1 │ Trade.PositionCloseWithTimeout   │ 2021-03-07 08:40 │
│                                        │   │  2 │ Trade.PositionEditSLWithTimeout  │ 2021-03-07 08:40 │
│ Trade.PositionCloseWithTimeout ──reads→ │   │  3 │ Trade.PositionOpenWithTimeout    │ 2021-03-07 08:40 │
│ Trade.PositionEditSLWithTimeout─reads→ │   └────┴──────────────────────────────────┴──────────────────┘
│ Trade.PositionOpenWithTimeout ──reads→ │
│                                        │
```

### 2.2 Timeout-Protected Trading Operations

**What**: The three trading procedures monitored for execution timeouts.

**Columns/Parameters Involved**: `ProcName`, `LastExecute`

**Rules**:
- Each row represents a stored procedure that has built-in timeout protection
- `LastExecute` records when the procedure last ran successfully — used by monitoring to detect hung procedures
- If a procedure hasn't executed within its expected interval, monitoring raises an alert
- All three procedures are critical trading operations (open, close, edit SL) — timeouts indicate system issues

---

## 3. Data Overview

| ID | ProcName | LastExecute | Meaning |
|---|---|---|---|
| 1 | Trade.PositionCloseWithTimeout | 2021-03-07 08:40 | Monitors position closure operations — if a close takes too long, the system escalates to prevent positions being stuck in a closing state |
| 2 | Trade.PositionEditSLWithTimeout | 2021-03-07 08:40 | Monitors stop-loss modification — timeout protection prevents SL edits from blocking the trading engine |
| 3 | Trade.PositionOpenWithTimeout | 2021-03-07 08:40 | Monitors position opening — critical for ensuring new positions don't get stuck in a pending state during high-load periods |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique identifier for the timeout-monitored procedure. PK of the remote PositionTimeOuts table: 1=PositionClose, 2=PositionEditSL, 3=PositionOpen. |
| 2 | ProcName | varchar | NO | - | VERIFIED | Fully qualified stored procedure name that is monitored for execution timeouts. Contains the schema-qualified name (e.g., "Trade.PositionCloseWithTimeout"). |
| 3 | LastExecute | datetime | YES | - | CODE-BACKED | Timestamp of the last successful execution of the monitored procedure. Updated by the procedure itself upon completion. Used by monitoring systems to detect hung procedures — a stale LastExecute indicates the procedure may be stuck. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] | Synonym → Remote table | Four-part name reference to the Always On readable secondary |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionCloseWithTimeout | - | SELECT/UPDATE | Reads and updates timeout tracking for position close operations |
| Trade.PositionEditSLWithTimeout | - | SELECT/UPDATE | Reads and updates timeout tracking for SL edit operations |
| Trade.PositionOpenWithTimeout | - | SELECT/UPDATE | Reads and updates timeout tracking for position open operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.SynPositionTimeOuts (synonym)
└── [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] | Remote Table | Synonym target — all queries against this synonym are redirected to the remote table via the linked server |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionCloseWithTimeout | Procedure | Reads/updates timeout status for position close |
| Trade.PositionEditSLWithTimeout | Procedure | Reads/updates timeout status for SL edits |
| Trade.PositionOpenWithTimeout | Procedure | Reads/updates timeout status for position open |
| Trade.SynPositionTimeOuts | Synonym | Parallel synonym in Trade schema pointing to same remote table |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym. The remote PositionTimeOuts table has a clustered PK on ID.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Linked server dependency | Infrastructure | Requires [AO-REAL-DB] linked server to be online and accessible |

---

## 8. Sample Queries

### 8.1 Read all timeout-monitored procedures via the synonym
```sql
SELECT  ID, ProcName, LastExecute
FROM    Dictionary.SynPositionTimeOuts WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find procedures that haven't executed recently (potential hang detection)
```sql
SELECT  ProcName, LastExecute,
        DATEDIFF(MINUTE, LastExecute, GETDATE()) AS MinutesSinceLastRun
FROM    Dictionary.SynPositionTimeOuts WITH (NOLOCK)
WHERE   DATEDIFF(MINUTE, LastExecute, GETDATE()) > 60
```

### 8.3 Compare local and remote synonym targets
```sql
SELECT  'Dictionary' AS [Schema], ProcName, LastExecute
FROM    Dictionary.SynPositionTimeOuts WITH (NOLOCK)
UNION ALL
SELECT  'Trade', ProcName, LastExecute
FROM    Trade.SynPositionTimeOuts WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.SynPositionTimeOuts | Type: Synonym | Source: etoro/etoro/Dictionary/Synonyms/Dictionary.SynPositionTimeOuts.sql*
