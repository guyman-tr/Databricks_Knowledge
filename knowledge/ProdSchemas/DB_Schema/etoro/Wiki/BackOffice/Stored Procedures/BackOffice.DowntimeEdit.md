# BackOffice.DowntimeEdit

> Modifies an open downtime incident's classification fields and appends a history entry to History.Downtime. Blocked on closed incidents.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DowntimeID - the incident to modify |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DowntimeEdit updates the classification and description of an existing open downtime incident. An agent might call this to change the severity, update the type, or correct the system as new information about the incident becomes available. Like DowntimeAdd, it also appends a record to `History.Downtime` - preserving the full change history of every classification update.

The procedure enforces the business rule that closed incidents cannot be edited: if `Closed=1`, error 60024 is raised immediately. This prevents retroactive modification of resolved incidents.

---

## 2. Business Logic

### 2.1 Closed-Incident Guard

**What**: Prevents editing incidents that have been closed.

**Columns/Parameters Involved**: `@DowntimeID`, `BackOffice.Downtime.Closed`

**Rules**:
- IF EXISTS (SELECT * FROM BackOffice.Downtime WHERE DowntimeID = @DowntimeID AND Closed = 1): RAISERROR(60024, 'Cannot Edit Closed Downtime Case') + RETURN 60024.
- Only open incidents (Closed=0) can be modified.

### 2.2 Update + History Append

**What**: Modifies the live record and records the change in History.Downtime.

**Columns/Parameters Involved**: All classification parameters + History.Downtime

**Rules**:
- UPDATE BackOffice.Downtime: DowntimeSystemID, DowntypeID, DowntimeSeverityID, DowntimeStatusID, OpenComment = @Comment.
- If UPDATE fails: ROLLBACK + RAISERROR(60000) + RETURN 60000.
- INSERT History.Downtime: DowntimeID, same classification fields, Comment=@Comment, TimeChanged=GETDATE() (not a parameter - current time), ChangedBy=@ManagerID.
- If INSERT fails: ROLLBACK + RAISERROR(60000) + RETURN 60000.
- Note: TimeChanged uses GETDATE() (edit time), while DowntimeAdd uses @TimeOpened (reported incident time).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DowntimeID | INTEGER | NO | - | CODE-BACKED | The incident to edit. PK of BackOffice.Downtime. Must exist and be open (Closed=0) or error 60024 is raised. |
| 2 | @DowntimeSystemID | INTEGER | NO | - | VERIFIED | Updated affected system. FK to Dictionary.DowntimeSystem: 1=Tradonomi Real, 2=Tradonomi Demo, 3=IFx, 4=Dealing, 5=Website. |
| 3 | @DowntypeID | INTEGER | NO | - | VERIFIED | Updated problem type. FK to Dictionary.Downtype: 1=Can't Login, 2=Can't Register, 3=Unable to Open Trades, 4=No Rates, 5=Problem with Charts, 6=Chat not Working, 7=Slow Response Times, 8=Dealing Desk, 9=Delta Diff, 10-16=platforms, 17=Other. |
| 4 | @DowntimeSeverityID | INTEGER | NO | - | VERIFIED | Updated severity. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. |
| 5 | @DowntimeStatusID | INTEGER | NO | - | VERIFIED | Updated operational status. FK to Dictionary.DowntimeStatus: 1=Not Working, 2=Not Working as Should, 3=Specific Feature not Working. |
| 6 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Agent making the edit. Written to History.Downtime.ChangedBy. FK to BackOffice.Manager. |
| 7 | @Comment | VARCHAR(MAX) | NO | - | CODE-BACKED | Updated description. Written to BackOffice.Downtime.OpenComment (replaces prior comment) and History.Downtime.Comment (appended). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DowntimeID | BackOffice.Downtime | Modifier | UPDATE target - replaces classification fields for the open incident. |
| @DowntimeID + fields | History.Downtime | Writer | INSERT - appends a history record with the new values and current timestamp. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice tooling | EXEC | Caller | No SQL-layer callers. Last used circa 2009. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DowntimeEdit (procedure)
├── BackOffice.Downtime (table) - closed-check guard + UPDATE
└── History.Downtime (table) - INSERT change history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Downtime | Table | EXISTS check (closed guard) + UPDATE classification fields |
| History.Downtime | Table | INSERT - appends edit record with TimeChanged=GETDATE() |

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
| Closed guard | Business rule | Raises error 60024 if Closed=1. Closed incidents are immutable. |
| OpenComment replaced (not appended) | Behavior | UPDATE sets OpenComment = @Comment, overwriting the prior value. History.Downtime preserves all prior comments. |
| TimeChanged = GETDATE() | Behavior | History entry uses server time (not a parameter). DowntimeAdd uses @TimeOpened (agent-provided). |
| @@ERROR check (legacy) | Convention | Manual @@ERROR + ROLLBACK + RAISERROR(60000) pattern (no TRY/CATCH). |

---

## 8. Sample Queries

### 8.1 Edit an incident's severity and comment
```sql
EXEC BackOffice.DowntimeEdit
    @DowntimeID = 3,
    @DowntimeSystemID = 1,    -- Tradonomi Real (unchanged)
    @DowntypeID = 3,          -- Unable to Open Trades (unchanged)
    @DowntimeSeverityID = 2,  -- Downgraded to High
    @DowntimeStatusID = 2,    -- Not Working as Should
    @ManagerID = 42,
    @Comment = 'Partial recovery - some users can trade, investigating remaining issues'
```

### 8.2 View incident edit history
```sql
SELECT h.DowntimeID, h.TimeChanged, h.ChangedBy, h.DowntimeStatusID, h.Comment
FROM History.Downtime h WITH (NOLOCK)
WHERE h.DowntimeID = 3
ORDER BY h.TimeChanged ASC
```

### 8.3 Verify an incident is open before editing
```sql
SELECT DowntimeID, Closed, DowntimeStatusID, OpenComment
FROM BackOffice.Downtime WITH (NOLOCK)
WHERE DowntimeID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DowntimeEdit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DowntimeEdit.sql*
