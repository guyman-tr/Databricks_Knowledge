# Trade.GetActiveCopiersForParents

> Returns distinct active copier CIDs and their GCIDs for a batch of parent (leader) investor CIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ParentCID, CopierCID, CopierGCID triples |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all distinct active copiers (and their Global Customer IDs) who are copying any of the given parent (leader) investors. It validates that each copier actually has open positions via the mirror (JOIN to Trade.Position) and enriches the result with the copier's GCID from Customer.CustomerStatic.

The procedure exists to support batch operations on parent investors' copier networks - for example, sending notifications to all copiers of a set of parents, or performing compliance checks across multiple copy relationships simultaneously.

Data flows from a batch of parent CIDs (via TVP) through Trade.Mirror (active mirrors), Trade.Position (confirms open positions exist), and Customer.CustomerStatic (provides GCID). The TVP is materialized into an indexed temp table for efficient joining.

---

## 2. Business Logic

### 2.1 Active Copier Verification

**What**: A copier is only returned if they have an active mirror AND at least one open position via that mirror.

**Columns/Parameters Involved**: `MirrorID`, `IsActive`, `Trade.Position`

**Rules**:
- Mirror must be active (IsActive = 1)
- Mirror must have at least one position in Trade.Position (INNER JOIN on MirrorID)
- The DISTINCT ensures each copier appears once per parent even if they have multiple positions
- GCID is resolved from Customer.CustomerStatic for cross-system identification

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCIDs | Trade.CidList (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing the batch of parent (leader) CIDs to query. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ParentCID | INT | NO | - | CODE-BACKED | The parent (leader) investor's CID from Trade.Mirror. |
| 3 | CopierCID | INT | NO | - | CODE-BACKED | The copier's CID (M.CID) - the customer copying the parent. |
| 4 | CopierGCID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | The copier's Global Customer ID from Customer.CustomerStatic. Used for cross-system identification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentCIDs | Trade.CidList | UDT | Table-valued parameter type for batch CID input |
| FROM | Trade.Mirror | Direct Read | Active mirror relationships |
| INNER JOIN | Trade.Position | Direct Read (View) | Confirms copier has open positions via mirror |
| INNER JOIN | Customer.CustomerStatic | Cross-Schema Read | Resolves copier's GCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetActiveCopiersForParents (procedure)
├── Trade.Mirror (table)
├── Trade.Position (view)
├── Customer.CustomerStatic (table)
└── Trade.CidList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | INNER JOIN - active mirror relationships |
| Trade.Position | View | INNER JOIN - verify open positions exist |
| Customer.CustomerStatic | Table | INNER JOIN - resolve copier GCID |
| Trade.CidList | User Defined Type | TVP input parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get active copiers for a batch of parents

```sql
DECLARE @Parents Trade.CidList;
INSERT INTO @Parents (CID) VALUES (111), (222), (333);

EXEC Trade.GetActiveCopiersForParents @ParentCIDs = @Parents;
```

### 8.2 Verify active mirrors with positions for a parent

```sql
SELECT DISTINCT
    M.ParentCID,
    M.CID AS CopierCID,
    M.MirrorID
FROM    Trade.Mirror M WITH (NOLOCK)
INNER JOIN Trade.Position P WITH (NOLOCK)
    ON M.MirrorID = P.MirrorID
WHERE   M.ParentCID = 12345678
    AND M.IsActive = 1;
```

### 8.3 Count copiers per parent

```sql
SELECT  M.ParentCID,
        COUNT(DISTINCT M.CID) AS ActiveCopierCount
FROM    Trade.Mirror M WITH (NOLOCK)
INNER JOIN Trade.Position P WITH (NOLOCK)
    ON M.MirrorID = P.MirrorID
WHERE   M.IsActive = 1
GROUP BY M.ParentCID
ORDER BY ActiveCopierCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetActiveCopiersForParents | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetActiveCopiersForParents.sql*
