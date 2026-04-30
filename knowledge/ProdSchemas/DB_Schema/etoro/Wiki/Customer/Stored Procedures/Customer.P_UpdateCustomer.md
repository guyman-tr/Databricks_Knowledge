# Customer.P_UpdateCustomer

> Updates demographic and account configuration fields on Customer.Customer for a customer identified by GCID (or CID for demo accounts), the shared update primitive called by DemographyEdit.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID / @CID + @IsReal; performs UPDATE, no SELECT output |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.P_UpdateCustomer is the low-level UPDATE primitive for customer demographic data. It updates a single row in the Customer.Customer view with the supplied values. It is called by Customer.DemographyEdit (the higher-level orchestrator) which handles pre-processing logic (affiliate changes, SpreadGroup resolution, NULL coalescing) before delegating the actual UPDATE here.

The "P_" prefix follows a convention for primitive/internal helper procedures not called directly by application code.

The WHERE clause handles two scenarios:
- **GCID-based update** (`GCID=@GCID AND GCID>0`): the primary path; updates both real and demo accounts sharing the GCID
- **CID-based update for demo** (`@IsReal=0 AND CID=@CID`): fallback for demo-only accounts without a GCID link

Commented-out fields (CountryID, LanguageID, BirthDate, FirstName, LastName, Email) were removed over time as those became managed by dedicated procedures with stricter controls (e.g., CountryID is locked post-registration; BirthDate is KYC-sensitive).

**Change history (from DDL comments)**:
- 22/07/2014: FogBugz 23263 (Geri Reshef) - original creation
- 24/08/2014: FogBugz 23671 (Geri Reshef) - removed CountryID, LanguageID, FirstName, LastName
- 07/09/2014: FogBugz 23671 (Yitzchak Wahnon) - field removals
- 27/07/2015: Varchar to NVarchar migration (Geri Reshef)
- 03/12/2016: FogBugz 32274 (Geri Reshef) - 3 SPs changed
- 27/05/2018: OPS0419 MiFID II updates (Geri Reshef, FogBugz 51656)
- 09/07/2019: Added SubRegionID (Ran Ovadia)

---

## 2. Business Logic

### 2.1 Dual-Identity Update

**What**: Updates Customer.Customer matching either GCID (primary) or CID (demo fallback).

**Columns/Parameters Involved**: `@GCID`, `@CID`, `@IsReal`

**Rules**:
- WHERE: `(GCID=@GCID AND GCID>0) OR (@IsReal=0 AND CID=@CID)`
- GCID path: updates all accounts under the GCID (typically 1 row; may be 2 for cross-product)
- Demo CID path: only active when IsReal=0 (demo account) AND GCID is 0 or absent
- The two conditions are OR-ed but in practice only one fires per call

### 2.2 SpreadGroup Resolution

**What**: SpreadGroupID determines the customer's pricing tier (spread markup).

**Columns/Parameters Involved**: `@SpreadGroupID`

**Rules**:
- SpreadGroupID is passed in (resolved by DemographyEdit based on affiliate changes)
- This SP does not compute SpreadGroupID; it only stores it

### 2.3 SubSerial Handling

**What**: SubSerial is the sub-affiliate tracking code (secondary affiliate chain).

**Columns/Parameters Involved**: `@SubSerial`, `SubSerialID`

**Rules**:
- Column in Customer.Customer is named SubSerialID but parameter is @SubSerial (Varchar(1024))
- Direct assignment; no validation in this SP

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StateID | INT | NO | - | CODE-BACKED | State/province ID. FK to Dictionary.State. |
| 2 | @CommunicationLanguageID | INT | YES | NULL | CODE-BACKED | Preferred language for communications. FK to Dictionary.Language. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Customer's base currency. FK to Dictionary.Currency (1=USD, 2=EUR, etc.). |
| 4 | @TimeZoneID | INT | NO | - | CODE-BACKED | Customer's time zone. FK to Dictionary.TimeZone. |
| 5 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Club membership level. 0=no club, 100=Bronze Plus sentinel. Used by RAF model lookups. |
| 6 | @Gender | CHAR(1) | NO | - | CODE-BACKED | Gender: 'M'=Male, 'F'=Female. |
| 7 | @Address | NVARCHAR(100) | NO | - | CODE-BACKED | Street address (NVarchar to support Unicode characters). |
| 8 | @BuildingNumber | NVARCHAR(30) | YES | NULL | CODE-BACKED | Building/apartment number. Optional. |
| 9 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | City name (Unicode). |
| 10 | @Zip | NVARCHAR(50) | NO | - | CODE-BACKED | ZIP/postal code (Unicode to support international formats). |
| 11 | @Phone | VARCHAR(30) | NO | - | CODE-BACKED | Primary phone number. |
| 12 | @Fax | VARCHAR(30) | NO | - | CODE-BACKED | Fax number (legacy field; often empty). |
| 13 | @Mobile | VARCHAR(30) | NO | - | CODE-BACKED | Mobile/cell phone number. Used for SMS 2FA. |
| 14 | @SerialID | INT | YES | NULL | CODE-BACKED | Primary affiliate (SerialID). FK to BackOffice.Affiliate.AffiliateID. |
| 15 | @SpreadGroupID | INT | NO | - | CODE-BACKED | Pricing spread group. Determined by DemographyEdit based on affiliate; stored here. |
| 16 | @SubSerial | VARCHAR(1024) | YES | NULL | CODE-BACKED | Sub-affiliate tracking code chain. Stored in SubSerialID column. |
| 17 | @GCID | INT | NO | - | CODE-BACKED | Group Customer ID. Primary WHERE key; GCID>0 required to use GCID path. |
| 18 | @IsReal | INT | NO | - | CODE-BACKED | 0=Demo account, 1=Real account. Enables CID-based update path when IsReal=0. |
| 19 | @CID | INT | NO | - | CODE-BACKED | Internal Customer ID. Used as fallback WHERE key when @IsReal=0. |
| 20 | @SubRegionID | INT | YES | NULL | CODE-BACKED | Sub-region ID for geographic classification. Added 09/07/2019 (Ran Ovadia). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID / @CID | Customer.Customer | UPDATE (via view) | Target of all demographic field updates |

### 5.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| Customer.DemographyEdit | EXEC (calls this SP as update primitive) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.P_UpdateCustomer (procedure)
`-- Customer.Customer (view -> CustomerStatic + CustomerMoney)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target - updates underlying CustomerStatic/CustomerMoney via view |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.DemographyEdit | Procedure | EXEC - calls as update primitive after pre-processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Commented-out sensitive fields | Design | CountryID, LanguageID, BirthDate, FirstName, LastName, Email all removed (FogBugz 23671) - managed by dedicated procedures |
| GCID>0 guard | Data quality | Prevents GCID=0 (unlinked demo) from matching the GCID path |
| No SET NOCOUNT ON | Side effect | Returns row count of affected rows; callers should expect this |

---

## 8. Sample Queries

### 8.1 Update customer demographics (typically called via DemographyEdit)
```sql
-- This SP is a primitive - prefer calling Customer.DemographyEdit instead
EXEC Customer.P_UpdateCustomer
    @StateID = 0, @CommunicationLanguageID = NULL,
    @CurrencyID = 1, @TimeZoneID = 35,
    @PlayerLevelID = 0, @Gender = 'M',
    @Address = N'123 Main St', @BuildingNumber = NULL,
    @City = N'New York', @Zip = '10001',
    @Phone = '+1-555-0100', @Fax = '', @Mobile = '+1-555-0101',
    @SerialID = NULL, @SpreadGroupID = 1, @SubSerial = NULL,
    @GCID = 1983785, @IsReal = 1, @CID = 123456,
    @SubRegionID = NULL;
```

### 8.2 What gets updated vs what is locked
```sql
-- UPDATABLE by this SP:
-- StateID, CommunicationLanguageID, CurrencyID, TimeZoneID, PlayerLevelID
-- Gender, Address, BuildingNumber, City, Zip, Phone, Fax, Mobile
-- SerialID, SpreadGroupID, SubSerialID, SubRegionID

-- NOT updatable (locked/removed):
-- CountryID, LanguageID, BirthDate, FirstName, LastName, Email, UserName
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FogBugz 23671 | Work item | Removal of CountryID, LanguageID, BirthDate, FirstName, LastName (2014) |
| FogBugz 51656 / OPS0419 | Work item | MiFID II-related SP updates (27/05/2018) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Work items: 2 from DDL comments | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.P_UpdateCustomer | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.P_UpdateCustomer.sql*
