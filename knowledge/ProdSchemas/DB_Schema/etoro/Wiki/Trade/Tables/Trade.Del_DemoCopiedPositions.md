# Trade.Del_DemoCopiedPositions

> Deletion-tracking table for demo positions that have been copied to real accounts, used during demo-to-real migration or cleanup operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 |

---

## 1. Business Meaning

Trade.Del_DemoCopiedPositions is a leaf table that tracks PositionIDs of demo positions that have been copied or migrated to real accounts. The "Del_" prefix indicates a deletion or cleanup-related staging/delta table in the eToro naming convention. It stores minimal data: an identity surrogate key (ID) and the PositionID being tracked. No stored procedures in the SSDT repo directly reference this table—inserts and reads are likely performed by application services (e.g., demo-to-real migration jobs or copy-trading sync processes).

This table exists to support operations where demo account positions are copied to real accounts. The system needs to record which positions have already been processed to avoid duplicates and to support rollback or audit trails. The similarity to Trade.Del_DemoCopiedOrders and Trade.Del_DemoCopiedCIDs suggests a family of demo-copy tracking tables for different entity types (positions, orders, customers).

Data flow: application code or scheduled jobs INSERT rows when demo positions are copied; no SQL procedures in the repo perform DML. The table is read-only from a SQL procedure perspective. Indexes on PositionID support lookups to check whether a position has already been copied.

---

## 2. Business Logic

### 2.1 Position Copy Tracking

**What**: Each row represents a PositionID that has been copied from a demo account to a real account.

**Columns/Parameters Involved**: `ID`, `PositionID`

**Rules**:
- ID is IDENTITY(1,1) NOT FOR REPLICATION—prevents replication from resetting the identity
- PositionID is nullable—allows for partial or staged records if needed
- IX_TradeDemoCopiedPositionsPositionID and IX_TradeDemoCopiedOrdersOrderID support lookups by PositionID (the second index name references "OrderID" but is on PositionID per DDL—likely a naming inconsistency from when the schema was cloned from Del_DemoCopiedOrders)

### 2.2 Leaf Table Characteristics

**What**: No declared foreign keys; relationships are implicit.

**Rules**:
- PositionID implicitly references Trade.Position (or equivalent position table) for the demo account
- No procedures in etoro/etoro/Trade/Stored Procedures/ reference Del_DemoCopiedPositions
- Trade.DemoCopiedPositions (different table) is referenced by Trade.GetPositionHierarchy_Rollback—that table may serve a related but distinct purpose (active copy tracking vs. deletion/archive tracking)

---

## 3. Data Overview

| ID | PositionID | Meaning |
|----|------------|---------|
| 128107 | 13508145 | Demo position 13508145 was copied to real. |
| 128305 | 34713827 | Demo position 34713827 was copied to real. |
| 128256 | 36196903 | Demo position 36196903 was copied to real. |
| 128152 | 36237961 | Demo position 36237961 was copied to real. |
| 128331 | 40848680 | Demo position 40848680 was copied to real. |

**Row count**: 339 (as of sample query)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Clustered primary key. Surrogate identifier. NOT FOR REPLICATION prevents identity reset during replication. |
| 2 | PositionID | bigint | YES | - | CODE-BACKED | The demo position identifier that was copied to a real account. Implicit FK to Trade.Position (demo). Indexed for lookups. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.Position | Implicit | Demo position that was copied to real account |

### 5.2 Referenced By

No SQL procedures or views in the SSDT repo reference this table. Application code likely performs reads and writes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Del_DemoCopiedPositions (table)
└── Trade.Position (implicit via PositionID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | PositionID implicitly references position records (demo context) |

### 6.2 Objects That Depend On This

None found in SSDT repo. Application services expected.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeDemoCopiedPositions | CLUSTERED | ID | - | - | Active |
| IX_TradeDemoCopiedOrdersOrderID | NC | PositionID | - | - | Active |
| IX_TradeDemoCopiedPositionsPositionID | NC | PositionID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeDemoCopiedPositions | PRIMARY KEY | Unique on ID (CLUSTERED) |

---

## 8. Sample Queries

### 8.1 Get latest 10 copied positions
```sql
SELECT TOP 10 ID, PositionID
  FROM Trade.Del_DemoCopiedPositions WITH (NOLOCK)
 ORDER BY ID DESC
```

### 8.2 Check if a position was copied
```sql
SELECT ID, PositionID
  FROM Trade.Del_DemoCopiedPositions WITH (NOLOCK)
 WHERE PositionID = 13508145
```

### 8.3 Count total copied positions
```sql
SELECT COUNT(*) AS Cnt
  FROM Trade.Del_DemoCopiedPositions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 6.5/10 (Elements: 7/10, Logic: 6/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL+Live+Grep*
*Sources: Atlassian: 0 | Procedures: 0 referencing | App Code: inferred from naming*
*Object: Trade.Del_DemoCopiedPositions | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Del_DemoCopiedPositions.sql*
