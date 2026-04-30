# Ev.GetEvRequiredFields

> Returns EV required field names for a specific country by first looking up the assigned provider, then querying field requirements.

| Property | Value |
|----------|-------|
| **Schema** | Ev |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryId (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Ev.GetEvRequiredFields returns which identity data fields are required for electronic verification in a specific country. First looks up the provider for the country from Ev.CountryToProvider, then queries Ev.FieldToCountry for that provider+country combination. Returns a list of field names.

---

## 2. Business Logic

Two-step lookup: Country -> Provider -> Fields.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryId | int (IN) | NO | - | CODE-BACKED | Country to get EV field requirements for. |

Output: FieldName (varchar).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Ev.CountryToProvider | SELECT FROM | Provider lookup |
| - | Ev.FieldToCountry | SELECT FROM | Field requirements |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Ev.GetEvRequiredFields (procedure)
  +-- Ev.CountryToProvider (table) [done]
  +-- Ev.FieldToCountry (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Ev.CountryToProvider | Table | SELECT FROM |
| Ev.FieldToCountry | Table | SELECT FROM |

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

### 8.1 Get required fields for UK
```sql
EXEC Ev.GetEvRequiredFields @CountryId = 44
```

### 8.2 Get required fields for Australia
```sql
EXEC Ev.GetEvRequiredFields @CountryId = 61
```

### 8.3 Direct equivalent
```sql
DECLARE @pid INT
SELECT @pid = ProviderId FROM Ev.CountryToProvider WITH (NOLOCK) WHERE CountryId = 44
SELECT FieldName FROM Ev.FieldToCountry WITH (NOLOCK) WHERE ProviderId = @pid AND CountryId = 44
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Ev.GetEvRequiredFields | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Ev/Stored Procedures/Ev.GetEvRequiredFields.sql*
