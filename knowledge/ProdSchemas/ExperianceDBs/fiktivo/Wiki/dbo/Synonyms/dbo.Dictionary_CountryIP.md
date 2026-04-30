# dbo.Dictionary_CountryIP

> Synonym pointing to [tradonomi].[Dictionary].[CountryIP], providing local access to the tradonomi database Dictionary schema CountryIP table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [tradonomi].[Dictionary].[CountryIP] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Dictionary_CountryIP is a synonym that provides a local reference to [tradonomi].[Dictionary].[CountryIP]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-schema paths in their code.

The target object resides in the tradonomi database under the Dictionary schema. Based on the name, this is an IP-to-country mapping table -- a lookup table that maps IP address ranges to their corresponding countries. It is used for geo-location of web traffic, enabling affiliate and marketing systems to identify the country of origin for registrations and leads based on their IP addresses.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [tradonomi].[Dictionary].[CountryIP].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [tradonomi].[Dictionary].[CountryIP] | Synonym | Points to the IP-to-country lookup table in the tradonomi database |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Dictionary_CountryIP (synonym)
  +-- [tradonomi].[Dictionary].[CountryIP] (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [tradonomi].[Dictionary].[CountryIP] | Table | Synonym target |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes
N/A for synonym.

### 7.2 Constraints
N/A for synonym.

---

## 8. Sample Queries

### 8.1 Query through the synonym
```sql
SELECT TOP 5 * FROM dbo.Dictionary_CountryIP WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'Dictionary_CountryIP'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.Dictionary_CountryIP WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.Dictionary_CountryIP | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.Dictionary_CountryIP.sql*
