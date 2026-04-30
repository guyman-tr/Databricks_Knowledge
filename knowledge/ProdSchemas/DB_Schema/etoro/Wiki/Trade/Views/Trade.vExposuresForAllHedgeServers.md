# Trade.vExposuresForAllHedgeServers

> SCHEMABINDING aggregated view that sums OpenedBuy and OpenedSell exposures per ProviderID, InstrumentID, HedgeServerID - the go-to view for net exposure per instrument per hedge server.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID, HedgeServerID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.vExposuresForAllHedgeServers provides aggregated net exposure data per instrument per hedge server. Each row represents the summed OpenedBuy and OpenedSell amounts for a (ProviderID, InstrumentID, HedgeServerID) combination, plus a COUNT_BIG(*) for the number of contributing positions. This is the primary view for hedge exposure monitoring and risk management - used to understand net long/short exposure at the hedge server level.

The view exists because the base object Trade.ExposuresForAllHedgeServers contains row-level or intermediate exposure data. Consumers need pre-aggregated sums for dashboards, risk limits, and hedging decisions. The GROUP BY ProviderID, InstrumentID, HedgeServerID with SUM(OpenedBuy), SUM(OpenedSell) provides exactly that. SCHEMABINDING and COUNT_BIG(*) enable potential indexed view materialization if an index is created on the view in the future.

Used by hedge exposure monitoring, risk management dashboards, and automated hedging logic that needs net exposure per instrument per hedge server.

---

## 2. Business Logic

Aggregation. SELECT from Trade.ExposuresForAllHedgeServers with WITH (NOLOCK). GROUP BY ProviderID, InstrumentID, HedgeServerID. SUM(OpenedBuy), SUM(OpenedSell), COUNT_BIG(*). Output: ProviderID, InstrumentID, HedgeServerID, OpenedBuy, OpenedSell, cnt. Each output row = one (ProviderID, InstrumentID, HedgeServerID) with net buy/sell exposure totals.

---

## 3. Data Overview

N/A - output is aggregated from Trade.ExposuresForAllHedgeServers. See [Trade.ExposuresForAllHedgeServers](Trade.ExposuresForAllHedgeServers.md) for raw exposure semantics.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier. Part of grouping key. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Instrument of the exposure. Part of grouping key. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server identifier. Part of grouping key. |
| 4 | OpenedBuy | decimal/money | YES | - | CODE-BACKED | SUM(OpenedBuy) - total buy exposure for this instrument on this hedge server. |
| 5 | OpenedSell | decimal/money | YES | - | CODE-BACKED | SUM(OpenedSell) - total sell exposure for this instrument on this hedge server. |
| 6 | cnt | bigint | NO | - | CODE-BACKED | COUNT_BIG(*) - number of rows aggregated. Supports indexed view. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Instrument of the exposure |
| ProviderID | (Provider) | Implicit FK | Provider reference |
| HedgeServerID | (HedgeServer) | Implicit FK | Hedge server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.vExposuresForAllHedgeServers (view)
    |
    +-- Trade.ExposuresForAllHedgeServers (table/view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers | Table/View | FROM - source of OpenedBuy, OpenedSell, GROUP BY columns, WITH (NOLOCK) |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

SCHEMABINDING. Required for potential indexed view materialization. Locks the view definition to the base object schema.

---

## 8. Sample Queries

### 8.1 Net exposure by hedge server

```sql
SELECT ProviderID, InstrumentID, HedgeServerID, OpenedBuy, OpenedSell, cnt
FROM Trade.vExposuresForAllHedgeServers WITH (NOLOCK)
WHERE HedgeServerID = @HedgeServerID;
```

### 8.2 Top instruments by exposure volume

```sql
SELECT InstrumentID, SUM(OpenedBuy + OpenedSell) AS TotalExposure
FROM Trade.vExposuresForAllHedgeServers WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY TotalExposure DESC;
```

### 8.3 Exposure for specific instrument across hedge servers

```sql
SELECT HedgeServerID, OpenedBuy, OpenedSell, cnt
FROM Trade.vExposuresForAllHedgeServers WITH (NOLOCK)
WHERE ProviderID = @ProviderID AND InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.vExposuresForAllHedgeServers | Type: View | Source: etoro/etoro/Trade/Views/Trade.vExposuresForAllHedgeServers.sql*
