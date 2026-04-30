# History.UserDataMailingAddress

> System-versioned temporal history table that automatically stores previous versions of Apex.UserDataMailingAddress rows when they are updated, providing a complete audit trail of customer mailing address changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) + 1 nonclustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserDataMailingAddress is the temporal history table for Apex.UserDataMailingAddress. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserDataMailingAddress is updated. Each row represents a previous state of a customer's mailing address record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a complete audit trail of every mailing address change a customer has made.

This table supports compliance requirements around customer contact address history. When a customer updates or removes their separate mailing address, the previous address version is preserved here. Regulators or compliance teams can determine what mailing address was on file at any specific date, which is relevant for verifying that account statements, tax documents, and regulatory correspondence were directed to the correct address. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows precise point-in-time address lookups.

Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserDataMailingAddress are created, updated, or deleted (deletion of the parent row closes the period with EndTime). PAGE compression is applied to reduce storage.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserDataMailingAddress creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.UserDataMailingAddress row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserDataMailingAddress gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Only customers who have ever had a separate mailing address appear in this table
- When Apex.DeleteMailingAddress removes the current row, the final version is preserved here with a non-'9999' EndTime
- Temporal queries use `Apex.UserDataMailingAddress FOR SYSTEM_TIME AS OF '2024-01-01'` to see what mailing address was active on a specific date

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserDataMailingAddress columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserDataMailingAddress.GCID at the time this version was active. |
| 2 | CountryID | int | NO | - | VERIFIED | Country of the mailing address AT THE TIME this version was active. Integer reference to a country lookup. |
| 3 | Address | nvarchar(255) | YES | - | VERIFIED | Street address line for mailing at the time this version was active. |
| 4 | City | nvarchar(50) | YES | - | VERIFIED | City name for mailing address at the time this version was active. |
| 5 | Zip | nvarchar(50) | YES | - | VERIFIED | ZIP/postal code for mailing address at the time this version was active. |
| 6 | BuildingNumber | nvarchar(30) | YES | - | VERIFIED | Building/apartment number for mailing address at the time this version was active. |
| 7 | RegionID | int | YES | - | VERIFIED | Region/state ID for mailing address at the time this version was active. NULL when not applicable. |
| 8 | SubRegionID | int | YES | - | VERIFIED | Sub-region ID for mailing address at the time this version was active. NULL when not applicable. |
| 9 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserDataMailingAddress). Part of the temporal period. |
| 10 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version or deleted. The update/delete timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserDataMailingAddress | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserDataMailingAddress |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserDataMailingAddress | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserDataMailingAddress | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |
| ix_History_UserDataMailingAddress | NONCLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Applied to clustered and ix_History_UserDataMailingAddress; reduces storage for historical data |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete mailing address history for a customer

```sql
SELECT GCID, CountryID, Address, BuildingNumber, City, Zip, RegionID, SubRegionID,
       BeginTime, EndTime
FROM History.UserDataMailingAddress WITH (NOLOCK)
WHERE GCID = 49469
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what mailing address was active on a specific date

```sql
SELECT GCID, CountryID, Address, BuildingNumber, City, Zip, RegionID,
       BeginTime, EndTime
FROM Apex.UserDataMailingAddress
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 49469;
```

### 8.3 Find all mailing address changes within a date range

```sql
SELECT GCID, CountryID, Address, City, Zip, BeginTime, EndTime
FROM Apex.UserDataMailingAddress
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 49469
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserDataMailingAddress | Type: Table | Source: USABroker/History/Tables/History.UserDataMailingAddress.sql*
