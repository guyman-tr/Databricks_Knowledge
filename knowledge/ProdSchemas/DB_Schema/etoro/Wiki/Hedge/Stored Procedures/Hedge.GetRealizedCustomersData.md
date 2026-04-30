# Hedge.GetRealizedCustomersData

> Aggregates realized customer P&L per hedge server and instrument for a time window, sourcing data from History.Position (closed positions) and Trade.Position (recently opened positions that are compute-eligible).

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set: HedgeServerID, InstrumentID, SUM(NetPL), SUM(CommissionOnClose), SUM(ExecutionVolumeInUSD), OccurredAt |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetRealizedCustomersData` is a reader procedure that computes the aggregate realized P&L for all customers per hedge server and instrument within a specified time window `[@From, @To]`. It is the data source used by `Hedge.AddCustomersDataGeneral` to feed the `Hedge.CustomerClosedPositions` real-time accumulation table.

The procedure queries two sources:
1. **`History.Position`** (closed positions): Joins with `Customer.Customer` to exclude internal/staff accounts (`PlayerLevelID != 4`). This ensures only real customer P&L is included in the hedge cost calculation.
2. **`Trade.Position`** (open positions eligible for hedge compute): Positions with `IsComputeForHedge = 1` that were opened (`Occurred`) in the window. These contribute `0` realized P&L (not closed yet) but are counted for tracking new positions entering the hedge computation.

The procedure uses `MAXDOP 1` to control parallelism on the `History.Position` query - a hint suggesting the table is large and uncontrolled parallelism may degrade performance.

**Developer note (2020-04-23)**: `OccurredAt` column was added to the output on this date.

---

## 2. Business Logic

### 2.1 Realized P&L Window Calculation

**What**: Aggregates actual closed customer P&L for the hedge cost computation cycle.

**Columns/Parameters Involved**: `@From`, `@To`

**Rules**:
- `History.Position` filter: `CloseOccurred > @From AND CloseOccurred <= @To` - positions that closed within the window.
- Excludes `PlayerLevelID = 4` (staff/internal accounts) to ensure only genuine customer P&L is counted.
- `NetPL = ISNULL(NetProfit, 0)` from History.Position.
- `CommissionOnClose = ISNULL(CommissionOnClose, 0)` from History.Position.
- `ExecutionVolumeInUSD = 0` - the volume calculation is commented out (`/*...*/ 0`). This was presumably disabled for performance or correctness reasons.

### 2.2 Trade.Position Contribution

**What**: Includes recently opened hedge-compute-eligible positions to track new entries.

**Columns/Parameters Involved**: `IsComputeForHedge`, `Occurred`

**Rules**:
- `Trade.Position` filter: `IsComputeForHedge = 1 AND Occurred > @From AND Occurred <= @To`.
- All financial values are 0 (NetPL = 0, CommissionOnClose = 0, ExecutionVolumeInUSD = 0) - these positions have not closed yet, so they contribute no realized P&L.
- Purpose: notifies the hedge system of new position inventory that entered the hedge compute universe in this window.

### 2.3 Aggregation and Output

**What**: Groups and sums the UNION result to produce one row per HedgeServerID/InstrumentID.

**Rules**:
- GROUP BY (HedgeServerID, InstrumentID).
- `OccurredAt = @To` in the output (not the actual close date) - the timestamp is set to the window endpoint for consistent time-series alignment.
- `MAXDOP 1` hint on the History.Position query to prevent excessive parallelism.

**Diagram**:
```
[@From, @To]
  |
  +-- History.Position JOIN Customer.Customer (PlayerLevelID != 4)
  |   (closed positions, CloseOccurred in window)
  |
  +-- Trade.Position (IsComputeForHedge=1, Occurred in window)
  |
  UNION ALL
  |
  GROUP BY (HedgeServerID, InstrumentID)
  |
  SELECT HedgeServerID, InstrumentID, SUM(NetPL), SUM(CommissionOnClose), SUM(ExecutionVolumeInUSD), @To AS OccurredAt
  |
  v
Caller: Hedge.AddCustomersDataGeneral -> Hedge.CustomerClosedPositions
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | DATETIME | NO | - | CODE-BACKED | Window start (exclusive, > @From): positions that closed after this date are included from History.Position. Also the open date filter (> @From) for Trade.Position. Typically set to the last computation cycle's end time. |
| 2 | @To | DATETIME | NO | - | CODE-BACKED | Window end (inclusive, <= @To): positions closed up to this date are included. Also set as the OccurredAt value in the output, aligning all result rows to the same reference timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.Position | READ (NOLOCK) | Source of closed customer positions with realized P&L |
| - | Customer.Customer | JOIN (NOLOCK) | Used to filter out staff accounts (PlayerLevelID = 4) |
| - | Trade.Position | READ (NOLOCK) | Source of recently opened hedge-compute-eligible positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddCustomersDataGeneral | EXEC call | Caller | Calls this procedure to get realized customer data for insertion into Hedge.CustomerClosedPositions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetRealizedCustomersData (procedure)
├── History.Position (table) [READ - NOLOCK, MAXDOP 1]
├── Customer.Customer (table) [JOIN - NOLOCK]
└── Trade.Position (table) [READ - NOLOCK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Source of closed customer position P&L data |
| Customer.Customer | Table | Joined to filter out PlayerLevelID = 4 (staff/internal) accounts |
| Trade.Position | Table | Source of new hedge-compute positions opened in the window |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddCustomersDataGeneral | Stored Procedure | Calls this to populate Hedge.CustomerClosedPositions with realized customer P&L |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (MAXDOP 1) | Query hint | Forces single-threaded execution on History.Position query to avoid parallelism overhead on a large history table |
| PlayerLevelID != 4 | Business filter | Excludes eToro staff/internal accounts from customer P&L computation |

---

## 8. Sample Queries

### 8.1 Execute for a specific time window
```sql
EXEC [Hedge].[GetRealizedCustomersData]
    @From = '2026-03-18 00:00:00',
    @To   = '2026-03-19 00:00:00'
```

### 8.2 Check realized P&L by hedge server
```sql
SELECT HedgeServerID,
       SUM(NetPL) AS TotalNetPL,
       SUM(CommissionOnClose) AS TotalCommission,
       COUNT(*) AS InstrumentCount
FROM [Hedge].[CustomerClosedPositions] WITH (NOLOCK)
WHERE OccurredAt >= DATEADD(day, -1, GETUTCDATE())
GROUP BY HedgeServerID
ORDER BY ABS(SUM(NetPL)) DESC
```

### 8.3 Verify staff account exclusion
```sql
SELECT DISTINCT PlayerLevelID, COUNT(*) AS AccountCount
FROM [Customer].[Customer] WITH (NOLOCK)
WHERE PlayerLevelID IN (1, 2, 3, 4)
GROUP BY PlayerLevelID
-- PlayerLevelID = 4 is excluded from GetRealizedCustomersData
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | CustomerPL (realized) flows: History.Position data (closed positions) drives "Clients P&L - Realized" in the INSight HedgeCost display; stored in Cosmos DB (Realized Customer) and SQL History DB |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetRealizedCustomersData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetRealizedCustomersData.sql*
