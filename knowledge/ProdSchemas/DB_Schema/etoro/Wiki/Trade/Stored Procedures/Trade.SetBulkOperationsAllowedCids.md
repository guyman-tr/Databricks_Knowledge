# Trade.SetBulkOperationsAllowedCids

> Upserts a batch of CID-to-GroupID mappings into Trade.BulkOperationsAllowedCids using a MERGE statement, inserting new CIDs and updating the GroupID for existing ones.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @AllowedCidsTbl Trade.BulkOperationsAllowedCidsTbl - the batch of CIDs and group assignments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.BulkOperationsAllowedCids` is an allowlist that controls which customers (CIDs) are permitted to participate in bulk trading operations, and which operational group they belong to. This procedure is the write interface for that allowlist - it accepts a batch of CID+GroupID pairs and upserts them atomically.

The MERGE pattern makes this idempotent: calling it twice with the same data produces the same result. The `GroupID` can be updated for existing CIDs (e.g., when re-assigning a customer to a different bulk operations group).

The table-valued parameter (`Trade.BulkOperationsAllowedCidsTbl`) allows bulk updates in a single procedure call without the overhead of row-by-row inserts.

---

## 2. Business Logic

### 2.1 Upsert via MERGE

**What**: Insert new CIDs or update the GroupID for existing ones.

**Columns/Parameters Involved**: `Trade.BulkOperationsAllowedCids.CID`, `Trade.BulkOperationsAllowedCids.GroupID`

**Rules**:
- MERGE target: `Trade.BulkOperationsAllowedCids`
- MERGE source: `@AllowedCidsTbl` (TVP)
- Match key: `CID`
- WHEN MATCHED: UPDATE tab1.GroupID = tab2.GroupID
- WHEN NOT MATCHED: INSERT (CID, GroupID) VALUES (tab2.CID, tab2.GroupID)
- No WHEN NOT MATCHED BY SOURCE clause - existing CIDs not in the TVP are left unchanged

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AllowedCidsTbl | Trade.BulkOperationsAllowedCidsTbl READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the CID+GroupID pairs to upsert. READONLY prevents modification inside the procedure. Each row is either inserted (new CID) or used to update the GroupID (existing CID). |

**Trade.BulkOperationsAllowedCidsTbl columns (UDT):**

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| 1 | CID | INT | CODE-BACKED | Customer ID - the match key for the MERGE operation |
| 2 | GroupID | INT | CODE-BACKED | Bulk operations group assignment for this CID |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP type | Trade.BulkOperationsAllowedCidsTbl | UDT | Table-valued parameter type defining input structure |
| MERGE target | Trade.BulkOperationsAllowedCids | Modifier | Upserts CID+GroupID - inserts new, updates existing |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by bulk operations configuration management service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetBulkOperationsAllowedCids (procedure)
|- Trade.BulkOperationsAllowedCidsTbl (UDT - TVP type)
|- Trade.BulkOperationsAllowedCids (table - upsert target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCidsTbl | User Defined Type | TVP type - defines structure of @AllowedCidsTbl input |
| Trade.BulkOperationsAllowedCids | Table | MERGE target - upserted with CID+GroupID pairs |

### 6.2 Objects That Depend On This

No dependents found - called by bulk operations configuration service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotent upsert | Logic | MERGE is idempotent - safe to call multiple times with same data |
| No delete | Logic | No WHEN NOT MATCHED BY SOURCE clause - existing CIDs not in TVP are preserved |

---

## 8. Sample Queries

### 8.1 Add or update bulk operations allowances for a batch of CIDs

```sql
DECLARE @CidBatch Trade.BulkOperationsAllowedCidsTbl
INSERT INTO @CidBatch (CID, GroupID) VALUES
    (111111, 1),
    (222222, 1),
    (333333, 2)

EXEC Trade.SetBulkOperationsAllowedCids @AllowedCidsTbl = @CidBatch
```

### 8.2 Check current allowlist

```sql
SELECT CID, GroupID
FROM Trade.BulkOperationsAllowedCids WITH (NOLOCK)
ORDER BY GroupID, CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetBulkOperationsAllowedCids | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetBulkOperationsAllowedCids.sql*
