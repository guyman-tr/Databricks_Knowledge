# Trade.ExposuresForAllHedgeServers

> Real-time running aggregate of open position lot counts (buy and sell) per customer, provider, instrument, and hedge server combination, used for hedge exposure calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID + ProviderID + InstrumentID + HedgeServerID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

This table maintains a real-time aggregate of open position exposure broken down by customer (CID), liquidity provider (ProviderID), financial instrument (InstrumentID), and hedge server (HedgeServerID). Each row stores the total lot count of open Buy positions and open Sell positions for that combination. The hedging system uses this data to calculate net exposure and determine when hedging trades are needed.

Without this table, the system would need to recalculate exposure from individual open positions each time a hedge decision is needed - which would be prohibitively slow given the volume of positions. This precomputed aggregate enables near-instant exposure lookups for the CES (Customer Exposure System) queries used by hedge servers.

Rows are incrementally updated by `Trade.ExposuresForAllHedgeServers_Update` whenever a position opens or closes. The procedure adjusts OpenedBuy or OpenedSell by the position's lot count. A periodic consistency check (`Trade.ExposuresForAllHedgeServers_Check`) recalculates the expected values from Trade.Position and corrects any drift, logging discrepancies to Trade.ExposuresForAllHedgeServers_Log. Weekend cleanup (`Trade.ExposuresForAllHedgeServers_WeekendCleanup`) handles stale rows.

---

## 2. Business Logic

### 2.1 Incremental Exposure Tracking

**What**: The table is updated in real-time as positions open and close, not batch-recalculated.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell`, `CID`, `ProviderID`, `InstrumentID`, `HedgeServerID`

**Rules**:
- On position open: LotCountDecimal is ADDED to OpenedBuy (if IsBuy=1) or OpenedSell (if IsBuy=0)
- On position close (self only - ActionTypes 1,2,5,7): LotCountDecimal is SUBTRACTED from the appropriate column
- On hierarchical close (ActionTypes 0,8,9,10,12,13,14): Sums lot counts of 1st-generation child positions from Trade.Position and subtracts along with the parent's lot count
- If no row exists for the combination, a new row is inserted

**Diagram**:
```
Position Open (IsBuy=1, Lots=10)
  --> ExposuresForAllHedgeServers.OpenedBuy += 10

Position Close (IsBuy=1, Lots=10, ActionType=1 StopLoss)
  --> ExposuresForAllHedgeServers.OpenedBuy -= 10

Hierarchical Close (Parent + Children)
  --> Sum child lots from Trade.Position WHERE ParentPositionID = @PositionID
  --> Subtract combined total from parent's hedge server row(s)
```

### 2.2 Action Type Classification

**What**: Close operations are classified by action type to determine which positions' exposure to decrease.

**Columns/Parameters Involved**: via `ExposuresForAllHedgeServers_Update` @ActionType parameter

**Rules**:
- Decrease self + 1st generation children: ActionType 0 (Customer), 8 (BackOffice), 12 (CloseAll), 13 (MirrorSL), 14 (Manual close of copied position)
- Decrease only 1st generation children: ActionType 9 (Hierarchical Close), 10 (Hierarchical close by recovery)
- Decrease ONLY self: ActionType 1 (StopLoss), 2 (EndOfWeek), 5 (TakeProfit), 7 (ContractRollover)
- Do nothing: ActionType 3 (SL via trade server), 4 (ReturnToMarket), 6 (TP via trade server), 11 (JoinDemoChallenge)

### 2.3 Consistency Check and Self-Healing

**What**: A periodic job recalculates expected exposure from live positions and fixes drift.

**Columns/Parameters Involved**: `OpenedBuy`, `OpenedSell` (corrected); differences logged to `Trade.ExposuresForAllHedgeServers_Log`

**Rules**:
- The Check procedure sums LotCountDecimal from Trade.Position (WHERE IsComputeForHedge=1) grouped by CID/Provider/Instrument/HedgeServer
- Three types of discrepancies are detected and logged: value mismatches, rows in table but not in positions (zeroed out), rows in positions but not in table (inserted)
- The table is corrected to match the recalculated values within a SERIALIZABLE transaction

---

## 3. Data Overview

| CID | ProviderID | InstrumentID | HedgeServerID | OpenedBuy | OpenedSell | Meaning |
|-----|-----------|--------------|--------------|-----------|------------|---------|
| 28 | 1 | 2 | 8 | 0 | 0 | Customer 28 has no active buy or sell exposure on instrument 2 via provider 1 on hedge server 8 - row retained as placeholder |
| 28 | 1 | 25 | 8 | 200 | 0 | Customer 28 holds 200 lots of buy exposure on instrument 25 with no sell positions - fully long |
| 28 | 1 | 1019 | 8 | 115 | 0 | Customer 28 holds 115 lots of buy exposure on instrument 1019 - long only |
| 4498 | 1 | 100000 | 5 | 0.001102 | 0 | Small fractional buy exposure on a crypto instrument (100000-series) via hedge server 5 |
| 297741 | 1 | 100017 | 1 | 10.137758 | 0 | Customer with ~10 lots of buy exposure on crypto instrument via primary hedge server |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID whose exposure is tracked. References Customer.Customer. Each customer has one row per unique Provider/Instrument/HedgeServer combination. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider identifier. References Trade.Provider. Determines which provider's pricing and execution is used for the positions contributing to this exposure row. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier. References Trade.Instrument. Combined with ProviderID and HedgeServerID to define the specific exposure bucket. |
| 4 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server handling this exposure segment. References Trade.HedgeServer. Children of a position can be on different hedge servers than the parent, so hierarchical close operations must handle multiple HedgeServerID values. |
| 5 | OpenedBuy | decimal(38,6) | NO | - | VERIFIED | Running total of lot counts for open Buy (long) positions for this CID/Provider/Instrument/HedgeServer combination. Incremented on position open (IsBuy=1), decremented on position close. Updated by ExposuresForAllHedgeServers_Update. |
| 6 | OpenedSell | decimal(38,6) | NO | - | VERIFIED | Running total of lot counts for open Sell (short) positions for this CID/Provider/Instrument/HedgeServer combination. Incremented on position open (IsBuy=0), decremented on position close. Updated by ExposuresForAllHedgeServers_Update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer account whose exposure is tracked |
| ProviderID | Trade.Provider | Implicit | Liquidity provider for the exposure bucket |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument for the exposure bucket |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server handling this exposure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExposuresForAllHedgeServers_Update | - | Writer | Incrementally updates OpenedBuy/OpenedSell on position open/close |
| Trade.ExposuresForAllHedgeServers_Check | - | Writer/Reader | Recalculates and corrects exposure values, logs discrepancies |
| Trade.ExposuresForAllHedgeServers_WeekendCleanup | - | Writer | Cleans up stale exposure rows on weekends |
| Trade.GetCESQuery | - | Reader | Reads exposure data for Customer Exposure System queries |
| Trade.DELGetCESQuery | - | Reader | Legacy CES query (reads exposure data) |
| Trade.MovePositionsHedgeServers | - | Writer | Updates exposure when positions move between hedge servers |
| Trade.MovePositionsHedgeServersByRerouteService | - | Writer | Updates exposure during hedge server rerouting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers_Update | Stored Procedure | Writes exposure changes on position open/close |
| Trade.ExposuresForAllHedgeServers_Check | Stored Procedure | Reads/writes to reconcile against Trade.Position |
| Trade.ExposuresForAllHedgeServers_WeekendCleanup | Stored Procedure | Cleans stale rows |
| Trade.GetCESQuery | Stored Procedure | Reads for CES hedge exposure |
| Trade.DELGetCESQuery | Stored Procedure | Legacy CES query reader |
| Trade.MovePositionsHedgeServers | Stored Procedure | Updates on hedge server migration |
| Trade.MovePositionsHedgeServersByRerouteService | Stored Procedure | Updates on hedge server reroute |
| Trade.vExposuresForAllHedgeServers | View | Reads exposure data (view wrapper) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ExposuresForAllHedgeServers | CLUSTERED PK | CID, ProviderID, InstrumentID, HedgeServerID | - | - | Active (FILLFACTOR=80, STATISTICS_NORECOMPUTE=ON) |
| ix_Trade_ExposuresForAllHedgeServerst_CoveringForCES | NONCLUSTERED | ProviderID, InstrumentID, HedgeServerID | OpenedBuy, OpenedSell | - | Active (FILLFACTOR=80, STATISTICS_NORECOMPUTE=ON) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ExposuresForAllHedgeServers | PRIMARY KEY | Ensures one exposure row per CID/Provider/Instrument/HedgeServer combination |

---

## 8. Sample Queries

### 8.1 Get total exposure for a specific instrument across all hedge servers
```sql
SELECT HedgeServerID,
       SUM(OpenedBuy)  AS TotalBuyLots,
       SUM(OpenedSell) AS TotalSellLots,
       SUM(OpenedBuy) - SUM(OpenedSell) AS NetExposure
FROM   Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
       AND ProviderID = @ProviderID
GROUP BY HedgeServerID
```

### 8.2 Find customers with the largest buy exposure
```sql
SELECT TOP 20 CID,
       InstrumentID,
       OpenedBuy
FROM   Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
WHERE  OpenedBuy > 0
ORDER BY OpenedBuy DESC
```

### 8.3 Check for stale zero-exposure rows
```sql
SELECT CID, ProviderID, InstrumentID, HedgeServerID
FROM   Trade.ExposuresForAllHedgeServers WITH (NOLOCK)
WHERE  OpenedBuy = 0
       AND OpenedSell = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServers | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExposuresForAllHedgeServers.sql*
