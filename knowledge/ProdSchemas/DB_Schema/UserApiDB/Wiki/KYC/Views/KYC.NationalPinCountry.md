# KYC.NationalPinCountry

> View that pivots national PIN type data from NationalCountry and NationalCountryTypes into a flat structure with up to 5 type columns per country.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | View |
| **Key Identifier** | CountryID (from NationalCountry) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.NationalPinCountry is a denormalized view that combines NationalCountry configuration with pivoted NationalCountryTypes data. For each country, it returns the mandatory type, validation rules, fast verification flag, and up to 5 national PIN value type IDs (FirstTypeID through FifthTypeID). This flat structure is consumed by GetNationalPinCountry and used by the registration flow to determine which national PIN options to present.

The OUTER APPLY with conditional aggregation (IIF + MAX) pivots the variable-length NationalCountryTypes rows into fixed columns.

---

## 2. Business Logic

### 2.1 Type Pivoting

**What**: Converts rows (TypeNumber 1-5) into columns (FirstTypeID through FifthTypeID).

**Columns/Parameters Involved**: `FirstTypeID`, `SecondTypeID`, `ThirdTypeID`, `FourthTypeID`, `FifthTypeID`

**Rules**:
- TypeNumber=1 -> FirstTypeID, TypeNumber=2 -> SecondTypeID, etc.
- NULL when country has fewer than 5 type options
- Uses MAX(IIF(TypeNumber=N, ValueTypeID, NULL)) pattern

---

## 3. Data Overview

N/A - view (251 rows, one per country).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Country identifier. From KYC.NationalCountry. |
| 2 | FirstTypeID | int | YES | - | CODE-BACKED | Primary national PIN type. Pivoted from NationalCountryTypes TypeNumber=1. |
| 3 | SecondTypeID | int | YES | - | CODE-BACKED | Second PIN type option. TypeNumber=2. NULL if country has only 1 type. |
| 4 | ThirdTypeID | int | YES | - | CODE-BACKED | Third PIN type option. TypeNumber=3. |
| 5 | FourthTypeID | int | YES | - | CODE-BACKED | Fourth PIN type option. TypeNumber=4. |
| 6 | FifthTypeID | int | YES | - | CODE-BACKED | Fifth PIN type option. TypeNumber=5. |
| 7 | MandatoryTypeID | int | NO | - | CODE-BACKED | From NationalCountry. 0=Exempt, 1=Optional, 2=Mandatory. |
| 8 | ValidationExpression | varchar(1000) | YES | - | CODE-BACKED | From NationalCountry. Regex for PIN validation. |
| 9 | MaskExpression | varchar(50) | YES | - | CODE-BACKED | From NationalCountry. Input mask pattern. |
| 10 | ValidationExpressionMessage | varchar(100) | YES | - | CODE-BACKED | From NationalCountry. Error message for validation failure. |
| 11 | HasFastVerification | bit | NO | - | CODE-BACKED | From NationalCountry. Whether fast EV is available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.NationalCountry | FROM | Base country configuration |
| - | KYC.NationalCountryTypes | OUTER APPLY | Pivoted type mappings |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetNationalPinCountry | - | SP reads | Returns all rows from this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.NationalPinCountry (view)
  +-- KYC.NationalCountry (table) [done]
  +-- KYC.NationalCountryTypes (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalCountry | Table | FROM |
| KYC.NationalCountryTypes | Table | OUTER APPLY |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetNationalPinCountry | Stored Procedure | SELECT FROM |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All country PIN configs
```sql
SELECT * FROM KYC.NationalPinCountry WITH (NOLOCK) ORDER BY CountryID
```

### 8.2 Countries with multiple PIN types
```sql
SELECT CountryID, FirstTypeID, SecondTypeID, ThirdTypeID FROM KYC.NationalPinCountry WITH (NOLOCK) WHERE SecondTypeID IS NOT NULL
```

### 8.3 Mandatory PIN countries with types
```sql
SELECT npc.CountryID, c.Name, npc.FirstTypeID, vt.Name AS PrimaryType
FROM KYC.NationalPinCountry npc WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON npc.CountryID = c.CountryID
LEFT JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON npc.FirstTypeID = vt.ValueTypeID
WHERE npc.MandatoryTypeID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: KYC.NationalPinCountry | Type: View | Source: UserApiDB/UserApiDB/KYC/Views/KYC.NationalPinCountry.sql*
