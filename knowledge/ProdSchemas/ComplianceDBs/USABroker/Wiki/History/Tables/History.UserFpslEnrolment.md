# History.UserFpslEnrolment

> System-versioned temporal history table that automatically stores previous versions of Apex.UserFpslEnrolment rows when they are updated, providing a complete audit trail of FPSL program enrollment status and appropriateness assessment changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserFpslEnrolment is the temporal history table for Apex.UserFpslEnrolment. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserFpslEnrolment is updated. Each row represents a previous state of a customer's FPSL (Fully Paid Securities Lending) enrollment record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a full audit trail of every change to enrollment status and appropriateness assessment results.

FPSL is a regulated lending program where customers lend their fully-paid shares to short sellers in exchange for income. Enrollment requires a separate suitability assessment to ensure the customer understands the risks of securities lending. This history table allows compliance teams and regulators to determine: when a customer enrolled in or opted out of FPSL, what their appropriateness test result was at any given time, and whether any recalculations occurred. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows precise point-in-time reconstruction of enrollment state.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserFpslEnrolment are updated by Apex.SaveUserFpslEnrolment or Apex.SaveUserFpslAppropriateness. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserFpslEnrolment creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.UserFpslEnrolment row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserFpslEnrolment gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Two separate save procedures can generate history rows: SaveUserFpslEnrolment (changes FpslEnrolmentStatusID) and SaveUserFpslAppropriateness (changes AppropriatenessTestResultID and related fields), each producing a distinct history entry
- AppropriatenessProductID is always 2 (FPSL) in both current and history rows for this table
- Temporal queries use `Apex.UserFpslEnrolment FOR SYSTEM_TIME AS OF '2024-01-01'` to see enrollment and appropriateness state at any specific date

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserFpslEnrolment columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserFpslEnrolment.GCID at the time this version was active. |
| 2 | FpslEnrolmentStatusID | int | NO | - | VERIFIED | FPSL enrollment status AT THE TIME this version was active. Likely 0=None, 1=OptIn, 2=OptOut. The transition between statuses creates a new history row. |
| 3 | AppropriatenessTestResultID | int | NO | - | VERIFIED | Suitability test result for the FPSL product at the time this version was active. 0=None, 1=Failed, 2=Passed. See [Appropriateness Test Result](../_glossary.md#appropriateness-test-result). |
| 4 | AppropriatenessProductID | int | NO | - | VERIFIED | The product being assessed at the time this version was active. Always 2 (FPSL) for this table. See [Appropriateness Product](../_glossary.md#appropriateness-product). |
| 5 | AppropriatenessRecalculationReasonID | int | NO | - | VERIFIED | Reason for appropriateness test recalculation at the time this version was active. See [Appropriateness Recalculation Reason](../_glossary.md#appropriateness-recalculation-reason). |
| 6 | BeginTime | datetime2(0) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserFpslEnrolment). Part of the temporal period. |
| 7 | EndTime | datetime2(0) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserFpslEnrolment | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserFpslEnrolment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserFpslEnrolment | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserFpslEnrolment | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete FPSL enrollment history for a customer

```sql
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID,
       AppropriatenessProductID, AppropriatenessRecalculationReasonID,
       BeginTime, EndTime
FROM History.UserFpslEnrolment WITH (NOLOCK)
WHERE GCID = 11
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the FPSL enrollment status on a specific date

```sql
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID,
       AppropriatenessRecalculationReasonID, BeginTime, EndTime
FROM Apex.UserFpslEnrolment
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 11;
```

### 8.3 Find all FPSL enrollment changes within a date range

```sql
SELECT GCID, FpslEnrolmentStatusID, AppropriatenessTestResultID,
       AppropriatenessRecalculationReasonID, BeginTime, EndTime
FROM Apex.UserFpslEnrolment
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 11
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserFpslEnrolment | Type: Table | Source: USABroker/History/Tables/History.UserFpslEnrolment.sql*
