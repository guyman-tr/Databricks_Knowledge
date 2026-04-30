# dbo.HistoryPositionActive

> Synonym pointing to [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active], providing local access to the active (open) positions in the history schema without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.HistoryPositionActive is a synonym that provides a local reference to [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the RealForAffiliateAggregatedData linked server under the History schema. Based on the name, Position_Active is the table or view containing currently open (active) trading positions that have not yet been closed. This serves affiliate aggregation use cases that need to account for unrealized exposure or in-progress trades as part of customer activity reporting, alongside the closed positions in History.Position.

Note: dbo.SYN_History_Position_Active_ForAffiliateAggregatedData is a separate synonym that also points to the same target [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active], suggesting this synonym may be an earlier or alternate alias for the same object.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active] | Synonym | Points to the active (open) trading positions table in the History schema |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema. Also note that dbo.SYN_History_Position_Active_ForAffiliateAggregatedData is a parallel synonym pointing to the same target.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.HistoryPositionActive (synonym)
  +-- [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [RealForAffiliateAggregatedData].[etoro].[History].[Position_Active] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.HistoryPositionActive WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'HistoryPositionActive'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.HistoryPositionActive WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.HistoryPositionActive | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.HistoryPositionActive.sql*
