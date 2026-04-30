# Trade.GetCIDByGCID

> Resolves a Global Customer ID (GCID) to the local Customer ID (CID) by looking up the Customer.Customer table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CID for a given GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure translates between two customer identification systems. GCID (Global Customer ID) is the cross-system identifier used across the eToro group's multiple databases and services, while CID (Customer ID) is the local identifier used within the Trade database. When an external service or cross-database operation needs to work with the Trade database, it first needs to resolve its GCID to a local CID.

The procedure exists because different systems within the eToro group use different customer identifiers. Created by Geri Reshef (2016-09-22, ticket 41015), this simple lookup enables inter-system communication.

Data flows from `Customer.Customer` using NOLOCK for non-blocking reads. A simple equality filter on GCID returns the matching CID.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple GCID-to-CID lookup. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID to resolve. The cross-system customer identifier. |
| 2 | CID | INT | NO | - | CODE-BACKED | Local Customer ID in the Trade database. The resolved local identifier for the given GCID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.Customer | SELECT FROM | Customer table lookup for GCID-to-CID translation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCIDByGCID (procedure)
+-- Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | SELECT FROM - GCID to CID lookup |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Resolve a GCID
```sql
EXEC Trade.GetCIDByGCID @GCID = 100200;
```

### 8.2 Direct lookup with more customer info
```sql
SELECT  CID, GCID, PlayerStatusID
FROM    Customer.Customer WITH (NOLOCK)
WHERE   GCID = 100200;
```

### 8.3 Find customers with GCID-CID mismatch (different values)
```sql
SELECT  CID, GCID
FROM    Customer.Customer WITH (NOLOCK)
WHERE   CID <> GCID
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCIDByGCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCIDByGCID.sql*
