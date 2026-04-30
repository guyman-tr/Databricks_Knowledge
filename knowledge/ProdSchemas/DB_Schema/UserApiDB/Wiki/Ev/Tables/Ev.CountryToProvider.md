# Ev.CountryToProvider

> Maps each country to its assigned Electronic Verification provider for identity verification routing.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Table |
| **Key Identifier** | CountryId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Ev.CountryToProvider defines which Electronic Verification provider handles identity verification for each country. One provider per country (PK on CountryId). ProviderId can be NULL for countries without electronic verification support. Used by Ev.GetProviderForCountry and Ev.GetAllEvRequiredFields.

---

## 2. Business Logic

No complex business logic. Country-to-provider mapping lookup.

---

## 3. Data Overview

N/A - configuration table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderId | int | YES | - | CODE-BACKED | FK to Dictionary.EvProvider. Which EV provider handles this country. NULL = no EV available for this country. See [EV Provider](_glossary.md#ev-provider). |
| 2 | CountryId | int | NO | - | CODE-BACKED | Primary key. Country identifier. Implicit FK to Dictionary.Country. One row per country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderId | Dictionary.EvProvider | Explicit FK | Assigned EV provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ev.GetProviderForCountry | CountryId | SP reads | Returns provider for a country |
| Ev.GetAllEvRequiredFields | CountryId | SP reads | Joins for field requirements |
| Ev.GetEvRequiredFields | CountryId | SP reads | Looks up provider for field query |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.CountryToProvider (table)
  +-- Dictionary.EvProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EvProvider | Table | FK: ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Ev.GetProviderForCountry | SP | SELECT FROM |
| Ev.GetAllEvRequiredFields | SP | JOIN |
| Ev.GetEvRequiredFields | SP | SELECT FROM |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EvCountryToProvider | CLUSTERED PK | CountryId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EvCountryToProvider | FOREIGN KEY | ProviderId -> Dictionary.EvProvider |

---

## 8. Sample Queries

### 8.1 Provider for a country
```sql
SELECT ep.Name AS Provider FROM Ev.CountryToProvider ctp WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON ctp.ProviderId = ep.EvProviderId WHERE ctp.CountryId = @CountryId
```

### 8.2 Countries without EV
```sql
SELECT c.Name FROM Ev.CountryToProvider ctp WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ctp.CountryId = c.CountryID WHERE ctp.ProviderId IS NULL
```

### 8.3 All mappings with names
```sql
SELECT c.Name AS Country, ep.Name AS Provider FROM Ev.CountryToProvider ctp WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK) ON ctp.CountryId = c.CountryID
LEFT JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON ctp.ProviderId = ep.EvProviderId ORDER BY c.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Ev.CountryToProvider | Type: Table | Source: UserApiDB/UserApiDB/Ev/Tables/Ev.CountryToProvider.sql*
