# dbo.CustomerAllTimeAggregatedData

> Synonym pointing to [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData], providing local access to the AORealRO linked-server BackOffice object without embedding cross-database paths in local code.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.CustomerAllTimeAggregatedData is a synonym that provides a local reference to [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AORealRO linked server (a read-only replica of the etoro production database) under the BackOffice schema. Based on the name, this is a table or view that stores aggregated lifetime-value metrics per customer -- such as all-time deposit totals, trade counts, net revenue, and similar summary statistics accumulated across the customer's full history. It is a key source for affiliate commission calculations and customer quality assessments.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData] | Synonym | Points to the actual data object on the AORealRO linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CustomerAllTimeAggregatedData (synonym)
  +-- [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData] (table/view on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AORealRO].[etoro].[BackOffice].[CustomerAllTimeAggregatedData] | Table or View | Synonym target |

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
SELECT TOP 5 * FROM dbo.CustomerAllTimeAggregatedData WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'CustomerAllTimeAggregatedData'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.CustomerAllTimeAggregatedData WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.CustomerAllTimeAggregatedData | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.CustomerAllTimeAggregatedData.sql*
