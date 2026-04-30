# Dictionary.MandatoryType

> Lookup table defining whether a KYC field or document is required, optional, or exempt for a given regulatory configuration.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MandatoryTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.MandatoryType controls the requirement level of KYC data fields and documents per regulatory jurisdiction. When configuring what information each regulation demands from users, each field is classified as Exempt (not applicable), Optional, or Mandatory. This drives the registration and verification forms dynamically.

This table is essential for multi-regulatory compliance. Different regulations require different data: CySEC may mandate a Tax ID while ASIC does not; FCA may require employer information while FSA Seychelles does not. Without this three-state classification, the platform would need hardcoded logic for each regulation.

Mandatory type is stored in KYC configuration tables that map: (RegulationID, ExtendedUserFieldID) -> MandatoryTypeID. The registration flow reads this configuration to determine which fields to show and which are required for form submission.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| MandatoryTypeID | Name | Meaning |
|---|---|---|
| 0 | Exempt | Field is not applicable for this regulation/country combination - not shown in UI |
| 1 | Optional | Field is shown to the user but can be left blank - nice to have but not blocking |
| 2 | Mandatory | Field must be provided - registration or verification cannot proceed without it |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MandatoryTypeID | int | NO | - | CODE-BACKED | Primary key. Requirement level: 0=Exempt (hidden), 1=Optional (shown, not required), 2=Mandatory (required for completion). See [Mandatory Type](_glossary.md#mandatory-type). |
| 2 | Name | varchar(20) | NO | - | CODE-BACKED | Requirement level label used in admin configuration tools. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC field configuration tables | MandatoryTypeID | Lookup | Defines requirement level per regulation-field combination |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MandatoryType | CLUSTERED PK | MandatoryTypeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all mandatory types
```sql
SELECT MandatoryTypeID, Name
FROM Dictionary.MandatoryType WITH (NOLOCK)
ORDER BY MandatoryTypeID
```

### 8.2 Find mandatory fields for a regulation
```sql
SELECT f.Name AS FieldName, mt.Name AS Requirement
FROM Customer.KycFieldConfig c WITH (NOLOCK)
JOIN Dictionary.ExtendedUserField f WITH (NOLOCK) ON c.FieldId = f.FieldId
JOIN Dictionary.MandatoryType mt WITH (NOLOCK) ON c.MandatoryTypeID = mt.MandatoryTypeID
WHERE c.RegulationID = 1 AND mt.MandatoryTypeID = 2 -- CySEC mandatory fields
```

### 8.3 Regulation comparison
```sql
SELECT r.Name AS Regulation, f.Name AS Field, mt.Name AS Requirement
FROM Customer.KycFieldConfig c WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON c.RegulationID = r.ID
JOIN Dictionary.ExtendedUserField f WITH (NOLOCK) ON c.FieldId = f.FieldId
JOIN Dictionary.MandatoryType mt WITH (NOLOCK) ON c.MandatoryTypeID = mt.MandatoryTypeID
ORDER BY r.Name, mt.MandatoryTypeID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MandatoryType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.MandatoryType.sql*
