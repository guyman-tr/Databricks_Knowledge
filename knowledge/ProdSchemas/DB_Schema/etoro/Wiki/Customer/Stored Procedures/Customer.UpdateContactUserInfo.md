# Customer.UpdateContactUserInfo

> Updates a customer's contact and address fields on CustomerStatic and queues an async propagation action (ActionID=10) for downstream systems, also handling email verification state with a preserve-existing pattern.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID lookup for CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateContactUserInfo is the main-application write-path for a customer's contact and address data - country, email, address, city, zip, phone, mobile, fax, state, region, citizenship country, place of birth, and email verification status. It updates Customer.CustomerStatic directly and then queues an async action (ActionID=10) in Internal.ActionsToExecute_Registration to propagate the contact change to downstream systems.

The procedure differs from UpdateContactUserInfoRemote in two ways: (1) it writes the action queue entry for downstream propagation, and (2) it handles IsEmailVerified and EmailVerificationProviderID with ISNULL (preserving existing values when not provided). The "Remote" variant skips these two fields and the queue.

Data flow: called from the customer profile UI or KYC onboarding flow when contact details are submitted or updated. ActionID=10 is the "UpdateContactUserInfo" action type consumed by the Internal action processor. @RowCount OUTPUT returns the rows affected by the CustomerStatic UPDATE.

---

## 2. Business Logic

### 2.1 Contact Field Update (Direct SET, No ISNULL for Most Fields)

**What**: Most contact fields are updated unconditionally; passing NULL clears the column. Only IsEmailVerified and EmailVerificationProviderID use ISNULL to preserve existing values.

**Columns/Parameters Involved**: All @param fields, CustomerStatic contact columns

**Rules**:
- CountryID, CitizenshipCountryID, POBCountryID, Email, Address, City, Zip, Phone, PhonePrefix, PhoneBody, Mobile, Fax, StateID, BuildingNumber, RegionID, SubRegionID: SET directly (NULL clears the column)
- IsEmailVerified = ISNULL(@isEmailVerified, IsEmailVerified) - NULL preserves existing verification state
- EmailVerificationProviderID = ISNULL(@emailVerificationProviderId, EmailVerificationProviderID) - NULL preserves

### 2.2 Async Downstream Queue (ActionID=10)

**What**: After CustomerStatic UPDATE, serializes contact fields to XML and queues for downstream propagation.

**Rules**:
- XML built using FOR XML Path('Root') with attribute-value pairs for each parameter
- ActionID = 10 = "UpdateContactUserInfo" action type
- InsertedToQueue = GETUTCDATE(), CurrentTry=0, Status=0, RetVal=0 (new entry)
- CATCH raises error 50001 if queue INSERT fails (unlike UpdateBasicUserInfo which uses THROW)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Lookup key for CustomerStatic WHERE GCID=@gcid. |
| 2 | @countryId | int | YES | NULL | CODE-BACKED | Customer's country of residence. Maps to CustomerStatic.CountryID. SET directly (NULL clears). |
| 3 | @email | varchar(50) | YES | NULL | CODE-BACKED | Customer's email address. Maps to CustomerStatic.Email. SET directly (NULL clears). |
| 4 | @address | nvarchar(100) | YES | NULL | CODE-BACKED | Street address. Maps to CustomerStatic.Address. SET directly (NULL clears). |
| 5 | @city | nvarchar(50) | YES | NULL | CODE-BACKED | City of residence. Maps to CustomerStatic.City. SET directly (NULL clears). |
| 6 | @zip | nvarchar(50) | YES | NULL | CODE-BACKED | Postal/zip code. Maps to CustomerStatic.Zip. SET directly (NULL clears). |
| 7 | @phone | nvarchar(30) | YES | NULL | CODE-BACKED | Full phone number. Maps to CustomerStatic.Phone. SET directly (NULL clears). |
| 8 | @phonePrefix | nvarchar(6) | YES | NULL | CODE-BACKED | International phone prefix (e.g., +1, +44). Maps to CustomerStatic.PhonePrefix. SET directly (NULL clears). |
| 9 | @phoneBody | nvarchar(24) | YES | NULL | CODE-BACKED | Phone number body without prefix. Maps to CustomerStatic.PhoneBody. SET directly (NULL clears). |
| 10 | @mobile | nvarchar(30) | YES | NULL | CODE-BACKED | Mobile/cell number. Maps to CustomerStatic.Mobile. SET directly (NULL clears). |
| 11 | @fax | nvarchar(30) | YES | NULL | CODE-BACKED | Fax number (legacy field). Maps to CustomerStatic.Fax. SET directly (NULL clears). |
| 12 | @stateId | int | YES | NULL | CODE-BACKED | State/province identifier. Maps to CustomerStatic.StateID. SET directly (NULL clears). |
| 13 | @buildingNumber | nvarchar(30) | YES | NULL | CODE-BACKED | Building/apartment number. Maps to CustomerStatic.BuildingNumber. SET directly (NULL clears). |
| 14 | @RegionID | int | YES | NULL | CODE-BACKED | Geographic region identifier. Maps to CustomerStatic.RegionID. Added 2016-09-13. SET directly (NULL clears). |
| 15 | @CitizenshipCountryId | int | YES | NULL | CODE-BACKED | Country of citizenship (may differ from country of residence). Maps to CustomerStatic.CitizenshipCountryID. Added 2018-02-21. SET directly (NULL clears). |
| 16 | @POBCountryId | int | YES | NULL | CODE-BACKED | Place of birth country. Maps to CustomerStatic.POBCountryID. Added 2019-04-16. SET directly (NULL clears). |
| 17 | @SubRegionId | int | YES | NULL | CODE-BACKED | Sub-region identifier within a region. Maps to CustomerStatic.SubRegionID. Added 2019-07-09. SET directly (NULL clears). |
| 18 | @isEmailVerified | bit | YES | NULL | CODE-BACKED | Email verification state. Maps to CustomerStatic.IsEmailVerified. ISNULL: NULL preserves existing. |
| 19 | @emailVerificationProviderId | int | YES | NULL | CODE-BACKED | Which verification service confirmed the email. Maps to CustomerStatic.EmailVerificationProviderID. ISNULL: NULL preserves existing. |
| 20 | @RowCount | int | YES (OUTPUT) | NULL | CODE-BACKED | Output: @@RowCount from the CustomerStatic UPDATE. Non-zero means the customer was found and updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Modifier | Updates all contact/address fields via GCID lookup |
| All params | Internal.ActionsToExecute_Registration | Writer | Queues ActionID=10 for async downstream propagation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from customer profile/KYC services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateContactUserInfo (procedure)
├── Customer.CustomerStatic (table - UPDATE)
└── Internal.ActionsToExecute_Registration (table - queue INSERT, ActionID=10)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target for contact/address fields via GCID lookup |
| Internal.ActionsToExecute_Registration | Table | Queue INSERT (ActionID=10) for downstream propagation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Direct SET for most fields | Design | NULL passed for most fields clears the column (not preserved) |
| ISNULL for email verification | Design | IsEmailVerified and EmailVerificationProviderID preserved if NULL |
| RAISERROR 50001 on queue failure | Error handling | Queue INSERT failure raises 50001 with message; returns -1 |
| ActionID=10 | Protocol | Queue action type 10 = "UpdateContactUserInfo" |

---

## 8. Sample Queries

### 8.1 Update customer email and phone
```sql
DECLARE @Rows INT;
EXEC Customer.UpdateContactUserInfo
    @gcid = 67890,
    @email = 'new@example.com',
    @phone = '+12125551234',
    @RowCount = @Rows OUTPUT;
SELECT @Rows AS RowsUpdated;
```

### 8.2 Update address fields only
```sql
EXEC Customer.UpdateContactUserInfo
    @gcid = 67890,
    @address = N'123 Main St',
    @city = N'New York',
    @zip = '10001',
    @countryId = 230;
```

### 8.3 Check queued contact update actions
```sql
SELECT TOP 5 ActionID, Params, InsertedToQueue, Status
FROM Internal.ActionsToExecute_Registration WITH (NOLOCK)
WHERE ActionID = 10
ORDER BY InsertedToQueue DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateContactUserInfo | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateContactUserInfo.sql*
