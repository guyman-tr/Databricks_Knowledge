# Apex.UserDataMailingAddress

> Stores the customer's separate mailing address when it differs from their home address, used for correspondence and account statements.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.UserDataMailingAddress stores an optional separate mailing address for customers whose mailing address differs from their home address (stored in UserData). Apex Clearing supports sending account statements and correspondence to a different address than the customer's residential address. Only customers who have explicitly provided a different mailing address have a row here.

This table exists to support the Apex API's mailing address field. When present, account correspondence is directed to this address instead of the home address. The table uses system versioning (History.UserDataMailingAddress) to track address changes for compliance audit purposes.

Data is written by Apex.SaveMailingAddress and read by Apex.GetMailingAddress. Deletion by Apex.DeleteMailingAddress (used when the customer removes their separate mailing address).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple optional address storage with temporal tracking.

---

## 3. Data Overview

| GCID | CountryID | Address | City | Zip | BuildingNumber | Meaning |
|------|----------|---------|------|-----|----------------|---------|
| 49469 | 218 | whybourne terrace | Rotherham | S60 2LH | 12 | UK mailing address (CountryID 218). Note lowercase - indicates data was not normalized to uppercase like UserData. |
| 86059 | 218 | ESKDALE STREET | DARLINGTON | DL3 7DG | 7 | Another UK mailing address, this one in uppercase format. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. One optional mailing address per customer. |
| 2 | CountryID | int | NO | - | NAME-INFERRED | Country of the mailing address. Integer reference to a country lookup. |
| 3 | Address | nvarchar(255) | YES | - | CODE-BACKED | Street address line for mailing. |
| 4 | City | nvarchar(50) | YES | - | CODE-BACKED | City name for mailing address. |
| 5 | Zip | nvarchar(50) | YES | - | CODE-BACKED | ZIP/postal code for mailing address. |
| 6 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building/apartment number for mailing address. |
| 7 | RegionID | int | YES | - | NAME-INFERRED | Region/state ID for mailing address. NULL when not applicable. |
| 8 | SubRegionID | int | YES | - | NAME-INFERRED | Sub-region ID for mailing address. NULL when not applicable. |
| 9 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Part of SYSTEM_TIME period for History.UserDataMailingAddress. |
| 10 | EndTime | datetime2(7) | NO | '99991231 23:59:59.9999999' | CODE-BACKED | System versioning row end time. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveMailingAddress | @GCID | Writer | Creates/updates mailing address |
| Apex.GetMailingAddress | @GCID | Reader | Retrieves mailing address |
| Apex.DeleteMailingAddress | @GCID | Deleter | Removes mailing address |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveMailingAddress | Stored Procedure | Writer |
| Apex.GetMailingAddress | Stored Procedure | Reader |
| Apex.DeleteMailingAddress | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserDataMailingAddress | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserDataMailingAddress | PRIMARY KEY | Clustered on GCID |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.UserDataMailingAddress |

---

## 8. Sample Queries

### 8.1 Get a customer's mailing address

```sql
SELECT GCID, CountryID, Address, BuildingNumber, City, Zip, RegionID
FROM Apex.UserDataMailingAddress WITH (NOLOCK)
WHERE GCID = 49469;
```

### 8.2 Find customers with mailing addresses in a specific country

```sql
SELECT GCID, Address, City, Zip
FROM Apex.UserDataMailingAddress WITH (NOLOCK)
WHERE CountryID = 218
ORDER BY City;
```

### 8.3 View mailing address change history

```sql
SELECT GCID, Address, City, Zip, BeginTime, EndTime
FROM Apex.UserDataMailingAddress WITH (NOLOCK) WHERE GCID = 49469
UNION ALL
SELECT GCID, Address, City, Zip, BeginTime, EndTime
FROM History.UserDataMailingAddress WITH (NOLOCK) WHERE GCID = 49469
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 8.5/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserDataMailingAddress | Type: Table | Source: USABroker/Apex/Tables/Apex.UserDataMailingAddress.sql*
