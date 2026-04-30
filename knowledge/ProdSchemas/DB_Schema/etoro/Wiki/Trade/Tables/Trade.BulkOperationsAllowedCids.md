# Trade.BulkOperationsAllowedCids

> Whitelist of client IDs (CIDs) that are permitted to perform bulk trading operations such as bulk position closes and fee processing, grouped by internal vs general classification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Trade.BulkOperationsAllowedCids stores the whitelist of client IDs (CIDs) that are allowed to perform bulk operations in the trading platform. Bulk operations include batch position management, bulk fee processing, and other mass-trade actions that require explicit authorization. The system restricts these operations to specific CIDs for risk control, compliance, and operational safety - only whitelisted accounts can trigger bulk processing.

This table exists because bulk operations (e.g., closing many positions at once, processing fees for thousands of accounts) carry higher operational and financial risk. Without a whitelist, any CID could potentially trigger bulk actions. The table pairs each allowed CID with a GroupID from Trade.BulkOperationsAllowedCidsGroups - 0 for Internal Cids (test/support) and 1 for General Cids (production whitelisted).

Data flows as follows: rows are created or updated via Trade.SetBulkOperationsAllowedCids (MERGE from TVP), deleted via Trade.DeleteBulkOperationsAllowedCid, and read by Trade.GetAllBulkOperationsAllowedCids and Trade.GetBulkOperationsAllowedCids. Application services call these procedures to validate whether a CID is permitted before executing bulk operations.

---

## 2. Business Logic

### 2.1 CID Whitelist with Group Classification

**What**: Each whitelisted CID belongs to exactly one group. The group distinguishes internal (test/support) accounts from production whitelisted customers.

**Columns/Parameters Involved**: `CID`, `GroupID`

**Rules**:
- CID is the primary key - one row per allowed client ID. Client ID comes from the user/customer identity system.
- GroupID references Trade.BulkOperationsAllowedCidsGroups: 0=Internal Cids (test/support), 1=General Cids (production).
- SetBulkOperationsAllowedCids MERGEs from TVP: WHEN MATCHED updates GroupID, WHEN NOT MATCHED inserts (CID, GroupID).
- DeleteBulkOperationsAllowedCid removes a CID from the whitelist by CID.
- GetBulkOperationsAllowedCids filters allowed CIDs from the table; GetAllBulkOperationsAllowedCids returns all.

**Diagram**:
```
Trade.BulkOperationsAllowedCidsGroups (parent)
  GroupID 0 -> Internal Cids
  GroupID 1 -> General Cids
        |
Trade.BulkOperationsAllowedCids (child)
  CID 149   -> GroupID 0 (internal)
  CID 3739182 -> GroupID 0 (internal)
```

---

## 3. Data Overview

| CID | GroupID | Meaning |
|-----|---------|---------|
| 149 | 0 | Internal test or support account permitted for bulk operations. Used for automated tests, support staff operations, or demo environments. Bulk operations on this CID may have relaxed validation. |
| 3739182 | 0 | Another internal CID whitelisted for bulk operations. Could be a test harness, migration script, or support tool that requires batch processing capability. |

**Selection criteria for the 5 rows:**
- Table contains 2 rows; both are shown above.
- Both rows use GroupID 0 (Internal Cids). Production General Cids (GroupID 1) would appear when high-volume or institutional clients are whitelisted.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Primary key. Client ID from the user/customer identity system. Only CIDs present in this table are permitted to trigger bulk trading operations (bulk position closes, bulk fee processing). Referenced by SetBulkOperationsAllowedCids (MERGE), DeleteBulkOperationsAllowedCid (DELETE), GetAllBulkOperationsAllowedCids, GetBulkOperationsAllowedCids. |
| 2 | GroupID | tinyint | NO | - | CODE-BACKED | FK to Trade.BulkOperationsAllowedCidsGroups. 0=Internal Cids (test/support accounts), 1=General Cids (production whitelisted). Used to distinguish processing behavior - internal CIDs may have different validation or logging than production CIDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GroupID | Trade.BulkOperationsAllowedCidsGroups | FK | Each whitelisted CID is assigned to a group. FK enforces referential integrity. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetBulkOperationsAllowedCids | - | MERGE | Inserts/updates whitelist from TVP. |
| Trade.DeleteBulkOperationsAllowedCid | - | DELETE | Removes CID from whitelist. |
| Trade.GetAllBulkOperationsAllowedCids | - | SELECT | Returns all whitelisted CIDs. |
| Trade.GetBulkOperationsAllowedCids | - | SELECT | Returns whitelisted CIDs filtered by input. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.BulkOperationsAllowedCids (table)
  -> Trade.BulkOperationsAllowedCidsGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BulkOperationsAllowedCidsGroups | Table | FK GroupID references GroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetBulkOperationsAllowedCids | Stored Procedure | MERGE - writes whitelist |
| Trade.DeleteBulkOperationsAllowedCid | Stored Procedure | DELETE - removes CID |
| Trade.GetAllBulkOperationsAllowedCids | Stored Procedure | SELECT - reads all |
| Trade.GetBulkOperationsAllowedCids | Stored Procedure | SELECT - reads filtered |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BulkOperationsAllowedCids | CLUSTERED PK | CID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BulkOperationsAllowedCids | PRIMARY KEY | Unique CID - one whitelist entry per client |
| FK (unnamed) | FOREIGN KEY | GroupID -> Trade.BulkOperationsAllowedCidsGroups(GroupID) |

---

## 8. Sample Queries

### 8.1 List all whitelisted CIDs with group name
```sql
SELECT bo.CID,
       bo.GroupID,
       g.GroupName
FROM Trade.BulkOperationsAllowedCids bo WITH (NOLOCK)
JOIN Trade.BulkOperationsAllowedCidsGroups g WITH (NOLOCK)
  ON bo.GroupID = g.GroupID
ORDER BY g.GroupID, bo.CID;
```

### 8.2 Check if a CID is whitelisted for bulk operations
```sql
SELECT CID,
       GroupID
FROM Trade.BulkOperationsAllowedCids WITH (NOLOCK)
WHERE CID = 149;
```

### 8.3 Count whitelisted CIDs by group
```sql
SELECT g.GroupName,
       COUNT(bo.CID) AS CidCount
FROM Trade.BulkOperationsAllowedCidsGroups g WITH (NOLOCK)
LEFT JOIN Trade.BulkOperationsAllowedCids bo WITH (NOLOCK)
  ON g.GroupID = bo.GroupID
GROUP BY g.GroupID, g.GroupName
ORDER BY g.GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 10/10, Logic: 6/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL, LiveData, Grep*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.BulkOperationsAllowedCids | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.BulkOperationsAllowedCids.sql*
