# KYC.GetFastVerificationConfigurations

> Returns all active fast verification data collection configurations.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetFastVerificationConfigurations returns all active fast verification configuration rows (IsActive=1). Used by the fast verification service to load data collection rules at startup. Returns CountryId, ExtendedUserValueTypeId, ProvinceId, ValidationExpression, MaskExpression, MinLength, DataFieldId.

---

## 2. Business Logic

No complex business logic. SELECT with IsActive=1 filter.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: CountryId, ExtendedUserValueTypeId, ProvinceId, ValidationExpression, MaskExpression, MinLength, DataFieldId.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.FastVerificationConfiguration | SELECT FROM | Active configurations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetFastVerificationConfigurations (procedure)
  +-- KYC.FastVerificationConfiguration (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.FastVerificationConfiguration | Table | SELECT FROM |

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

### 8.1 Get active configs
```sql
EXEC KYC.GetFastVerificationConfigurations
```

### 8.2 Direct query
```sql
SELECT CountryId, ExtendedUserValueTypeId, ProvinceId, ValidationExpression, MaskExpression, MinLength, DataFieldId
FROM KYC.FastVerificationConfiguration WITH (NOLOCK) WHERE IsActive = 1
```

### 8.3 With country names
```sql
SELECT c.Name, f.ExtendedUserValueTypeId, f.ProvinceId FROM KYC.FastVerificationConfiguration f WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON f.CountryId = c.CountryID WHERE f.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetFastVerificationConfigurations | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetFastVerificationConfigurations.sql*
