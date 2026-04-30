# Trade.GetUsersUnrealizedEquityData

> Returns unrealized equity per CID+MirrorID pair using a TVP input - routes non-copy (MirrorID=0) queries to Trade.SynRealPortfolioEquitySnapshotTbl (always Real DB) and copy (MirrorID!=0) queries to the environment-appropriate Pnl DB.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cidToMirrorId TVP - Trade.CidToMirrorId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUsersUnrealizedEquityData` retrieves current unrealized equity for a batch of CID+MirrorID pairs. It is designed around eToro's multi-database P&L architecture where unrealized equity for direct (non-copy) positions is always sourced from the Real database via a synonym, while copy position equity comes from the Pnl database matching the current environment (Real or Demo).

The dual-source design reflects two different P&L tracking systems:
- **MirrorID=0**: Direct/manual positions - equity comes from `Trade.SynRealPortfolioEquitySnapshotTbl` (a synonym pointing to the Real Pnl DB). The comment states this should ALWAYS be from Real DB, even in Demo environments.
- **MirrorID!=0**: Copy positions - equity comes from `[Pnl].[Trade].[PortfolioEquitySnapshotTbl]` (the linked server or cross-DB reference that follows the current environment).

The TVP is materialized to a temp table with a clustered index (same performance pattern as GetUserRegulationsByBatch) for efficient joins.

---

## 2. Business Logic

### 2.1 TVP Materialization

**What**: TVP materialized to temp table with clustered index for join performance.

**Rules**:
- `SELECT CID, MirrorID INTO #CidToMirrorId FROM @cidToMirrorId`
- `CREATE CLUSTERED INDEX IX_CID_MirrorID ON #CidToMirrorId (CID, MirrorID)`
- Standard performance pattern for TVP joins in this schema

### 2.2 Split by MirrorID=0 vs !=0

**What**: Routes to different Pnl data sources based on whether the row represents a direct or copy position.

**Rules**:
- **Branch 1 (MirrorID=0)**: `Trade.SynRealPortfolioEquitySnapshotTbl` - always the Real Pnl DB synonym regardless of environment. Comment: "Should be always [Pnl REAL] (even if SP is running in DEMO)"
- **Branch 2 (MirrorID!=0)**: `[Pnl].[Trade].[PortfolioEquitySnapshotTbl]` - the environment-specific Pnl DB. Comment: "Should be [Pnl REAL] \ [Pnl DEMO] -> same as where SP is running"
- UNION ALL combines both sets

### 2.3 No IsRealDB Gate

**What**: Unlike other SPs in this batch, there is no IsRealDB feature flag check.

**Rules**:
- The routing is always done the same way (via synonym for MirrorID=0, via linked Pnl DB for MirrorID!=0)
- The Demo vs Real split is handled implicitly by the synonym/linked server configuration

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cidToMirrorId | Trade.CidToMirrorId READONLY | NO | - | CODE-BACKED | TVP of CID+MirrorID pairs to retrieve unrealized equity for. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 3 | MirrorID | INT | NO | - | CODE-BACKED | Mirror ID. 0 = direct/manual position equity; >0 = copy position equity. |
| 4 | UnRealizedEquity | MONEY | YES | - | CODE-BACKED | Unrealized P&L in dollars from PortfolioEquitySnapshotTbl. From the appropriate Pnl DB based on MirrorID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | Trade.CidToMirrorId | User Defined Type | Input TVP type |
| MirrorID=0 branch | Trade.SynRealPortfolioEquitySnapshotTbl | INNER JOIN | Synonym to Real Pnl DB - always real regardless of environment |
| MirrorID!=0 branch | [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | INNER JOIN | Environment-appropriate Pnl DB (linked server / cross-DB) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (equity calculation) | @cidToMirrorId TVP | EXEC caller | Batch unrealized equity retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsersUnrealizedEquityData (procedure)
+-- Trade.CidToMirrorId (UDT - TVP type)
+-- Trade.SynRealPortfolioEquitySnapshotTbl (synonym -> Real Pnl DB)
+-- [Pnl].[Trade].[PortfolioEquitySnapshotTbl] (linked server / cross-DB)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidToMirrorId | User Defined Type | Input TVP type |
| Trade.SynRealPortfolioEquitySnapshotTbl | Synonym | Real DB unrealized equity for direct positions |
| [Pnl].[Trade].[PortfolioEquitySnapshotTbl] | Cross-DB Table | Environment-specific unrealized equity for copy positions |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #CidToMirrorId clustered index | Performance | TVP materialized for efficient join |
| MirrorID = 0 | Route filter | Direct positions always use Real Pnl synonym |
| MirrorID <> 0 | Route filter | Copy positions use environment Pnl DB |

---

## 8. Sample Queries

### 8.1 Get unrealized equity for a batch of CID+MirrorID pairs
```sql
DECLARE @pairs Trade.CidToMirrorId;
INSERT INTO @pairs VALUES (123456, 0), (123456, 99887766);
EXEC Trade.GetUsersUnrealizedEquityData @cidToMirrorId = @pairs;
```

### 8.2 Understand the routing split
```sql
-- MirrorID=0 -> always Real Pnl DB (via synonym):
SELECT CID, MirrorID, UnRealizedEquity
FROM Trade.SynRealPortfolioEquitySnapshotTbl WITH (NOLOCK)
WHERE CID = 123456 AND MirrorID = 0;

-- MirrorID!=0 -> environment Pnl DB:
SELECT CID, MirrorID, UnRealizedEquity
FROM [Pnl].[Trade].[PortfolioEquitySnapshotTbl] WITH (NOLOCK)
WHERE CID = 123456 AND MirrorID != 0;
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Pnl DB routing infrastructure not covered in the TRAD/DB Confluence folder.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUsersUnrealizedEquityData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsersUnrealizedEquityData.sql*
