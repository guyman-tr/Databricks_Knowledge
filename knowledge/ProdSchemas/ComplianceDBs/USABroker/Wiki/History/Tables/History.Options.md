# History.Options

> System-versioned temporal history table that automatically stores previous versions of Apex.Options rows when they are updated, providing a complete audit trail of options trading eligibility, appropriateness, and approval status changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.Options is the temporal history table for Apex.Options. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.Options is updated. Each row represents a previous state of a customer's options trading record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a full audit trail of every change to appropriateness test results, eligibility status, Apex approval status, and reasoning form workflow state.

This table is essential for regulatory compliance and operational investigation. Options trading is a regulated activity under FINRA Rule 2360, requiring documented proof of suitability assessments. Regulators or compliance teams may request the complete history of when a customer's options eligibility or approval status changed, or when the reasoning form workflow progressed. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows querying the exact state of any customer's options record at any point in time.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.Options are updated by any of the four save procedures (SaveOptionsAppropriateness, SaveOptionsEligibility, SaveOptionsStatus, SaveOptionsReasoningStatus). The old version is moved here with the original BeginTime and an EndTime set to the update timestamp. PAGE compression is applied to reduce storage across potentially millions of historical rows.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.Options creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.Options row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.Options gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per GCID are expected (one per status change across any of the four update procedures)
- Temporal queries use `Apex.Options FOR SYSTEM_TIME AS OF '2024-01-01'` to see the exact state at a specific time
- The four segmented update procedures each create separate history rows when they fire, allowing fine-grained reconstruction of which system changed which fields

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.Options columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.Options.GCID at the time this version was active. |
| 2 | AppropriatenessTestResultID | int | NO | - | VERIFIED | Result of the suitability/appropriateness assessment AT THE TIME this version was active. 0=None, 1=Failed, 2=Passed. See [Appropriateness Test Result](../_glossary.md#appropriateness-test-result). |
| 3 | AppropriatenessProductID | int | NO | - | VERIFIED | The financial product being assessed for appropriateness at the time this version was active. See [Appropriateness Product](../_glossary.md#appropriateness-product). |
| 4 | AppropriatenessRecalculationReasonID | int | NO | - | VERIFIED | Reason why the appropriateness test was recalculated at the time this version was active. See [Appropriateness Recalculation Reason](../_glossary.md#appropriateness-recalculation-reason). |
| 5 | EligibilityStatusID | int | NO | - | VERIFIED | Whether the customer was eligible for options trading at the time this version was active. 0=Disallowed, 1=Allowed. See [Eligibility Status](../_glossary.md#eligibility-status). |
| 6 | EligibilityStatusReasonID | int | NO | - | VERIFIED | The specific reason for the eligibility determination at the time this version was active. |
| 7 | OptionsStatusID | int | NO | - | VERIFIED | The Apex Clearing approval status for options trading AT THE TIME this version was active. 0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected. See [Options Status](../_glossary.md#options-status). |
| 8 | OptionsApexID | nvarchar(50) | YES | - | VERIFIED | The Apex Clearing identifier for the options application at the time this version was active. NULL until an application was sent to Apex. |
| 9 | ApplicationName | nvarchar(50) | YES | - | VERIFIED | Name of the service/application that last modified the record at the time this version was written. |
| 10 | OptionsStatusControlID | int | NO | - | VERIFIED | Administrative override for options trading access at the time this version was active. 0=None, 1=Blocked, 2=Allowed. See [Options Status Control](../_glossary.md#options-status-control). |
| 11 | BeginTime | datetime2(0) | NO | - | VERIFIED | When this version became active (was originally written to Apex.Options). Part of the temporal period. |
| 12 | EndTime | datetime2(0) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |
| 13 | ReasoningStatusID | int | YES | - | VERIFIED | Status of the options reasoning form workflow at the time this version was active. See [Reasoning Status](../_glossary.md#reasoning-status). |
| 14 | ReasoningFormID | uniqueidentifier | YES | - | VERIFIED | GUID linking to the reasoning form instance active at the time this version was written. |
| 15 | AppropriatenessTestDate | datetime | YES | - | VERIFIED | Timestamp of when the appropriateness test was last taken or recalculated as of this version. |
| 16 | StocksElegibilityStatusID | int | YES | - | VERIFIED | Eligibility status for stock trading at the time this version was active. 0=Disallowed, 1=Allowed. Note: column name has typo "Elegibility". |
| 17 | CryptoElegibilityStatusID | int | YES | - | VERIFIED | Eligibility status for cryptocurrency trading at the time this version was active. 0=Disallowed, 1=Allowed. Note: column name has typo "Elegibility". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.Options | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.Options |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.Options | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Options | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete options status history for a customer

```sql
SELECT GCID, OptionsStatusID, EligibilityStatusID, AppropriatenessTestResultID,
       ReasoningStatusID, ApplicationName, BeginTime, EndTime
FROM History.Options WITH (NOLOCK)
WHERE GCID = 12345
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the options status on a specific date

```sql
SELECT GCID, OptionsStatusID, EligibilityStatusID, AppropriatenessTestResultID,
       OptionsStatusControlID, BeginTime, EndTime
FROM Apex.Options
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 12345;
```

### 8.3 Find all options status transitions for a date range

```sql
SELECT GCID, OptionsStatusID, EligibilityStatusID, AppropriatenessTestResultID,
       ApplicationName, BeginTime, EndTime
FROM Apex.Options
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 12345
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 17 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Options | Type: Table | Source: USABroker/History/Tables/History.Options.sql*
