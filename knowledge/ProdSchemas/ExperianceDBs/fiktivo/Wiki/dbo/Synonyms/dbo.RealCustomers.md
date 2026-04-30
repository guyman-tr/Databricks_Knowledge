# dbo.RealCustomers

> Synonym pointing to [AO-REAL-DB-ROR].[etoro].[Customer].[Customer], providing local access to the real-account customer table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.RealCustomers is a synonym that provides a local reference to [AO-REAL-DB-ROR].[etoro].[Customer].[Customer]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AO-REAL-DB-ROR linked server (a read-only replica of the etoro real-accounts production database) under the Customer schema. Based on the name, this is the primary customer registry table for real (live, funded) account holders -- as opposed to demo or practice account users. It contains customer identity, registration, and account information and is the foundational reference for affiliate attribution: the fiktivo affiliate system joins to this table to identify which customers were acquired through which affiliates, driving commission and LTV calculations.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AO-REAL-DB-ROR].[etoro].[Customer].[Customer].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] | Synonym | Points to the real-account customer table on the AO-REAL-DB-ROR linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.RealCustomers (synonym)
  +-- [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[Customer].[Customer] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.RealCustomers WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'RealCustomers'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.RealCustomers WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.RealCustomers | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.RealCustomers.sql*
