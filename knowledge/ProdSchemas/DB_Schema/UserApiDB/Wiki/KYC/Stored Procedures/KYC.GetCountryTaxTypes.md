# KYC.GetCountryTaxTypes

> Returns all country tax type configurations joined with value type names from Dictionary, filtered to Tax ID field types only.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetCountryTaxTypes returns the full tax type configuration by joining KYC.CountryTaxType with Dictionary.ExtendedUserValueType (filtered to FieldTypeID=3, Tax ID types only). Returns country, tax type name, requirement level, validation regex, mask, and min length. Used by the registration flow to configure tax ID collection.

---

## 2. Business Logic

No complex business logic. SELECT with JOIN, filtered to Tax ID types.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: CountryId, TaxTypeId (name from ExtendedUserValueType), TaxIdRequirmentTypeId, ValidationExpression, MaskExpression, MinLength.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CountryTaxType | SELECT FROM | Tax type configurations |
| - | Dictionary.ExtendedUserValueType | JOIN | Tax type names (FieldTypeID=3) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetCountryTaxTypes (procedure)
  +-- KYC.CountryTaxType (table) [done]
  +-- Dictionary.ExtendedUserValueType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CountryTaxType | Table | SELECT FROM |
| Dictionary.ExtendedUserValueType | Table | JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all tax types
```sql
EXEC KYC.GetCountryTaxTypes
```

### 8.2 Direct equivalent
```sql
SELECT t.CountryID, d.Name AS TaxTypeId, t.TaxIdRequirmentTypeId, t.ValidationExpression, t.MaskExpression, t.MinLength
FROM KYC.CountryTaxType t WITH (NOLOCK) JOIN Dictionary.ExtendedUserValueType d WITH (NOLOCK) ON t.TaxTypeID = d.ValueTypeID AND d.FieldTypeID = 3
```

### 8.3 Filter for a country
```sql
-- SP returns all; filter client-side or use direct query
SELECT t.CountryID, d.Name FROM KYC.CountryTaxType t WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType d WITH (NOLOCK) ON t.TaxTypeID = d.ValueTypeID AND d.FieldTypeID = 3
WHERE t.CountryID = 44
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetCountryTaxTypes | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetCountryTaxTypes.sql*
