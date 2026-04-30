# Trade.BulkOperationsAllowedCidsTbl

> A table-valued parameter type for passing the whitelist of CIDs allowed for bulk operations, with optional grouping. Pairs with Trade.BulkOperationsAllowedCids table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int) |
| **Partition** | N/A |
| **Indexes** | 1 (PRIMARY KEY CLUSTERED on CID) |

---

## 1. Business Meaning

Trade.BulkOperationsAllowedCidsTbl is a table-valued parameter (TVP) type used to pass the whitelist of Customer IDs (CIDs) permitted to perform bulk operations. Bulk operations are high-volume trade actions (e.g., mass closes, bulk rebalances) restricted to a curated set of accounts. This type enables procedures to receive and enforce that whitelist in a single parameter.

Without this type, the system could not efficiently pass and validate the bulk-operations-allowed set. The Get/Set procedures (Trade.GetBulkOperationsAllowedCids, Trade.SetBulkOperationsAllowedCids) rely on this type to read and update the whitelist persisted in Trade.BulkOperationsAllowedCids.

Administrative workflows or configuration jobs load the allowed CIDs (and optionally group them by GroupID), pass them into the procedures, and the procedures MERGE or compare against the persisted table.

---

## 2. Business Logic

### 2.1 CID to GroupID Association

**What**: Links each allowed CID to an operational group for categorization or segmentation.

**Columns/Parameters Involved**: `CID`, `GroupID`

**Rules**:
- CID is the primary identifier; each row must be unique (PK enforces this).
- GroupID is optional (NULL) - when present, associates the CID with a logical group.
- Duplicate CIDs are rejected by the primary key (IGNORE_DUP_KEY = OFF).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - uniquely identifies an account in the bulk-operations whitelist. Primary key enforces no duplicates. Pairs with Trade.BulkOperationsAllowedCids.CID. |
| 2 | GroupID | tinyint | YES | - | CODE-BACKED | Operational group identifier. Associates this CID with a logical group for segmentation. NULL when no group is assigned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. CID semantically references Customer.CustomerTbl; GroupID may reference a lookup (no FK on type).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SetBulkOperationsAllowedCids | Parameter (TVP) | TVP | Writes the whitelist to Trade.BulkOperationsAllowedCids |
| Trade.GetBulkOperationsAllowedCids | Parameter (TVP) | TVP | Receives or returns the current whitelist |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SetBulkOperationsAllowedCids | Stored Procedure | READONLY TVP parameter |
| Trade.GetBulkOperationsAllowedCids | Stored Procedure | TVP parameter for whitelist exchange |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implicit) | CLUSTERED | CID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | CID - enforces uniqueness, IGNORE_DUP_KEY = OFF |

---

## 8. Sample Queries

### 8.1 Set bulk-operations whitelist with group assignment

```sql
DECLARE @Cids Trade.BulkOperationsAllowedCidsTbl;
INSERT INTO @Cids (CID, GroupID) VALUES (10001, 1), (10002, 1), (10003, 2);
EXEC Trade.SetBulkOperationsAllowedCids @Cids = @Cids;
```

### 8.2 Declare and populate for retrieval

```sql
DECLARE @Result Trade.BulkOperationsAllowedCidsTbl;
EXEC Trade.GetBulkOperationsAllowedCids @Cids = @Result OUTPUT;
SELECT CID, GroupID FROM @Result WITH (NOLOCK);
```

### 8.3 Build whitelist from a table

```sql
DECLARE @Cids Trade.BulkOperationsAllowedCidsTbl;
INSERT INTO @Cids (CID, GroupID)
SELECT CID, GroupID
FROM   Trade.SomeConfigTable WITH (NOLOCK)
WHERE  IsBulkAllowed = 1;
EXEC Trade.SetBulkOperationsAllowedCids @Cids = @Cids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BulkOperationsAllowedCidsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.BulkOperationsAllowedCidsTbl.sql*
