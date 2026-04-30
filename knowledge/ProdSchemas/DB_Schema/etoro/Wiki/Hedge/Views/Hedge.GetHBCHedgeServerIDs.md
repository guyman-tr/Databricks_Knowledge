# Hedge.GetHBCHedgeServerIDs

> Returns the HedgeServerIDs of all hedge servers configured to use the HBC (Hedge-By-Client) strategy (HedgeStrategyModeID=2). Currently returns 0 rows - no servers are actively using HBC mode.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | View |
| **Row Count** | 0 (no active HBC servers) |

---

## 1. Business Meaning

Hedge.GetHBCHedgeServerIDs identifies which hedge servers operate in HBC (Hedge-By-Client) mode. HBC is a hedging strategy where individual client positions are hedged separately at the LP, as opposed to the standard aggregate netting approach (where all client positions are netted and only the net exposure is hedged).

The four hedge strategy modes (from Dictionary.HedgeStrategyMode):
- 0: STRATEGY_FULLY - fully hedge all exposure
- 1: STRATEGY_BOUNDARIES - hedge only when exposure exceeds configured boundaries
- 2: STRATEGY_HBC - Hedge-By-Client (per-client individual hedging)
- 3: STRATEGY_PERIODIC_BOUNDARIES - boundary-based hedging with periodic evaluation

This view is a simple filter returning only HBC server IDs. It enables the hedge system to quickly identify and apply HBC-specific logic (tracked in Hedge.HBCExecutionLog and Hedge.HBCOrderLog) to the correct servers without querying Trade.HedgeServer directly.

Currently returns 0 rows - no hedge servers have HedgeStrategyModeID=2. The HBC infrastructure (tables, procedures) exists but this strategy is not currently activated on any server.

---

## 2. Business Logic

### 2.1 Single-Column Filter View

**Source Table**: `Trade.HedgeServer`

**Filter**: `WHERE HedgeStrategyModeID = 2` (STRATEGY_HBC)

**Output**: Just `HedgeServerID` - the minimal identifier needed for the hedge system to route HBC-specific logic.

The simplicity is intentional: callers use this view in IN or JOIN predicates to test whether a given HedgeServerID uses HBC mode.

```sql
-- Typical usage pattern by callers:
WHERE hs.HedgeServerID IN (SELECT HedgeServerID FROM Hedge.GetHBCHedgeServerIDs)
```

---

## 3. Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Trade.HedgeServer | ID of a hedge server running in HBC (Hedge-By-Client) mode |

---

## 4. Data Overview

0 rows currently. When HBC mode is activated on a server, that server's HedgeServerID appears here.

---

## 5. Relationships

### 5.1 Source Tables

| Table | Join Type | Condition |
|-------|-----------|-----------|
| Trade.HedgeServer | Base (filtered) | WHERE HedgeStrategyModeID = 2 |

### 5.2 Consumed By

No stored procedures or views in the Hedge schema were found to reference this view directly. Application code likely uses it directly to identify HBC servers.

---

## 6. Dependencies

```
Hedge.GetHBCHedgeServerIDs (view)
+-- Trade.HedgeServer (table) [source, filtered to HedgeStrategyModeID=2]
+-- Dictionary.HedgeStrategyMode (table) [defines mode 2 = STRATEGY_HBC]
```

---

## 7. Sample Queries

### 7.1 Check if a specific server is HBC
```sql
SELECT CASE
    WHEN EXISTS (
        SELECT 1 FROM [Hedge].[GetHBCHedgeServerIDs] WITH (NOLOCK)
        WHERE HedgeServerID = 3
    )
    THEN 'HBC' ELSE 'Not HBC'
END AS ServerMode;
```

### 7.2 Join to get full server details for HBC servers (when populated)
```sql
SELECT  hs.HedgeServerID,
        hbc.HedgeServerID AS IsHBC
FROM    [Trade].[HedgeServer] hs WITH (NOLOCK)
INNER JOIN [Hedge].[GetHBCHedgeServerIDs] hbc WITH (NOLOCK)
        ON hs.HedgeServerID = hbc.HedgeServerID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this view.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11 (View phases)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetHBCHedgeServerIDs | Type: View | Source: etoro/etoro/Hedge/Views/Hedge.GetHBCHedgeServerIDs.sql*
