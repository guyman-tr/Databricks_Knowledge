# Trade.GetExposuresForAllHedgeServers

> Aggregates net exposure per instrument per hedge server by combining open position lots, active hedge lots, and pending hedge request lots via FULL OUTER JOINs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID + InstrumentID + HedgeServerID (composite) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetExposuresForAllHedgeServers provides a **complete exposure picture** for every instrument on every hedge server by combining three data sources: (1) aggregated open position lot counts from Trade.vExposuresForAllHedgeServers, (2) aggregated hedge lot counts from Trade.Hedge, and (3) recently requested (pending) hedge lot counts from Trade.HedgeRequest. The FULL OUTER JOIN ensures instruments that appear in any source are included, even if they have positions but no hedges or vice versa.

This view is critical for the hedge execution system. The difference between Opened and Hedged represents the **unhedged exposure** that the risk management system needs to cover. The Requested column adds pending hedge requests to prevent over-hedging while requests are in flight. Without this view, the system could not determine how much additional hedging is needed for each instrument.

Data is read-only aggregation. The comment history shows optimization from 2013: originally computed positions inline, then switched to use the pre-aggregated Trade.vExposuresForAllHedgeServers view for performance. Hedge requests are time-bounded using HedgeServer.ConsiderOpenRequestsSec to exclude stale requests.

---

## 2. Business Logic

### 2.1 Exposure Calculation

**What**: Calculates net exposure by combining positions, hedges, and pending requests.

**Columns/Parameters Involved**: `Opened`, `OpenedBuy`, `OpenedSell`, `Hedged`, `Requested`

**Rules**:
- Opened = OpenedBuy - OpenedSell (net position lots, from vExposuresForAllHedgeServers)
- Hedged = SUM of hedge lots (buy=+1, sell=-1) * LotCountDecimal from Trade.Hedge
- Requested = SUM of pending request lots within the ConsiderOpenRequestsSec window
- Unhedged exposure = Opened - Hedged (not a column but the key derived metric)
- ISNULL coalescing ensures zero instead of NULL when a source has no data for an instrument

### 2.2 Hedge Request Time Window

**What**: Only recent hedge requests are included to prevent stale requests from inflating the requested amount.

**Columns/Parameters Involved**: `Requested`, `HedgeServer.ConsiderOpenRequestsSec`

**Rules**:
- Requests are included only if Occurred >= DATEADD(ss, 0 - ConsiderOpenRequestsSec, GETDATE())
- ConsiderOpenRequestsSec is per-hedge-server configuration from Trade.HedgeServer
- This prevents double-hedging when old requests have already been fulfilled

**Diagram**:
```
vExposuresForAllHedgeServers     Trade.Hedge          Trade.HedgeRequest
(pre-aggregated position lots)   (active hedges)      (recent requests only)
    |                                |                      |
    +-- OpenedBuy, OpenedSell       +-- Hedged             +-- Requested
    |                                |                      |
    +======= FULL OUTER JOIN ========+===== FULL OUTER JOIN =+
    |
    = ProviderID, InstrumentID, HedgeServerID
      Opened, OpenedBuy, OpenedSell, Hedged, Requested
```

---

## 3. Data Overview

| ProviderID | InstrumentID | HedgeServerID | Opened | OpenedBuy | OpenedSell | Hedged | Requested | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 5 | 0.004937 | 0.004937 | 0 | 0 | 0 | Small net long position on instrument 1/server 5, no hedging applied |
| 1 | 1 | 8 | -0.025 | 0 | 0.025 | 0 | 0 | Net short position on instrument 1/server 8, unhedged |
| 1 | 2 | 8 | 0 | 0 | 0 | 0 | 0 | No open positions or hedges for instrument 2 on server 8 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | YES | - | CODE-BACKED | Execution provider ID. Coalesced from positions, hedges, or requests - whichever is non-null first. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument. Coalesced from positions, hedges, or requests. FK to Trade.Instrument. |
| 3 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this exposure. Coalesced from positions, hedges, or requests. FK to Trade.HedgeServer. |
| 4 | Opened | decimal | YES | 0 | CODE-BACKED | Computed: OpenedBuy - OpenedSell. Net open position lots (positive = net long, negative = net short). |
| 5 | OpenedBuy | decimal | YES | 0 | CODE-BACKED | Total buy-side lot count from open positions. From Trade.vExposuresForAllHedgeServers. |
| 6 | OpenedSell | decimal | YES | 0 | CODE-BACKED | Total sell-side lot count from open positions. From Trade.vExposuresForAllHedgeServers. |
| 7 | Hedged | decimal | YES | 0 | CODE-BACKED | Net hedge lot count (buy=+1, sell=-1 * LotCountDecimal). Aggregated from Trade.Hedge. |
| 8 | Requested | decimal | YES | 0 | CODE-BACKED | Net pending hedge request lots within the time window. Aggregated from Trade.HedgeRequest filtered by ConsiderOpenRequestsSec. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | Trade.vExposuresForAllHedgeServers | Subquery | Pre-aggregated open position lots |
| (hedges) | Trade.Hedge | Subquery | Active hedge records |
| (requests) | Trade.HedgeRequest | Subquery | Pending hedge requests |
| HedgeServerID | Trade.HedgeServer | JOIN | ConsiderOpenRequestsSec for request time window |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetCESQuery | SELECT | Procedure reader | CES (Centralized Exposure Service) query |
| Trade.DELGetCESQuery | SELECT | Procedure reader | Deleted/legacy CES query variant |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExposuresForAllHedgeServers (view)
+-- Trade.vExposuresForAllHedgeServers (view)
|     +-- Trade.Position (view)
|           +-- Trade.PositionTbl (table)
|           +-- Trade.PositionTreeInfo (table)
+-- Trade.Hedge (table)
+-- Trade.HedgeRequest (table)
+-- Trade.HedgeServer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.vExposuresForAllHedgeServers | View | Pre-aggregated position lots (OpenedBuy, OpenedSell) |
| Trade.Hedge | Table | Active hedge lot aggregation |
| Trade.HedgeRequest | Table | Pending request lot aggregation |
| Trade.HedgeServer | Table | ConsiderOpenRequestsSec time window config |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetCESQuery | Procedure | Reads exposure data for CES |
| Trade.DELGetCESQuery | Procedure | Legacy CES query |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Current exposure for all instruments

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged,
       Opened - Hedged AS UnhedgedExposure, Requested
FROM   Trade.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE  Opened <> 0 OR Hedged <> 0
ORDER BY ABS(Opened - Hedged) DESC;
```

### 8.2 Instruments with significant unhedged exposure

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Requested,
       Opened - Hedged - Requested AS NetUnhedged
FROM   Trade.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE  ABS(Opened - Hedged) > 1;
```

### 8.3 Exposure summary by hedge server

```sql
SELECT HedgeServerID,
       SUM(OpenedBuy) AS TotalBuyLots,
       SUM(OpenedSell) AS TotalSellLots,
       SUM(Hedged) AS TotalHedgedLots
FROM   Trade.GetExposuresForAllHedgeServers WITH (NOLOCK)
GROUP BY HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExposuresForAllHedgeServers | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetExposuresForAllHedgeServers.sql*
