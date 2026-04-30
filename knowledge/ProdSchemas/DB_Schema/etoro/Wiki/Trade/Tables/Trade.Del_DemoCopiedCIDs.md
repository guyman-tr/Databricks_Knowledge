# Trade.Del_DemoCopiedCIDs

> Staging table holding customer IDs (CIDs) and their demo copy counts for demo account cleanup workflows, used when deleting or migrating copy-trading relationships in demo environments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (PK) |
| **Partition** | No |
| **Indexes** | 1 |

---

## 1. Business Meaning

Trade.Del_DemoCopiedCIDs is a **staging/utility table** that stores customer IDs and the number of demo copiers (NumOfDemoCopiers) associated with each CID. The "Del_" prefix suggests it holds candidates for deletion or cleanup—likely CIDs whose copy-trading relationships have been or will be removed in demo environments. The table has no explicit foreign keys in SSDT; references are cross-schema (Customer or related schemas) or populated by application/ETL processes.

Data is populated by cross-schema processes; no procedures in etoro/etoro/Trade/Stored Procedures reference this table directly. Related tables Trade.DemoCopiedCIDs and Trade.DemoCopiedPositions (without Del_) are used by Trade.GetPositionHierarchy_Rollback for NumOfDemoCopiers and HasCopyPlusInDemo—suggesting Del_DemoCopiedCIDs may be a staging copy for batch delete operations. Live data shows CIDs with NumOfDemoCopiers ranging from 1 to 40.

---

## 2. Business Logic

### 2.1 CID and Demo Copy Count

**What**: Each row represents one customer (CID) and how many demo copiers they have. Used in demo account deletion or migration workflows.

**Columns/Parameters Involved**: CID, NumOfDemoCopiers.

**Rules**:
- CID is the primary key; one row per customer.
- NumOfDemoCopiers is the count of copy-trading relationships for that CID in demo.
- No procedure references found in etoro Trade schema; likely populated by application code or cross-schema jobs.

### 2.2 Del_ Prefix Semantics

**What**: The "Del_" prefix typically indicates tables used in deletion or cleanup workflows—candidates for removal or staging before bulk deletes.

**Rules**:
- Paired conceptually with Trade.Del_DemoCopiedOrders and Trade.Del_DemoCopiedPositions.
- Workflow: populate staging tables → perform deletes → possibly clear staging.

---

## 3. Data Overview

| CID | NumOfDemoCopiers | Meaning |
|-----|------------------|---------|
| 149 | 12 | Customer 149 has 12 demo copiers; candidate for cleanup or tracking. |
| 918 | 40 | Customer 918 has 40 demo copiers; high copy count. |
| 4498 | 3 | Customer 4498 has 3 demo copiers. |
| 5297 | 1 | Customer 5297 has 1 demo copier. |
| 10413 | 1 | Customer 10413 has 1 demo copier. |

**Selection criteria**: TOP 5 from live query with ORDER BY CID. NumOfDemoCopiers values reflect active copy-trading relationships in demo.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier. PK. Implicit reference to Customer.CustomerStatic. |
| 2 | NumOfDemoCopiers | int | NO | - | CODE-BACKED | Count of demo copiers associated with this CID. Used in cleanup/tracking. |

---

## 5. Relationships

### 5.1 References To
| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Customer being tracked. Cross-schema. |

### 5.2 Referenced By
| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None in etoro Trade) | - | - | No procedure references in etoro/etoro/Trade/Stored Procedures. Cross-schema population. |

---

## 6. Dependencies

### 6.0 Dependency Chain
```
Trade.Del_DemoCopiedCIDs (table)
└── Customer.CustomerStatic (table) [implicit, cross-schema]
```

### 6.1 Objects This Depends On
| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | CID references customer. Implicit. |

### 6.2 Objects That Depend On This
| Object | Type | How Used |
|--------|------|----------|
| (None identified) | - | Leaf table; cross-schema consumers not in SSDT. |

---

## 7. Technical Details

### 7.1 Indexes
| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_TradeDemoCopiedCIDs | CLUSTERED PK | CID | Active |

### 7.2 Constraints
| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeDemoCopiedCIDs | PK | CID |

---

## 8. Sample Queries

### 8.1 List all CIDs with demo copy counts
```sql
SELECT CID, NumOfDemoCopiers
  FROM Trade.Del_DemoCopiedCIDs WITH (NOLOCK)
 ORDER BY NumOfDemoCopiers DESC;
```

### 8.2 Find CIDs with more than 10 demo copiers
```sql
SELECT CID, NumOfDemoCopiers
  FROM Trade.Del_DemoCopiedCIDs WITH (NOLOCK)
 WHERE NumOfDemoCopiers > 10
 ORDER BY NumOfDemoCopiers DESC;
```

### 8.3 Get row count and summary stats
```sql
SELECT COUNT(*) AS RowCount,
       SUM(NumOfDemoCopiers) AS TotalDemoCopiers,
       AVG(CAST(NumOfDemoCopiers AS FLOAT)) AS AvgDemoCopiers
  FROM Trade.Del_DemoCopiedCIDs WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| - | - | No Atlassian sources linked. |

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
