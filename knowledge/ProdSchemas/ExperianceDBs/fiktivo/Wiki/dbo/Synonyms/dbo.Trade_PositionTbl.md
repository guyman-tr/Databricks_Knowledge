# dbo.Trade_PositionTbl

> Synonym pointing to [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl], providing local access to the live trading positions table via the AO-REAL-DB-ROR linked server without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.Trade_PositionTbl is a synonym that provides a local reference to [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AO-REAL-DB-ROR linked server (a read-only replica of the etoro real-accounts production database) under the Trade schema. Based on the name, Trade.PositionTbl is the primary live trading positions table -- the current state of all open (not yet closed) trades held by real-account customers. This is one of the most important data sources in the trading platform, used for affiliate attribution of active customer positions, computing open position metrics, and driving real-time reporting.

Note: dbo.SYN_Trade_PositionTbl_ForAffiliateAggregatedData is a related synonym pointing to the same logical table but via the RealForAffiliateAggregatedData linked server. The two synonyms allow different parts of the system to use appropriate server connections for their workloads.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl] | Synonym | Points to the live open trading positions table on the AO-REAL-DB-ROR linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema. Also note that dbo.SYN_Trade_PositionTbl_ForAffiliateAggregatedData is a related synonym for the same logical table via a different server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Trade_PositionTbl (synonym)
  +-- [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl] (table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[Trade].[PositionTbl] | Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.Trade_PositionTbl WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'Trade_PositionTbl'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.Trade_PositionTbl WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.Trade_PositionTbl | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.Trade_PositionTbl.sql*
