# Trade.GetTreeNodesByParentPositionAndTreeId_MOT

> Memory-optimized TVP that holds copy-trade tree traversal results. Collects child nodes with position data, mirror state, hedge server info, and settlement type for a given parent position and tree.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID |
| **Partition** | N/A |
| **Indexes** | IX_PositionID (NC) |

---

## 1. Business Meaning

Trade.GetTreeNodesByParentPositionAndTreeId_MOT is a memory-optimized table type (MOT) used as a local variable container for copy-trade tree traversal results. When querying the tree hierarchy for a specific parent position and tree, procedures such as Trade.GetTreeNodesByParentPositionAndTreeId populate this type with all child nodes.

Each row represents one node in the copy-trade tree: Level (depth: 0=root, 1=direct copier, 2=copier-of-copier), CID, PositionID, MirrorID, ParentPositionID, Units, Amount, plus flags for settlement type (IsSettled), hedge computation (IsComputeForHedge), mirror state (IsMirrorActive), and copy mode (IsFundCopy). RootHedgeServerID and HedgeServerID identify which hedge servers handle the root and this position. The MOT suffix enables lock-free in-memory processing of tree traversal output.

---

## 2. Business Logic

### 2.1 Tree Traversal Result Container

**What**: Holds the flattened result of a copy-trade tree walk. Each row is a node with its depth, position data, and metadata.

**Columns/Parameters Involved**: Level, CID, PositionID, MirrorID, ParentPositionID, Units, Amount, IsSettled, IsComputeForHedge, RootHedgeServerID, HedgeServerID, TreeID, IsMirrorActive, IsFundCopy.

**Rules**:
- Level: depth in tree (0=root, 1=direct copier, 2=copier-of-copier).
- IsSettled: legacy real stock flag (1=real stock, 0=CFD).
- IsComputeForHedge: whether included in hedge calculations.
- IsMirrorActive: mirror copy state (0=paused, 1=active).
- IsFundCopy: whether copy is via CopyFund vs CopyTrader.
- RootHedgeServerID: hedge server of root position; HedgeServerID: hedge server of this position.
- Index IX_PositionID supports lookups by PositionID.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Level | int | YES | - | High | Depth in tree (0=root, 1=direct copier, 2=copier-of-copier) |
| 2 | CID | int | YES | - | High | Customer ID |
| 3 | PositionID | bigint | YES | - | High | Position identifier |
| 4 | MirrorID | int | YES | - | High | Copy-trade mirror ID |
| 5 | ParentPositionID | bigint | YES | - | High | Parent position in tree |
| 6 | Units | decimal(16,6) | YES | - | High | Position units |
| 7 | Amount | money | YES | - | High | Position amount |
| 8 | IsSettled | bit | YES | - | High | Legacy real stock flag (1=real stock, 0=CFD) |
| 9 | IsComputeForHedge | smallint | YES | - | High | Whether included in hedge calculations |
| 10 | RootHedgeServerID | int | YES | - | High | Hedge server of root position |
| 11 | HedgeServerID | int | YES | - | High | Hedge server of this position |
| 12 | TreeID | bigint | YES | - | High | Copy-trade tree identifier |
| 13 | IsMirrorActive | tinyint | YES | - | High | Mirror state (0=paused, 1=active) |
| 14 | IsFundCopy | int | YES | - | High | CopyFund vs CopyTrader (1=CopyFund, 0=CopyTrader) |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Position record |
| MirrorID | Trade.MirrorTbl | Implicit | Copy-trade mirror |
| CID | Customer tables | Implicit | Customer |
| ParentPositionID | Trade.PositionTbl | Implicit | Parent position in tree |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTreeNodesByParentPositionAndTreeId | @Position (local variable) | Local variable | Tree traversal result container |
| Trade.GetTreeNodesByParentPositionAndTreeIdTest | @Position (local variable) | Local variable | Test procedure tree result container |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentPositionAndTreeId | Stored Procedure | Local variable @Position |
| Trade.GetTreeNodesByParentPositionAndTreeIdTest | Stored Procedure | Local variable @Position |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_PositionID | NC | PositionID ASC | - | - | Active |

### 7.2 Constraints

None. Memory-optimized with MEMORY_OPTIMIZED = ON.

---

## 8. Sample Queries

### 8.1 Declare and Use in Tree Traversal

```sql
-- Inside Trade.GetTreeNodesByParentPositionAndTreeId (conceptual)
DECLARE @Position Trade.GetTreeNodesByParentPositionAndTreeId_MOT;
INSERT INTO @Position (Level, CID, PositionID, MirrorID, ParentPositionID, Units, Amount, ...)
SELECT ... FROM ...; -- Tree traversal logic populates
-- Subsequent logic reads from @Position
```

### 8.2 Query by PositionID (Uses IX_PositionID)

```sql
DECLARE @Position Trade.GetTreeNodesByParentPositionAndTreeId_MOT;
-- After population...
SELECT * FROM @Position WHERE PositionID = 123456789;
```

### 8.3 Filter Active Mirrors Only

```sql
DECLARE @Position Trade.GetTreeNodesByParentPositionAndTreeId_MOT;
-- After population...
SELECT * FROM @Position WHERE IsMirrorActive = 1 AND Level > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentPositionAndTreeId_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.GetTreeNodesByParentPositionAndTreeId_MOT.sql*
