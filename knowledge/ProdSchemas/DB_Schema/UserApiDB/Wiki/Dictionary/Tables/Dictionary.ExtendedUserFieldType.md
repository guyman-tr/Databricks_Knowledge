# Dictionary.ExtendedUserFieldType

> Lookup table categorizing extended user profile fields by their data nature and purpose (address, name, tax ID, national PIN, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | UserFieldTypeId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.ExtendedUserFieldType groups extended user profile fields into categories based on their data nature. The eToro platform collects different user data depending on the user's country and regulation - beyond core fields (name, email, DOB), additional fields may be required for compliance. These additional fields are "extended" fields, and this table defines their type categories.

This table is the parent of a hierarchy: ExtendedUserFieldType -> ExtendedUserField (specific fields within each type) -> ExtendedUserValueType (sub-classifications, primarily for Tax ID and NationalPin). It enables the platform to dynamically configure which fields are required per regulation without code changes.

Field types are used in KYC configuration to determine which data collection sections appear in the registration or verification flow. For example, ASIC-regulated users may need "Tax ID" type fields, while CySEC users may need "NationalPin" type fields.

---

## 2. Business Logic

### 2.1 Extended Field Type Hierarchy

**What**: Three-tier hierarchy for dynamic KYC field configuration.

**Columns/Parameters Involved**: `UserFieldTypeId`, `Name`

**Rules**:
- Each type groups multiple ExtendedUserField entries (via FK)
- Each ExtendedUserField may have multiple ExtendedUserValueType sub-classifications (via FK)
- Types 0-4 are the core KYC categories; 5-9 are specialized
- Dictionary.MandatoryType controls whether a specific field is Required/Optional/Exempt per regulation

**Diagram**:
```
ExtendedUserFieldType (this table)
  |-- Address (0): province, SubBuildingNumber
  |-- Name (1): SecondSurname
  |-- NationalId (2): CodeFiscale, SocialInsuranceNumber, NIF
  |-- Tax ID (3): TaxId -> 20+ country-specific subtypes
  |-- NationalPin (4): NationalPin -> 10+ reporting subtypes
  |-- Employer Name (5): EmployerName
  |-- DepositQuestion (6): DepositQuestion
  |-- WithdrawQuestion (7): WithdrawQuestion
  |-- Text (8): (generic text fields)
  |-- DedicatedEv (9): DedicatedEv
```

---

## 3. Data Overview

| UserFieldTypeId | Name | Meaning |
|---|---|---|
| 0 | Address | Address-related supplemental fields like province or sub-building number |
| 1 | Name | Name-related supplemental fields like second surname (for Spanish-speaking jurisdictions) |
| 2 | NationalId | National identification document numbers (Codice Fiscale, SIN, NIF) |
| 3 | Tax ID | Tax identification numbers - 20+ country-specific subtypes (CPR, UTR, TFN, CPF, PAN, etc.) |
| 4 | NationalPin | National personal identification numbers for regulatory transaction reporting |
| 5 | Employer Name | Employment information required for source-of-funds verification |

*5 of 10 rows shown - selected to represent core KYC categories.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserFieldTypeId | int | NO | - | CODE-BACKED | Primary key. Field category: 0=Address, 1=Name, 2=NationalId, 3=Tax ID, 4=NationalPin, 5=Employer Name, 6=DepositQuestion, 7=WithdrawQuestion, 8=Text, 9=DedicatedEv. Referenced by ExtendedUserField and ExtendedUserValueType. See [Extended User Field Type](_glossary.md#extended-user-field-type). |
| 2 | Name | varchar(30) | NO | - | CODE-BACKED | Category label used in KYC configuration UI and regulatory reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.ExtendedUserField | FieldTypeId | Explicit FK | Each extended field belongs to one field type category |
| Dictionary.ExtendedUserValueType | FieldTypeID | Explicit FK | Each value type subtype belongs to one field type category |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserField | Table | FK: FieldTypeId -> UserFieldTypeId |
| Dictionary.ExtendedUserValueType | Table | FK: FieldTypeID -> UserFieldTypeId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryExtendedUserFieldType | CLUSTERED PK | UserFieldTypeId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all field types
```sql
SELECT UserFieldTypeId, Name
FROM Dictionary.ExtendedUserFieldType WITH (NOLOCK)
ORDER BY UserFieldTypeId
```

### 8.2 Show field type hierarchy
```sql
SELECT ft.Name AS FieldType, f.Name AS FieldName, f.ExtendedUserFieldShortName
FROM Dictionary.ExtendedUserFieldType ft WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField f WITH (NOLOCK) ON ft.UserFieldTypeId = f.FieldTypeId
ORDER BY ft.UserFieldTypeId, f.FieldId
```

### 8.3 Count value subtypes per field type
```sql
SELECT ft.Name, COUNT(*) AS SubtypeCount
FROM Dictionary.ExtendedUserFieldType ft WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON ft.UserFieldTypeId = vt.FieldTypeID
GROUP BY ft.Name
ORDER BY SubtypeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ExtendedUserFieldType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.ExtendedUserFieldType.sql*
