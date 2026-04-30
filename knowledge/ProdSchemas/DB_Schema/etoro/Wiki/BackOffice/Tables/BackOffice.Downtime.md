# BackOffice.Downtime

> Early-era (2009) incident tracking table recording system outage events across eToro's original "Tradonomi" trading platforms. Only 5 rows, all from 2009, none closed - effectively abandoned. Heavy indexing (8 indexes) reflects an ambitious design that was never actively used.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | DowntimeID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 8 active (1 clustered PK + 7 NC on each lookup column) |

---

## 1. Business Meaning

BackOffice.Downtime is an incident management table designed to track system outages and degradations across eToro's trading platforms. Each row represents a reported downtime incident: which system was affected, what type of problem occurred, its severity, current status, who opened it, and (when resolved) who closed it and how.

The table was built in early 2009 when eToro was operating under the "Tradonomi" brand. The 5 systems tracked (Tradonomi Real, Tradonomi Demo, IFx, Dealing, Website) reflect eToro's original platform architecture before it became the social trading platform known today. The downtime types (Can't Login, No Rates, Unable to Open Trades, etc.) represent the specific failure modes of that era's FX retail trading platform.

As of 2026-03-17, only 5 rows exist, all from 2009 (March and October), none closed (Closed=0 for all). The table has not been written to in over 15 years. The elaborate indexing (7 NC indexes, one per lookup column) suggests it was designed for active operational use but was never fully adopted - likely superseded by modern incident management tooling.

BackOffice.Manager FKs on both OpenedBy and ClosedBy confirm this was a BackOffice agent workflow.

---

## 2. Business Logic

### 2.1 Incident Lifecycle

**What**: DowntimeAdd opens a new incident; DowntimeEdit modifies it; DowntimeClose resolves it.

**Columns Involved**: `Closed`, `DowntimeCloseStatusID`, `TimeClosed`, `ClosedBy`, `CloseComment`

**Rules**:
- Open: INSERT via DowntimeAdd. Closed=0 (DEFAULT). TimeClosed=NULL, ClosedBy=NULL, DowntimeCloseStatusID=NULL.
- Edit: UPDATE via DowntimeEdit - modifies any open fields.
- Close: UPDATE via DowntimeClose - sets Closed=1, TimeClosed=now, ClosedBy=@ManagerID, DowntimeCloseStatusID (Fixed/Not Reproducible/Duplicate/By Design), CloseComment.

---

## 3. Data Overview

5 rows as of 2026-03-17 (all from 2009, all open):

| DowntimeID | TimeOpened | System | Notes |
|-----------|-----------|--------|-------|
| 1-5 (range) | 2009-03-02 to 2009-10-27 | DowntimeSystemIDs 1, 2, 3 used | Tradonomi Real, Tradonomi Demo, IFx. All Closed=0. DowntimeStatusID 1 (Not Working, 4 rows) and 2 (Not Working as Should, 1 row). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DowntimeID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing incident ID. NOT FOR REPLICATION. CLUSTERED PK. Range: 5 rows total as of 2026-03-17. |
| 2 | DowntimeSystemID | int | NO | - | VERIFIED | The affected system. FK (WITH CHECK) to Dictionary.DowntimeSystem. Values: 1=Tradonomi Real, 2=Tradonomi Demo, 3=IFx, 4=Dealing, 5=Website. NC index BODT_SYSTEM. Only IDs 1, 2, 3 appear in the 5 existing rows. |
| 3 | DowntypeID | int | NO | - | VERIFIED | Type of downtime/problem. FK (WITH CHECK) to Dictionary.Downtype. 17 values: 1=Can't Login, 2=Can't Register, 3=Unable to Open Trades, 4=No Rates, 5=Problem with Charts, 6=Chat not Working, 7=Slow Response Times, 8=Dealing Desk, 9=Delta Diff Issue, 10-12=Hedge 1/8/10, 13=etoro.com, 14=RetailFX.com, 15=Affiliate Wiz, 16=eToro Partners, 17=Other. NC index BODT_TYPE. |
| 4 | DowntimeSeverityID | int | NO | - | VERIFIED | Incident severity. FK (WITH CHECK) to Dictionary.DowntimeSeverity. Values: 1=Critical, 2=High, 3=Medium, 4=Low. NC index BODT_SEVERITY. |
| 5 | DowntimeStatusID | int | NO | - | VERIFIED | Current operational status. FK (WITH CHECK) to Dictionary.DowntimeStatus. Values: 1=Not Working (4 rows), 2=Not Working as Should (1 row), 3=Specific Feature not Working (0 rows). NC index BODT_STATUS. |
| 6 | TimeOpened | datetime | NO | - | VERIFIED | UTC timestamp when the incident was reported. Range in data: 2009-03-02 to 2009-10-27. |
| 7 | OpenedBy | int | NO | - | VERIFIED | BackOffice manager who reported the incident. FK (WITH CHECK) to BackOffice.Manager(ManagerID). NC index BODT_OPENEDBY. |
| 8 | Closed | bit | NO | 0 | VERIFIED | Whether the incident has been resolved. 0=open (all 5 current rows), 1=closed. DEFAULT=0. NC index BODT_CLOSED. |
| 9 | DowntimeCloseStatusID | int | YES | NULL | VERIFIED | Resolution outcome. FK (WITH CHECK) to Dictionary.DowntimeCloseStatus. Values: 1=Fixed, 2=Not Reproducible, 3=Duplicate Item, 4=By Design. NULL when Closed=0. NC index BODT_CLOSEID. |
| 10 | TimeClosed | datetime | YES | NULL | CODE-BACKED | UTC timestamp when the incident was closed. NULL for all current rows (all open). |
| 11 | ClosedBy | int | YES | NULL | CODE-BACKED | BackOffice manager who closed the incident. FK (WITH CHECK) to BackOffice.Manager(ManagerID). NULL for all current rows. NC index BODT_CLOSEDBY. |
| 12 | OpenComment | varchar(max) | YES | NULL | CODE-BACKED | Free-text description of the incident when opened. Agent notes on what is failing and initial context. |
| 13 | CloseComment | varchar(max) | YES | NULL | CODE-BACKED | Free-text description when incident was resolved - root cause, fix applied. NULL for all current rows (all open). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DowntimeSystemID | Dictionary.DowntimeSystem | FK (WITH CHECK) | Affected system (Tradonomi Real/Demo, IFx, Dealing, Website) |
| DowntypeID | Dictionary.Downtype | FK (WITH CHECK) | Problem type (17 types) |
| DowntimeSeverityID | Dictionary.DowntimeSeverity | FK (WITH CHECK) | Severity (Critical/High/Medium/Low) |
| DowntimeStatusID | Dictionary.DowntimeStatus | FK (WITH CHECK) | Operational status (3 states) |
| DowntimeCloseStatusID | Dictionary.DowntimeCloseStatus | FK (WITH CHECK) | Resolution outcome (Fixed/Not Reproducible/Duplicate/By Design) |
| OpenedBy | BackOffice.Manager | FK (WITH CHECK) | Reporting manager |
| ClosedBy | BackOffice.Manager | FK (WITH CHECK) | Resolving manager |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DowntimeAdd | DowntimeID | WRITER | Opens a new downtime incident |
| BackOffice.DowntimeEdit | DowntimeID | MODIFIER | Edits an existing incident |
| BackOffice.DowntimeClose | DowntimeID | MODIFIER | Closes an incident |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Downtime (table)
- FK targets:
  |- Dictionary.DowntimeSystem (5 systems)
  |- Dictionary.Downtype (17 problem types)
  |- Dictionary.DowntimeSeverity (4 severities)
  |- Dictionary.DowntimeStatus (3 statuses)
  |- Dictionary.DowntimeCloseStatus (4 close statuses)
  |- BackOffice.Manager (OpenedBy, ClosedBy)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DowntimeSystem | Table | FK on DowntimeSystemID |
| Dictionary.Downtype | Table | FK on DowntypeID |
| Dictionary.DowntimeSeverity | Table | FK on DowntimeSeverityID |
| Dictionary.DowntimeStatus | Table | FK on DowntimeStatusID |
| Dictionary.DowntimeCloseStatus | Table | FK on DowntimeCloseStatusID |
| BackOffice.Manager | Table | FK on OpenedBy, ClosedBy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DowntimeAdd | Procedure | WRITER - opens incident |
| BackOffice.DowntimeEdit | Procedure | MODIFIER - edits incident |
| BackOffice.DowntimeClose | Procedure | MODIFIER - closes incident |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_BODT | CLUSTERED PK | DowntimeID ASC | Active (FILLFACTOR=90) |
| BODT_CLOSED | NC | Closed ASC | Active (FILLFACTOR=90) |
| BODT_CLOSEDBY | NC | ClosedBy ASC | Active (FILLFACTOR=90) |
| BODT_CLOSEID | NC | DowntimeCloseStatusID ASC | Active (FILLFACTOR=90) |
| BODT_OPENEDBY | NC | OpenedBy ASC | Active (FILLFACTOR=90) |
| BODT_SEVERITY | NC | DowntimeSeverityID ASC | Active (FILLFACTOR=90) |
| BODT_STATUS | NC | DowntimeStatusID ASC | Active (FILLFACTOR=90) |
| BODT_SYSTEM | NC | DowntimeSystemID ASC | Active (FILLFACTOR=90) |
| BODT_TYPE | NC | DowntypeID ASC | Active (FILLFACTOR=90) |

8 indexes for a 5-row table reflects an ambitious design for high-volume operational use that never materialized.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BODT | PK | DowntimeID uniqueness |
| BODT_CLOSED | DEFAULT | Closed = 0 (new incidents start open) |
| FK_DDTSY_BODT | FK (WITH CHECK) | DowntimeSystemID -> Dictionary.DowntimeSystem |
| FK_DDTP_BODT | FK (WITH CHECK) | DowntypeID -> Dictionary.Downtype |
| FK_DDTSV_BODT | FK (WITH CHECK) | DowntimeSeverityID -> Dictionary.DowntimeSeverity |
| FK_DDTST_BODT | FK (WITH CHECK) | DowntimeStatusID -> Dictionary.DowntimeStatus |
| FK_DDCS_BODT | FK (WITH CHECK) | DowntimeCloseStatusID -> Dictionary.DowntimeCloseStatus |
| FK_BMNGO_BODT | FK (WITH CHECK) | OpenedBy -> BackOffice.Manager |
| FK_BMNGC_BODT | FK (WITH CHECK) | ClosedBy -> BackOffice.Manager |

---

## 8. Sample Queries

### 8.1 Get all open incidents
```sql
SELECT d.DowntimeID, ds.Name AS System, dt.Name AS DownType,
       dsev.Name AS Severity, dst.Name AS Status,
       d.TimeOpened, d.OpenComment
FROM BackOffice.Downtime d WITH (NOLOCK)
JOIN Dictionary.DowntimeSystem ds WITH (NOLOCK) ON ds.DowntimeSystemID = d.DowntimeSystemID
JOIN Dictionary.Downtype dt WITH (NOLOCK) ON dt.DowntypeID = d.DowntypeID
JOIN Dictionary.DowntimeSeverity dsev WITH (NOLOCK) ON dsev.DowntimeSeverityID = d.DowntimeSeverityID
JOIN Dictionary.DowntimeStatus dst WITH (NOLOCK) ON dst.DowntimeStatusID = d.DowntimeStatusID
WHERE d.Closed = 0
ORDER BY d.TimeOpened DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. The 2009 data and Tradonomi system names place this table in eToro's very early operational period, predating Confluence/Jira adoption.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 named | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Downtime | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Downtime.sql*
