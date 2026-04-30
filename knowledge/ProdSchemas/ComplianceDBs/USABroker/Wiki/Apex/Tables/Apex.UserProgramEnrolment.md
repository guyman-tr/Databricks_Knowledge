# Apex.UserProgramEnrolment

> Tracks customer opt-in/opt-out status for optional programs (FPSL, CryptoStaking, EthStaking, ProxyVoting), with composite PK allowing one enrollment record per customer per program.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID + UserProgramID (composite CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserProgramEnrolment tracks whether each customer has opted in or out of various optional programs offered through the Apex brokerage platform. Programs include FPSL (securities lending), cryptocurrency staking, Ethereum staking, and proxy voting. The composite PK (GCID + UserProgramID) allows one enrollment decision per customer per program.

Data is written by Apex.SaveUserProgramEnrolment. System versioning with History.UserProgramEnrolment tracks enrollment changes over time.

---

## 2. Business Logic

### 2.1 Three-State Enrollment Model

**What**: Each program enrollment uses a three-state model distinguishing between "never decided", "actively enrolled", and "actively declined".

**Columns/Parameters Involved**: `GCID`, `UserProgramID`, `UserProgramEnrolmentStatusID`

**Rules**:
- StatusID 0 (None): Customer has not made a decision about this program
- StatusID 1 (OptIn): Customer has actively enrolled in the program
- StatusID 2 (OptOut): Customer has actively declined the program
- A customer can have multiple rows (one per program they've interacted with)
- See [User Program](_glossary.md#user-program) and [User Program Enrolment Status](_glossary.md#user-program-enrolment-status)

---

## 3. Data Overview

| GCID | UserProgramEnrolmentStatusID | UserProgramID | Meaning |
|------|-----------------------------|--------------|-|
| 3876 | 1 (OptIn) | 3 (EthStaking) | Customer opted into Ethereum staking program. |
| 5519 | 1 (OptIn) | 2 (CryptoStaking) | Customer opted into general crypto staking. |
| 6557 | 1 (OptIn) | 3 (EthStaking) | Another Ethereum staking opt-in. EthStaking appears popular. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Part of composite PK with UserProgramID. |
| 2 | UserProgramEnrolmentStatusID | int | NO | - | VERIFIED | Enrollment decision. FK to Dictionary.UserProgramEnrolmentStatus: 0=None, 1=OptIn, 2=OptOut. See [User Program Enrolment Status](_glossary.md#user-program-enrolment-status). (Dictionary.UserProgramEnrolmentStatus) |
| 3 | UserProgramID | int | NO | - | VERIFIED | The program being enrolled in. FK to Dictionary.UserProgram: 0=None, 1=FPSL, 2=CryptoStaking, 3=EthStaking, 4=ProxyVotingManualPositions, 5=ProxyVotingCopiedPositions. See [User Program](_glossary.md#user-program). (Dictionary.UserProgram) |
| 4 | BeginTime | datetime2(0) | NO | dateadd(second,(-1),sysutcdatetime()) | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserProgramEnrolment. |
| 5 | EndTime | datetime2(0) | NO | '9999.12.31 23:59:59.99' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserProgramID | Dictionary.UserProgram | FK | Program being enrolled in |
| UserProgramEnrolmentStatusID | Dictionary.UserProgramEnrolmentStatus | FK | Enrollment decision |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveUserProgramEnrolment | @GCID, @UserProgramID | Writer | Upserts enrollment status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserProgramEnrolment (table)
├── Dictionary.UserProgram (table) [FK]
└── Dictionary.UserProgramEnrolmentStatus (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserProgram | Table | FK for UserProgramID |
| Dictionary.UserProgramEnrolmentStatus | Table | FK for UserProgramEnrolmentStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveUserProgramEnrolment | Stored Procedure | Writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserProgramEnrolment | CLUSTERED PK | GCID ASC, UserProgramID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserProgramEnrolment | PRIMARY KEY | Composite on (GCID, UserProgramID) |
| FK_UserProgramEnrolment_UserProgram | FOREIGN KEY | UserProgramID -> Dictionary.UserProgram |
| FK_UserProgramEnrolment_UserProgramEnrolmentStatus | FOREIGN KEY | UserProgramEnrolmentStatusID -> Dictionary.UserProgramEnrolmentStatus |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserProgramEnrolment |

---

## 8. Sample Queries

### 8.1 Get all enrollments for a customer with resolved names

```sql
SELECT e.GCID, p.Name AS Program, s.Name AS EnrolmentStatus, e.BeginTime
FROM Apex.UserProgramEnrolment e WITH (NOLOCK)
INNER JOIN Dictionary.UserProgram p WITH (NOLOCK) ON p.UserProgramID = e.UserProgramID
INNER JOIN Dictionary.UserProgramEnrolmentStatus s WITH (NOLOCK) ON s.UserProgramEnrolmentStatusID = e.UserProgramEnrolmentStatusID
WHERE e.GCID = 3876;
```

### 8.2 Count enrollments by program

```sql
SELECT p.Name AS Program, s.Name AS Status, COUNT(*) AS CustomerCount
FROM Apex.UserProgramEnrolment e WITH (NOLOCK)
INNER JOIN Dictionary.UserProgram p WITH (NOLOCK) ON p.UserProgramID = e.UserProgramID
INNER JOIN Dictionary.UserProgramEnrolmentStatus s WITH (NOLOCK) ON s.UserProgramEnrolmentStatusID = e.UserProgramEnrolmentStatusID
GROUP BY p.Name, s.Name ORDER BY p.Name, s.Name;
```

### 8.3 Find customers opted into EthStaking

```sql
SELECT GCID, BeginTime
FROM Apex.UserProgramEnrolment WITH (NOLOCK)
WHERE UserProgramID = 3 AND UserProgramEnrolmentStatusID = 1
ORDER BY BeginTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserProgramEnrolment | Type: Table | Source: USABroker/Apex/Tables/Apex.UserProgramEnrolment.sql*
