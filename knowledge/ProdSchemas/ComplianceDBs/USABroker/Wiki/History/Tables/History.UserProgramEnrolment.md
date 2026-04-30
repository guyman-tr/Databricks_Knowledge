# History.UserProgramEnrolment

> System-versioned temporal history table that automatically stores previous versions of Apex.UserProgramEnrolment rows when they are updated, providing a complete audit trail of customer opt-in and opt-out decisions for optional programs (FPSL, CryptoStaking, EthStaking, ProxyVoting).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserProgramEnrolment is the temporal history table for Apex.UserProgramEnrolment. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserProgramEnrolment is updated. Each row represents a previous enrollment state for a customer in a specific program, with BeginTime/EndTime defining when that enrollment decision was active. This enables point-in-time queries and a complete audit trail of every enrollment status change across all optional programs.

Optional programs tracked here include FPSL (securities lending), CryptoStaking, EthStaking, and ProxyVoting (manual and copied positions). Each program can independently cycle between None, OptIn, and OptOut states per customer. This history table enables compliance teams to confirm when a customer was enrolled in any given program at any specific date, how long they remained enrolled, and when they opted out. This is relevant for revenue attribution (FPSL income periods), regulatory reporting of program participation, and investigating customer disputes about program enrollment timelines. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows precise point-in-time enrollment queries.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserProgramEnrolment are updated by Apex.SaveUserProgramEnrolment. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserProgramEnrolment creates a historical record here, capturing each enrollment decision change per customer per program.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, `GCID`, `UserProgramID`, `UserProgramEnrolmentStatusID`

**Rules**:
- When an Apex.UserProgramEnrolment row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserProgramEnrolment gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per (GCID, UserProgramID) combination are expected - one per enrollment decision change
- The three-state model (0=None, 1=OptIn, 2=OptOut) means each transition from OptIn to OptOut and back produces a new history row
- Temporal queries use `Apex.UserProgramEnrolment FOR SYSTEM_TIME AS OF '2024-01-01'` to see enrollment state for all programs a customer has interacted with at a specific date

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserProgramEnrolment columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserProgramEnrolment.GCID at the time this version was active. |
| 2 | UserProgramEnrolmentStatusID | int | NO | - | VERIFIED | Enrollment decision AT THE TIME this version was active. 0=None, 1=OptIn, 2=OptOut. The transition from one status to the next creates a new history row. See [User Program Enrolment Status](../_glossary.md#user-program-enrolment-status). |
| 3 | UserProgramID | int | NO | - | VERIFIED | The program this enrollment decision applies to at the time this version was active. 0=None, 1=FPSL, 2=CryptoStaking, 3=EthStaking, 4=ProxyVotingManualPositions, 5=ProxyVotingCopiedPositions. See [User Program](../_glossary.md#user-program). |
| 4 | BeginTime | datetime2(0) | NO | - | VERIFIED | When this enrollment version became active (was originally written to Apex.UserProgramEnrolment). Part of the temporal period. |
| 5 | EndTime | datetime2(0) | NO | - | VERIFIED | When this enrollment version was superseded by a newer decision. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserProgramEnrolment | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserProgramEnrolment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserProgramEnrolment | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserProgramEnrolment | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete enrollment history for a customer across all programs

```sql
SELECT GCID, UserProgramID, UserProgramEnrolmentStatusID, BeginTime, EndTime,
       DATEDIFF(DAY, BeginTime, EndTime) AS DaysInStatus
FROM History.UserProgramEnrolment WITH (NOLOCK)
WHERE GCID = 3876
ORDER BY UserProgramID, BeginTime;
```

### 8.2 Point-in-time query - what programs was a customer enrolled in on a specific date

```sql
SELECT GCID, UserProgramID, UserProgramEnrolmentStatusID, BeginTime, EndTime
FROM Apex.UserProgramEnrolment
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 3876;
```

### 8.3 Find all enrollment status changes within a date range for a customer

```sql
SELECT GCID, UserProgramID, UserProgramEnrolmentStatusID, BeginTime, EndTime
FROM Apex.UserProgramEnrolment
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 3876
ORDER BY UserProgramID, BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserProgramEnrolment | Type: Table | Source: USABroker/History/Tables/History.UserProgramEnrolment.sql*
