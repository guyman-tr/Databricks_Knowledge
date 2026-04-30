# KYC.GetNoTaxReasons

> Returns the validation expression for a specific "no TIN" reason, used to validate user explanations.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReasonID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetNoTaxReasons returns the validation regex for a specific reason why a user cannot provide a TIN. Only ReasonID=1 ("unable to obtain") has a validation expression - requiring a free-text explanation. Other reasons have NULL validation (no explanation needed).

---

## 2. Business Logic

No complex business logic. Single SELECT by ReasonID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReasonID | int (IN) | NO | - | CODE-BACKED | Reason ID from KYC.ReasonsForNoTaxID (1-5). |

Output: ValidationExpression (varchar).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.ReasonsForNoTaxID | SELECT FROM | Validation rule lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetNoTaxReasons (procedure)
  +-- KYC.ReasonsForNoTaxID (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.ReasonsForNoTaxID | Table | SELECT FROM |

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

### 8.1 Get validation for reason 1
```sql
EXEC KYC.GetNoTaxReasons @ReasonID = 1 -- Returns regex
```

### 8.2 Get validation for reason 3
```sql
EXEC KYC.GetNoTaxReasons @ReasonID = 3 -- Returns NULL (no validation needed)
```

### 8.3 Direct query
```sql
SELECT ValidationExpression FROM KYC.ReasonsForNoTaxID WITH (NOLOCK) WHERE ReasonID = @ReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetNoTaxReasons | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetNoTaxReasons.sql*
