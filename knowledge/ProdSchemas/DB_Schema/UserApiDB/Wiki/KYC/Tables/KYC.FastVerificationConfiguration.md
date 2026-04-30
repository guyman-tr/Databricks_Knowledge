# KYC.FastVerificationConfiguration

> Configuration table defining fast electronic verification data collection rules per country, document type, province, and data field.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | CountryId + ExtendedUserValueTypeId + ProvinceId + DataFieldId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.FastVerificationConfiguration stores the validation and formatting rules for fast electronic verification data fields. Each row defines the validation regex, input mask, minimum length, and active status for a specific combination of country, document type (ExtendedUserValueType), province, and data field. Contains 18 configuration rows. Used by the fast verification flow to determine what data to collect and how to validate it.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Configuration lookup by composite key.

---

## 3. Data Overview

18 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryId | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.Country. Country this configuration applies to. |
| 2 | ExtendedUserValueTypeId | int | NO | - | CODE-BACKED | Part of composite PK. Document type from Dictionary.ExtendedUserValueType (e.g., Medicare, DrivingLicense). |
| 3 | ProvinceId | int | NO | 0 | CODE-BACKED | Part of composite PK. Province/state within the country. Default: 0 (all provinces). |
| 4 | ValidationExpression | nvarchar(max) | YES | - | CODE-BACKED | Regex pattern for validating the data field input. |
| 5 | MaskExpression | nvarchar(max) | YES | - | CODE-BACKED | Input mask pattern for the UI field. |
| 6 | MinLength | int | YES | - | CODE-BACKED | Minimum character length for the field. |
| 7 | IsActive | bit | NO | - | CODE-BACKED | Whether this configuration is currently active. GetFastVerificationConfigurations filters to IsActive=1. |
| 8 | DataFieldId | int | NO | 0 | CODE-BACKED | Part of composite PK. Identifies which specific data field within the document type. Default: 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryId | Dictionary.Country | Explicit FK | Country this config applies to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetFastVerificationConfigurations | - | SP reads | Returns active configurations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.FastVerificationConfiguration (table)
  +-- Dictionary.Country (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK: CountryId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetFastVerificationConfigurations | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_FastVerificationConfiguration | CLUSTERED PK | CountryId, ExtendedUserValueTypeId, ProvinceId, DataFieldId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_FastVerificationConfiguration_ProvinceId | DEFAULT | (0) - all provinces |
| DF_FastVerificationConfiguration_DataFieldId | DEFAULT | (0) |
| FK_KYC_FastVerificationConfiguration_CountryId | FOREIGN KEY | CountryId -> Dictionary.Country |

---

## 8. Sample Queries

### 8.1 Active configurations
```sql
SELECT CountryId, ExtendedUserValueTypeId, ProvinceId, MinLength FROM KYC.FastVerificationConfiguration WITH (NOLOCK) WHERE IsActive = 1
```

### 8.2 Configs for a country
```sql
SELECT * FROM KYC.FastVerificationConfiguration WITH (NOLOCK) WHERE CountryId = @CountryId AND IsActive = 1
```

### 8.3 With country and type names
```sql
SELECT c.Name AS Country, vt.Name AS DocType, f.ProvinceId, f.MinLength, f.IsActive
FROM KYC.FastVerificationConfiguration f WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON f.CountryId = c.CountryID
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON f.ExtendedUserValueTypeId = vt.ValueTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.FastVerificationConfiguration | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.FastVerificationConfiguration.sql*
