# KYC.CountryTaxType

> Configuration table mapping countries to their accepted tax ID types with validation rules, mask patterns, and requirement levels.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | CountryID + TaxTypeID (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.CountryTaxType defines which tax identification types are accepted for each country, along with validation rules. Each country may accept multiple tax ID types (e.g., UK accepts UTR and NINO). Contains 250 country-tax type combinations. Used by the registration flow to determine what tax ID format to request and validate.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Configuration mapping table.

---

## 3. Data Overview

250 rows mapping countries to tax types.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Part of composite PK. Country identifier. Implicit FK to Dictionary.Country. |
| 2 | TaxTypeID | int | NO | - | CODE-BACKED | Part of composite PK. Tax ID subtype. Maps to Dictionary.ExtendedUserValueType.ValueTypeID (FieldTypeID=3). |
| 3 | TaxIdRequirmentTypeId | int | NO | 1 | CODE-BACKED | FK to Dictionary.TaxIdRequirmentType. Whether this tax type is Required(1), Not Required(2), or NoTaxRequired(3) for this country. Default: 1 (Required). See [Tax ID Requirement Type](_glossary.md#tax-id-requirement-type). |
| 4 | ValidationExpression | varchar(1000) | YES | - | CODE-BACKED | Regex pattern for validating the tax ID format. Country-specific (e.g., UK UTR: 10-digit numeric). |
| 5 | MaskExpression | varchar(100) | YES | - | CODE-BACKED | Input mask pattern for the UI tax ID field. Guides user input format. |
| 6 | MinLength | int | YES | - | CODE-BACKED | Minimum character length for the tax ID value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TaxIdRequirmentTypeId | Dictionary.TaxIdRequirmentType | Explicit FK | Requirement level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetCountryTaxTypes | CountryID | SP reads | Returns tax type config |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.CountryTaxType (table)
  +-- Dictionary.TaxIdRequirmentType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TaxIdRequirmentType | Table | FK: TaxIdRequirmentTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetCountryTaxTypes | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CountryTaxType | CLUSTERED PK | CountryID, TaxTypeID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_KYC_CountryTaxType_TaxIdRequirmentTypeId | DEFAULT | (1) - Required by default |
| FK_KYC_CountryTaxType_TaxIdRequirmentType | FOREIGN KEY | TaxIdRequirmentTypeId -> Dictionary.TaxIdRequirmentType |

---

## 8. Sample Queries

### 8.1 Tax types for a country
```sql
SELECT t.CountryID, vt.Name AS TaxType, tr.Name AS Requirement, t.ValidationExpression
FROM KYC.CountryTaxType t WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON t.TaxTypeID = vt.ValueTypeID
JOIN Dictionary.TaxIdRequirmentType tr WITH (NOLOCK) ON t.TaxIdRequirmentTypeId = tr.TaxIdRequirmentTypeId
WHERE t.CountryID = @CountryID
```

### 8.2 Countries requiring tax ID
```sql
SELECT DISTINCT c.Name FROM KYC.CountryTaxType t WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON t.CountryID = c.CountryID WHERE t.TaxIdRequirmentTypeId = 1
```

### 8.3 All tax types with validation
```sql
SELECT c.Name AS Country, vt.Name AS TaxType, t.ValidationExpression, t.MinLength
FROM KYC.CountryTaxType t WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON t.CountryID = c.CountryID
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON t.TaxTypeID = vt.ValueTypeID ORDER BY c.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.CountryTaxType | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.CountryTaxType.sql*
