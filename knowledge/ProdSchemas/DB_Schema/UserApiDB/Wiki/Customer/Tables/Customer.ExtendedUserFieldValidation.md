# Customer.ExtendedUserFieldValidation

> Tracks validation status of extended user fields per user, country, and field combination.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID + CountryID + FieldID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.ExtendedUserFieldValidation records whether specific extended user field values have been validated. For each user/country/field combination, it stores an IsValid flag indicating whether the value passed validation rules. This is used to track which KYC fields need re-validation after rule changes or to flag invalid entries for user correction.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Part of composite PK. Country context for validation. |
| 3 | FieldID | int | NO | - | CODE-BACKED | Part of composite PK. Extended field identifier. Maps to Dictionary.ExtendedUserField. |
| 4 | IsValid | bit | YES | - | CODE-BACKED | Whether the field value passed validation. NULL=not yet validated, 1=valid, 0=invalid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.UpsertExtendedUserFieldValidation | Composite key | SP writes | Creates/updates validation status |
| Customer.GetValidationExtendedUserFieldByCountriesId_GCID | Composite key | SP reads | Returns validation status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.UpsertExtendedUserFieldValidation | Stored Procedure | Writes to |
| Customer.GetValidationExtendedUserFieldByCountriesId_GCID | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExtendedUserFieldValidation | CLUSTERED PK | GCID, CountryID, FieldID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get validation status for a user
```sql
SELECT FieldID, CountryID, IsValid FROM Customer.ExtendedUserFieldValidation WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Find invalid fields
```sql
SELECT GCID, FieldID, CountryID FROM Customer.ExtendedUserFieldValidation WITH (NOLOCK) WHERE IsValid = 0
```

### 8.3 Validation status with field names
```sql
SELECT v.GCID, df.Name AS FieldName, v.CountryID, v.IsValid
FROM Customer.ExtendedUserFieldValidation v WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField df WITH (NOLOCK) ON v.FieldID = df.FieldId
WHERE v.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ExtendedUserFieldValidation | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ExtendedUserFieldValidation.sql*
