# Ev.FieldToCountry

> Configuration table defining which identity fields are required for EV per provider and country combination.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Table |
| **Key Identifier** | ProviderId + CountryId + FieldName (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Ev.FieldToCountry defines which identity data fields (name, DOB, address, etc.) must be collected for electronic verification based on the provider and country. Different providers require different fields for different countries. Used by Ev.GetEvRequiredFields and Ev.GetAllEvRequiredFields.

---

## 2. Business Logic

No complex business logic. Provider+country-specific field requirements.

---

## 3. Data Overview

N/A - configuration table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderId | int | NO | - | CODE-BACKED | Part of composite PK. FK to Dictionary.EvProvider. |
| 2 | CountryId | int | NO | - | CODE-BACKED | Part of composite PK. Country this field requirement applies to. |
| 3 | FieldName | varchar(30) | NO | - | CODE-BACKED | Part of composite PK. Name of the required field (e.g., FirstName, DOB, Address). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.EvProvider | Explicit FK | EV provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ev.GetEvRequiredFields | ProviderId+CountryId | SP reads | Returns required fields |
| Ev.GetAllEvRequiredFields | CountryId | SP reads | Returns all fields with provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.FieldToCountry (table)
  +-- Dictionary.EvProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvProvider | Table | FK: ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Ev.GetEvRequiredFields | SP | SELECT FROM |
| Ev.GetAllEvRequiredFields | SP | JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EvFieldToCountry | CLUSTERED PK | ProviderId, CountryId, FieldName | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EvFieldToCountry | FOREIGN KEY | ProviderId -> Dictionary.EvProvider |

---

## 8. Sample Queries

### 8.1 Required fields for a country
```sql
SELECT FieldName FROM Ev.FieldToCountry WITH (NOLOCK) WHERE CountryId = @CountryId AND ProviderId = @ProviderId
```

### 8.2 All field requirements with provider names
```sql
SELECT c.Name AS Country, ep.Name AS Provider, ftc.FieldName
FROM Ev.FieldToCountry ftc WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ftc.CountryId = c.CountryID
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON ftc.ProviderId = ep.EvProviderId ORDER BY c.Name, ftc.FieldName
```

### 8.3 Count fields per country
```sql
SELECT CountryId, COUNT(*) AS FieldCount FROM Ev.FieldToCountry WITH (NOLOCK) GROUP BY CountryId ORDER BY FieldCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Ev.FieldToCountry | Type: Table | Source: UserApiDB/UserApiDB/Ev/Tables/Ev.FieldToCountry.sql*
