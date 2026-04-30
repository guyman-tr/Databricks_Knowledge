# History.CustomerOpenPositions

> Aggregated open positions snapshot table - stores time-series unrealized P&L aggregations by (HedgeServerID, InstrumentID, OccurredAt) across all open customer positions; currently empty (0 rows).

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

History.CustomerOpenPositions stores aggregated unrealized P&L snapshots for open customer positions, grouped by hedge server, instrument, and time. Like its sibling History.CustomerClosedPositions, this table aggregates the financial state of **all** customer open positions for a given instrument on a given hedge server at a specific OccurredAt timestamp.

Each row captures: unrealized P&L, commission on open, zero-PL (unrealized with commission offset), buy/sell units broken down and combined, the price rate used, and net open position in USD.

0 rows - no open position aggregate snapshots have been recorded.

This table is designed for portfolio-level risk and P&L analysis: "at time T, across all customers on hedge server H trading instrument I, what was the aggregate unrealized exposure?"

---

## 2. Business Logic

### 2.1 Aggregated Open Position Snapshot

**What**: Each row represents the aggregate state of all customer open positions for one instrument on one hedge server at a specific point in time.

**Columns**:

| Column | Description |
|--------|-------------|
| UnrealizedPL | Aggregate unrealized profit/loss across all open positions |
| CommissionOnOpen | Total commission charged at open for these positions |
| UnrealizedZeroPL | Unrealized P&L net of commission (zero-sum reference point) |
| OpenedBuyUnits | Total buy units open (int) |
| OpenedSellUnits | Total sell units open (int) |
| OpenedUnits | Net open units (decimal 14,4 - can represent fractional shares) |
| PriceRateID | ID of the price rate used for unrealized valuation |
| NetOpenInUSD | Net open exposure in USD |

### 2.2 Relationship to History.CustomerClosedPositions

These two tables form a pair:
- History.CustomerOpenPositions: aggregate unrealized state at a point in time
- History.CustomerClosedPositions: aggregate realized result of closures at a point in time

Both share the same PK structure (OccurredAt, HedgeServerID, InstrumentID) enabling time-aligned joins.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 0 |
| **Status** | Empty - no open position snapshots recorded |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | NO | - | VERIFIED | Hedge server managing these positions. FK to Trade.HedgeServer(HedgeServerID). PK component. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Instrument for which open positions are aggregated. Implicit FK to Trade.InstrumentTbl. PK component. |
| 3 | OccurredAt | datetime | NO | - | VERIFIED | Snapshot timestamp. Leading PK column for time-range queries. |
| 4 | UnrealizedPL | decimal(14,4) | NO | - | VERIFIED | Aggregate unrealized profit/loss across all open customer positions for this instrument/server/time. |
| 5 | CommissionOnOpen | decimal(14,4) | NO | - | VERIFIED | Total commission charged when these positions were opened. |
| 6 | UnrealizedZeroPL | decimal(14,4) | NO | - | VERIFIED | Unrealized P&L minus commission on open. Represents the zero-sum unrealized position. |
| 7 | OpenedBuyUnits | int | NO | - | VERIFIED | Total buy-side units open across all customer positions for this snapshot. |
| 8 | OpenedSellUnits | int | NO | - | VERIFIED | Total sell-side units open. |
| 9 | OpenedUnits | decimal(14,4) | NO | - | VERIFIED | Net open units (decimal for fractional shares/CFDs). |
| 10 | PriceRateID | bigint | YES | - | CODE-BACKED | Price rate ID used for unrealized P&L valuation. Links to price feed. NULL if price not available. |
| 11 | NetOpenInUSD | decimal(14,4) | NO | - | VERIFIED | Net open position value in USD. Key metric for exposure management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | FK (FK_HistoryCustomerOpenPositions_HedgeServer) | The hedge server context. |
| InstrumentID | Trade.InstrumentTbl | Implicit | The instrument for which positions are aggregated. |

### 5.2 Referenced By

| Object | How Used |
|--------|---------|
| History.CustomerClosedPositions | Sibling table - paired aggregate for closed positions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Options |
|-----------|------|-------------|---------|
| PK_HistoryCustomerOpenPositions | CLUSTERED PK | OccurredAt ASC, HedgeServerID ASC, InstrumentID ASC | DATA_COMPRESSION=PAGE |

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.8/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.CustomerOpenPositions | Type: Table | Source: etoro/etoro/History/Tables/History.CustomerOpenPositions.sql*
