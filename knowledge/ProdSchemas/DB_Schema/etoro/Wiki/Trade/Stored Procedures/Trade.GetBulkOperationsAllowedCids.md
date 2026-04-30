# Trade.GetBulkOperationsAllowedCids

> Validates a batch of CIDs against the bulk operations whitelist, returning only those that are pre-approved for bulk trading operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CID + GroupID for CIDs found in the bulk operations whitelist |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure validates a batch of customer IDs against the `Trade.BulkOperationsAllowedCids` whitelist table. Bulk operations (mass position opens, closes, or adjustments) are restricted to pre-approved customers. Before executing a bulk operation, the system submits the list of target CIDs through this procedure to filter down to only those approved.

The procedure exists as a security/validation gate for bulk trading operations. Without this whitelist check, bulk operations could accidentally target unauthorized customers, potentially causing significant financial impact.

Data flows by JOINing the input TVP (`@AllowedCidsTbl`) to the persistent whitelist (`Trade.BulkOperationsAllowedCids`). Only CIDs present in BOTH the input and the whitelist are returned. The GroupID allows categorizing approved CIDs into different operation groups.

---

## 2. Business Logic

### 2.1 Whitelist Validation via TVP JOIN

**What**: Filters input CIDs to only those present in the permanent whitelist.

**Columns/Parameters Involved**: `@AllowedCidsTbl`, `Trade.BulkOperationsAllowedCids`, `CID`

**Rules**:
- Input CIDs are provided via Table-Valued Parameter (TVP) of type Trade.BulkOperationsAllowedCidsTbl
- TVP is copied to a temp table (#AllowedCidsTbl) for JOIN performance
- Only CIDs present in BOTH the input and the whitelist table are returned
- Uses NOLOCK on the whitelist table for non-blocking validation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AllowedCidsTbl | Trade.BulkOperationsAllowedCidsTbl | NO | - | CODE-BACKED | READONLY Table-Valued Parameter containing CIDs to validate. Columns: CID (INT), GroupID (TINYINT). |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID that is approved for bulk operations. Only returned if present in both the input TVP and the whitelist table. |
| 3 | GroupID | TINYINT | YES | - | CODE-BACKED | Operation group classification for the approved CID. Allows bulk operations to be scoped to specific groups. From the whitelist table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AllowedCidsTbl | Trade.BulkOperationsAllowedCidsTbl | TVP type | User-defined table type for input |
| (body) | Trade.BulkOperationsAllowedCids | INNER JOIN | Persistent whitelist of approved CIDs |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetBulkOperationsAllowedCids (procedure)
+-- Trade.BulkOperationsAllowedCidsTbl (type)
+-- Trade.BulkOperationsAllowedCids (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCidsTbl | User Defined Type | TVP parameter type |
| Trade.BulkOperationsAllowedCids | Table | INNER JOIN - whitelist validation |

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

### 8.1 Validate CIDs for bulk operations
```sql
DECLARE @CidList Trade.BulkOperationsAllowedCidsTbl;
INSERT INTO @CidList (CID, GroupID) VALUES (12345, 1), (67890, 1), (11111, 2);

EXEC Trade.GetBulkOperationsAllowedCids @AllowedCidsTbl = @CidList;
```

### 8.2 View the full whitelist
```sql
SELECT  CID, GroupID
FROM    Trade.BulkOperationsAllowedCids WITH (NOLOCK)
ORDER BY GroupID, CID;
```

### 8.3 Count approved CIDs per group
```sql
SELECT  GroupID, COUNT(*) AS ApprovedCids
FROM    Trade.BulkOperationsAllowedCids WITH (NOLOCK)
GROUP BY GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetBulkOperationsAllowedCids | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetBulkOperationsAllowedCids.sql*
