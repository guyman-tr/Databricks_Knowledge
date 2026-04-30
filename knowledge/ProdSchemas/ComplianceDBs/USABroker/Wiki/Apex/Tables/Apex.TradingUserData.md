# Apex.TradingUserData

> Trading platform's copy of essential customer personal and address data, providing the trading system with name, address, and account identifiers needed for trade execution and CAT/OATS reporting.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 nonclustered (InsertDate) |

---

## 1. Business Meaning

Apex.TradingUserData stores the essential personal data the trading platform needs for each customer: legal name, address, Apex account ID, and FDID (Financial Data Identifier). This is a denormalized, read-optimized copy of data from UserData and ApexData, tailored specifically for the trading platform's needs.

This table exists to give the trading platform fast, direct access to customer identity and address data without complex JOINs to the Apex onboarding tables. The FDID is particularly important - it is the unique customer identifier used in CAT (Consolidated Audit Trail) and OATS (Order Audit Trail System) regulatory reporting for trade surveillance.

Data is written by Apex.SaveTradingUserData and read by GetTradingUserData (single customer) or GetTradingUsersDataList (bulk via Apex.GCIDs TVP). Deletion is handled by DeleteTradingUserData.

---

## 2. Business Logic

### 2.1 Dual Identifier System

**What**: Each customer has both a platform CID and a regulatory FDID, alongside the Apex account ID, enabling cross-system identification.

**Columns/Parameters Involved**: `CID`, `GCID`, `ApexID`, `FDID`

**Rules**:
- CID is the platform's Customer ID (different from GCID which is the Global Customer ID)
- GCID is the primary key and cross-system identifier
- ApexID is the Apex Clearing account identifier
- FDID is the Financial Data Identifier for regulatory reporting (CAT/OATS)
- FDID format observed: Base32-encoded string (e.g., "GNDE4MZXGU4TA")

---

## 3. Data Overview

| GCID | CID | GivenName | FamilyName | Country | State | City | ApexID | FDID | Meaning |
|------|-----|-----------|------------|---------|-------|------|--------|------|---------|
| 22055177 | 21771749 | KAYLEN | DONAHUE | USA | CA | HUNTINGTON PARK | 3FN37590 | GNDE4MZXGU4TA | Most recently inserted trading user. All-caps naming convention matches Apex Clearing's format requirements. |
| 47587445 | 47583025 | DAVID | DONNELL | USA | CA | EL CAJON | 3FN37589 | GNDE4MZXGU4DS | Standard US customer with California address. FDID is a Base32-encoded unique identifier. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Platform Customer ID. Different from GCID. The internal customer identifier used in the trading/user platform. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Primary key. The cross-system unique identifier. |
| 3 | GivenName | nvarchar(50) | NO | - | CODE-BACKED | Customer's first/given name in uppercase. Used for regulatory reporting and trade surveillance. |
| 4 | FamilyName | nvarchar(50) | NO | - | CODE-BACKED | Customer's last/family name in uppercase. |
| 5 | LegalName | nvarchar(150) | NO | - | CODE-BACKED | Full legal name (first + middle + last) as a single string. Used in official communications and regulatory filings. |
| 6 | Country | nvarchar(3) | NO | - | CODE-BACKED | ISO 3166 alpha-3 country code of the customer's home address. Observed: "USA". |
| 7 | State | nvarchar(2) | NO | - | CODE-BACKED | US state abbreviation (e.g., "CA", "TX"). Two-character USPS code. |
| 8 | City | nvarchar(50) | NO | - | CODE-BACKED | City name from the customer's home address. Uppercase format. |
| 9 | PostalCode | nvarchar(50) | NO | - | CODE-BACKED | ZIP/postal code of the customer's home address. |
| 10 | StreetAddress1 | nvarchar(50) | NO | - | CODE-BACKED | Primary street address line. |
| 11 | StreetAddress2 | nvarchar(50) | YES | - | CODE-BACKED | Secondary address line (apartment, suite, etc.). NULL when not applicable. |
| 12 | StreetAddress3 | nvarchar(50) | YES | - | CODE-BACKED | Third address line. Rarely used. NULL when not applicable. |
| 13 | ApexID | varchar(8) | NO | - | CODE-BACKED | Apex Clearing account identifier. Same value as in ApexData and TradingApexData. |
| 14 | FDID | varchar(20) | NO | - | CODE-BACKED | Financial Data Identifier - the unique customer identifier used for CAT (Consolidated Audit Trail) and OATS regulatory trade reporting. Base32-encoded format. Required by FINRA for trade surveillance. |
| 15 | InsertDate | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this record was created. Default is current UTC time. Indexed for chronological queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing FK references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveTradingUserData | all params | Writer | Creates/updates trading user data |
| Apex.GetTradingUserData | @GCID | Reader | Retrieves single customer |
| Apex.GetTradingUsersDataList | @gcids (Apex.GCIDs) | Reader | Bulk retrieval via TVP |
| Apex.DeleteTradingUserData | @GCID | Deleter | Removes by GCID |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveTradingUserData | Stored Procedure | Writer |
| Apex.GetTradingUserData | Stored Procedure | Reader |
| Apex.GetTradingUsersDataList | Stored Procedure | Bulk reader via GCIDs TVP |
| Apex.DeleteTradingUserData | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradingUserData | CLUSTERED PK | GCID ASC | - | - | Active |
| ix_TradingUserData_InsertDate | NONCLUSTERED | InsertDate ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradingUserData | PRIMARY KEY | Clustered on GCID |
| DF_TradingUserData_InsertDate | DEFAULT | InsertDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 Get a customer's trading data

```sql
SELECT GCID, CID, LegalName, ApexID, FDID, Country, State, City, InsertDate
FROM Apex.TradingUserData WITH (NOLOCK)
WHERE GCID = 22055177;
```

### 8.2 Find recently inserted trading users

```sql
SELECT TOP 20 GCID, CID, LegalName, ApexID, FDID, InsertDate
FROM Apex.TradingUserData WITH (NOLOCK)
ORDER BY InsertDate DESC;
```

### 8.3 Look up trading data by Apex account ID

```sql
SELECT GCID, CID, LegalName, ApexID, FDID, State, City
FROM Apex.TradingUserData WITH (NOLOCK)
WHERE ApexID = '3FN37590';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.TradingUserData | Type: Table | Source: USABroker/Apex/Tables/Apex.TradingUserData.sql*
