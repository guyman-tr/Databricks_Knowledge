# Customer.ExtendedUserField

> Stores user-provided values for regulation-specific extended profile fields (tax IDs, national PINs, employer names, etc.) per user, field, and country.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK NONCLUSTERED) / GCID+FieldId+CountryId (unique CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 (NC PK + unique clustered + 2 NC) |

---

## 1. Business Meaning

Customer.ExtendedUserField stores the actual values users provide for regulation-specific data fields. Each row represents one field value for one user in one country context. For example, a user's Italian fiscal code (FieldId=2, CountryId=Italy) or their UK tax ID (FieldId=6, CountryId=UK). The unique clustered index on (GCID, FieldId, CountryId) ensures one value per user per field per country.

This table is the data store behind the dynamic KYC data collection system. The fields that appear are configured per regulation (using Dictionary.MandatoryType), and the values users enter are stored here. It is heavily queried during KYC verification, regulatory reporting, and aggregated user info retrieval.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Key-value store with composite key (user + field + country).

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Part of unique clustered key. Global Customer ID. |
| 2 | FieldId | int | NO | - | CODE-BACKED | Part of unique clustered key. FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. See [Extended User Field](_glossary.md#extended-user-field). |
| 3 | Value | nvarchar(128) | YES | - | CODE-BACKED | The user-provided value for this field (e.g., the actual tax number, national PIN). |
| 4 | LastModified | datetime | NO | - | CODE-BACKED | When this field value was last updated. |
| 5 | TypeId | int | YES | - | CODE-BACKED | Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). |
| 6 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Surrogate PK (NONCLUSTERED). Auto-incrementing. Used for row identification. |
| 7 | CountryId | int | YES | - | CODE-BACKED | Part of unique clustered key. Country context for this field value. Allows per-country field values. |
| 8 | AdditionalDetails | varchar(max) | YES | - | CODE-BACKED | JSON or freeform additional data (e.g., document details, validation metadata). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FieldId | Dictionary.ExtendedUserField | Explicit FK | Which extended field this value is for |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.GetExtendedUserField | GCID | SP reads | Returns field values |
| Customer.UpdateExtendedUserField | GCID | SP writes | Updates field values |
| Customer.GetCustomersWithSameExtendedField | FieldId, Value | SP reads | Finds duplicate field values |
| Customer.GetCustomersWithSameSSN | FieldId, Value | SP reads | Finds duplicate SSN values |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ExtendedUserField (table)
  +-- Dictionary.ExtendedUserField (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserField | Table | FK: FieldId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.GetExtendedUserField | Stored Procedure | Reads from |
| Customer.UpdateExtendedUserField | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer_ExtendedUserField | NC PK | ID | - | - | Active (PAGE compressed) |
| Idx_Customer_ExtendedUserField | CLUSTERED UNIQUE | GCID, FieldId, CountryId | - | - | Active (PAGE compressed) |
| IDX_ExtendedUserField_FieldIdTypeIdGCID | NONCLUSTERED | FieldId, TypeId, GCID | Value, CountryId | - | Active (PAGE compressed) |
| IDX_ExtendedUserField_FieldIdValue | NONCLUSTERED | FieldId, Value | GCID | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CustomerExtendedUserField | FOREIGN KEY | FieldId -> Dictionary.ExtendedUserField(FieldId) |

---

## 8. Sample Queries

### 8.1 Get all extended fields for a user
```sql
SELECT ef.FieldId, df.Name AS FieldName, ef.Value, ef.CountryId, ef.LastModified
FROM Customer.ExtendedUserField ef WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField df WITH (NOLOCK) ON ef.FieldId = df.FieldId
WHERE ef.GCID = @GCID
```

### 8.2 Find users with a specific tax ID value
```sql
SELECT GCID FROM Customer.ExtendedUserField WITH (NOLOCK) WHERE FieldId = 6 AND Value = @TaxId
```

### 8.3 Get tax ID with subtype name
```sql
SELECT ef.GCID, ef.Value, vt.Name AS ValueSubtype
FROM Customer.ExtendedUserField ef WITH (NOLOCK)
LEFT JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON ef.TypeId = vt.ValueTypeID
WHERE ef.FieldId = 6 AND ef.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.ExtendedUserField | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.ExtendedUserField.sql*
