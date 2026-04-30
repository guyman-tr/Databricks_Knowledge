# Trade.BulkOperationsAllowedCidsGroups

> Lookup table defining groups of client IDs (CIDs) that are allowed to perform bulk trading operations, such as bulk position closes or fee processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | GroupID (tinyint, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Trade.BulkOperationsAllowedCidsGroups defines the categories of client IDs that are permitted to participate in bulk operations. Bulk operations include batch position management, bulk fee processing, and other mass-trade actions that require explicit whitelisting. The system restricts these operations to specific CIDs for risk control, compliance, and operational safety.

This table exists because the trading platform needs to classify allowed CIDs into logical groups (e.g., internal test accounts vs. general production accounts). The child table Trade.BulkOperationsAllowedCids stores individual CIDs and assigns each to a group via GroupID. Grouping enables differentiated handling: internal CIDs may get different rate limits, logging, or processing paths than general CIDs.

Data flows through this table as follows: rows are created during initial system setup or schema deployment and rarely change. The table is read when procedures such as Trade.GetAllBulkOperationsAllowedCids and Trade.SetBulkOperationsAllowedCids work with the child BulkOperationsAllowedCids table. Group names are used for display and reporting when resolving GroupID to a human-readable label.

---

## 2. Business Logic

### 2.1 CID Group Classification

**What**: Two groups categorize CIDs permitted for bulk operations - internal (testing/support) and general (production).

**Columns/Parameters Involved**: `GroupID`, `GroupName`

**Rules**:
- **Internal Cids (GroupID 0)**: CIDs used for internal testing, support operations, or demo purposes. These accounts may have relaxed validation or different processing behavior for bulk operations.
- **General Cids (GroupID 1)**: Production customer CIDs that are whitelisted for bulk operations. Typically a small subset of high-volume or institutional clients requiring batch processing capabilities.
- Each CID in Trade.BulkOperationsAllowedCids must reference a valid GroupID from this table via FK constraint.
- Group names are descriptive labels; GroupID is the stable identifier used in joins and application logic.

**Diagram**:
```
Trade.BulkOperationsAllowedCidsGroups (parent)
├── GroupID 0 -> "Internal Cids"
│   └── Trade.BulkOperationsAllowedCids rows (CID -> GroupID 0)
└── GroupID 1 -> "General Cids"
    └── Trade.BulkOperationsAllowedCids rows (CID -> GroupID 1)
```

---

## 3. Data Overview

| GroupID | GroupName | Meaning |
|---|---|---|
| 0 | Internal Cids | Internal or test accounts permitted for bulk operations. Used by support staff, automated tests, or demo environments. Bulk operations on these CIDs may bypass certain production checks or have different logging. |
| 1 | General Cids | Production customer CIDs whitelisted for bulk operations. These are real traders (e.g., high-volume or institutional) who require batch position closes or bulk fee processing. Operations follow full production validation. |

**Selection criteria for the 5 rows:**
- Table contains exactly 2 rows; both are shown above.
- Row 0 and 1 represent the full range of group types in the system.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | tinyint | NO | - | CODE-BACKED | Primary key identifying the bulk-operations CID group. 0=Internal Cids (test/support accounts), 1=General Cids (production whitelisted). Referenced by Trade.BulkOperationsAllowedCids via FK. Used by Trade.BulkOperationsAllowedCidsTbl UDT and procedures SetBulkOperationsAllowedCids, GetBulkOperationsAllowedCids. |
| 2 | GroupName | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the group. Used for UI display, reporting, and resolving GroupID to a descriptive name when joining BulkOperationsAllowedCids with this table. Values: "Internal Cids", "General Cids". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.BulkOperationsAllowedCids | GroupID | FK | Each whitelisted CID is assigned to a group. The FK enforces referential integrity so only valid group IDs can be used. |
| Trade.BulkOperationsAllowedCidsTbl | GroupID | Lookup | UDT used by SetBulkOperationsAllowedCids and GetBulkOperationsAllowedCids; GroupID values must exist in this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCids | Table | FK references GroupID |
| Trade.SetBulkOperationsAllowedCids | Stored Procedure | Merges into BulkOperationsAllowedCids using GroupID from TVP; FK validates GroupID |
| Trade.GetBulkOperationsAllowedCids | Stored Procedure | Reads BulkOperationsAllowedCids with GroupID; can JOIN here for group names |
| Trade.GetAllBulkOperationsAllowedCids | Stored Procedure | Reads BulkOperationsAllowedCids; GroupID resolves to this table |
| Trade.DeleteBulkOperationsAllowedCid | Stored Procedure | Deletes from BulkOperationsAllowedCids; no direct ref but FK enforces valid GroupID on insert |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade_BulkOperationsAllowedCidsGroups | CLUSTERED PK | GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Trade_BulkOperationsAllowedCidsGroups | PRIMARY KEY | Unique GroupID; ensures one row per group |

---

## 8. Sample Queries

### 8.1 List all bulk operations groups
```sql
SELECT  GroupID,
        GroupName
FROM    [Trade].[BulkOperationsAllowedCidsGroups] WITH (NOLOCK)
ORDER BY GroupID;
```

### 8.2 Count CIDs per group
```sql
SELECT  g.GroupName,
        COUNT(b.CID) AS CidCount
FROM    [Trade].[BulkOperationsAllowedCidsGroups] g WITH (NOLOCK)
LEFT JOIN [Trade].[BulkOperationsAllowedCids] b WITH (NOLOCK)
        ON g.GroupID = b.GroupID
GROUP BY g.GroupID,
         g.GroupName
ORDER BY g.GroupID;
```

### 8.3 Resolve GroupID to group name for allowed CIDs
```sql
SELECT  b.CID,
        b.GroupID,
        g.GroupName
FROM    [Trade].[BulkOperationsAllowedCids] b WITH (NOLOCK)
JOIN    [Trade].[BulkOperationsAllowedCidsGroups] g WITH (NOLOCK)
        ON b.GroupID = g.GroupID
ORDER BY g.GroupID,
         b.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BulkOperationsAllowedCidsGroups | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.BulkOperationsAllowedCidsGroups.sql*
