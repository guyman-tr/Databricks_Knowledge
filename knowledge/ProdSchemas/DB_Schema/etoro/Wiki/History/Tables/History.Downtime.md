# History.Downtime

> Legacy audit log for platform downtime/incident reports - each row records the state of a downtime incident at creation or edit time, tracking which system was affected, the incident type, severity, status, and the back-office manager who reported it.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | DowntimeID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 7 active (CLUSTERED PK on DowntimeID, NC on ChangedBy, NC on DowntimeID (redundant), NC on DowntimeSeverityID, NC on DowntimeStatusID, NC on DowntimeSystemID, NC on DowntypeID) |

---

## 1. Business Meaning

This table is the **incident audit log** for the `BackOffice.Downtime` platform incident tracking system. Back-office managers report platform outages and degradations - "downtime" events - via the back-office application, and every reported incident (creation or edit) is logged here.

`BackOffice.DowntimeAdd` inserts simultaneously to `BackOffice.Downtime` (the live incident record) and `History.Downtime` (this audit log). `BackOffice.DowntimeEdit` updates `BackOffice.Downtime` and also appends the new state to `History.Downtime`.

Each row captures a snapshot: which trading system was affected (`DowntimeSystemID`), what kind of problem it was (`DowntypeID`), how severe (`DowntimeSeverityID`), what state the incident was in (`DowntimeStatusID`), a free-text description (`Comment`), when it was logged (`TimeChanged`), and by whom (`ChangedBy`).

**Current status**: The table has only **5 rows from 2009** - this is a very old, legacy system that has not been actively used in many years. The DowntimeSystem dictionary (Tradonomi Real/Demo, IFx, Dealing, Website) reflects eToro's system architecture from ~2009 (Tradonomi was eToro's original trading platform name).

**Design note**: The CLUSTERED PK on `DowntimeID` allows only one history row per incident. Since `BackOffice.DowntimeEdit` inserts with the same `DowntimeID` as the original record, a second edit attempt would cause a primary key violation. This constrains History.Downtime to recording only the initial state (from DowntimeAdd) in practice, as subsequent edits via DowntimeEdit would fail silently if the PK already exists. This is consistent with the 5-row data showing exactly one row per unique DowntimeID.

---

## 2. Business Logic

### 2.1 Downtime Reporting Flow

**What**: A back-office manager reports a platform incident, creating simultaneous records in BackOffice.Downtime and this History table.

**Columns/Parameters Involved**: All columns

**Rules** (from `BackOffice.DowntimeAdd`):
- DowntimeAdd inserts to `BackOffice.Downtime` first, obtains the new `DowntimeID` via `SCOPE_IDENTITY()`, then inserts the same data to `History.Downtime` in the same transaction.
- `TimeChanged` in History = `@TimeOpened` parameter (the reported incident start time, not the current time of the INSERT).
- `ChangedBy` = the ManagerID of the reporting back-office agent (FK to `BackOffice.Manager`).
- On edit (`BackOffice.DowntimeEdit`): `BackOffice.Downtime` is updated with new values and History.Downtime receives the new state with `TimeChanged = GETDATE()`. However, the PK constraint prevents this if a History row for that DowntimeID already exists.
- Closed downtime incidents (`BackOffice.Downtime.Closed = 1`) cannot be edited (DowntimeEdit raises error 60024).

**Diagram**:
```
BO Manager reports outage:
  BackOffice.DowntimeAdd(@DowntimeSystemID=1, @DowntypeID=3, @Severity=1, @Status=1, ...)
  -> BackOffice.Downtime: DowntimeID=2 (IDENTITY)
  -> History.Downtime:    DowntimeID=2, same fields, TimeChanged=@TimeOpened, ChangedBy=ManagerID

BO Manager edits the incident:
  BackOffice.DowntimeEdit(@DowntimeID=2, @DowntimeSeverityID=2, ...)  <- downgrade severity
  -> BackOffice.Downtime: updated (severity 1->2)
  -> History.Downtime: INSERT DowntimeID=2 -> PK violation! Row already exists
     (Only one History row per downtime is feasible in practice)
```

### 2.2 Dictionary Values

**DowntimeSystem** (which platform component had the outage):

| DowntimeSystemID | Name |
|---|---|
| 1 | Tradonomi Real |
| 2 | Tradonomi Demo |
| 3 | IFx |
| 4 | Dealing |
| 5 | Website |

**Downtype** (the nature of the problem):

| DowntypeID | Name |
|---|---|
| 1 | Can't Login |
| 2 | Can't Register |
| 3 | Unable to Open Trades |
| 4 | No Rates |
| 5 | Problem with Charts |
| 6 | Chat not Working |
| 7 | Slow Response Times |
| 8 | Dealing Desk |
| 9 | Delta Diff Issue |
| 10 | Hedge 1 |
| 11 | Hedge 8 |
| 12 | Hedge 10 |
| 13 | etoro.com |
| 14 | RetailFX.com |
| 15 | Affiliate Wiz |
| 16 | eToro Partners |
| 17 | Other |

**DowntimeSeverity**:

| DowntimeSeverityID | Name |
|---|---|
| 1 | Critical |
| 2 | High |
| 3 | Medium |
| 4 | Low |

**DowntimeStatus** (the operational state at time of logging):

| DowntimeStatusID | Name |
|---|---|
| 1 | Not Working |
| 2 | Not Working as Should |
| 3 | Specific Feature not Working |

---

## 3. Data Overview

| DowntimeID | System | Downtype | Severity | Status | TimeChanged | Comment Summary |
|---|---|---|---|---|---|---|
| 1 | Dealing (4) | Other (17) | High (2) | Not Working as Should (2) | 2009-03-02 | EUR/USD chart problem |
| 2 | Tradonomi Real (1) | Unable to Open Trades (3) | Critical (1) | Not Working (1) | 2009-03-06 | Platform froze in real mode ~02:30, lots of complaints, resolved by 02:52 |
| 3 | Tradonomi Real (1) | Can't Login (1) | Critical (1) | Not Working (1) | 2009-03-10 | Login throws users out |
| 4 | Website (5) | etoro.com (13) | Critical (1) | Not Working (1) | 2009-04-13 | Test entry |
| 5 | Tradonomi Real (1) | Other (17) | Medium (3) | Not Working (1) | 2009-10-27 | Test entry |

All 5 rows are from 2009, representing eToro's earliest incident tracking records from the original Tradonomi platform era. The system has not been actively used since. DowntimeID=2 contains the most detailed incident comment documenting a real trading system outage.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DowntimeID | int | NO | - | CODE-BACKED | The incident identifier, matching BackOffice.Downtime.DowntimeID. CLUSTERED PK - due to this constraint, only one history row per downtime incident is possible in practice (DowntimeEdit's INSERT would violate the PK if called on an existing incident). FK to BackOffice.Downtime. |
| 2 | DowntimeSystemID | int | NO | - | VERIFIED | Which eToro platform component experienced the downtime. FK to Dictionary.DowntimeSystem: 1=Tradonomi Real, 2=Tradonomi Demo, 3=IFx, 4=Dealing, 5=Website. NC index HDTM_SYSTEM supports filtering by system. These reflect eToro's 2009 platform architecture. |
| 3 | DowntypeID | int | NO | - | VERIFIED | The type/category of the problem. FK to Dictionary.Downtype (17 values): 1=Can't Login, 2=Can't Register, 3=Unable to Open Trades, 4=No Rates, 5=Problem with Charts, 6=Chat not Working, 7=Slow Response Times, 8=Dealing Desk, 9=Delta Diff Issue, 10-12=Hedge variants, 13=etoro.com, 14=RetailFX.com, 15=Affiliate Wiz, 16=eToro Partners, 17=Other. NC index HDTM_TYPE. |
| 4 | DowntimeSeverityID | int | NO | - | VERIFIED | Impact severity of the incident. FK to Dictionary.DowntimeSeverity: 1=Critical, 2=High, 3=Medium, 4=Low. NC index HDTM_SEVERITY supports severity-based filtering. |
| 5 | DowntimeStatusID | int | NO | - | VERIFIED | Operational state of the system at the time of logging. FK to Dictionary.DowntimeStatus: 1=Not Working, 2=Not Working as Should, 3=Specific Feature not Working. NC index HDTM_STATUS. |
| 6 | Comment | varchar(max) | NO | - | VERIFIED | Free-text description of the incident. Entered by the back-office manager. Can be very detailed (e.g., the 2009-03-06 entry documents a minute-by-minute outage timeline). Stored on [HISTORY] filegroup TEXTIMAGE_ON for large-value columns. |
| 7 | TimeChanged | datetime | NO | - | VERIFIED | The timestamp of this history record. For DowntimeAdd: equals `@TimeOpened` (the reported incident start time). For DowntimeEdit: equals GETDATE() (current time). Represents when the incident was opened or last edited. |
| 8 | ChangedBy | int | NO | - | VERIFIED | The ManagerID of the back-office agent who created or edited the incident. FK to BackOffice.Manager (explicit constraint FK_BMNG_HDTM). NC index HDTM_CHANGED supports "what incidents did this manager log?" queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DowntimeID | BackOffice.Downtime | FK (FK_BODT_HDTM) | The live incident record this row audits |
| DowntypeID | Dictionary.Downtype | FK (FK_DDTP_HDTM) | The type of problem (17 values) |
| DowntimeStatusID | Dictionary.DowntimeStatus | FK (FK_DDTST_HDTM) | The operational state at time of logging |
| DowntimeSeverityID | Dictionary.DowntimeSeverity | FK (FK_DDTSV_HDTM) | The incident severity (Critical/High/Medium/Low) |
| DowntimeSystemID | Dictionary.DowntimeSystem | FK (FK_DDTSY_HDTM) | The affected platform component |
| ChangedBy | BackOffice.Manager | FK (FK_BMNG_HDTM) | The back-office agent who logged this entry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DowntimeAdd | History.Downtime | Writer | Inserts initial incident state alongside BackOffice.Downtime INSERT |
| BackOffice.DowntimeEdit | History.Downtime | Writer (constrained) | Attempts to append new state on edit; PK prevents if initial row exists |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Downtime (table)
- No code-level computed dependencies
- Written from BackOffice.Downtime (table) via BackOffice.DowntimeAdd (procedure)
- FK references: BackOffice.Manager, BackOffice.Downtime, Dictionary.Downtype,
  Dictionary.DowntimeStatus, Dictionary.DowntimeSeverity, Dictionary.DowntimeSystem
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Downtime | Table | FK - DowntimeID must exist in BackOffice.Downtime |
| BackOffice.Manager | Table | FK - ChangedBy must be a valid ManagerID |
| Dictionary.Downtype | Table | FK - DowntypeID lookup |
| Dictionary.DowntimeStatus | Table | FK - DowntimeStatusID lookup |
| Dictionary.DowntimeSeverity | Table | FK - DowntimeSeverityID lookup |
| Dictionary.DowntimeSystem | Table | FK - DowntimeSystemID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DowntimeAdd | Stored Procedure | Writer - creates initial history row |
| BackOffice.DowntimeEdit | Stored Procedure | Writer - attempts to append on edit (PK constrained) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Fill Factor | Status |
|-----------|------|-------------|------------|--------|
| PK_Downtime | CLUSTERED (PK) | DowntimeID ASC | 90% | Active |
| HDTM_CHANGED | NONCLUSTERED | ChangedBy ASC | 90% | Active |
| HDTM_DTID | NONCLUSTERED | DowntimeID ASC | 90% | Active (redundant - same as PK) |
| HDTM_SEVERITY | NONCLUSTERED | DowntimeSeverityID ASC | 90% | Active |
| HDTM_STATUS | NONCLUSTERED | DowntimeStatusID ASC | 90% | Active |
| HDTM_SYSTEM | NONCLUSTERED | DowntimeSystemID ASC | 90% | Active |
| HDTM_TYPE | NONCLUSTERED | DowntypeID ASC | 90% | Active |

Note: `HDTM_DTID` (NC on DowntimeID) is redundant given the CLUSTERED PK on DowntimeID. All indexes use FILLFACTOR=90 (10% free space for inserts).

**Filegroup**: [HISTORY] - table and TEXTIMAGE on [HISTORY] filegroup.
**Storage**: No DATA_COMPRESSION specified (default = none).
**FK constraints**: 6 explicit FK constraints - this is one of the most constrained tables in the History schema.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Downtime | PRIMARY KEY (CLUSTERED) | Uniqueness on DowntimeID |
| FK_BODT_HDTM | FOREIGN KEY | DowntimeID -> BackOffice.Downtime |
| FK_BMNG_HDTM | FOREIGN KEY | ChangedBy -> BackOffice.Manager |
| FK_DDTP_HDTM | FOREIGN KEY | DowntypeID -> Dictionary.Downtype |
| FK_DDTST_HDTM | FOREIGN KEY | DowntimeStatusID -> Dictionary.DowntimeStatus |
| FK_DDTSV_HDTM | FOREIGN KEY | DowntimeSeverityID -> Dictionary.DowntimeSeverity |
| FK_DDTSY_HDTM | FOREIGN KEY | DowntimeSystemID -> Dictionary.DowntimeSystem |

---

## 8. Sample Queries

### 8.1 All incidents logged by a specific manager
```sql
SELECT hd.DowntimeID, ds.Name AS System, dt.Name AS Downtype,
       dsv.Name AS Severity, dsts.Name AS Status,
       hd.Comment, hd.TimeChanged
FROM [History].[Downtime] hd WITH (NOLOCK)
INNER JOIN [Dictionary].[DowntimeSystem] ds WITH (NOLOCK) ON hd.DowntimeSystemID = ds.DowntimeSystemID
INNER JOIN [Dictionary].[Downtype] dt WITH (NOLOCK) ON hd.DowntypeID = dt.DowntypeID
INNER JOIN [Dictionary].[DowntimeSeverity] dsv WITH (NOLOCK) ON hd.DowntimeSeverityID = dsv.DowntimeSeverityID
INNER JOIN [Dictionary].[DowntimeStatus] dsts WITH (NOLOCK) ON hd.DowntimeStatusID = dsts.DowntimeStatusID
WHERE hd.ChangedBy = 34
ORDER BY hd.TimeChanged DESC
```

### 8.2 Critical incidents by system
```sql
SELECT ds.Name AS System, COUNT(*) AS CriticalCount
FROM [History].[Downtime] hd WITH (NOLOCK)
INNER JOIN [Dictionary].[DowntimeSystem] ds WITH (NOLOCK) ON hd.DowntimeSystemID = ds.DowntimeSystemID
WHERE hd.DowntimeSeverityID = 1  -- Critical
GROUP BY ds.Name
ORDER BY CriticalCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Downtime | Type: Table | Source: etoro/etoro/History/Tables/History.Downtime.sql*
