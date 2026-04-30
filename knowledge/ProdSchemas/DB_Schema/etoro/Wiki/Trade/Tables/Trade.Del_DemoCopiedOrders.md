# Trade.Del_DemoCopiedOrders

> Staging table holding order IDs for demo account cleanup workflows, used when deleting or migrating copied orders in demo environments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 |

---

## 1. Business Meaning

Trade.Del_DemoCopiedOrders is a **staging/utility table** that stores order IDs (OrderID) for demo account cleanup workflows. The "Del_" prefix indicates candidates for deletion—likely orders whose copy-trading relationships have been or will be removed in demo environments. The ID column is an IDENTITY with NOT FOR REPLICATION, suitable for replication scenarios where identity values must not conflict across replicas.

No procedures in etoro/etoro/Trade/Stored Procedures reference this table directly. It is conceptually paired with Trade.Del_DemoCopiedCIDs (customer-level) and Trade.Del_DemoCopiedPositions (position-level). Live data shows sequential ID values and OrderIDs in the millions (e.g., 1288494, 1538470).

---

## 2. Business Logic

### 2.1 Order ID Staging

**What**: Each row holds one OrderID to be processed (deleted or migrated) as part of demo copy cleanup.

**Columns/Parameters Involved**: ID, OrderID.

**Rules**:
- ID is surrogate key; OrderID is the business key (FK to Trade.Order implicitly).
- OrderID can repeat across rows (no unique constraint on OrderID).
- IDENTITY NOT FOR REPLICATION: identity values are not propagated in replication.

### 2.2 Del_ Prefix Semantics

**What**: The "Del_" prefix indicates deletion/cleanup staging. Paired with Del_DemoCopiedCIDs and Del_DemoCopiedPositions.

**Rules**:
- Populate → process (delete/migrate) → optionally clear.
- Workflow likely driven by application or cross-schema jobs.

---

## 3. Data Overview

| ID | OrderID | Meaning |
|----|---------|---------|
| 34906 | 1288494 | Order 1288494 staged for demo copy cleanup. |
| 34907 | 1538470 | Order 1538470 staged for cleanup. |
| 34908 | 2159575 | Order 2159575 staged for cleanup. |
| 34909 | 2189872 | Order 2189872 staged for cleanup. |
| 34910 | 2225066 | Order 2225066 staged for cleanup. |

**Selection criteria**: TOP 5 from live query. ID values indicate sequential inserts; OrderID values reference Trade.Order.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate key. PK. Identity not propagated in replication. |
| 2 | OrderID | int | NO | - | CODE-BACKED | Order identifier. Implicit FK to Trade.Order. Staged for cleanup. |

---

## 5. Relationships

### 5.1 References To
| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Order | Implicit | Order staged for deletion/migration. |

### 5.2 Referenced By
| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None in etoro Trade) | - | - | No procedure references in etoro/etoro/Trade/Stored Procedures. Implicit only. |

---

## 6. Dependencies

### 6.0 Dependency Chain
```
Trade.Del_DemoCopiedOrders (table)
└── Trade.Order (table) [implicit]
```

### 6.1 Objects This Depends On
| Object | Type | How Used |
|--------|------|----------|
| Trade.Order | Table | OrderID references order. Implicit. |

### 6.2 Objects That Depend On This
| Object | Type | How Used |
|--------|------|----------|
| (None identified) | - | Leaf table; consumers not in SSDT. |

---

## 7. Technical Details

### 7.1 Indexes
| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK_TradeDemoCopiedOrders | CLUSTERED PK | ID | Active |

### 7.2 Constraints
| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeDemoCopiedOrders | PK | ID |

---

## 8. Sample Queries

### 8.1 List order IDs staged for cleanup
```sql
SELECT ID, OrderID
  FROM Trade.Del_DemoCopiedOrders WITH (NOLOCK)
 ORDER BY ID;
```

### 8.2 Join to Order table for details (if exists)
```sql
SELECT DDO.ID, DDO.OrderID, O.CID, O.InstrumentID, O.StatusID
  FROM Trade.Del_DemoCopiedOrders DDO WITH (NOLOCK)
 INNER JOIN Trade.[Order] O WITH (NOLOCK) ON O.OrderID = DDO.OrderID
 ORDER BY DDO.ID;
```

### 8.3 Get row count
```sql
SELECT COUNT(*) AS RowCount
  FROM Trade.Del_DemoCopiedOrders WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| - | - | No Atlassian sources linked. |

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
