# History.UserDataTrustedContact

> System-versioned temporal history table that automatically stores previous versions of Apex.UserDataTrustedContact rows when they are updated, providing a complete audit trail of changes to FINRA-required trusted contact person information.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) + 1 nonclustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserDataTrustedContact is the temporal history table for Apex.UserDataTrustedContact. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserDataTrustedContact is updated. Each row represents a previous state of a customer's trusted contact person record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a complete audit trail of every change to trusted contact information.

Trusted contact person designation is required by FINRA Rule 4512. When a customer updates or removes their trusted contact, the previous record is preserved here, ensuring the broker-dealer can demonstrate compliance with the rule and reconstruct who the designated trusted contact was at any point in time. Compliance audits and regulatory inquiries about a customer's account history may require confirming that a trusted contact was on file and what their details were. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows precise point-in-time lookups of trusted contact information.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserDataTrustedContact are created, updated, or deleted by Apex.SaveTrustedContact or Apex.DeleteTrustedContact. PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserDataTrustedContact creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.UserDataTrustedContact row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserDataTrustedContact gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Only customers who have ever had a trusted contact appear in this table
- When Apex.DeleteTrustedContact removes the current row, the final version is preserved here with a non-'9999' EndTime, documenting when the trusted contact was removed
- Temporal queries use `Apex.UserDataTrustedContact FOR SYSTEM_TIME AS OF '2024-01-01'` to see who the trusted contact was on a specific date

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserDataTrustedContact columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserDataTrustedContact.GCID at the time this version was active. |
| 2 | FirstName | nvarchar(50) | NO | - | VERIFIED | Trusted contact's first name AT THE TIME this version was active. |
| 3 | LastName | nvarchar(50) | NO | - | VERIFIED | Trusted contact's last name at the time this version was active. |
| 4 | PhoneNumber | varchar(30) | YES | - | VERIFIED | Trusted contact's phone number at the time this version was active. NULL if no phone was provided. |
| 5 | PhoneNumberTypeID | int | YES | - | VERIFIED | Type of phone number at the time this version was active. 1=Home, 2=Work, 3=Mobile, 4=Fax, 5=Other. See [Phone Type](../_glossary.md#phone-type). NULL when no phone provided. |
| 6 | Email | varchar(50) | YES | - | VERIFIED | Trusted contact's email address at the time this version was active. NULL if no email was provided. |
| 7 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserDataTrustedContact). Part of the temporal period. |
| 8 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version or deleted. The update/delete timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserDataTrustedContact | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserDataTrustedContact |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserDataTrustedContact | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserDataTrustedContact | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_UserDataTrustedContact | NONCLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Applied to clustered and ix_History_UserDataTrustedContact; reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete trusted contact history for a customer

```sql
SELECT GCID, FirstName, LastName, PhoneNumber, PhoneNumberTypeID, Email,
       BeginTime, EndTime
FROM History.UserDataTrustedContact WITH (NOLOCK)
WHERE GCID = 1626844
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - who was the trusted contact on a specific date

```sql
SELECT GCID, FirstName, LastName, PhoneNumber, PhoneNumberTypeID, Email,
       BeginTime, EndTime
FROM Apex.UserDataTrustedContact
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 1626844;
```

### 8.3 Find all trusted contact changes within a date range

```sql
SELECT GCID, FirstName, LastName, PhoneNumber, Email, BeginTime, EndTime
FROM Apex.UserDataTrustedContact
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 1626844
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserDataTrustedContact | Type: Table | Source: USABroker/History/Tables/History.UserDataTrustedContact.sql*
