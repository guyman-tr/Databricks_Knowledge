# Customer.GetCustomersWithSameSSN

> Returns the count of other customers who have the same SSN/extended field value for the same field type, subtype, and country - used for compliance duplicate SSN detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns COUNT(1) of matching customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersWithSameSSN is a compliance procedure that counts how many other customers have the same SSN (Social Security Number) or equivalent extended field value. Unlike GetCustomersWithSameExtendedField (which returns the first matching customer's identity), this procedure returns only a count - indicating whether duplicates exist and how many.

This procedure was created in May 2019 per a Compliance team request to enforce SSN uniqueness rules. In September 2021 (COAKV-2683), it was updated to exclude closed accounts from the duplicate check, so that a user who previously closed their account does not block a new user from registering with the same SSN.

The procedure reads from Customer.ExtendedUserField (the field values store) with a subquery into dbo.Real_BackOfficeCustomer and dbo.Real_Customer to filter by verification level and exclude closed accounts (PlayerStatusID not in 4). It is called directly by the application during KYC validation flows.

---

## 2. Business Logic

### 2.1 SSN Duplicate Count with Closed Account Exclusion

**What**: Counts duplicate SSN/extended field entries while excluding deactivated accounts, so closed accounts do not block new registrations.

**Columns/Parameters Involved**: `@GCID`, `@VerificationLevelID`, `@FieldID`, `@TypeID`, `@Value`, `@CountryList`, `PlayerStatusID`

**Rules**:
- Only counts customers with `VerificationLevelID >= @VerificationLevelID` - unverified users are not counted as duplicates
- Closed or blocked accounts (`PlayerStatusID IN (4)`) are excluded from the count (COAKV-2683 change)
- The calling customer (`@GCID`) is excluded from the count (`GCID <> @GCID`)
- Returns an integer count (0 = no duplicates, 1+ = duplicates exist)
- Match is scoped to same FieldId, TypeId, Value, and matching CountryId

**Diagram**:
```
Caller provides: GCID, FieldID, TypeID, Value, VerificationLevelID, CountryList
  |
  v
COUNT from Customer.ExtendedUserField
  WHERE FieldId = @FieldID
    AND TypeId = @TypeID
    AND Value = @Value
    AND CountryId IN @CountryList
    AND GCID <> @GCID (exclude self)
    AND GCID IN (
      Real_BackOfficeCustomer JOIN Real_Customer
      WHERE PlayerStatusID NOT IN (4)
        AND VerificationLevelID >= @VerificationLevelID
    )
  |
  v
Return COUNT(1) -- 0 = unique, 1+ = duplicates
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID of the user being checked. This user is excluded from the duplicate count (self-exclusion). |
| 2 | @VerificationLevelID | int | NO | - | CODE-BACKED | Minimum verification level threshold. Only customers with VerificationLevelID >= this value are counted as duplicates. See [Verification Level](_glossary.md#verification-level). |
| 3 | @FieldID | int | NO | - | CODE-BACKED | The extended field type to check. Maps to Dictionary.ExtendedUserField: typically 6=TaxId or 7=NationalPin for SSN checks. See [Extended User Field](_glossary.md#extended-user-field). |
| 4 | @TypeID | int | NO | - | CODE-BACKED | Value subtype within the field. Maps to Dictionary.ExtendedUserValueType. Further classifies which specific type of SSN/tax ID. |
| 5 | @Value | nvarchar(128) | NO | - | CODE-BACKED | The actual SSN or field value to search for duplicates of. |
| 6 | @CountryList | dbo.IdList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing country IDs to scope the duplicate search. Only matches in these countries are counted. |
| 7 | (return) | int | - | - | CODE-BACKED | Count of other customers who hold the same value. 0 = no duplicates found, 1+ = duplicates exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FieldID | Customer.ExtendedUserField.FieldId | Lookup | Searches the extended field values store by FieldId |
| Subquery | dbo.Real_Customer | JOIN | Links GCID to CID for back-office lookup |
| Subquery | dbo.Real_BackOfficeCustomer | JOIN | Checks verification level and player status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called by KYC/compliance service during SSN validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomersWithSameSSN (procedure)
+-- Customer.ExtendedUserField (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - reads field values for counting |
| dbo.Real_Customer | Table | JOIN in subquery - resolves GCID to CID |
| dbo.Real_BackOfficeCustomer | Table | JOIN in subquery - checks PlayerStatusID and VerificationLevelID |

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

### 8.1 Check for duplicate SSN count
```sql
DECLARE @Countries dbo.IdList
INSERT @Countries VALUES (234) -- US
EXEC Customer.GetCustomersWithSameSSN
    @GCID = 12345,
    @VerificationLevelID = 3,
    @FieldID = 7,   -- NationalPin (SSN)
    @TypeID = 1,
    @Value = N'123-45-6789',
    @CountryList = @Countries
```

### 8.2 Check for duplicate tax ID count across multiple countries
```sql
DECLARE @Countries dbo.IdList
INSERT @Countries VALUES (106), (234), (80) -- Italy, US, Germany
EXEC Customer.GetCustomersWithSameSSN
    @GCID = 67890,
    @VerificationLevelID = 2,
    @FieldID = 6,   -- TaxId
    @TypeID = 1,
    @Value = N'RSSMRA80A01H501U',
    @CountryList = @Countries
```

### 8.3 Direct query equivalent (for analysis)
```sql
SELECT COUNT(1)
FROM Customer.ExtendedUserField WITH (NOLOCK)
WHERE GCID <> @GCID
    AND FieldId = @FieldID
    AND TypeId = @TypeID
    AND Value = @Value
    AND CountryId IN (SELECT Id FROM @CountryList)
    AND GCID IN (
        SELECT cc.GCID
        FROM dbo.Real_BackOfficeCustomer bc WITH (NOLOCK)
        INNER JOIN dbo.Real_Customer cc WITH (NOLOCK) ON bc.CID = cc.CID
        WHERE cc.PlayerStatusID NOT IN (4)
            AND bc.VerificationLevelID >= @VerificationLevelID
    )
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| HLD COAKV-3314 Cancel unique SSN feature if account was closed | Confluence | Business context for the closed-account exclusion logic (PlayerStatusID not in 4) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersWithSameSSN | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomersWithSameSSN.sql*
