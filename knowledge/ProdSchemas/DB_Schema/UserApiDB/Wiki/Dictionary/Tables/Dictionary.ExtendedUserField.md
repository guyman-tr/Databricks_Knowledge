# Dictionary.ExtendedUserField

> Lookup table defining regulation-specific and country-specific user profile fields beyond core registration data, such as tax IDs, national PINs, and employer names.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FieldId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.ExtendedUserField defines the specific additional data fields that may be collected from users beyond the core registration fields. Each field belongs to a field type category (Dictionary.ExtendedUserFieldType) and represents a concrete data point like "province", "SecondSurname", "TaxId", or "NationalPin".

These fields are dynamically configured per regulation and country. For example, Italian users need CodeFiscale (field 2), Spanish users need SecondSurname (field 1), and users in tax-reporting jurisdictions need TaxId (field 6). The MandatoryType configuration controls whether each field is Required, Optional, or Exempt.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| FieldId | FieldTypeId | Name | Meaning |
|---|---|---|---|
| 0 | 0 (Address) | province | User's province/state within their address (supplementary to main address) |
| 1 | 1 (Name) | SecondSurname | Second surname for Spanish/Portuguese naming conventions |
| 2 | 2 (NationalId) | CodeFiscale | Italian fiscal code (Codice Fiscale) - 16-character alphanumeric |
| 6 | 3 (Tax ID) | TaxId | Generic tax identification number - format varies by country |
| 7 | 4 (NationalPin) | NationalPin | National personal identification number for regulatory reporting |

*5 of 12 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FieldId | int | NO | - | CODE-BACKED | Primary key. Extended field identifier (0-11). See [Extended User Field](_glossary.md#extended-user-field). |
| 2 | FieldTypeId | int | NO | - | CODE-BACKED | FK to Dictionary.ExtendedUserFieldType. Groups field by category: 0=Address, 1=Name, 2=NationalId, 3=Tax ID, 4=NationalPin, 5=Employer, 6-9=specialized. |
| 3 | Name | varchar(30) | NO | - | CODE-BACKED | Internal field name used in KYC configuration and API payloads. |
| 4 | ExtendedUserFieldShortName | nvarchar(50) | YES | - | CODE-BACKED | Shortened field name for compact display and API responses. Typically matches Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FieldTypeId | Dictionary.ExtendedUserFieldType | Explicit FK | Each field belongs to one field type category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC field config tables | FieldId | Lookup | Maps regulation/country to required fields |
| Customer extended field value tables | FieldId | Lookup | Stores user-provided values for each field |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ExtendedUserField (table)
  +-- Dictionary.ExtendedUserFieldType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserFieldType | Table | FK: FieldTypeId -> UserFieldTypeId |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryExtendedUserField | CLUSTERED PK | FieldId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DictionaryExtendedUserField | FOREIGN KEY | FieldTypeId -> Dictionary.ExtendedUserFieldType(UserFieldTypeId) |

---

## 8. Sample Queries

### 8.1 List fields with types
```sql
SELECT f.FieldId, f.Name, ft.Name AS FieldType FROM Dictionary.ExtendedUserField f WITH (NOLOCK)
JOIN Dictionary.ExtendedUserFieldType ft WITH (NOLOCK) ON f.FieldTypeId = ft.UserFieldTypeId ORDER BY f.FieldId
```

### 8.2 Find mandatory fields for a regulation
```sql
SELECT f.Name, ft.Name AS FieldType, mt.Name AS Requirement
FROM Customer.KycFieldConfig c WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField f WITH (NOLOCK) ON c.FieldId = f.FieldId
JOIN Dictionary.ExtendedUserFieldType ft WITH (NOLOCK) ON f.FieldTypeId = ft.UserFieldTypeId
JOIN Dictionary.MandatoryType mt WITH (NOLOCK) ON c.MandatoryTypeID = mt.MandatoryTypeID
WHERE c.RegulationID = 1 AND mt.MandatoryTypeID = 2
```

### 8.3 Check user's extended field values
```sql
SELECT f.Name, efv.Value FROM Customer.ExtendedFieldValues efv WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField f WITH (NOLOCK) ON efv.FieldId = f.FieldId WHERE efv.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.ExtendedUserField | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.ExtendedUserField.sql*
