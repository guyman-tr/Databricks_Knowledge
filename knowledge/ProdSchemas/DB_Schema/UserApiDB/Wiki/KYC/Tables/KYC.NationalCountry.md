# KYC.NationalCountry

> Configuration table defining national PIN (personal identification number) requirements per country, including mandatory type, validation rules, and fast verification availability.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | CountryID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.NationalCountry defines per-country configuration for national personal identification numbers used in regulatory transaction reporting. For each of the 251 countries, it specifies whether a national PIN is mandatory, optional, or exempt, and provides validation and masking rules. The HasFastVerification flag indicates whether the country supports fast electronic verification of the PIN.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Per-country configuration lookup.

---

## 3. Data Overview

251 rows (one per country).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Primary key. Country identifier. Implicit FK to Dictionary.Country. One config per country. |
| 2 | MandatoryTypeID | int | NO | - | CODE-BACKED | FK to Dictionary.MandatoryType. Whether national PIN is: 0=Exempt, 1=Optional, 2=Mandatory. See [Mandatory Type](_glossary.md#mandatory-type). |
| 3 | ValidationExpression | varchar(1000) | YES | - | CODE-BACKED | Regex for validating the national PIN format. Country-specific. |
| 4 | MaskExpression | varchar(50) | YES | - | CODE-BACKED | Input mask pattern for the UI. |
| 5 | ValidationExpressionMessage | varchar(100) | YES | - | CODE-BACKED | Error message shown when validation fails. |
| 6 | HasFastVerification | bit | NO | 0 | CODE-BACKED | Whether this country supports fast electronic verification of the national PIN. Default: 0 (no). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MandatoryTypeID | Dictionary.MandatoryType | Explicit FK | PIN requirement level |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.NationalCountryTypes | CountryID | Explicit FK | PIN subtypes per country |
| KYC.NationalPinCountry | CountryID | View FROM | View reads from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.NationalCountry (table)
  +-- Dictionary.MandatoryType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MandatoryType | Table | FK: MandatoryTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalCountryTypes | Table | FK: CountryID |
| KYC.NationalPinCountry | View | FROM clause |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_NationalCountry | CLUSTERED PK | CountryID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_NationalCountry_HasFastVerification | DEFAULT | (0) - no fast verification |
| FK_KYC_NationalCountry_MandatoryTypeID | FOREIGN KEY | MandatoryTypeID -> Dictionary.MandatoryType |

---

## 8. Sample Queries

### 8.1 Countries requiring national PIN
```sql
SELECT nc.CountryID, c.Name, mt.Name AS Requirement FROM KYC.NationalCountry nc WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON nc.CountryID = c.CountryID
JOIN Dictionary.MandatoryType mt WITH (NOLOCK) ON nc.MandatoryTypeID = mt.MandatoryTypeID
WHERE nc.MandatoryTypeID = 2 ORDER BY c.Name
```

### 8.2 Countries with fast verification
```sql
SELECT c.Name FROM KYC.NationalCountry nc WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON nc.CountryID = c.CountryID WHERE nc.HasFastVerification = 1
```

### 8.3 Validation rules for a country
```sql
SELECT * FROM KYC.NationalCountry WITH (NOLOCK) WHERE CountryID = @CountryID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.NationalCountry | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.NationalCountry.sql*
