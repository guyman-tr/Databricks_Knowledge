# Hedge.VolatilityThresholdHedgeServer

> Per-instrument routing table that maps which hedge server to use depending on whether the instrument is above or below the volatility threshold. 5 rows covering the most liquid/volatile instruments (major FX pairs and non-expiry commodities).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID - single column CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only, PAGE compressed) |

---

## 1. Business Meaning

Hedge.VolatilityThresholdHedgeServer implements volatility-based hedge server routing. For specific high-activity instruments, the hedge system can use a different hedge server during high-volatility market conditions versus normal conditions.

The premise: certain instruments (major FX pairs, commodities) experience sudden spikes in volatility during economic events (e.g., Fed announcements, geopolitical news). During these spikes, a dedicated hedge server with different capabilities (e.g., higher throughput, specialized execution logic, or different LP connections) should handle the orders. This table is the routing configuration that enables the switch.

Current data shows 5 instruments - all of eToro's most liquid and volatile instruments:
- EUR/USD (ID=1) and GBP/USD (ID=2): the two largest FX pairs by volume
- Oil Non Expiry (ID=17), Gold Non Expiry (ID=18), Natural Gas Non Expiry (ID=22): the three major non-expiry commodities

For all 5, HedgeServerID=2 handles high-volatility conditions and HedgeServerID=1 handles below-threshold conditions. The volatility threshold itself is not stored in this table - it is defined elsewhere in application configuration or in Hedge.BoundariesConfiguration/InstrumentBoundaries.

No stored procedures reference this table - the application reads it directly via a query on InstrumentID.

---

## 2. Business Logic

### 2.1 Volatility-Based Server Routing

**What**: For each listed instrument, the hedge system selects the appropriate hedge server based on whether real-time volatility exceeds a threshold.

**Columns/Parameters Involved**: `InstrumentID`, `HedgeServerIDOverVolatilityThreshold`, `HedgeServerIDBelowVolatilityThreshold`

**Rules**:
- Application measures real-time volatility for the instrument (external to this table)
- If current volatility > threshold: route hedge orders to `HedgeServerIDOverVolatilityThreshold`
- If current volatility <= threshold: route hedge orders to `HedgeServerIDBelowVolatilityThreshold`
- Instruments NOT listed in this table are not subject to volatility-based routing (use their default server assignment from other configuration tables)
- Currently all 5 configured instruments share the same routing: ID=1 (normal) or ID=2 (high volatility)

**Diagram**:
```
Real-time volatility check for InstrumentID=1 (EUR/USD):
  volatility > threshold? -> HedgeServerID = 2 (high-volatility server)
  volatility <= threshold? -> HedgeServerID = 1 (standard server)

InstrumentID not in table (most instruments)?
  -> use default hedge server from other config (e.g., HedgeServerToLiquidityAccount)
```

---

## 3. Data Overview

5 rows (all active):

| InstrumentID | Instrument | Exchange | HedgeServerIDOver | HedgeServerIDBelow |
|---|---|---|---|---|
| 1 | EUR/USD | FX | 2 | 1 |
| 2 | GBP/USD | FX | 2 | 1 |
| 17 | Oil (Non Expiry) | Commodity | 2 | 1 |
| 18 | Gold (Non Expiry) | Commodity | 2 | 1 |
| 22 | Natural Gas (Non Expiry) | Commodity | 2 | 1 |

All 5 instruments route to HedgeServerID=2 during high volatility and HedgeServerID=1 during normal conditions. The instruments are eToro's highest-volume FX pairs and the three primary non-expiry commodity instruments (also used in Hedge.PortfolioConversionConfigurations for rolling futures hedging).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | PK. Implicit FK to Trade.Instrument. Identifies the instrument subject to volatility-based routing. Only high-activity instruments are listed (5 rows: EUR/USD, GBP/USD, Oil/Gold/NatGas Non Expiry). Instruments not in this table use their default server assignment. |
| 2 | HedgeServerIDOverVolatilityThreshold | int | NO | - | VERIFIED | Implicit FK to Trade.HedgeServer. The hedge server to use when this instrument's real-time volatility EXCEEDS the configured threshold. All 5 current rows point to HedgeServerID=2 - the dedicated high-volatility server. |
| 3 | HedgeServerIDBelowVolatilityThreshold | int | NO | - | VERIFIED | Implicit FK to Trade.HedgeServer. The hedge server to use when this instrument's real-time volatility is AT OR BELOW the configured threshold (normal conditions). All 5 current rows point to HedgeServerID=1 - the standard server. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | The instrument whose hedge server routing is configured |
| HedgeServerIDOverVolatilityThreshold | Trade.HedgeServer | Implicit | The hedge server used during high-volatility conditions |
| HedgeServerIDBelowVolatilityThreshold | Trade.HedgeServer | Implicit | The hedge server used during normal/low-volatility conditions |

### 5.2 Referenced By (other objects point to this)

No stored procedures reference Hedge.VolatilityThresholdHedgeServer. The table is read directly by application code (hedge server service) without a stored procedure layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.VolatilityThresholdHedgeServer (table)
+-- Trade.Instrument (table) [implicit FK target]
+-- Trade.HedgeServer (table) [implicit FK target - used for both Over and Below IDs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Implicit FK for InstrumentID |
| Trade.HedgeServer | Table | Implicit FK for both HedgeServerID columns |

### 6.2 Objects That Depend On This

No stored procedure dependents. Application code reads directly.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge.VolatilityThresholdHedgeServer | CLUSTERED PK | InstrumentID ASC | - | - | Active |

Note: PK uses `DATA_COMPRESSION = PAGE` - unusual for a 5-row table. This may have been set as a template from a larger table or anticipating significant growth. PAGE compression has minimal effect at 5 rows but becomes meaningful if the table grows to hundreds of instruments. FILLFACTOR=95.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge.VolatilityThresholdHedgeServer | PRIMARY KEY | One routing configuration per instrument |

---

## 8. Sample Queries

### 8.1 Current routing configuration with instrument and server names
```sql
SELECT  vt.InstrumentID,
        m.InstrumentDisplayName,
        m.Exchange,
        vt.HedgeServerIDOverVolatilityThreshold AS HighVolServer,
        vt.HedgeServerIDBelowVolatilityThreshold AS NormalServer
FROM    [Hedge].[VolatilityThresholdHedgeServer] vt WITH (NOLOCK)
LEFT JOIN [Trade].[InstrumentMetaData] m WITH (NOLOCK)
        ON vt.InstrumentID = m.InstrumentID
ORDER BY m.Exchange, vt.InstrumentID;
```

### 8.2 Check if an instrument has volatility-based routing configured
```sql
SELECT  CASE
            WHEN vt.InstrumentID IS NOT NULL THEN 'Yes - routes to server ' + CAST(vt.HedgeServerIDOverVolatilityThreshold AS VARCHAR) + ' when volatile'
            ELSE 'No - standard routing only'
        END AS VolatilityRoutingConfigured
FROM    (SELECT NULL AS anchor) base
LEFT JOIN [Hedge].[VolatilityThresholdHedgeServer] vt WITH (NOLOCK)
        ON vt.InstrumentID = 1; -- replace with target InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.VolatilityThresholdHedgeServer. Confluence search returned no relevant results.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.VolatilityThresholdHedgeServer | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.VolatilityThresholdHedgeServer.sql*
