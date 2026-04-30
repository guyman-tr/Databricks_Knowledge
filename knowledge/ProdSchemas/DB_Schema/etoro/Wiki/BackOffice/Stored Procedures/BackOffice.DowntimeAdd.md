# BackOffice.DowntimeAdd

> Opens a new system downtime/incident record in BackOffice.Downtime and simultaneously creates the initial history entry in History.Downtime.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SCOPE_IDENTITY() after INSERT - the new DowntimeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.DowntimeAdd is the entry point for reporting a system outage or degradation incident in eToro's legacy incident tracking system (`BackOffice.Downtime`). When a BackOffice agent identifies a system problem, they call this procedure to open a new incident record, capturing which system is affected, what type of problem, how severe, and the initial status.

Critically, the procedure also writes the initial state to `History.Downtime` in the same transaction - so every incident begins with a history record, creating a complete change log from the moment of creation. The DowntimeID from SCOPE_IDENTITY() links both records.

Note: The BackOffice.Downtime table has only 5 rows, all from 2009 (none closed), indicating this entire incident management system has been effectively abandoned for 15+ years - superseded by modern tooling. These procedures remain in the schema as legacy code.

---

## 2. Business Logic

### 2.1 Dual-Insert with History from Creation

**What**: Creates both the live incident record and its first history entry atomically.

**Columns/Parameters Involved**: All procedure parameters -> BackOffice.Downtime + History.Downtime

**Rules**:
- INSERT BackOffice.Downtime: DowntimeSystemID, DowntypeID, DowntimeSeverityID, DowntimeStatusID, TimeOpened, OpenedBy=@ManagerID, OpenComment=@Comment.
- SCOPE_IDENTITY() captures the new DowntimeID.
- If first INSERT fails: ROLLBACK + RAISERROR(60000) + RETURN 60000.
- INSERT History.Downtime: same data + DowntimeID, TimeChanged=@TimeOpened, ChangedBy=@ManagerID.
- If second INSERT fails: ROLLBACK + RAISERROR(60000) + RETURN 60000.
- COMMIT. RETURN 0 on success.

**Diagram**:
```
BEGIN TRAN
  INSERT BackOffice.Downtime -> SCOPE_IDENTITY() = @DowntimeID
  INSERT History.Downtime (DowntimeID, same fields, TimeChanged=@TimeOpened)
COMMIT
RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DowntimeSystemID | INTEGER | NO | - | VERIFIED | The affected system. FK to Dictionary.DowntimeSystem: 1=Tradonomi Real, 2=Tradonomi Demo, 3=IFx, 4=Dealing, 5=Website. Maps to BackOffice.Downtime.DowntimeSystemID. |
| 2 | @DowntypeID | INTEGER | NO | - | VERIFIED | Type of problem. FK to Dictionary.Downtype: 1=Can't Login, 2=Can't Register, 3=Unable to Open Trades, 4=No Rates, 5=Problem with Charts, 6=Chat not Working, 7=Slow Response Times, 8=Dealing Desk, 9=Delta Diff Issue, 10-16=various platforms, 17=Other. |
| 3 | @DowntimeSeverityID | INTEGER | NO | - | VERIFIED | Severity level. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. |
| 4 | @DowntimeStatusID | INTEGER | NO | - | VERIFIED | Initial operational status. FK to Dictionary.DowntimeStatus: 1=Not Working, 2=Not Working as Should, 3=Specific Feature not Working. |
| 5 | @TimeOpened | DATETIME | NO | - | CODE-BACKED | When the incident was detected/opened. Written to BackOffice.Downtime.TimeOpened and History.Downtime.TimeChanged. |
| 6 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent who opened the incident. Written to BackOffice.Downtime.OpenedBy and History.Downtime.ChangedBy. FK to BackOffice.Manager. |
| 7 | @Comment | VARCHAR(MAX) | NO | - | CODE-BACKED | Initial description of the incident. Written to BackOffice.Downtime.OpenComment and History.Downtime.Comment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DowntimeSystemID | Dictionary.DowntimeSystem | Lookup | System being reported as down. FK WITH CHECK on BackOffice.Downtime. |
| @DowntypeID | Dictionary.Downtype | Lookup | Type of outage/problem. FK WITH CHECK on BackOffice.Downtime. |
| @DowntimeSeverityID | Dictionary.DowntimeSeverity | Lookup | Incident severity. FK WITH CHECK on BackOffice.Downtime. |
| @DowntimeStatusID | Dictionary.DowntimeStatus | Lookup | Current status. FK WITH CHECK on BackOffice.Downtime. |
| All params | BackOffice.Downtime | Writer | INSERT - creates the live incident record. |
| All params + @DowntimeID | History.Downtime | Writer | INSERT - creates the initial history entry for the incident. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice incident tooling | EXEC | Caller | Called when opening a new incident. No SQL-layer callers found. Last used circa 2009. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DowntimeAdd (procedure)
├── BackOffice.Downtime (table) - INSERT live incident
└── History.Downtime (table) - INSERT initial history entry
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Downtime | Table | INSERT new incident record |
| History.Downtime | Table | INSERT initial history entry |

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
| Atomic dual-insert | Safety | Both BackOffice.Downtime and History.Downtime inserts are in one transaction. |
| @@ERROR check (legacy) | Convention | Uses @@ERROR + manual ROLLBACK rather than TRY/CATCH. RAISERROR(60000) on any failure. |
| SCOPE_IDENTITY() | Key passing | DowntimeID from the live table INSERT is passed to the History INSERT to link the records. |

---

## 8. Sample Queries

### 8.1 Open a new critical downtime incident
```sql
EXEC BackOffice.DowntimeAdd
    @DowntimeSystemID = 1,     -- Tradonomi Real
    @DowntypeID = 3,           -- Unable to Open Trades
    @DowntimeSeverityID = 1,   -- Critical
    @DowntimeStatusID = 1,     -- Not Working
    @TimeOpened = GETDATE(),
    @ManagerID = 42,
    @Comment = 'Users reporting inability to open new positions on Tradonomi Real'
```

### 8.2 View all open incidents
```sql
SELECT d.DowntimeID, d.TimeOpened, d.DowntimeSystemID, d.DowntypeID,
       d.DowntimeSeverityID, d.DowntimeStatusID, d.OpenComment
FROM BackOffice.Downtime d WITH (NOLOCK)
WHERE d.Closed = 0
ORDER BY d.TimeOpened DESC
```

### 8.3 View incident history
```sql
SELECT h.DowntimeID, h.TimeChanged, h.ChangedBy, h.DowntimeStatusID, h.Comment
FROM History.Downtime h WITH (NOLOCK)
WHERE h.DowntimeID = 1
ORDER BY h.TimeChanged ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DowntimeAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.DowntimeAdd.sql*
