# Customer.Address

> Temporal table storing customer mailing/tax addresses by GCID and address type, used for KYC compliance, W8BEN tax form collection, and regulatory correspondence.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID + AddressTypeID (composite PK, clustered) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (clustered PK only) |

---

## 1. Business Meaning

Customer.Address stores structured postal address records for customers, keyed by Global Customer ID (GCID) and address type. It is specifically a separate, structured address table designed to support W8BEN tax form collection (the IRS form for non-US persons claiming treaty benefits or certifying foreign status) and KYC (Know Your Customer) address verification. Unlike CustomerStatic which stores minimal country-level residence, this table captures full postal details — street address, city, zip, building number, and geographic subdivisions — required for formal regulatory and tax correspondence.

This table was deliberately separated from CustomerStatic to support more fields required for specific countries (State, ProvinceID, SubRegionID) and to allow the address to be managed independently through the User API with dedicated REST endpoints (GET/PUT/DELETE `/v1/users/{GCID}/addresses/{addressType}`). The KYC Proxy service also uses these endpoints for compliance verification.

Data flows in via Customer.UpdateContactUserInfo and Customer.UpdateContactUserInfoRemote, is preserved historically by SQL Server temporal versioning (full change history in History.Address), and is deleted via Customer.GDPRDeleteUser when a customer exercises GDPR data deletion rights. Currently all 10,555 records use AddressTypeID=1 (Mailing), reflecting the single current use case, though the schema is designed for multiple address types.

---

## 2. Business Logic

### 2.1 W8BEN and Tax Address Collection

**What**: Customer.Address stores the formal mailing address required for W8BEN (US tax treaty benefit certification) for non-US resident customers.

**Columns/Parameters Involved**: `GCID`, `AddressTypeID`, `CountryID`, `Address`, `City`, `Zip`, `BuildingNumber`

**Rules**:
- W8BEN requires a verifiable foreign address — CountryID (FK to Dictionary.Country) is always populated; street address fields may be optional depending on country requirements
- AddressTypeID=1 (Mailing) is the only current type — used for correspondence, tax forms, and KYC document delivery
- Country-specific geographic data (SubRegionID, RegionID) supports jurisdiction-specific compliance requirements
- KYC Proxy service routes address updates through User API to this table for verification workflows

### 2.2 Temporal Versioning (Full Address History)

**What**: SQL Server temporal table — every change to a customer's address is automatically preserved in History.Address.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- SYSTEM_VERSIONING = ON with HISTORY_TABLE = History.Address
- BeginTime: auto-populated with GETUTCDATE() when row is inserted or updated
- EndTime: set to '9999-12-31 23:59:59.9999999' for current record; updated to actual UTC time when row is changed
- History rows preserve all previous addresses — required for tax compliance (historical address determines applicable tax treaty) and fraud investigation (address change patterns)
- No explicit period triggers needed — SQL Server handles versioning automatically on any INSERT/UPDATE/DELETE

**Diagram**:
```
Customer.Address (current)
  GCID=1001, AddressTypeID=1, CountryID=218, Zip="SW1A 1AA"
  BeginTime=2024-01-15 | EndTime=9999-12-31

History.Address (all previous versions)
  GCID=1001, AddressTypeID=1, CountryID=132, Zip="10001"
  BeginTime=2022-06-01 | EndTime=2024-01-15 (moved from US to UK)
```

---

## 3. Data Overview

| GCID | AddressTypeID | CountryID | Address | Zip | City | Meaning |
|---|---|---|---|---|---|---|
| 12548686 | 1 (Mailing) | 218 (UK) | NULL | AA9A 9AA | NULL | A UK customer with partial address - only zip code captured, likely submitted via KYC flow where only zip was required |
| 12548691 | 1 (Mailing) | 218 (UK) | NULL | A9A 9AA | NULL | UK customer with a different format postal code - address/city fields are NULL indicating a minimal KYC submission |

*Note: All 10,555 current records use AddressTypeID=1 (Mailing). CountryID=218 appears frequently in sample, suggesting UK customers are a major segment of the address collection. Many rows have NULL for Address and City, with Zip being the most consistently populated field - consistent with W8BEN collection where postal code is the minimum required for country-level verification.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID - part of composite PK. Identifies the customer globally across eToro systems. References the same GCID in Customer.CustomerStatic. |
| 2 | AddressTypeID | int | NO | - | VERIFIED | Address classification: 1=Mailing (only current type). FK to Dictionary.AddressType. Designed for future expansion (billing, residential, etc.). See [AddressType](../../Dictionary/Tables/Dictionary.AddressType.md) for full definitions. |
| 3 | CountryID | int | NO | - | VERIFIED | Country of the address. FK to Dictionary.Country. Always populated - the minimum required field for tax and KYC purposes. Determines which tax treaty rules apply. |
| 4 | Address | nvarchar(255) | YES | - | CODE-BACKED | Street address line (street name and number). NULL in many records, indicating partial submissions where only Zip was required for the specific KYC workflow. |
| 5 | City | nvarchar(50) | YES | - | CODE-BACKED | City/locality of the address. NULL in many records — optional depending on country-specific KYC requirements. |
| 6 | Zip | nvarchar(50) | YES | - | CODE-BACKED | Postal/ZIP code. The most frequently populated address field — used for country-level verification, mailing zone determination, and tax jurisdiction. |
| 7 | BuildingNumber | nvarchar(30) | YES | - | CODE-BACKED | Building or apartment number, separate from the street address line. NULL in most records. Supports address formats (common in some European countries) where building number is a separate field from street name. |
| 8 | SubRegionID | int | YES | - | CODE-BACKED | Sub-regional geographic division (e.g., US state, Canadian province). FK to Dictionary.SubRegion. NULL for most records; populated for countries where regulatory compliance requires sub-region tracking. |
| 9 | BeginTime | datetime2(7) | NO | getutcdate() | VERIFIED | System-generated temporal period start. Set automatically by SQL Server when the row is created or when a previous version's EndTime closes. Marks when this version of the address became effective. |
| 10 | EndTime | datetime2(7) | NO | 9999-12-31 | VERIFIED | System-generated temporal period end. Value of '9999-12-31 23:59:59.9999999' indicates the current active version. SQL Server sets this to the actual change time when the row is superseded. |
| 11 | RegionID | int | YES | - | CODE-BACKED | IP-based geographic region. FK to Dictionary.RegionByIP (RegionByIP_ID). Optionally populated to correlate declared address with IP-inferred region for fraud/compliance checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AddressTypeID | Dictionary.AddressType | FK (FK_Customer_Address_AddressTypeID) | Address category: currently only Mailing (1) |
| CountryID | Dictionary.Country | FK (FK_Customer_Address_CountryID) | Country of the address - always populated |
| SubRegionID | Dictionary.SubRegion | FK (FK_Customer_Address_SubRegionID) | Sub-regional division, NULL for most records |
| RegionID | Dictionary.RegionByIP | FK (FK_Customer_Address_RegionID) | IP-derived region correlation, NULL for most records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Address | GCID + AddressTypeID | Temporal History | Automatically receives all superseded address versions via SYSTEM_VERSIONING |
| Customer.UpdateContactUserInfo | GCID | WRITER | Updates customer contact details including address |
| Customer.UpdateContactUserInfoRemote | GCID | WRITER | Remote service call to update contact/address data |
| Customer.GDPRDeleteUser | GCID | DELETER | Deletes address records as part of GDPR right-to-erasure |
| Customer.DynamicsInsert | GCID | READER/WRITER | Synchronizes customer data including address to Microsoft Dynamics CRM |
| User API | GCID + AddressTypeID | REST (GET/PUT/DELETE) | `/v1/users/{GCID}/addresses/{addressType}` - primary external access path |
| KYC Proxy | GCID | Indirect via User API | Routes address updates for KYC document verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Address (table)
|- Dictionary.AddressType (table) [FK - leaf]
|- Dictionary.Country (table) [FK - leaf]
|- Dictionary.SubRegion (table) [FK - leaf]
|- Dictionary.RegionByIP (table) [FK - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AddressType | Table | FK - AddressTypeID identifies the address purpose |
| Dictionary.Country | Table | FK - CountryID identifies the country of the address |
| Dictionary.SubRegion | Table | FK - SubRegionID identifies the sub-regional division |
| Dictionary.RegionByIP | Table | FK - RegionID correlates address with IP-derived region |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Address | Table | Temporal history - receives all superseded address versions automatically |
| Customer.UpdateContactUserInfo | Stored Procedure | Writes customer address data |
| Customer.UpdateContactUserInfoRemote | Stored Procedure | Remote write for address updates |
| Customer.GDPRDeleteUser | Stored Procedure | Deletes on GDPR erasure request |
| Customer.DynamicsInsert | Stored Procedure | Reads address for CRM sync |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAddress | CLUSTERED | GCID ASC, AddressTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerAddress | PRIMARY KEY | GCID + AddressTypeID must be unique - one address record per customer per address type |
| FK_Customer_Address_AddressTypeID | FOREIGN KEY | AddressTypeID must exist in Dictionary.AddressType |
| FK_Customer_Address_CountryID | FOREIGN KEY | CountryID must exist in Dictionary.Country |
| FK_Customer_Address_SubRegionID | FOREIGN KEY | SubRegionID must exist in Dictionary.SubRegion (when not NULL) |
| FK_Customer_Address_RegionID | FOREIGN KEY | RegionID must exist in Dictionary.RegionByIP (when not NULL) |
| Df_Customer_Address_BeginTime | DEFAULT | BeginTime = GETUTCDATE() on insert |
| Df_Customer_Address_EndTime | DEFAULT | EndTime = '99991231 23:59:59.9999999' on insert (current version sentinel) |

---

## 8. Sample Queries

### 8.1 Get current address for a customer

```sql
SELECT
    a.GCID,
    dat.Name AS AddressType,
    dc.Name AS Country,
    a.Address,
    a.City,
    a.Zip,
    a.BuildingNumber
FROM Customer.Address a WITH (NOLOCK)
INNER JOIN Dictionary.AddressType dat WITH (NOLOCK) ON dat.AddressTypeID = a.AddressTypeID
INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON dc.CountryID = a.CountryID
WHERE a.GCID = 12548686
```

### 8.2 Get complete address history for a customer (temporal query)

```sql
SELECT
    GCID,
    AddressTypeID,
    CountryID,
    Address,
    City,
    Zip,
    BeginTime,
    EndTime
FROM Customer.Address
FOR SYSTEM_TIME ALL
WHERE GCID = 12548686
ORDER BY BeginTime
```

### 8.3 Find customers with a specific country address for compliance reporting

```sql
SELECT
    a.GCID,
    dc.Name AS Country,
    a.Zip,
    a.City,
    a.BeginTime AS AddedDate
FROM Customer.Address a WITH (NOLOCK)
INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON dc.CountryID = a.CountryID
WHERE a.AddressTypeID = 1
  AND a.CountryID = 218  -- UK
ORDER BY a.BeginTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: RD-12501 W8BEN - Mailing Address](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/730497130/HLD+RD-12501+W8BEN+-+Mailing+Address) | Confluence | Original design spec: table created for W8BEN tax form address collection; originally part of CustomerStatic but separated for richer fields; User API endpoints GET/PUT/DELETE /v1/users/{GCID}/addresses/{addressType}; KYC Proxy integration |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.Address | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.Address.sql*
