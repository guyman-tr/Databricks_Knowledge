# BackOffice.DowntimeClose

> Closes an open system downtime incident by marking it as resolved with close status, manager, timestamp, and comment.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DowntimeID - the incident to close |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DowntimeClose marks a system downtime incident as resolved in `BackOffice.Downtime`. It sets the `Closed` flag to 1 and records who closed it, when, how (close status), and with what notes. Note: unlike DowntimeAdd and DowntimeEdit, this procedure does NOT write a History.Downtime record - the closure event is captured only in the live row. The History table for Downtime is only written by Add and Edit operations.

As with all Downtime procedures, this is legacy code from 2009. No incidents have been closed since then (all 5 rows remain Closed=0).

---

## 2. Business Logic

### 2.1 Incident Closure Update

**What**: Single UPDATE marking the incident as resolved.

**Columns/Parameters Involved**: `@DowntimeID`, `Closed`, `ClosedBy`, `TimeClosed`, `CloseComment`, `DowntimeCloseStatusID`

**Rules**:
- UPDATE fires unconditionally - no guard checks if already closed.
- Sets: Closed=1, ClosedBy=@ManagerID, TimeClosed=@TimeClosed, CloseComment=@Comment, DowntimeCloseStatusID=@DowntimeCloseStatusID.
- DowntimeCloseStatusID represents HOW it was resolved (e.g., Fixed, Not Reproducible, Duplicate, By Design - from Dictionary.DowntimeCloseStatus).
- Returns @@ERROR. No transaction wrapping.
- No History.Downtime insert on close (contrast with DowntimeAdd/Edit which both write history).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DowntimeID | INTEGER | NO | - | CODE-BACKED | The incident to close. PK of BackOffice.Downtime. |
| 2 | @DowntimeCloseStatusID | INTEGER | NO | - | CODE-BACKED | How the incident was resolved. FK to Dictionary.DowntimeCloseStatus (e.g., Fixed, Not Reproducible, Duplicate, By Design). Written to BackOffice.Downtime.DowntimeCloseStatusID. |
| 3 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent who closed the incident. Written to BackOffice.Downtime.ClosedBy. FK to BackOffice.Manager. |
| 4 | @TimeClosed | DATETIME | NO | - | CODE-BACKED | When the incident was resolved. Written to BackOffice.Downtime.TimeClosed. |
| 5 | @Comment | VARCHAR(MAX) | NO | - | CODE-BACKED | Resolution notes describing how/why the incident was closed. Written to BackOffice.Downtime.CloseComment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DowntimeID | BackOffice.Downtime | Modifier | UPDATE target - sets Closed=1 and all closure fields. |
| @DowntimeCloseStatusID | Dictionary.DowntimeCloseStatus | Lookup | Resolution type. FK on BackOffice.Downtime. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice tooling | EXEC | Caller | No SQL-layer callers. Last used circa 2009. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DowntimeClose (procedure)
└── BackOffice.Downtime (table) - UPDATE Closed=1 + closure fields
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Downtime | Table | UPDATE - sets Closed=1, ClosedBy, TimeClosed, CloseComment, DowntimeCloseStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice tooling | External | EXEC (abandoned, last used 2009) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No history write | Behavior | Unlike DowntimeAdd/Edit, closure does not create a History.Downtime record. Closure state is only in the live row. |
| No closed-check guard | Behavior | Can re-close an already-closed incident without error. DowntimeEdit blocks editing closed incidents (Closed=1 guard), but DowntimeClose has no equivalent guard. |
| @@ERROR return | Convention | Returns SQL error code. No TRY/CATCH or transaction. |

---

## 8. Sample Queries

### 8.1 Close an incident as Fixed
```sql
EXEC BackOffice.DowntimeClose
    @DowntimeID = 3,
    @DowntimeCloseStatusID = 1,  -- Fixed
    @ManagerID = 42,
    @TimeClosed = GETDATE(),
    @Comment = 'Root cause identified and resolved - server restart applied'
```

### 8.2 View all open incidents
```sql
SELECT DowntimeID, TimeOpened, DowntimeSystemID, DowntimeStatusID, OpenComment
FROM BackOffice.Downtime WITH (NOLOCK)
WHERE Closed = 0
ORDER BY TimeOpened
```

### 8.3 View closed incidents with resolution details
```sql
SELECT DowntimeID, TimeOpened, TimeClosed, DowntimeCloseStatusID, CloseComment, ClosedBy
FROM BackOffice.Downtime WITH (NOLOCK)
WHERE Closed = 1
ORDER BY TimeClosed DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DowntimeClose | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DowntimeClose.sql*
