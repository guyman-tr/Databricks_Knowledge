# dbo.GetAffiliatesInfo_RealCustomers

> Synonym pointing to [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers], providing local access to the AO-REAL-DB-ROR linked-server stored procedure without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.GetAffiliatesInfo_RealCustomers is a synonym that provides a local reference to [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AO-REAL-DB-ROR linked server (a read-only replica of the etoro real-accounts production database) in the dbo schema. Based on the name, this is a stored procedure that retrieves affiliate information specifically for real (live, funded) customers -- as distinct from demo or practice account holders. It is likely used to pull customer acquisition data attributed to specific affiliates for commission and reporting purposes.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers] | Synonym | Points to the affiliate info procedure on the AO-REAL-DB-ROR linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliatesInfo_RealCustomers (synonym)
  +-- [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers] (stored procedure on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[dbo].[GetAffiliatesInfo_RealCustomers] | Stored Procedure | Synonym target |

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
-- This synonym points to a stored procedure; execute rather than SELECT
EXEC dbo.GetAffiliatesInfo_RealCustomers
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'GetAffiliatesInfo_RealCustomers'
```

### 8.3 Check synonym metadata
```sql
SELECT name, base_object_name, create_date, modify_date
FROM sys.synonyms
WHERE name = 'GetAffiliatesInfo_RealCustomers'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.GetAffiliatesInfo_RealCustomers | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.GetAffiliatesInfo_RealCustomers.sql*
