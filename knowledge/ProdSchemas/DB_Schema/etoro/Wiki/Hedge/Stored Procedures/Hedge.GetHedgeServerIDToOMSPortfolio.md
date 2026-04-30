# Hedge.GetHedgeServerIDToOMSPortfolio

> Lookup procedure: returns the OMS portfolio name(s) mapped to a hedge server. Pass a HedgeServerID to get one mapping, or omit it (NULL) to get all mappings. Joins HedgeServerIDToOMSPortfolio with Dictionary.OMSStrategyType to resolve the strategy type name.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @hedgeServerID INT = NULL - optional filter (NULL = return all) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHedgeServerIDToOMSPortfolio provides the mapping between a hedge server and its OMS (Order Management System) portfolio, enriched with the human-readable strategy type name. It is used to determine which OMS portfolio a given hedge server sends orders to, and what execution strategy type (e.g., IM = Institutional Market, DMA = Direct Market Access) governs those orders.

The @hedgeServerID parameter is optional (defaults to NULL). When NULL, all rows from HedgeServerIDToOMSPortfolio are returned - useful for full configuration audits. When a specific ID is provided, only that server's mapping is returned. The NULL-safe filter `WHERE HedgeServerID = ISNULL(@hedgeServerID, HedgeServerID)` achieves this without a separate code path.

The underlying table (Hedge.HedgeServerIDToOMSPortfolio) was observed to be empty in the current environment, suggesting this feature is either not yet deployed or is used only in specific trading configurations (e.g., DMA/IM environments).

Called by HedgeAlertService (external) and configuration tooling; no SQL procedure callers within the Hedge schema.

---

## 2. Business Logic

### 2.1 Optional HedgeServerID Filter

**What**: The procedure accepts an optional server ID. If not provided, all mappings are returned.

**Columns/Parameters Involved**: `@hedgeServerID`, `Hedge.HedgeServerIDToOMSPortfolio.HedgeServerID`

**Rules**:
- Default: `@hedgeServerID INT = NULL`.
- Filter: `WHERE HedgeServerID = ISNULL(@hedgeServerID, HedgeServerID)`.
- `ISNULL(@hedgeServerID, HedgeServerID)` evaluates to the column's own value when param is NULL, so the WHERE clause is always true (no filtering) - effectively a full table scan when called without arguments.
- When @hedgeServerID is supplied, only the matching row(s) are returned.

### 2.2 OMS Strategy Type Name Resolution

**What**: OMSStrategyTypeID (integer) is resolved to a human-readable name via Dictionary.OMSStrategyType.

**Columns/Parameters Involved**: `OMSStrategyTypeID`, `Dictionary.OMSStrategyType.ID`, `Dictionary.OMSStrategyType.Name AS OMSStrategyType`

**Rules**:
- INNER JOIN on `HSTOP.OMSStrategyTypeID = OST.ID` - a NULL OMSStrategyTypeID would exclude the row.
- Known values: 1 = IM (Institutional Market), 2 = DMA (Direct Market Access).
- IM means eToro aggregates customer exposure into a single institutional market order. DMA means orders are sent directly to market on behalf of customer.
- The join is aliased `OST`; the returned column is `OST.Name AS OMSStrategyType`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @hedgeServerID | int | YES | NULL | CODE-BACKED | Optional filter: HedgeServerID to look up. NULL returns all hedge server -> OMS portfolio mappings. Used in ISNULL() filter pattern to handle all-or-one behavior. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server identifier. FK to Hedge.HedgeServerToLiquidityAccount.HedgeServerID. Groups all liquidity accounts for that server. |
| 3 | PortfolioName | nvarchar | YES | - | CODE-BACKED | The OMS portfolio name assigned to this hedge server. Identifies the portfolio in the OMS that receives orders from this hedge server instance. |
| 4 | OMSStrategyType | nvarchar | NO | - | CODE-BACKED | Human-readable OMS strategy type resolved from Dictionary.OMSStrategyType. Known values: 'IM' (Institutional Market) or 'DMA' (Direct Market Access). Determines how hedge orders are routed through the OMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID filter | Hedge.HedgeServerIDToOMSPortfolio | Lookup / Read | Main config table. All rows or filtered by @hedgeServerID. |
| OMSStrategyTypeID join | Dictionary.OMSStrategyType | Cross-schema Lookup | Resolves integer type ID to strategy name (IM/DMA). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @hedgeServerID | Caller | Configuration read at startup or on-demand to identify OMS routing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHedgeServerIDToOMSPortfolio (procedure)
├── Hedge.HedgeServerIDToOMSPortfolio (table)
└── Dictionary.OMSStrategyType (table) [cross-schema lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeServerIDToOMSPortfolio | Table | Main data source: HedgeServerID, PortfolioName, OMSStrategyTypeID. Filtered by @hedgeServerID or all rows. |
| Dictionary.OMSStrategyType | Table | Cross-schema: INNER JOIN on ID = OMSStrategyTypeID; returns Name as OMSStrategyType. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Reads hedge server -> OMS portfolio mapping for routing configuration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No temp tables. Simple two-table join with optional WHERE filter. No OPTION(RECOMPILE). Lightweight read-only procedure.

---

## 8. Sample Queries

### 8.1 Get all hedge server -> OMS portfolio mappings

```sql
EXEC Hedge.GetHedgeServerIDToOMSPortfolio;
-- or explicitly:
EXEC Hedge.GetHedgeServerIDToOMSPortfolio @hedgeServerID = NULL;
```

### 8.2 Get OMS portfolio for a specific hedge server

```sql
EXEC Hedge.GetHedgeServerIDToOMSPortfolio @hedgeServerID = 1;
```

### 8.3 Check OMS strategy types available

```sql
SELECT ID, Name FROM Dictionary.OMSStrategyType ORDER BY ID;
-- Expected: 1=IM, 2=DMA
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | OMS portfolio mapping for IM/DMA hedge routing configurations. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHedgeServerIDToOMSPortfolio | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHedgeServerIDToOMSPortfolio.sql*
