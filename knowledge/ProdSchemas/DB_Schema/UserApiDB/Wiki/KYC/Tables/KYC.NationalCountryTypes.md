# KYC.NationalCountryTypes

> Maps countries to their accepted national PIN value types with ordering, supporting up to 5 types per country.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | CountryID + TypeNumber (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.NationalCountryTypes maps each country to the specific national PIN value types (from Dictionary.ExtendedUserValueType) it accepts, with ordering. TypeNumber (1-5) indicates priority - countries may accept up to 5 different national PIN types. Contains 495 country-type combinations. The NationalPinCountry view pivots this data into a flat structure (FirstTypeID through FifthTypeID).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Ordered mapping table.

---

## 3. Data Overview

495 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | CODE-BACKED | Part of composite PK. FK to KYC.NationalCountry. Country this type mapping applies to. |
| 2 | TypeNumber | int | NO | - | CODE-BACKED | Part of composite PK. Priority order (1=first/primary, 2=second, up to 5). |
| 3 | ValueTypeID | int | NO | - | CODE-BACKED | National PIN value type. Implicit FK to Dictionary.ExtendedUserValueType (e.g., NationalNumber, PassportNumber, TaxNumber). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | KYC.NationalCountry | Explicit FK | Parent country configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.NationalPinCountry | CountryID | View OUTER APPLY | Pivoted into FirstTypeID-FifthTypeID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.NationalCountryTypes (table)
  +-- KYC.NationalCountry (table) [done in this batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalCountry | Table | FK: CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.NationalPinCountry | View | OUTER APPLY with GROUP BY pivot |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYC_NationalCountryTypes | CLUSTERED PK | CountryID, TypeNumber | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_KYC_NationalCountry_CountryID | FOREIGN KEY | CountryID -> KYC.NationalCountry(CountryID) |

---

## 8. Sample Queries

### 8.1 Types for a country
```sql
SELECT nct.TypeNumber, vt.Name AS ValueType FROM KYC.NationalCountryTypes nct WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON nct.ValueTypeID = vt.ValueTypeID
WHERE nct.CountryID = @CountryID ORDER BY nct.TypeNumber
```

### 8.2 Countries accepting a specific type
```sql
SELECT c.Name FROM KYC.NationalCountryTypes nct WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON nct.CountryID = c.CountryID WHERE nct.ValueTypeID = @ValueTypeID
```

### 8.3 Count types per country
```sql
SELECT c.Name, COUNT(*) AS TypeCount FROM KYC.NationalCountryTypes nct WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON nct.CountryID = c.CountryID GROUP BY c.Name ORDER BY TypeCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.NationalCountryTypes | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.NationalCountryTypes.sql*
