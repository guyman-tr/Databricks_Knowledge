# Hedge.GetStrategyGroupsAndHedgeServerID

> Returns all strategy groups with their associated hedge server assignment, enabling the hedge engine to route customer positions belonging to different trading strategies to the correct hedge server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full strategy group to hedge server mapping |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetStrategyGroupsAndHedgeServerID` loads the routing table that maps eToro trading strategy groups to hedge servers. eToro's customer trading accounts are grouped by trading strategy (copy trading, manual trading, etc.) and different strategy groups may be assigned to different hedge servers for isolation, risk management, or operational reasons.

The LEFT JOIN design is intentional: all strategy groups are returned, even those not yet assigned to a hedge server (HedgeServerID will be NULL for unassigned groups). This allows the hedge engine to have a complete view of all existing strategy groups while identifying which ones are active (have a server) vs inactive (no server assignment).

`StrategyGroupName` is returned for readability in logs and monitoring. The hedge engine's primary use is the (StrategyGroupName, HedgeServerID) pair - when a customer position arrives with a given strategy group, the engine looks up which HedgeServerID should process it.

Data flows as follows: on startup, the hedge engine calls this procedure to build its strategy-to-server routing dictionary. When processing a customer position, the engine reads the position's StrategyGroup, looks up the corresponding HedgeServerID in the dictionary, and routes the position to that server for hedge computation. Positions belonging to strategy groups with no HedgeServerID (NULL) may be excluded from hedge computation or handled by a default server.

---

## 2. Business Logic

### 2.1 All Strategy Groups with Optional Server Assignment (LEFT JOIN)

**What**: LEFT JOIN from Dictionary.StrategyGroups to Trade.HedgeServer on StrategyGroupID = StrategyGroup. All strategy groups are returned; HedgeServerID is NULL for unassigned groups.

**Columns/Parameters Involved**: `StrategyGroupName`, `HedgeServerID`, `StrategyGroupID`, `StrategyGroup` (FK col in Trade.HedgeServer)

**Rules**:
- Base table: Dictionary.StrategyGroups (SG) - the complete catalog of trading strategy groups
- LEFT JOIN Trade.HedgeServer (THS) ON SG.StrategyGroupID = THS.StrategyGroup: one hedge server can be assigned to one strategy group; a strategy group may have no server
- LEFT JOIN ensures unassigned strategy groups appear with HedgeServerID=NULL (not dropped from results)
- No ORDER BY, no WHERE clause: full mapping returned in natural join order
- Both tables use NOLOCK: avoids blocking on startup configuration reads

**Diagram**:
```
Dictionary.StrategyGroups:        Trade.HedgeServer:
  StrategyGroupID=1, Name='Copy'   HedgeServerID=1, StrategyGroup=1
  StrategyGroupID=2, Name='Manual' HedgeServerID=2, StrategyGroup=2
  StrategyGroupID=3, Name='Test'   (no server for group 3)

LEFT JOIN result:
  StrategyGroupName='Copy',   HedgeServerID=1  -> route to server 1
  StrategyGroupName='Manual', HedgeServerID=2  -> route to server 2
  StrategyGroupName='Test',   HedgeServerID=NULL -> no hedge server assigned
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyGroupName | varchar | NO | - | VERIFIED | Human-readable name of the trading strategy group (e.g., 'Copy Trading', 'Manual Trading'). From Dictionary.StrategyGroups. Used for logging, monitoring, and routing rule identification. |
| 2 | HedgeServerID | int | YES | - | VERIFIED | The hedge server assigned to process positions from this strategy group. NULL if no hedge server is assigned. From Trade.HedgeServer via LEFT JOIN. The engine uses this to route incoming customer positions to the correct server for hedge computation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SG.StrategyGroupName | Dictionary.StrategyGroups | SELECT (base) | Source of all strategy group names and IDs. |
| THS.HedgeServerID | Trade.HedgeServer | LEFT JOIN | Provides the hedge server assignment for each strategy group. NULL for unassigned groups. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to build the strategy group to hedge server routing dictionary. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetStrategyGroupsAndHedgeServerID (procedure)
├── Dictionary.StrategyGroups (table) [cross-schema]
└── Trade.HedgeServer (table) [cross-schema]
      - Also read by: Hedge.GetServerCircuitBreakerThresholds
      - Also read by: Hedge.GetStrategyExecutionFactorConfiguration
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.StrategyGroups | Table | Base of LEFT JOIN - complete catalog of trading strategy groups |
| Trade.HedgeServer | Table | LEFT JOIN target - provides hedge server assignment for each strategy group |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - builds startup routing dictionary mapping strategy groups to hedge server IDs |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Dictionary.StrategyGroups has a PK on StrategyGroupID. Trade.HedgeServer has a PK on HedgeServerID and likely an index on StrategyGroup (FK column). The LEFT JOIN is straightforward. Both tables use NOLOCK.

### 7.2 Constraints

N/A for Stored Procedure. The LEFT JOIN design is a key architectural choice: unlike the other Trade.HedgeServer reader procedures (GetServerCircuitBreakerThresholds, GetStrategyExecutionFactorConfiguration) which start from Trade.HedgeServer, this procedure starts from Dictionary.StrategyGroups. This ensures all strategy groups are visible, even those awaiting server assignment. The hedge engine must handle NULL HedgeServerID rows gracefully (skip, log, or assign to a default).

---

## 8. Sample Queries

### 8.1 Load full strategy group to hedge server mapping
```sql
EXEC [Hedge].[GetStrategyGroupsAndHedgeServerID];
```

### 8.2 Direct equivalent query
```sql
SELECT  SG.StrategyGroupName,
        THS.HedgeServerID
FROM    [Dictionary].[StrategyGroups] SG WITH (NOLOCK)
LEFT JOIN [Trade].[HedgeServer] THS WITH (NOLOCK)
        ON SG.StrategyGroupID = THS.StrategyGroup
ORDER BY SG.StrategyGroupName;
```

### 8.3 Find strategy groups not yet assigned to a hedge server
```sql
SELECT  SG.StrategyGroupName,
        SG.StrategyGroupID
FROM    [Dictionary].[StrategyGroups] SG WITH (NOLOCK)
LEFT JOIN [Trade].[HedgeServer] THS WITH (NOLOCK)
        ON SG.StrategyGroupID = THS.StrategyGroup
WHERE   THS.HedgeServerID IS NULL
ORDER BY SG.StrategyGroupName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetStrategyGroupsAndHedgeServerID | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetStrategyGroupsAndHedgeServerID.sql*
