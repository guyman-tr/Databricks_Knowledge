# Ev.GetAllEvRequiredFields

> Returns all EV required fields across all countries that have an assigned provider.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Ev.GetAllEvRequiredFields returns the complete list of identity fields required for electronic verification across all countries. Joins FieldToCountry with CountryToProvider, filtering to countries that have a non-null provider. Used for caching the full field requirements at service startup.

---

## 2. Business Logic

No complex business logic. JOIN + filter to countries with assigned providers.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: CountryId, FieldName.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Ev.FieldToCountry | SELECT FROM | Field requirements |
| - | Ev.CountryToProvider | JOIN | Filter to countries with providers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.GetAllEvRequiredFields (procedure)
  +-- Ev.FieldToCountry (table) [done]
  +-- Ev.CountryToProvider (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Ev.FieldToCountry | Table | SELECT FROM |
| Ev.CountryToProvider | Table | JOIN |

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

### 8.1 Get all required fields
```sql
EXEC Ev.GetAllEvRequiredFields
```

### 8.2 Direct equivalent
```sql
SELECT ftc.CountryId, FieldName FROM Ev.FieldToCountry ftc WITH (NOLOCK)
JOIN Ev.CountryToProvider cp WITH (NOLOCK) ON cp.CountryId = ftc.CountryId WHERE cp.ProviderId IS NOT NULL ORDER BY cp.CountryId
```

### 8.3 Count fields per country
```sql
SELECT CountryId, COUNT(*) AS FieldCount FROM Ev.FieldToCountry WITH (NOLOCK) GROUP BY CountryId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Ev.GetAllEvRequiredFields | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Ev/Stored Procedures/Ev.GetAllEvRequiredFields.sql*
