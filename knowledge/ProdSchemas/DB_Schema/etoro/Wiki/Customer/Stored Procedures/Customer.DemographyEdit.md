# Customer.DemographyEdit

> Orchestrates a full customer demographic update: resolves affiliate and spread group changes, synchronizes both real and demo account records, and optionally updates the customer's password - the top-level SP for customer profile edits.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; no SELECT output (returns 0 on success or raises error 60000) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DemographyEdit is the primary entry point for updating a customer's demographic information. Unlike the lower-level Customer.P_UpdateCustomer (which is a plain UPDATE), DemographyEdit handles the full business logic around:

1. **Null coalescing**: Reads current values from CustomerStatic; if a parameter is NULL, retains the existing value (prevents accidental blanking)
2. **Affiliate change logic**: If the customer's affiliate (SerialID) changes, ensures the new affiliate exists in both RealAffiliate and DemoAffiliate tables, and recalculates the appropriate SpreadGroupID
3. **Cross-account sync**: Updates both the Customer.Customer (real/demo via GCID) and RealCustomers (real account) tables to keep them in sync
4. **Password update**: Optionally delegates to STS_P_UpdateCustomerPassword if @Password is provided
5. **CommunicationLanguage fallback**: If not provided, reads from DemoCustomers or RealCustomers depending on stage

The procedure uses `XACT_ABORT ON` to ensure the transaction rolls back cleanly if any statement fails.

**Change history (from DDL comments)**:
- Original: Evgeny & Geri (early creation)
- 25/08/2015: Varchar to NVarchar migration, FogBugz 28292 (Geri Reshef)
- 03/12/2015: FogBugz 32274 - 3 SPs changed (Geri Reshef)
- 27/05/2018: OPS0419 MiFID II SP updates, FogBugz 51656 (Geri Reshef)
- 15/07/2018: Phone null check (Ran Ovadia, requested by Stav)
- 07/08/2018: BackOffice-to-UserApi alignment, FogBugz 52399 (Geri Reshef)
- 18/09/2019: SubRegionID hot fix (Geri Reshef)

---

## 2. Business Logic

### 2.1 NULL Coalescing (Preserve Existing Values)

**What**: Reads current CustomerStatic values to fill in NULL input parameters.

**Columns/Parameters Involved**: `@SerialID`, `@Phone`, `@Fax`, `@Mobile`, `@Address`, `@BuildingNumber`, `@City`, `@Zip`, `@Gender`, `@SubRegionID`, `@old_SpreadGroupID`, `@old_SerialID`

**Rules**:
- `SELECT @SerialID=ISNULL(@SerialID, SerialID), @Phone=ISNULL(@Phone, Phone), ...` from Customer.CustomerStatic WHERE CID=@CID
- Phone explicitly uses ISNULL (requested by Stav 15/07/2018) - prevents phone number being wiped on partial updates
- Also captures @old_SpreadGroupID and @old_SerialID for affiliate change detection

### 2.2 Affiliate Change Detection and SpreadGroup Resolution

**What**: When the affiliate changes, determines the new SpreadGroupID based on affiliate configuration.

**Columns/Parameters Involved**: `@SerialID`, `@old_SerialID`, `@SpreadGroupID`, `@old_SpreadGroupID`, `@old_SerialSpreadGroupID`

**Rules**:
- If `@SerialID != @old_SerialID` (affiliate changed):
  - Ensures new affiliate exists in RealAffiliate (inserts with AffiliateStatusID=1 if missing)
  - Ensures new affiliate exists in DemoAffiliate (inserts with AffiliateStatusID=1 if missing)
  - Gets old affiliate's SpreadGroupID from BackOffice.Affiliate (@old_SerialSpreadGroupID)
  - **SpreadGroup transfer rule**: If old affiliate's SpreadGroupID matches the customer's current SpreadGroupID (customer was using affiliate's group), then switch to new affiliate's SpreadGroupID. Otherwise, keep customer's existing SpreadGroupID (customer had a custom group).
- If affiliate did NOT change: read SpreadGroupID from Customer.Customer

### 2.3 GCID and IsReal Resolution

**What**: Resolves the GCID and account type flag needed for P_UpdateCustomer.

**Columns/Parameters Involved**: `@GCID`, `@IsReal`

**Rules**:
- `SELECT @GCID=GCID, @IsReal=IsReal FROM Customer.Customer WHERE CID=@CID`
- IsReal=1 means real-money account; IsReal=0 means demo account

### 2.4 CommunicationLanguage Fallback

**What**: Determines the communication language if not provided by the caller.

**Columns/Parameters Involved**: `@CommunicationLanguageID`

**Rules**:
- First attempt (before P_UpdateCustomer call): if NULL, read from DemoCustomers WHERE GCID=@GCID
- Second attempt (after P_UpdateCustomer call for RealCustomers update): if still NULL, read from RealCustomers WHERE GCID=@GCID
- This two-stage fallback ensures the real/demo sync uses the appropriate source

### 2.5 Core Update via P_UpdateCustomer

**What**: Delegates the actual UPDATE of Customer.Customer to the primitive SP.

**Columns/Parameters Involved**: All demographic parameters

**Rules**:
- `EXEC Customer.P_UpdateCustomer @StateID, @CommunicationLanguageID, ... @GCID, @IsReal, @CID, @SubRegionID`
- P_UpdateCustomer uses WHERE (GCID=@GCID AND GCID>0) OR (@IsReal=0 AND CID=@CID)
- Updates Customer.Customer view (which underlies both real and demo accounts)

### 2.6 Password Update

**What**: Updates the customer's password if a new value is provided.

**Columns/Parameters Involved**: `@Password`, `@GCID`

**Rules**:
- `IF @Password IS NOT NULL EXEC STS_P_UpdateCustomerPassword @gcid=@GCID, @newPlainTextPassword=@Password`
- @Password is VARCHAR(20) - plaintext; STS_P_UpdateCustomerPassword handles hashing
- Email (previously updatable) and UserName are commented out - not modified by this SP

### 2.7 RealCustomers Direct Update

**What**: Directly updates the RealCustomers synonym/view (real-money account table).

**Columns/Parameters Involved**: All demographic parameters + `SubSerialID`

**Rules**:
- `UPDATE RealCustomers SET ... WHERE (GCID=@GCID AND GCID IS NOT NULL AND GCID>0) OR (@IsReal=1 AND CID=@CID)`
- Note: @IsReal=1 in the CID fallback (reverse of P_UpdateCustomer which uses @IsReal=0)
- This second UPDATE ensures the real-account record is synchronized
- Password column explicitly commented out ("This column should not be in use")

### 2.8 Error Handling

**What**: Checks for errors and raises error code 60000 on failure.

**Rules**:
- `XACT_ABORT ON` - rolls back transaction on any error
- `SELECT @LocalError=@@Error` checked after P_UpdateCustomer and after RealCustomers update
- `RaiseError(60000, 16, 1, 'Customer.DemographyEdit', @LocalError)` if error detected
- `RETURN 60000` on error; `RETURN 0` on success

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input: Internal customer ID. Used to read current values from CustomerStatic and passed to P_UpdateCustomer. |
| 2 | @StateID | INT | NO | - | CODE-BACKED | State/province ID for the customer's address. FK to Dictionary.State. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Customer's base currency. FK to Dictionary.Currency. |
| 4 | @TimeZoneID | INT | NO | - | CODE-BACKED | Customer's time zone preference. FK to Dictionary.TimeZone. |
| 5 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Club membership level. 0=no club. Passed through to Customer.Customer. |
| 6 | @UserName | VARCHAR(20) | NO | - | CODE-BACKED | Customer username. Accepted as parameter but NOT updated (commented out since FogBugz 23671). |
| 7 | @Password | VARCHAR(20) | YES | - | CODE-BACKED | New plaintext password. If non-NULL, triggers STS_P_UpdateCustomerPassword. NOT stored in columns directly. |
| 8 | @Gender | CHAR(1) | NO | - | CODE-BACKED | Gender: 'M' or 'F'. NULL-coalesced to existing value. |
| 9 | @Address | NVARCHAR(100) | NO | - | CODE-BACKED | Street address (Unicode). NULL-coalesced to existing value. |
| 10 | @BuildingNumber | NVARCHAR(30) | YES | NULL | CODE-BACKED | Building/apartment number. Optional. NULL-coalesced to existing value. |
| 11 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | City name (Unicode). NULL-coalesced to existing value. |
| 12 | @Zip | NVARCHAR(50) | NO | - | CODE-BACKED | Postal code (Unicode). NULL-coalesced to existing value. |
| 13 | @Phone | VARCHAR(30) | NO | - | CODE-BACKED | Phone number. NULL-coalesced to existing value (phone preservation added 15/07/2018). |
| 14 | @Fax | VARCHAR(30) | NO | - | CODE-BACKED | Fax number (legacy). NULL-coalesced to existing value. |
| 15 | @Mobile | VARCHAR(30) | NO | - | CODE-BACKED | Mobile phone. NULL-coalesced to existing value. |
| 16 | @SerialID | INT | YES | NULL | CODE-BACKED | Affiliate ID. Triggers affiliate change logic if different from current value. FK to BackOffice.Affiliate.AffiliateID. |
| 17 | @CommunicationLanguageID | INT | YES | NULL | CODE-BACKED | Communication language. If NULL, falls back to DemoCustomers then RealCustomers source. |
| 18 | @SubSerial | VARCHAR(1024) | YES | NULL | CODE-BACKED | Sub-affiliate tracking code. Stored as SubSerialID. NULL-coalesced to existing value (implicit via P_UpdateCustomer). |
| 19 | @SubRegionID | INT | YES | NULL | CODE-BACKED | Sub-region ID. NULL-coalesced to existing value. Added as hot fix 18/09/2019. |
| **Return value** | | | | | | |
| 20 | Return 0 | INT | - | - | CODE-BACKED | Success return code. |
| 21 | Return 60000 | INT | - | - | CODE-BACKED | Error return code. Raised via RaiseError(60000,...) on any @@Error != 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | FROM (read current values) | NULL coalescing and old value capture |
| @SerialID | RealAffiliate | EXISTS check + INSERT | Ensures new affiliate exists in real affiliate table |
| @SerialID | DemoAffiliate | EXISTS check + INSERT | Ensures new affiliate exists in demo affiliate table |
| @SerialID | BackOffice.Affiliate | FROM (SpreadGroupID lookup) x2 | Resolves old and new affiliate SpreadGroupIDs |
| @CID | Customer.Customer | FROM (GCID, IsReal lookup) | Resolves GCID and account type |
| @GCID | DemoCustomers | FROM (CommunicationLanguage fallback) | Pre-update language fallback |
| @GCID | RealCustomers | FROM + UPDATE | Post-update language fallback + real account direct update |
| All params | Customer.P_UpdateCustomer | EXEC | Core UPDATE of Customer.Customer view |
| @GCID | STS_P_UpdateCustomerPassword | EXEC (conditional) | Password change if @Password IS NOT NULL |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice and UserApi services when updating customer profiles.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DemographyEdit (procedure)
|-- Customer.CustomerStatic (table - read)
|-- Customer.Customer (view - read GCID/IsReal)
|-- BackOffice.Affiliate (table - SpreadGroup lookup)
|-- RealAffiliate (synonym/view - affiliate existence)
|-- DemoAffiliate (synonym/view - affiliate existence)
|-- DemoCustomers (synonym/view - CommunicationLanguage fallback)
|-- RealCustomers (synonym/view - real account update)
|-- Customer.P_UpdateCustomer (procedure - core UPDATE)
`-- STS_P_UpdateCustomerPassword (procedure - password update)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FROM - reads current values for NULL coalescing |
| Customer.Customer | View | FROM - resolves GCID and IsReal |
| BackOffice.Affiliate | Table | FROM x2 - old and new affiliate SpreadGroupID lookup |
| RealAffiliate | Synonym/View | EXISTS check + INSERT - ensures affiliate exists |
| DemoAffiliate | Synonym/View | EXISTS check + INSERT - ensures affiliate exists |
| DemoCustomers | Synonym/View | FROM - pre-update CommunicationLanguage fallback |
| RealCustomers | Synonym/View | FROM + UPDATE - post-update language fallback and real account sync |
| Customer.P_UpdateCustomer | Procedure | EXEC - core demographic UPDATE |
| STS_P_UpdateCustomerPassword | Procedure | EXEC conditional - password update |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by BackOffice and UserApi application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Transaction safety | Automatic rollback on any statement error |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| @UserName accepted but unused | Dead parameter | Parameter received but update commented out since FogBugz 23671 |
| Error code 60000 | Error protocol | Non-standard error code; callers check return value or catch RAISERROR |
| Two-stage real/demo sync | Architecture | Customer.Customer (GCID) + RealCustomers (GCID) both updated to maintain sync |
| Phone null preservation | Bug fix | @Phone=ISNULL(@Phone,Phone) added 15/07/2018 to prevent phone being wiped |

---

## 8. Sample Queries

### 8.1 Update customer demographics
```sql
EXEC Customer.DemographyEdit
    @CID = 123456,
    @StateID = 0,
    @CurrencyID = 1,
    @TimeZoneID = 35,
    @PlayerLevelID = 0,
    @UserName = 'john_doe',  -- accepted but not updated
    @Password = NULL,        -- no password change
    @Gender = 'M',
    @Address = N'123 Main Street',
    @BuildingNumber = NULL,
    @City = N'New York',
    @Zip = '10001',
    @Phone = '+1-555-0100',
    @Fax = '',
    @Mobile = '+1-555-0101',
    @SerialID = 42,
    @CommunicationLanguageID = NULL,
    @SubSerial = NULL,
    @SubRegionID = NULL;
-- Returns 0 on success; raises error 60000 on failure
```

### 8.2 Update address only (phone preserved via NULL coalescing)
```sql
-- @Phone = NULL -> existing phone is preserved, not wiped
EXEC Customer.DemographyEdit
    @CID = 123456, @StateID = 0, @CurrencyID = 1, @TimeZoneID = 35,
    @PlayerLevelID = 0, @UserName = '', @Password = NULL, @Gender = 'M',
    @Address = N'456 New Street', @City = N'Boston', @Zip = '02101',
    @Phone = NULL,   -- NULL -> ISNULL(NULL, existing_phone) = existing_phone preserved
    @Fax = NULL, @Mobile = NULL, @SerialID = NULL, @SubSerial = NULL;
```

### 8.3 Affiliate change cascade
```sql
-- When @SerialID changes, DemographyEdit:
-- 1. Ensures new affiliate exists in RealAffiliate and DemoAffiliate
-- 2. If customer was using old affiliate's SpreadGroupID -> switches to new affiliate's SpreadGroupID
-- 3. If customer had custom SpreadGroupID -> keeps it unchanged
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FogBugz 28292 | Work item | Varchar to NVarchar migration (25/08/2015) |
| FogBugz 51656 / OPS0419 | Work item | MiFID II SP updates (27/05/2018) |
| FogBugz 52399 | Work item | BackOffice-to-UserApi alignment for customer details (07/08/2018) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Work items: 3 from DDL comments | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.DemographyEdit | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DemographyEdit.sql*
