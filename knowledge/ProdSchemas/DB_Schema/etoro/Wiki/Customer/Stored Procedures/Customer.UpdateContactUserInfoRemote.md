# Customer.UpdateContactUserInfoRemote

> Updates a customer's contact and address fields on CustomerStatic via GCID - the "Remote" variant that skips the action queue and email verification fields used by UpdateContactUserInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID lookup for CustomerStatic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateContactUserInfoRemote updates the same contact and address fields on Customer.CustomerStatic as Customer.UpdateContactUserInfo, but without: (1) the Internal.ActionsToExecute_Registration queue entry, and (2) IsEmailVerified / EmailVerificationProviderID fields. The "Remote" suffix indicates this is called by external management or back-office systems that do not need downstream action propagation.

Unlike UpdateContactUserInfo (which uses ISNULL for email verification), all fields here are SET directly - NULL clears the column. This is appropriate for remote systems that typically provide the full customer record.

History: RegionID added (Case 40722, 2016-09-13), CitizenshipCountryID (Case 50308, 2018-02-21), POBCountryID (RD-4436/5736, 2019-04-16), migrated to CustomerStatic (2019-06-17), SubRegionID (2019-07-09).

---

## 2. Business Logic

### 2.1 Direct Contact Update (No Queue, No Email Verification)

**Rules**:
- All contact fields SET directly from parameters (NULL clears)
- No IsEmailVerified or EmailVerificationProviderID fields (unlike UpdateContactUserInfo)
- No Internal.ActionsToExecute_Registration INSERT
- No BEGIN/END block, no TRY/CATCH - bare UPDATE statement

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. Lookup key for CustomerStatic WHERE GCID=@gcid. |
| 2 | @countryId | int | YES | NULL | CODE-BACKED | Country of residence. Maps to CustomerStatic.CountryID. SET directly (NULL clears). |
| 3 | @email | varchar(50) | YES | NULL | CODE-BACKED | Email address. Maps to CustomerStatic.Email. SET directly (NULL clears). |
| 4 | @address | nvarchar(100) | YES | NULL | CODE-BACKED | Street address. Maps to CustomerStatic.Address. SET directly (NULL clears). |
| 5 | @city | nvarchar(50) | YES | NULL | CODE-BACKED | City. Maps to CustomerStatic.City. SET directly (NULL clears). |
| 6 | @zip | nvarchar(50) | YES | NULL | CODE-BACKED | Postal code. Maps to CustomerStatic.Zip. SET directly (NULL clears). |
| 7 | @phone | nvarchar(30) | YES | NULL | CODE-BACKED | Full phone number. Maps to CustomerStatic.Phone. SET directly (NULL clears). |
| 8 | @phonePrefix | nvarchar(6) | YES | NULL | CODE-BACKED | International phone prefix. Maps to CustomerStatic.PhonePrefix. SET directly (NULL clears). |
| 9 | @phoneBody | nvarchar(24) | YES | NULL | CODE-BACKED | Phone body without prefix. Maps to CustomerStatic.PhoneBody. SET directly (NULL clears). |
| 10 | @mobile | nvarchar(30) | YES | NULL | CODE-BACKED | Mobile number. Maps to CustomerStatic.Mobile. SET directly (NULL clears). |
| 11 | @fax | nvarchar(30) | YES | NULL | CODE-BACKED | Fax number (legacy). Maps to CustomerStatic.Fax. SET directly (NULL clears). |
| 12 | @stateId | int | YES | NULL | CODE-BACKED | State/province. Maps to CustomerStatic.StateID. SET directly (NULL clears). |
| 13 | @buildingNumber | nvarchar(30) | YES | NULL | CODE-BACKED | Building/apartment number. Maps to CustomerStatic.BuildingNumber. SET directly (NULL clears). |
| 14 | @RegionID | int | YES | NULL | CODE-BACKED | Geographic region. Maps to CustomerStatic.RegionID. SET directly (NULL clears). |
| 15 | @CitizenshipCountryId | int | YES | NULL | CODE-BACKED | Country of citizenship. Maps to CustomerStatic.CitizenshipCountryID. SET directly (NULL clears). |
| 16 | @POBCountryId | int | YES | NULL | CODE-BACKED | Place of birth country. Maps to CustomerStatic.POBCountryID. SET directly (NULL clears). |
| 17 | @SubRegionId | int | YES | NULL | CODE-BACKED | Sub-region within a region. Maps to CustomerStatic.SubRegionID. SET directly (NULL clears). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Modifier | Updates contact/address fields via GCID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external system) | - | - | No intra-DB callers found; called from back-office/KYC remote systems |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateContactUserInfoRemote (procedure)
└── Customer.CustomerStatic (table - UPDATE)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target for contact/address fields via GCID lookup |

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
| No queue | Design | Does NOT write Internal.ActionsToExecute_Registration |
| Direct SET | Design | All fields are SET directly; NULL clears the column (no ISNULL preservation) |

---

## 8. Sample Queries

### 8.1 Update customer address from a remote system
```sql
EXEC Customer.UpdateContactUserInfoRemote
    @gcid = 67890,
    @address = N'456 Park Ave',
    @city = N'London',
    @countryId = 86;
```

### 8.2 Update phone fields
```sql
EXEC Customer.UpdateContactUserInfoRemote
    @gcid = 67890,
    @phonePrefix = N'+44',
    @phoneBody = N'7911123456',
    @phone = N'+447911123456';
```

### 8.3 Verify the contact update
```sql
SELECT GCID, CountryID, Email, Address, City, Phone, PhonePrefix, RegionID
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateContactUserInfoRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateContactUserInfoRemote.sql*
