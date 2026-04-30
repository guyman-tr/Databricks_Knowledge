# dbo.LoadRegionsIsoMappings

> Returns all region-to-ISO-code mappings from Dictionary.RegionByIP_ISOCode for service caching.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Simple data access procedure returning all region ISO code mappings. Used by services to cache the full RegionByIP_ID -> RegionISOCode mapping at startup.

---

## 2. Business Logic

No complex business logic. Single SELECT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: RegionID (aliased RegionByIP_ID), CountryID, RegionISOCode.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.RegionByIP_ISOCode | SELECT FROM | ISO code mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.LoadRegionsIsoMappings (procedure)
  +-- Dictionary.RegionByIP_ISOCode (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RegionByIP_ISOCode | Table | SELECT FROM |

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

### 8.1 Load all mappings
```sql
EXEC dbo.LoadRegionsIsoMappings
```

### 8.2 Direct equivalent
```sql
SELECT RegionByIP_ID AS RegionID, CountryID, RegionISOCode FROM Dictionary.RegionByIP_ISOCode WITH (NOLOCK)
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Dictionary.RegionByIP_ISOCode WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.LoadRegionsIsoMappings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.LoadRegionsIsoMappings.sql*
