# Ev.GetProviderForCountry

> Returns the assigned EV provider ID for a specific country.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryId (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Ev.GetProviderForCountry is a simple lookup that returns which EV provider is assigned to handle identity verification for a given country. Returns ProviderId from Ev.CountryToProvider.

---

## 2. Business Logic

No complex business logic. Single SELECT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryId | int (IN) | NO | - | CODE-BACKED | Country to look up. |

Output: ProviderId (int, nullable).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Ev.CountryToProvider | SELECT FROM | Provider lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.GetProviderForCountry (procedure)
  +-- Ev.CountryToProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Ev.CountryToProvider | Table | SELECT FROM |

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

### 8.1 Get provider for UK
```sql
EXEC Ev.GetProviderForCountry @CountryId = 44
```

### 8.2 Direct equivalent
```sql
SELECT ProviderId FROM Ev.CountryToProvider WITH (NOLOCK) WHERE CountryId = 44
```

### 8.3 With provider name
```sql
SELECT ep.Name FROM Ev.CountryToProvider ctp WITH (NOLOCK)
JOIN Dictionary.EvProvider ep WITH (NOLOCK) ON ctp.ProviderId = ep.EvProviderId WHERE ctp.CountryId = 44
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Ev.GetProviderForCountry | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Ev/Stored Procedures/Ev.GetProviderForCountry.sql*
