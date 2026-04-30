# Dictionary.StrategyGroups

> Classifies hedge server execution strategies into named groups for configuration and monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StrategyGroupID (smallint, IDENTITY, PK) |
| **Row Count** | 3 |
| **Indexes** | 1 (clustered composite PK) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.StrategyGroups is a lookup table that categorizes hedge server execution strategies into named groups. Each hedge server can be assigned to a strategy group, enabling grouped configuration and monitoring of hedging behavior.

### Why It Exists
The eToro platform routes hedge operations through multiple hedge servers, each potentially running different execution strategies. Strategy groups allow grouping these servers for consolidated management — for example, all servers running a particular hedging algorithm can be queried or configured as a unit.

### How It Works
The `StrategyGroupID` is referenced by `Trade.HedgeServer.StrategyGroup` (and its history counterpart). The procedure `Hedge.GetStrategyGroupsAndHedgeServerID` LEFT JOINs strategy groups to hedge servers, returning the mapping of group names to server IDs — this is used by the hedge infrastructure to discover which servers belong to which strategy group.

---

## 2. Business Logic

### Value Map (Complete — 3 rows)

| StrategyGroupID | StrategyGroupName | Business Meaning |
|-----------------|-------------------|------------------|
| 1 | stam | Placeholder/default group (Hebrew for "just/generic") |
| 2 | stam2 | Second placeholder group |
| 3 | stam3 | Third placeholder group |

### Observations
- All three values are placeholder names ("stam" is Hebrew slang meaning "just" or "generic"), suggesting this feature was scaffolded but the business-meaningful group names were never populated in production.
- The table uses IDENTITY(1,1), so new groups get auto-incrementing IDs.
- The composite PK includes both `StrategyGroupID` AND `StrategyGroupName`, which is unusual — it means the combination must be unique, though the IDENTITY on StrategyGroupID already guarantees uniqueness on its own.

---

## 3. Data Overview

| StrategyGroupID | StrategyGroupName | Typical Use |
|-----------------|-------------------|-------------|
| 1 | stam | Default/unclassified hedge servers |
| 2 | stam2 | Second group (placeholder) |
| 3 | stam3 | Third group (placeholder) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyGroupID | smallint | NO | IDENTITY(1,1) | HIGH | Auto-incrementing primary key identifying the strategy group. Referenced by `Trade.HedgeServer.StrategyGroup`. Part of composite PK with StrategyGroupName. |
| 2 | StrategyGroupName | varchar(50) | NO | — | MEDIUM | Human-readable name for the strategy group. Currently contains placeholder values ("stam", "stam2", "stam3"). Part of composite PK. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Trade.HedgeServer | StrategyGroup | Implicit FK → StrategyGroupID | Joined in Hedge.GetStrategyGroupsAndHedgeServerID |
| History.HedgeServer | StrategyGroup | Implicit FK → StrategyGroupID | Historical archive of hedge server config |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Hedge.GetStrategyGroupsAndHedgeServerID | SELECT (LEFT JOIN) | Returns strategy group names with their associated hedge server IDs |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Trade.HedgeServer` — stores `StrategyGroup` per hedge server
- `History.HedgeServer` — historical archive

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| pk_StrategyGroups | CLUSTERED PK | StrategyGroupID ASC, StrategyGroupName ASC | Composite PK (unusual — IDENTITY alone would suffice) |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |
| Identity | StrategyGroupID IDENTITY(1,1) |

---

## 8. Sample Queries

```sql
-- Get all strategy groups
SELECT  StrategyGroupID,
        StrategyGroupName
FROM    Dictionary.StrategyGroups WITH (NOLOCK)
ORDER BY StrategyGroupID;

-- Map strategy groups to hedge servers
SELECT  SG.StrategyGroupName,
        THS.HedgeServerID
FROM    Dictionary.StrategyGroups SG WITH (NOLOCK)
LEFT JOIN Trade.HedgeServer THS WITH (NOLOCK)
        ON SG.StrategyGroupID = THS.StrategyGroup;

-- Find hedge servers in a specific strategy group
SELECT  HS.*
FROM    Trade.HedgeServer HS WITH (NOLOCK)
JOIN    Dictionary.StrategyGroups SG WITH (NOLOCK)
        ON HS.StrategyGroup = SG.StrategyGroupID
WHERE   SG.StrategyGroupName = 'stam';
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `StrategyGroups`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.StrategyGroups | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.StrategyGroups.sql*
