# KYC.GetNationalPinCountry

> Returns all national PIN country configurations from the NationalPinCountry view (pivoted type IDs, validation rules, and fast verification flags).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetNationalPinCountry is a simple wrapper that returns all rows from KYC.NationalPinCountry view. Used by the registration service to load the full national PIN configuration at startup - which countries require PINs, what types they accept, and validation rules.

---

## 2. Business Logic

No complex business logic. Simple SELECT * FROM KYC.NationalPinCountry.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: CountryID, FirstTypeID through FifthTypeID, MandatoryTypeID, ValidationExpression, MaskExpression, ValidationExpressionMessage, HasFastVerification.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.NationalPinCountry | SELECT FROM | Reads pivoted view |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetNationalPinCountry (procedure)
  +-- KYC.NationalPinCountry (view) [done]
        +-- KYC.NationalCountry (table) [done]
        +-- KYC.NationalCountryTypes (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalPinCountry | View | SELECT FROM |

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

### 8.1 Get all PIN configs
```sql
EXEC KYC.GetNationalPinCountry
```

### 8.2 Direct view query
```sql
SELECT * FROM KYC.NationalPinCountry WITH (NOLOCK) ORDER BY CountryID
```

### 8.3 Mandatory PIN countries only
```sql
SELECT * FROM KYC.NationalPinCountry WITH (NOLOCK) WHERE MandatoryTypeID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetNationalPinCountry | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetNationalPinCountry.sql*
