# Customer.GetCustomersWithSameExtendedField

> Checks whether another customer already has the same extended field value (e.g., tax ID, national PIN) for the same field type, subtype, and country - used in compliance duplicate detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 matching GCID + CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersWithSameExtendedField is a compliance-oriented duplicate detection procedure. Given a customer's GCID and a specific extended field value (such as a tax ID, national PIN, or SSN), it searches for any OTHER customer who holds the same value for the same field type, subtype, and country context. If a match is found, it returns the first matching customer's GCID and CID.

This procedure exists to enforce uniqueness rules on regulated identity fields. When a user submits a tax ID or national PIN during KYC onboarding, the system calls this procedure to check whether that exact value is already registered to another verified user. This prevents regulatory violations where the same government-issued identifier is used across multiple accounts.

The procedure is called directly by the application during KYC field validation. It reads from Customer.ExtendedUserField (the field values store), joins to dbo.Real_Customer (to get CID from GCID), and dbo.Real_BackOfficeCustomer (to check verification level and player status). Only active accounts are considered - closed/blocked accounts (PlayerStatusID=4) are excluded from duplicate checks.

---

## 2. Business Logic

### 2.1 Duplicate Detection with Verification Threshold

**What**: The procedure only reports duplicates against customers at or above a given verification level, excluding inactive accounts.

**Columns/Parameters Involved**: `@VerificationLevelID`, `@FieldID`, `@TypeID`, `@Value`, `@CountryList`, `PlayerStatusID`

**Rules**:
- Only customers with `VerificationLevelID >= @VerificationLevelID` are considered matches - unverified users are not blocking duplicates
- Closed or blocked accounts (`PlayerStatusID IN (4)`) are excluded from the search, so deactivated accounts do not cause false-positive blocks
- The match is scoped to the same FieldId, TypeId, Value, and matching CountryId from the provided country list
- The calling customer (`@GCID`) is explicitly excluded from results (`e.GCID <> @GCID`)
- Returns TOP 1 - only needs to confirm at least one duplicate exists, not enumerate all

**Diagram**:
```
Caller provides: GCID, FieldID, TypeID, Value, VerificationLevelID, CountryList
  |
  v
Search Customer.ExtendedUserField
  WHERE FieldId = @FieldID
    AND TypeId = @TypeID
    AND Value = @Value
    AND CountryId IN @CountryList
    AND GCID <> @GCID (exclude self)
  |
  v
JOIN Real_Customer + Real_BackOfficeCustomer
  WHERE PlayerStatusID NOT IN (4)   -- exclude closed
    AND VerificationLevelID >= @VerificationLevelID
  |
  v
Return TOP 1 (GCID, CID) or empty set
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the user being checked. This user is excluded from duplicate search results (self-exclusion). |
| 2 | @VerificationLevelID | int | NO | - | CODE-BACKED | Minimum verification level threshold. Only customers with VerificationLevelID >= this value are considered matches. Filters out unverified or low-verification users. See [Verification Level](_glossary.md#verification-level). |
| 3 | @FieldID | int | NO | - | CODE-BACKED | The extended field type to check. Maps to Dictionary.ExtendedUserField: 0=province, 6=TaxId, 7=NationalPin, etc. See [Extended User Field](_glossary.md#extended-user-field). |
| 4 | @TypeID | int | NO | - | CODE-BACKED | Value subtype within the field. Maps to Dictionary.ExtendedUserValueType. Further classifies the field (e.g., which specific type of tax ID). |
| 5 | @Value | nvarchar(128) | NO | - | CODE-BACKED | The actual field value to search for duplicates of (e.g., the tax number string, national PIN number). |
| 6 | @CountryList | dbo.IdList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing a list of country IDs to scope the duplicate search. Only matches in these countries are returned. |
| 7 | GCID (output) | int | - | - | CODE-BACKED | Global Customer ID of the first matching duplicate customer found. |
| 8 | CID (output) | int | - | - | CODE-BACKED | Customer ID (real account) of the matching duplicate customer. From dbo.Real_Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FieldID | Customer.ExtendedUserField.FieldId | Lookup | Searches the extended field values store by FieldId |
| @GCID | dbo.Real_Customer.GCID | JOIN | Links customer's extended fields to their real account |
| CID | dbo.Real_BackOfficeCustomer.CID | JOIN | Checks verification level and player status on the back-office record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called by the KYC/compliance service during field validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomersWithSameExtendedField (procedure)
+-- Customer.ExtendedUserField (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - reads field values for matching |
| dbo.Real_Customer | Table | JOIN on GCID - resolves CID for the matching customer |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - checks PlayerStatusID and VerificationLevelID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check for duplicate tax ID in specific countries
```sql
DECLARE @Countries dbo.IdList
INSERT @Countries VALUES (106), (234) -- Italy, UK
EXEC Customer.GetCustomersWithSameExtendedField
    @GCID = 12345,
    @VerificationLevelID = 3,
    @FieldID = 6,   -- TaxId
    @TypeID = 1,
    @Value = N'RSSMRA80A01H501U',
    @CountryList = @Countries
```

### 8.2 Check for duplicate national PIN
```sql
DECLARE @Countries dbo.IdList
INSERT @Countries VALUES (13) -- Australia
EXEC Customer.GetCustomersWithSameExtendedField
    @GCID = 67890,
    @VerificationLevelID = 2,
    @FieldID = 7,   -- NationalPin
    @TypeID = 1,
    @Value = N'123456789',
    @CountryList = @Countries
```

### 8.3 Direct query equivalent (for analysis)
```sql
SELECT TOP 1 e.GCID, cc.CID
FROM Customer.ExtendedUserField e WITH (NOLOCK)
INNER JOIN dbo.Real_Customer cc WITH (NOLOCK) ON e.GCID = cc.GCID
INNER JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON bc.CID = cc.CID
WHERE e.GCID <> @GCID
    AND e.FieldId = @FieldID
    AND e.TypeId = @TypeID
    AND e.Value = @Value
    AND e.CountryId IN (SELECT Id FROM @CountryList)
    AND bc.PlayerStatusID NOT IN (4)
    AND bc.VerificationLevelID >= @VerificationLevelID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| EDM Compliance Planning | Confluence | Tangential reference to extended field duplicate detection in compliance context |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersWithSameExtendedField | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomersWithSameExtendedField.sql*
