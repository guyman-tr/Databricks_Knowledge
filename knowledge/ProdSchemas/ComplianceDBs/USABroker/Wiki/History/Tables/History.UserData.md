# History.UserData

> System-versioned temporal history table that automatically stores previous versions of Apex.UserData rows when they are updated, providing a complete audit trail of customer personal, identification, and compliance data changes. Dynamic data masking on PII columns is inherited.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (system-managed temporal history table) |
| **Partition** | No |
| **Indexes** | 1 clustered (EndTime, BeginTime) |

---

## 1. Business Meaning

History.UserData is the temporal history table for Apex.UserData. SQL Server's SYSTEM_VERSIONING feature automatically moves old row versions here whenever Apex.UserData is updated. Each row represents a previous state of a customer's master profile record, with BeginTime/EndTime defining when that version was active. This enables point-in-time queries and a full audit trail of every change to customer personal information, regulatory disclosures, approval status, and visa data.

This table is critical for regulatory compliance under KYC, CIP, and AML requirements. Regulators may require proof of what information was on file at the time of account opening or at any subsequent point. Compliance investigations can use this table to determine exactly when a customer's address, phone number, name, or disclosure flags changed, and which version of the data was submitted to Apex Clearing in each API call. The temporal query syntax (`FOR SYSTEM_TIME AS OF`, `FOR SYSTEM_TIME BETWEEN`) allows precise point-in-time reconstruction of the customer profile.

Dynamic data masking is applied to all PII columns (FirstName, LastName, MiddleName, DateOfBirth, NationalPin, PhoneNumber, Email, Address, BuildingNumber, City, Zip) exactly as on the parent table. Unauthorized database users see masked values in both the current and historical data. Data is never directly written to this table. SQL Server automatically manages it when rows in Apex.UserData are updated. PAGE compression is applied to reduce storage across potentially millions of historical rows.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Automatic version tracking where every UPDATE to Apex.UserData creates a historical record here.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all data columns

**Rules**:
- When an Apex.UserData row is updated, the OLD values are inserted here with EndTime = update timestamp
- The current row in Apex.UserData gets BeginTime = update timestamp, EndTime = '9999-12-31'
- History rows are immutable - they are never updated after creation
- Multiple history rows per GCID are expected: one per call to SaveUserData or SaveUserDataApproveInfo
- Dynamic data masking applies identically to history rows - PII is masked for unauthorized users in both current and historical queries
- Temporal queries use `Apex.UserData FOR SYSTEM_TIME AS OF '2024-01-01'` to see the exact customer profile at any point in time

---

## 3. Data Overview

N/A - History tables contain potentially millions of rows. Data is a mirror of Apex.UserData columns at previous points in time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Same value as Apex.UserData.GCID at the time this version was active. |
| 2 | AccountTypeID | int | NO | - | VERIFIED | Brokerage account type AT THE TIME this version was active. 1=CASH, 2=MARGIN, 3=OPTION. See [Account Type](../_glossary.md#account-type). |
| 3 | CustomerTypeID | int | NO | - | VERIFIED | Account ownership structure at the time this version was active. 1=INDIVIDUAL, 2=IRA, 3=JOINT, 4=CUSTODIAN. See [Customer Type](../_glossary.md#customer-type). |
| 4 | FirstName | nvarchar(50) MASKED | NO | - | VERIFIED | Customer's first name at the time this version was active. Dynamic data masking applied - unauthorized users see empty string. |
| 5 | LastName | nvarchar(50) MASKED | NO | - | VERIFIED | Customer's last name at the time this version was active. Dynamic data masking applied. |
| 6 | MiddleName | nvarchar(50) MASKED | NO | - | VERIFIED | Customer's middle name at the time this version was active. Dynamic data masking applied. |
| 7 | DateOfBirth | date MASKED | NO | - | VERIFIED | Customer's date of birth at the time this version was active. Dynamic data masking applied. |
| 8 | NationalPin | varchar(128) MASKED | NO | - | VERIFIED | SSN or national identification number at the time this version was active. Stored encrypted/hashed. Dynamic data masking applied. |
| 9 | CitizenshipCountryID | int | NO | - | VERIFIED | Country ID of the customer's citizenship at the time this version was active. |
| 10 | PermanentResident | bit | NO | - | VERIFIED | Whether the customer was a US permanent resident at the time this version was active. |
| 11 | PhoneNumber | varchar(30) MASKED | NO | - | VERIFIED | Customer's phone number at the time this version was active. Dynamic data masking applied. |
| 12 | PhoneNumberTypeID | int | NO | - | VERIFIED | Type of phone number at the time this version was active. 1=Home, 2=Work, 3=Mobile, 4=Fax, 5=Other. See [Phone Type](../_glossary.md#phone-type). |
| 13 | Email | varchar(50) MASKED | NO | - | VERIFIED | Customer's email address at the time this version was active. Dynamic data masking applied. |
| 14 | Address | nvarchar(100) MASKED | NO | - | VERIFIED | Primary street address line at the time this version was active. Dynamic data masking applied. |
| 15 | BuildingNumber | nvarchar(30) MASKED | NO | - | VERIFIED | Building/apartment number at the time this version was active. Dynamic data masking applied. |
| 16 | City | nvarchar(50) MASKED | NO | - | VERIFIED | City name at the time this version was active. Dynamic data masking applied. |
| 17 | ProvinceID | int | YES | - | VERIFIED | State/province ID for the home address at the time this version was active. NULL when not applicable. |
| 18 | Zip | nvarchar(50) MASKED | NO | - | VERIFIED | ZIP/postal code at the time this version was active. Dynamic data masking applied. |
| 19 | CountryID | int | NO | - | VERIFIED | Country ID of the customer's home address at the time this version was active. |
| 20 | POBCountryID | int | YES | - | VERIFIED | Place of Birth country ID at the time this version was active. NULL if not collected. |
| 21 | IsControlPerson | bit | YES | - | VERIFIED | Whether the customer was a control person of a public company at the time this version was active. |
| 22 | DisclosureCompanySymbols | nvarchar(255) | YES | - | VERIFIED | Stock tickers of companies where customer was a control person at the time this version was active. |
| 23 | IsAffiliatedExchangeOrFINRA | bit | YES | - | VERIFIED | Whether the customer was FINRA-affiliated at the time this version was active. |
| 24 | DisclosureFirmName | nvarchar(255) | YES | - | VERIFIED | Name of the affiliated FINRA firm at the time this version was active. |
| 25 | IsPoliticallyExposed | bit | YES | - | VERIFIED | Whether the customer was a PEP at the time this version was active. |
| 26 | PepAdditionalData | nvarchar(255) | YES | - | VERIFIED | Additional PEP disclosure information at the time this version was active. |
| 27 | ApproverName | varchar(128) | YES | - | VERIFIED | Compliance officer who approved the account as of this version. NULL for auto-approved records. |
| 28 | ApprovedByDate | datetime2(7) | YES | - | VERIFIED | Timestamp of manual approval as of this version. NULL for auto-approved records. |
| 29 | BeginTime | datetime2(7) | NO | - | VERIFIED | When this version became active (was originally written to Apex.UserData). Part of the temporal period. |
| 30 | EndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded by a newer version. The update timestamp. Part of the temporal period. Clustered index key (EndTime, BeginTime). |
| 31 | CID | int | YES | - | VERIFIED | Platform Customer ID at the time this version was active. NULL for records created before CID tracking was added. |
| 32 | Created | datetime2(7) | NO | - | VERIFIED | Original creation timestamp of the user data record. This value does not change across versions - it always reflects when the record was first inserted. |
| 33 | VisaType | nvarchar(10) | YES | - | VERIFIED | US visa classification code at the time this version was active. NULL for citizens and permanent residents. |
| 34 | VisaExpirationDate | datetime2(7) | YES | - | VERIFIED | Visa expiration date at the time this version was active. NULL for non-visa holders. |
| 35 | UsVisaHolder | bit | YES | - | VERIFIED | Whether the customer was a US visa holder at the time this version was active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references. History tables have no constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.UserData | SYSTEM_VERSIONING | Temporal | SQL Server automatically manages this table as the history store for Apex.UserData |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is system-managed.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserData | Table | Parent temporal table - this is its history store |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserData | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION | PAGE | Reduces storage for historical data |
| MASKED columns | DDM | FirstName, LastName, MiddleName, DateOfBirth, NationalPin, PhoneNumber, Email, Address, BuildingNumber, City, Zip use default() masking for unauthorized users |
| (none) | - | No PK, no FKs - system-managed temporal table |

---

## 8. Sample Queries

### 8.1 View complete customer data change history for a GCID

```sql
SELECT GCID, AccountTypeID, CustomerTypeID, PermanentResident,
       IsControlPerson, IsAffiliatedExchangeOrFINRA, IsPoliticallyExposed,
       UsVisaHolder, ApproverName, BeginTime, EndTime
FROM History.UserData WITH (NOLOCK)
WHERE GCID = 19533157
ORDER BY BeginTime;
```

### 8.2 Point-in-time query - what was the customer profile on a specific date

```sql
SELECT GCID, AccountTypeID, CustomerTypeID, PermanentResident,
       IsControlPerson, IsAffiliatedExchangeOrFINRA, IsPoliticallyExposed,
       CID, Created, BeginTime, EndTime
FROM Apex.UserData
FOR SYSTEM_TIME AS OF '2024-06-15 00:00:00'
WHERE GCID = 19533157;
```

### 8.3 Find all customer data changes within a date range

```sql
SELECT GCID, AccountTypeID, CustomerTypeID, IsControlPerson,
       IsAffiliatedExchangeOrFINRA, IsPoliticallyExposed,
       ApproverName, ApprovedByDate, BeginTime, EndTime
FROM Apex.UserData
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE GCID = 19533157
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 35 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UserData | Type: Table | Source: USABroker/History/Tables/History.UserData.sql*
