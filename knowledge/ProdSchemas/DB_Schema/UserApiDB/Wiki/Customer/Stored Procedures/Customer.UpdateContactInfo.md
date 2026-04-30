# Customer.UpdateContactInfo

> Updates contact/address fields in Customer.ContactUserInfo (new-style) with SubRegion validation, session context, and cache invalidation signal.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.ContactUserInfo with validation + session context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateContactInfo updates contact and address data in the normalized Customer.ContactUserInfo table. It includes SubRegion validation (checks Dictionary.SubRegion consistency), sets session context for audit trail, and returns SELECT 1 for cache invalidation. This is the new-style version; UpdateContactUserInfo is the legacy equivalent.

The "DO NOT REMOVE THIS SELECT" comment highlights that the return value is critical for UAPI cache invalidation.

---

## 2. Business Logic

### 2.1 SubRegion Validation

**What**: Validates that SubRegionID is consistent with CountryID and RegionID.

**Rules**:
- If @SubRegionId IS NOT NULL: checks Dictionary.SubRegion for matching CountryID + RegionID + SubRegionID
- If not found: RAISERROR - prevents inconsistent geographic data
- If @SubRegionId IS NULL: no validation (sub-region not being changed)

### 2.2 Session Context + Cache Signal

**Rules**:
- Sets correlationId/clientRequestId/requestTime
- Updates all contact fields directly (NOT using ISNULL pattern - all values are overwritten)
- IsEmailVerified and EmailVerificationProviderID use ISNULL (only overwritten if provided)
- Returns SELECT 1 if @@RowCount > 0 (DO NOT REMOVE - UAPI cache depends on it)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @countryId | int | YES | NULL | CODE-BACKED | Country. |
| 3 | @email | varchar(50) | YES | NULL | CODE-BACKED | Email. |
| 4 | @address | nvarchar(100) | YES | NULL | CODE-BACKED | Street address. |
| 5 | @city | nvarchar(50) | YES | NULL | CODE-BACKED | City. |
| 6 | @zip | nvarchar(50) | YES | NULL | CODE-BACKED | Postal code. |
| 7 | @phone | nvarchar(30) | YES | NULL | CODE-BACKED | Phone. |
| 8 | @phonePrefix | nvarchar(6) | YES | NULL | CODE-BACKED | Phone prefix. |
| 9 | @phoneBody | nvarchar(24) | YES | NULL | CODE-BACKED | Phone body. |
| 10 | @mobile | nvarchar(30) | YES | NULL | CODE-BACKED | Mobile. |
| 11 | @fax | nvarchar(30) | YES | NULL | CODE-BACKED | Fax. |
| 12 | @stateId | int | YES | NULL | CODE-BACKED | State. |
| 13 | @buildingNumber | nvarchar(50) | YES | NULL | CODE-BACKED | Building number. |
| 14 | @RegionID | int | YES | NULL | CODE-BACKED | Region. |
| 15 | @CitizenshipCountryId | int | YES | NULL | CODE-BACKED | Citizenship country. |
| 16 | @POBCountryId | int | YES | NULL | CODE-BACKED | Place of birth country. |
| 17 | @SubRegionId | int | YES | NULL | CODE-BACKED | Sub-region (validated against Dictionary.SubRegion). |
| 18 | @ChangeEmailSts | bit | YES | 0 | CODE-BACKED | Not used in new-style (legacy compatibility param). |
| 19 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 20 | @clientRequestId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 21 | @requestTime | datetime | YES | NULL | CODE-BACKED | Audit trail. |
| 22 | @isEmailVerified | bit | YES | NULL | CODE-BACKED | Email verification flag (ISNULL - only if provided). |
| 23 | @emailVerificationProviderId | int | YES | NULL | CODE-BACKED | Verification provider (ISNULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.ContactUserInfo | UPDATE | Contact data |
| @SubRegionId | Dictionary.SubRegion | Validation | Geographic consistency check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Contact updates (new path) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateContactInfo (procedure)
+-- Customer.ContactUserInfo (table)
+-- Dictionary.SubRegion (table) [validation only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | UPDATE |
| Dictionary.SubRegion | Table | Validation check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR | Validation | SubRegionID must be consistent with CountryID + RegionID |
| TRY/CATCH | Error handling | Returns -1 on failure |

---

## 8. Sample Queries

### 8.1 Update contact info
```sql
EXEC Customer.UpdateContactInfo @gcid=12345, @countryId=234, @email='new@example.com',
    @correlationId='abc', @clientRequestId='req', @requestTime=GETUTCDATE()
```

### 8.2 Compare with legacy
```sql
-- UpdateContactInfo: Customer.ContactUserInfo (new, with validation)
-- UpdateContactUserInfo: dbo.Real_UpdateContactUserInfoRemote (legacy, with async queue)
```

### 8.3 Verify update
```sql
SELECT * FROM Customer.ContactUserInfo WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateContactInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateContactInfo.sql*
