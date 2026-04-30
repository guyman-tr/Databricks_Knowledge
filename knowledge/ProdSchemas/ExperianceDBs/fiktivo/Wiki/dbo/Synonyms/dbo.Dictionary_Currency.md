# dbo.Dictionary_Currency

> Synonym pointing to [AORealRO].[etoro].[Dictionary].[Currency], providing local access to the AORealRO linked-server Dictionary schema Currency table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AORealRO].[etoro].[Dictionary].[Currency] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Dictionary_Currency is a synonym that provides a local reference to [AORealRO].[etoro].[Dictionary].[Currency]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AORealRO linked server (a read-only replica of the etoro production database) under the Dictionary schema. Based on the name, this is the canonical currency reference table -- a lookup table containing currency codes, names, symbols, and related attributes used across the platform for financial calculations, display, and reporting. It supports multi-currency account handling in the affiliate management and reporting context.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AORealRO].[etoro].[Dictionary].[Currency].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AORealRO].[etoro].[Dictionary].[Currency] | Synonym | Points to the canonical currency lookup table on the AORealRO linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Dictionary_Currency (synonym)
  +-- [AORealRO].[etoro].[Dictionary].[Currency] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AORealRO].[etoro].[Dictionary].[Currency] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.Dictionary_Currency WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'Dictionary_Currency'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.Dictionary_Currency WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.Dictionary_Currency | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.Dictionary_Currency.sql*
