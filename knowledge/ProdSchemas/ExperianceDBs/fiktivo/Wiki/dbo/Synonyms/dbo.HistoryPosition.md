# dbo.HistoryPosition

> Synonym pointing to [RealForAffiliateAggregatedData].[etoro].[History].[Position], providing local access to the closed trading positions history table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [RealForAffiliateAggregatedData].[etoro].[History].[Position] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.HistoryPosition is a synonym that provides a local reference to [RealForAffiliateAggregatedData].[etoro].[History].[Position]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the RealForAffiliateAggregatedData linked server under the History schema. Based on the name, this is the main closed/historical trading positions table -- containing records of all trades that have been closed by real-account customers. It is a core data source for affiliate commission calculations based on customer trading activity, net revenue computations, and LTV (lifetime value) aggregations.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [RealForAffiliateAggregatedData].[etoro].[History].[Position].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [RealForAffiliateAggregatedData].[etoro].[History].[Position] | Synonym | Points to the closed trading positions history table |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.HistoryPosition (synonym)
  +-- [RealForAffiliateAggregatedData].[etoro].[History].[Position] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [RealForAffiliateAggregatedData].[etoro].[History].[Position] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.HistoryPosition WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'HistoryPosition'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.HistoryPosition WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.HistoryPosition | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.HistoryPosition.sql*
