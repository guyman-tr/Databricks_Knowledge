# dbo.etoro_HistoryActiveCredit

> Synonym pointing to [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit], providing local access to the active credit history table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.etoro_HistoryActiveCredit is a synonym that provides a local reference to [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AO-REAL-DB-ROR linked server (a read-only replica of the etoro real-accounts production database) under the History schema. Based on the name, History.ActiveCredit is the table containing records of currently active (outstanding, not yet expired or consumed) credit balances in customer accounts. Credit in trading platforms typically refers to promotional or bonus funds. Tracking active credit is important for the affiliate system to calculate net deposits, true equity, and chargeback risk for customers attributed to specific affiliates.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit] | Synonym | Points to the active credit history table on the AO-REAL-DB-ROR linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.etoro_HistoryActiveCredit (synonym)
  +-- [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[History].[ActiveCredit] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.etoro_HistoryActiveCredit WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'etoro_HistoryActiveCredit'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.etoro_HistoryActiveCredit WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.etoro_HistoryActiveCredit | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.etoro_HistoryActiveCredit.sql*
