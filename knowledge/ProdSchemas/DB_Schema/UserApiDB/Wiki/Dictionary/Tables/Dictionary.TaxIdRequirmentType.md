# Dictionary.TaxIdRequirmentType

> Lookup table defining whether a tax ID is required, not required, or exempt for a given regulation/country.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TaxIdRequirmentTypeId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.TaxIdRequirmentType controls whether a Tax Identification Number must be collected during KYC for a given regulatory jurisdiction. Different countries have different tax reporting requirements, and some jurisdictions do not issue or require tax IDs at all. This three-level classification drives the registration flow's tax ID field behavior.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

| TaxIdRequirmentTypeId | Name | Meaning |
|---|---|---|
| 1 | Required | Tax ID must be provided - registration cannot complete without it |
| 2 | Not Required | Tax ID field is shown but not mandatory - user can proceed without it |
| 3 | NoTaxRequired | Jurisdiction has no tax ID system or user is exempt - field is hidden |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaxIdRequirmentTypeId | int | NO | - | CODE-BACKED | Primary key. Tax requirement: 1=Required, 2=Not Required, 3=NoTaxRequired. See [Tax ID Requirement Type](_glossary.md#tax-id-requirement-type). |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Requirement level label. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC regulation config tables | TaxIdRequirmentTypeId | Lookup | Defines tax ID requirement per regulation/country |

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
| PK_Dictionary_TaxIdRequirmentType | CLUSTERED PK | TaxIdRequirmentTypeId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all tax requirement types
```sql
SELECT TaxIdRequirmentTypeId, Name FROM Dictionary.TaxIdRequirmentType WITH (NOLOCK) ORDER BY TaxIdRequirmentTypeId
```

### 8.2 Regulations requiring tax ID
```sql
SELECT r.Name AS Regulation, t.Name AS TaxRequirement
FROM Customer.KycTaxConfig c WITH (NOLOCK)
JOIN Dictionary.Regulation r WITH (NOLOCK) ON c.RegulationID = r.ID
JOIN Dictionary.TaxIdRequirmentType t WITH (NOLOCK) ON c.TaxIdRequirmentTypeId = t.TaxIdRequirmentTypeId
ORDER BY r.Name
```

### 8.3 Count countries by tax requirement
```sql
SELECT t.Name, COUNT(DISTINCT c.CountryID) AS CountryCount
FROM Customer.KycTaxConfig c WITH (NOLOCK)
JOIN Dictionary.TaxIdRequirmentType t WITH (NOLOCK) ON c.TaxIdRequirmentTypeId = t.TaxIdRequirmentTypeId
GROUP BY t.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.TaxIdRequirmentType | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.TaxIdRequirmentType.sql*
