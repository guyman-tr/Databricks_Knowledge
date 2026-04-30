# History.CustomerClosedPositions

> Aggregated closed positions snapshot table - stores time-series P&L aggregations by (HedgeServerID, InstrumentID, OccurredAt) across all customer positions; currently empty (0 rows).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (OccurredAt, HedgeServerID, InstrumentID) - composite PK CLUSTERED |
| **Partition** | No |
| **Temporal** | No - time-series snapshot |
| **Indexes** | 1 (PK clustered, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

History.CustomerClosedPositions stores aggregated P&L snapshots for closed customer positions, grouped by hedge server, instrument, and time. Unlike per-customer position tables, this table aggregates the financial impact of **all** customer close events across the entire customer base for a given instrument on a given hedge server at a specific OccurredAt timestamp.

Each row captures the net aggregate result of position closures: total NetPL, total CommissionOnClose, the computed ZeroPL (zero-profit metric = NetPL + CommissionOnClose), and ExecutionVolumeInUSD.

0 rows - no aggregate close snapshots have been recorded.

The PK ordering (OccurredAt, HedgeServerID, InstrumentID) optimizes for time-range queries: retrieve all instrument P&L snapshots within a time window, grouped by server.

---

## 2. Business Logic

### 2.1 Aggregated P&L Snapshot

**What**: Each row represents the aggregate financial result of customer position closures for one instrument on one hedge server at a specific point in time.

**Columns**:
| Column | Description |
|--------|-------------|
| NetPL | Net profit/loss from closed positions (decimal 14,4) |
| CommissionOnClose | Commission charged at close |
| ZeroPL | Computed: NetPL + CommissionOnClose - the "zero sum" P&L (revenue neutral point) |
| ExecutionVolumeInUSD | Total execution volume in USD for these closures |

### 2.2 Relationship to History.CustomerOpenPositions

These two tables form a pair:
- History.CustomerClosedPositions: aggregate of closed position events
- History.CustomerOpenPositions: aggregate of open position state
Both share the same PK structure (OccurredAt, HedgeServerID, InstrumentID).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 |
| **Status** | Empty - no snapshots recorded |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | VERIFIED | Hedge server that processed these position closures. FK to Trade.HedgeServer(HedgeServerID). PK component. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Financial instrument for which positions were closed. Implicit FK to Trade.InstrumentTbl. PK component. |
| 3 | OccurredAt | datetime | NO | - | VERIFIED | Timestamp of the snapshot. Leading PK column for time-range queries. |
| 4 | NetPL | decimal(14,4) | NO | - | VERIFIED | Net profit/loss aggregated across all customer position closures for this instrument/server/time. |
| 5 | CommissionOnClose | decimal(14,4) | NO | - | VERIFIED | Total commission charged on position closures. |
| 6 | ZeroPL | computed AS (NetPL+CommissionOnClose) | - | - | VERIFIED | Computed zero-profit metric: NetPL + CommissionOnClose. Represents eToro's net revenue from these closures. |
| 7 | ExecutionVolumeInUSD | decimal(14,4) | NO | - | VERIFIED | Total execution volume in USD for the closed positions in this snapshot. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_HistoryCustomerClosedPositions_HedgeServer) | The hedge server context. |
| InstrumentID | Trade.InstrumentTbl | Implicit | The instrument whose positions were closed. |

### 5.2 Referenced By

| Object | How Used |
|--------|---------|
| History.CustomerOpenPositions | Sibling table - paired aggregate for open positions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_HistoryCustomerClosedPositions | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC, InstrumentID ASC | DATA_COMPRESSION=PAGE |

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CustomerClosedPositions | Type: Table | Source: etoro/etoro/History/Tables/History.CustomerClosedPositions.sql*
