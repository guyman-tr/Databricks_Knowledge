# Hedge.HedgeServerIDToOMSPortfolio

> OMS portfolio routing table: maps each hedge server to its OMS portfolio name and execution strategy (IM or DMA); one row per hedge server; empty in this environment (OMS hedging not active).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | HedgeServerID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on HedgeServerID) |

---

## 1. Business Meaning

Hedge.HedgeServerIDToOMSPortfolio maps a hedge server to its **OMS (Order Management System) portfolio** configuration. When a hedge server is connected to an OMS-based liquidity provider (such as OMS UAT connections observed in Hedge.FIXConnections), this table provides two pieces of routing information:
1. **PortfolioName**: The identifier used in the OMS system to identify this hedge server's order flow (e.g., "ETORO_PORTFOLIO_1").
2. **OMSStrategyTypeID**: The execution strategy: IM (Internal Matching = orders matched internally before going external) or DMA (Direct Market Access = orders sent directly to market).

The PK is HedgeServerID alone (not composite), meaning each hedge server has at most one OMS portfolio configuration. This is a one-to-one mapping.

The table is **empty in this environment** - OMS portfolio routing may be configured in production only, or this feature may be in staging/testing.

The single reader `Hedge.GetHedgeServerIDToOMSPortfolio` is called with an optional @hedgeServerID parameter (NULL = return all). It joins to Dictionary.OMSStrategyType to return the human-readable strategy name ("IM" or "DMA") rather than the raw ID.

---

## 2. Business Logic

### 2.1 OMS Portfolio Routing

**What**: Assigns a hedge server to a named OMS portfolio with a specific execution strategy.

**Columns/Parameters Involved**: `HedgeServerID`, `PortfolioName`, `OMSStrategyTypeID`

**Rules**:
- Each HedgeServerID can have only one OMS portfolio (PK on HedgeServerID alone).
- PortfolioName is the OMS-side identifier for this server's order flow - used when routing orders through the OMS to identify which portfolio they belong to.
- OMSStrategyTypeID: 1=IM (Internal Matching), 2=DMA (Direct Market Access).
  - IM: Orders first matched internally; only the unmatched remainder goes to the LP. Reduces market impact.
  - DMA: Orders bypass internal matching and go directly to the LP for immediate execution.
- Only hedge servers that participate in OMS-based hedging (e.g., ScheduleID="OMS" in FIXConnections) need entries in this table.
- Not all hedge servers need OMS portfolio configuration - servers using direct FIX connections without OMS routing (e.g., ZBFX direct connections) do not require entries here.

---

## 3. Data Overview

0 rows | Table is empty in this environment

*In production, expected rows would look like:*

| HedgeServerID | PortfolioName | OMSStrategyTypeID |
|---|---|---|
| (example) | "ETORO_PORTFOLIO_IMx" | 1 (IM) |
| (example) | "ETORO_DMA_PORTFOLIO" | 2 (DMA) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer(HedgeServerID). CLUSTERED PK. One-to-one mapping: each hedge server has at most one OMS portfolio. |
| 2 | PortfolioName | varchar(50) | NO | - | CODE-BACKED | The portfolio identifier in the OMS system for this hedge server's order flow. Used by the OMS to route and attribute orders. Max 50 chars - sufficient for OMS portfolio naming conventions. |
| 3 | OMSStrategyTypeID | int | NO | - | CODE-BACKED | FK to Dictionary.OMSStrategyType. Execution strategy: 1=IM (Internal Matching - orders matched internally first), 2=DMA (Direct Market Access - orders go directly to LP). Determines how OMS-routed orders are executed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (WITH CHECK) | FK_HedgeServerIDToOMSPortfolio_HedgeServer |
| OMSStrategyTypeID | Dictionary.OMSStrategyType | FK (WITH CHECK) | FK_HedgeServerIDToOMSPortfolio_OMSStrategyTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetHedgeServerIDToOMSPortfolio | @hedgeServerID | Reader | Returns OMS portfolio config + strategy name for a hedge server (or all servers) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeServerIDToOMSPortfolio (table)
  - FK: Trade.HedgeServer (HedgeServerID)
  - FK: Dictionary.OMSStrategyType (OMSStrategyTypeID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeServer | Table | FK target for HedgeServerID |
| Dictionary.OMSStrategyType | Table | FK target for OMSStrategyTypeID (1=IM, 2=DMA) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetHedgeServerIDToOMSPortfolio | Procedure | Reader: returns portfolio config joined with strategy type name |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeServerIDToOMSPortfolio | CLUSTERED PK | HedgeServerID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeServerIDToOMSPortfolio | PRIMARY KEY (CLUSTERED) | HedgeServerID - one OMS portfolio per server |
| FK_HedgeServerIDToOMSPortfolio_HedgeServer | FOREIGN KEY (WITH CHECK) | HedgeServerID -> Trade.HedgeServer |
| FK_HedgeServerIDToOMSPortfolio_OMSStrategyTypeID | FOREIGN KEY (WITH CHECK) | OMSStrategyTypeID -> Dictionary.OMSStrategyType |

---

## 8. Sample Queries

### 8.1 All OMS portfolio configurations
```sql
SELECT h.HedgeServerID, h.PortfolioName,
       s.Name AS OMSStrategyType
FROM Hedge.HedgeServerIDToOMSPortfolio h WITH (NOLOCK)
JOIN Dictionary.OMSStrategyType s WITH (NOLOCK) ON s.ID = h.OMSStrategyTypeID
ORDER BY h.HedgeServerID;
```

### 8.2 Get OMS config for a specific server
```sql
EXEC Hedge.GetHedgeServerIDToOMSPortfolio @hedgeServerID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.HedgeServerIDToOMSPortfolio.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeServerIDToOMSPortfolio | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.HedgeServerIDToOMSPortfolio.sql*
