# dbo.HistoryPositionSlim

> Synonym pointing to [AORealRO].[etoro].[History].[PositionSlim], providing local access to the slim (reduced-column) closed trading positions history table without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AORealRO].[etoro].[History].[PositionSlim] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.HistoryPositionSlim is a synonym that provides a local reference to [AORealRO].[etoro].[History].[PositionSlim]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AORealRO linked server (a read-only replica of the etoro production database) under the History schema. Based on the name, PositionSlim is a reduced-column or optimized version of the full position history table -- containing only the most frequently needed fields for efficient querying. This type of "slim" table is typically used for high-volume reporting and aggregation queries where joining to the full position table would be too costly. It is a key data source for affiliate performance reports and commission calculations.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AORealRO].[etoro].[History].[PositionSlim].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AORealRO].[etoro].[History].[PositionSlim] | Synonym | Points to the slim position history table on the AORealRO linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.HistoryPositionSlim (synonym)
  +-- [AORealRO].[etoro].[History].[PositionSlim] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AORealRO].[etoro].[History].[PositionSlim] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.HistoryPositionSlim WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'HistoryPositionSlim'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.HistoryPositionSlim WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.HistoryPositionSlim | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.HistoryPositionSlim.sql*
