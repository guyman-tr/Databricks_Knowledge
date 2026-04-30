# Hedge.InsertOpenPositionBulk

> Bulk-inserts open position snapshots from a memory-optimized TVP into Hedge.CustomerOpenPositions_New, joining with commission data retrieved via OPENQUERY from the [AO-REAL-DB-ROR] linked server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.CustomerOpenPositions_New; reads commission from [AO-REAL-DB-ROR] via OPENQUERY |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.InsertOpenPositionBulk` is the high-throughput bulk writer for `Hedge.CustomerOpenPositions_New`. Created in August 2020 (by Yitzchak), it replaces multiple single-row `Hedge.InsertOpenPosition` calls with a single set-based operation. The hedge server application batches all open position snapshots for all instruments at once into the `Hedge.OpenPositionsBulkParameters` TVP and calls this procedure once.

Unlike the single-row counterpart, this procedure:
- Accepts all positions in a single TVP parameter (`@OpenPositions` - memory-optimized, no lock contention).
- Retrieves ALL active position commission data in one OPENQUERY call to [AO-REAL-DB-ROR] (grouped by server + instrument), rather than per-instrument SELECTs.
- Writes directly to the local `Hedge.CustomerOpenPositions_New` table (not via synonym).
- Includes `OccurredAt` in the insert (from the TVP), providing a timestamped snapshot per row.

The OPENQUERY pattern is used because the primary position data (Trade.PositionTbl) resides on the [AO-REAL-DB-ROR] linked server (the read-optimized replica), and bulk retrieval via OPENQUERY with NOLOCK ensures minimal impact on production queries.

---

## 2. Business Logic

### 2.1 Commission Aggregation via OPENQUERY

**What**: CommissionOnOpen is computed from ALL active open positions on the remote server in a single batch query.

**Columns/Parameters Involved**: `#TP.CommissionOnOpen`

**Rules**:
- OPENQUERY target: `[AO-REAL-DB-ROR]` - the read-optimized replica of the primary.
- Query: `SELECT HedgeServerID, InstrumentID, SUM(Commission) as CommissionOnOpen FROM etoro.Trade.PositionTbl (NOLOCK) WHERE StatusID=1 GROUP BY HedgeServerID, InstrumentID`.
- Returns commission aggregates for ALL active positions across ALL instruments and servers - not filtered by any TVP row subset.
- Result loaded into temp table `#TP (HedgeServerID INT, InstrumentID INT, CommissionOnOpen decimal(14,4))`.

### 2.2 Bulk INSERT with Commission JOIN

**What**: All TVP rows are inserted with their corresponding commission, defaulting to 0 if no match.

**Columns/Parameters Involved**: `@OpenPositions`, `#TP.CommissionOnOpen`, `NetOpenInUSD`

**Rules**:
- LEFT JOIN: `@OpenPositions O LEFT JOIN #TP TP ON O.InstrumentID = TP.InstrumentID AND O.HedgeServerID = TP.HedgeServerID`.
- ISNULL(CommissionOnOpen, 0): instruments with no active customer positions (no match in #TP) receive CommissionOnOpen = 0.
- `NetOpenInUSD = 0`: hardcoded, same as single-row version - expected to be updated/computed downstream.
- `OccurredAt`: taken from the TVP row (not GETDATE()) - the calling application provides the snapshot timestamp.

**Diagram**:
```
@OpenPositions TVP (N rows - one per HedgeServer/Instrument combination)
        |
        | OPENQUERY [AO-REAL-DB-ROR]:
        |   SELECT HedgeServerID, InstrumentID, SUM(Commission)
        |   FROM Trade.PositionTbl WHERE StatusID=1 GROUP BY ...
        v
#TP (all active instrument commissions from primary replica)
        |
        | INSERT INTO Hedge.CustomerOpenPositions_New
        |   SELECT O.*, ISNULL(TP.CommissionOnOpen,0), 0 as NetOpenInUSD
        |   FROM @OpenPositions O LEFT JOIN #TP TP
        v
Hedge.CustomerOpenPositions_New (one row per TVP entry, with computed commission)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OpenPositions | OpenPositionsBulkParameters (TVP) | NO | - | CODE-BACKED | Memory-optimized table-valued parameter. Each row represents one aggregate open position snapshot: HedgeServerID, InstrumentID, OccurredAt, UnrealizedPL, OpenBuyUnits, OpenSellUnits, PriceRateID. The NONCLUSTERED index on (HedgeServerID, InstrumentID) in the UDT type accelerates the LEFT JOIN against #TP. READONLY parameter - no modifications allowed. |

**TVP columns (from Hedge.OpenPositionsBulkParameters):**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | HedgeServerID | INT | Hedge server for this snapshot row |
| 2 | InstrumentID | INT | Trading instrument for this snapshot row |
| 3 | OccurredAt | DATETIME | Snapshot timestamp (NOT NULL) - used as-is in CustomerOpenPositions_New |
| 4 | UnrealizedPL | DECIMAL(14,4) | Unrealized P&L for all open positions on this instrument/server |
| 5 | OpenBuyUnits | INT | Total long position units |
| 6 | OpenSellUnits | INT | Total short position units |
| 7 | PriceRateID | BIGINT | Market rate snapshot ID used for P&L calculation |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | [AO-REAL-DB-ROR].[etoro].Trade.PositionTbl | READ via OPENQUERY | Commission aggregation: all active positions (StatusID=1) grouped by HedgeServerID + InstrumentID |
| - | Hedge.CustomerOpenPositions_New | Writer (INSERT) | Bulk INSERT of all TVP rows with computed CommissionOnOpen |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. HedgeCostService database role holds EXECUTE permission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InsertOpenPositionBulk (procedure)
|-- [AO-REAL-DB-ROR].[etoro].Trade.PositionTbl (remote table) [OPENQUERY - commission aggregation]
+-- Hedge.CustomerOpenPositions_New (table) [INSERT - bulk open position snapshots]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].Trade.PositionTbl | Remote Table | OPENQUERY: all active position commission aggregates |
| Hedge.CustomerOpenPositions_New | Table | INSERT target for bulk open position snapshots |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application (HedgeCostService). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPENQUERY [AO-REAL-DB-ROR] | Cross-server read | Commission data retrieved from the read-optimized replica via linked server. Requires the AO-REAL-DB-ROR linked server connection to be active. |
| LEFT JOIN on #TP | NULL safety | Instruments with no commission data (no active customer positions) receive CommissionOnOpen = 0 via ISNULL. |
| NetOpenInUSD = 0 | Placeholder | Hardcoded to 0 - same as single-row version; updated downstream. |

---

## 8. Sample Queries

### 8.1 Execute with a TVP containing position snapshots
```sql
DECLARE @Positions [Hedge].[OpenPositionsBulkParameters]
INSERT INTO @Positions VALUES (1, 1, GETUTCDATE(), -250.50, 50000, 0, 9876543210)
INSERT INTO @Positions VALUES (1, 4, GETUTCDATE(), 1200.00, 0, 10000, 9876543211)

EXEC [Hedge].[InsertOpenPositionBulk] @OpenPositions = @Positions
```

### 8.2 Verify the commission data that would be fetched from the replica
```sql
-- Preview commission aggregates that OPENQUERY would return
SELECT TOP 20 HedgeServerID, InstrumentID, SUM(Commission) AS CommissionOnOpen
FROM [Trade].[PositionTbl] WITH (NOLOCK)
WHERE StatusID = 1
GROUP BY HedgeServerID, InstrumentID
ORDER BY HedgeServerID, InstrumentID
```

### 8.3 Check latest CustomerOpenPositions_New entries after bulk insert
```sql
SELECT TOP 20 HedgeServerID, InstrumentID, OccurredAt,
       OpenedBuyUnits, OpenedSellUnits, UnrealizedPL, CommissionOnOpen
FROM [Hedge].[CustomerOpenPositions_New] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InsertOpenPositionBulk | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.InsertOpenPositionBulk.sql*
