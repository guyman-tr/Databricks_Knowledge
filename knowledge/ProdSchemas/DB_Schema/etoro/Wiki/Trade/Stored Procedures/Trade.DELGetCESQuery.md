# Trade.DELGetCESQuery

> Retrieves exposure summary (buy/sell/hedged/requested lots) per instrument per hedge server for a specific provider from the Trade.GetExposuresForAllHedgeServers view.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID (filter parameter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **thin wrapper** around the Trade.GetExposuresForAllHedgeServers view, filtering by a specific liquidity provider. It returns the Current Exposure Summary (CES) showing net buy/sell lot counts, hedged amounts, and pending hedge requests for each instrument on each hedge server belonging to the specified provider.

The CES data is used by the hedge execution system and risk monitoring tools to understand the current exposure state for a provider's instruments. The difference between OpenedBuy/OpenedSell and Hedged reveals unhedged exposure that may require additional hedge orders.

The "DEL" prefix in the name suggests this is a legacy or deprecated procedure (possibly from a "delete" or "delivery" context), but it functionally serves as a read-only exposure query. It delegates all aggregation logic to the Trade.GetExposuresForAllHedgeServers view, which combines position data, active hedges, and pending hedge requests via FULL OUTER JOINs.

---

## 2. Business Logic

### 2.1 Provider-Filtered Exposure Query

**What**: Returns exposure data for a single liquidity provider.

**Columns/Parameters Involved**: `@ProviderID`, `HedgeServerID`, `InstrumentID`, `OpenedBuy`, `OpenedSell`, `Hedged`, `Requested`

**Rules**:
- Queries Trade.GetExposuresForAllHedgeServers (a view aggregating positions, hedges, and pending requests)
- Filters WHERE ProviderID = @ProviderID (default 1)
- Returns one row per HedgeServerID + InstrumentID combination
- OpenedBuy/OpenedSell: aggregate lot counts of open positions (buy and sell directions)
- Hedged: aggregate lot counts of existing hedge positions
- Requested: aggregate lot counts of pending hedge requests (time-bounded by HedgeServer.ConsiderOpenRequestsSec)
- Unhedged exposure = (OpenedBuy - OpenedSell) - Hedged - Requested (computed by the consumer, not this procedure)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INT | NO | 1 | CODE-BACKED | Liquidity provider ID to filter exposures. Default 1 (primary provider). Filters the Trade.GetExposuresForAllHedgeServers view's ProviderID column, which comes from Trade.HedgeServer.ProviderID. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server identifier. Each hedge server manages a subset of instruments for the provider. |
| R2 | InstrumentID | INT | NO | - | CODE-BACKED | Tradeable instrument identifier. FK to Dictionary.Instrument. |
| R3 | OpenedBuy | DECIMAL | YES | - | CODE-BACKED | Total aggregate lot count of open BUY positions for this instrument on this hedge server. |
| R4 | OpenedSell | DECIMAL | YES | - | CODE-BACKED | Total aggregate lot count of open SELL positions for this instrument on this hedge server. |
| R5 | Hedged | DECIMAL | YES | - | CODE-BACKED | Total lot count of existing hedge positions covering this instrument. |
| R6 | Requested | DECIMAL | YES | - | CODE-BACKED | Total lot count of pending (in-flight) hedge requests for this instrument. Time-bounded by HedgeServer.ConsiderOpenRequestsSec to exclude stale requests. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT FROM) | Trade.GetExposuresForAllHedgeServers | View dependency | Reads all exposure data from this aggregation view |
| @ProviderID | Trade.HedgeServer.ProviderID | Implicit FK | Filters by liquidity provider via the view's ProviderID column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (External systems / ad-hoc) | N/A | Consumer | Likely called by hedge management tools or monitoring dashboards to check current provider exposure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DELGetCESQuery (procedure)
+-- Trade.GetExposuresForAllHedgeServers (view)
      +-- Trade.vExposuresForAllHedgeServers (view)
      |     +-- Trade.PositionTbl (table)
      |     +-- Trade.HedgeServer (table)
      +-- Trade.Hedge (table)
      +-- Trade.HedgeRequest (table)
      +-- Trade.HedgeServer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExposuresForAllHedgeServers | View | SELECT FROM - provides all aggregated exposure data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | No stored procedures call this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: This procedure does not use WITH (NOLOCK) on its query. The underlying view handles locking semantics.

---

## 8. Sample Queries

### 8.1 Get exposure for default provider

```sql
EXEC Trade.DELGetCESQuery;
```

### 8.2 Get exposure for a specific provider

```sql
EXEC Trade.DELGetCESQuery @ProviderID = 2;
```

### 8.3 Direct query of the underlying view with additional filtering

```sql
SELECT  HedgeServerID, InstrumentID, OpenedBuy, OpenedSell, Hedged, Requested,
        (ISNULL(OpenedBuy, 0) - ISNULL(OpenedSell, 0) - ISNULL(Hedged, 0) - ISNULL(Requested, 0)) AS UnhedgedExposure
FROM    Trade.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE   ProviderID = 1
        AND (ISNULL(OpenedBuy, 0) - ISNULL(OpenedSell, 0) - ISNULL(Hedged, 0) - ISNULL(Requested, 0)) <> 0
ORDER BY ABS(ISNULL(OpenedBuy, 0) - ISNULL(OpenedSell, 0) - ISNULL(Hedged, 0) - ISNULL(Requested, 0)) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DELGetCESQuery | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DELGetCESQuery.sql*
