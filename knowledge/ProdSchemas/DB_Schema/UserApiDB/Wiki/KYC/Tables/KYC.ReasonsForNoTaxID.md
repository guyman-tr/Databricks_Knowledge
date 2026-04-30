# KYC.ReasonsForNoTaxID

> Lookup table defining valid reasons why a user cannot provide a Tax Identification Number, with optional free-text validation.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.ReasonsForNoTaxID defines the accepted reasons a user can provide when they cannot supply a TIN (Tax Identification Number) during KYC. CRS (Common Reporting Standard) regulations require platforms to collect TINs, but recognize valid reasons for non-provision. Contains 5 standardized reasons aligned with CRS guidelines.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CRS-compliant reason codes.

---

## 3. Data Overview

| ReasonID | Description | Meaning |
|---|---|---|
| 1 | I'm unable to obtain a TIN or equivalent number | User has applied for but not yet received their TIN - requires free-text explanation |
| 2 | The authorities in my tax residency don't require disclosure of TIN | Country does not mandate TIN disclosure to financial institutions |
| 3 | The country doesn't issue TIN | User's country has no TIN system |
| 4 | I'm not legally required to have TIN or functional equivalent | User is exempt from TIN requirement - may need documentation |
| 5 | I am Diplomat/UN employee or spouse/dependent | Diplomatic exemption from tax reporting - documented proof may be required |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | int | NO | - | CODE-BACKED | Primary key. CRS-aligned reason code (1-5). |
| 2 | Description | varchar(200) | YES | - | CODE-BACKED | User-facing description of the reason, displayed in the KYC form. |
| 3 | ValidationExpression | varchar(100) | YES | - | CODE-BACKED | Regex for validating free-text explanation. Only ReasonID=1 has a validation rule (requires explanation). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetNoTaxReasons | ReasonID | SP reads | Returns reasons for UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetNoTaxReasons | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_ReasonsForNoTaxID | CLUSTERED PK | ReasonID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All reasons
```sql
SELECT ReasonID, Description, ValidationExpression FROM KYC.ReasonsForNoTaxID WITH (NOLOCK) ORDER BY ReasonID
```

### 8.2 Reasons requiring explanation
```sql
SELECT * FROM KYC.ReasonsForNoTaxID WITH (NOLOCK) WHERE ValidationExpression IS NOT NULL
```

### 8.3 Validate user's explanation
```sql
SELECT CASE WHEN @UserExplanation LIKE '%[0-9a-zA-Z]%' THEN 1 ELSE 0 END AS IsValid
-- Based on validation regex from ReasonID=1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.ReasonsForNoTaxID | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.ReasonsForNoTaxID.sql*
