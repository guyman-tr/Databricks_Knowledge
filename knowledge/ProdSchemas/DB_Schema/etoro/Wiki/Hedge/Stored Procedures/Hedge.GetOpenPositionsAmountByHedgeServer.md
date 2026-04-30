# Hedge.GetOpenPositionsAmountByHedgeServer

> Aggregates open customer trading positions by hedge server, instrument, and direction to produce the net eToro customer book exposure that each hedge server must cover, used as the input for hedge exposure calculation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full system-wide open position summary |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetOpenPositionsAmountByHedgeServer` answers the question: "How much exposure does each hedge server need to cover per instrument, per direction?" It reads the Trade.PositionTbl (eToro's core position table), filters to open positions that require hedge computation, and aggregates the total units per (InstrumentID, HedgeServerID, IsBuy) combination. The result is the raw exposure input that drives hedge order sizing.

This procedure exists because the hedge server does not process individual customer positions - it processes aggregate exposures. A hedge server might have 10,000 customers long EUR/USD with a combined 500M units; the server needs to place a single 500M-unit hedge order rather than 10,000 individual trades. Without this aggregation, the hedge server could not determine how much to hedge.

Data flows as follows: the hedge engine calls this procedure periodically (or on trigger) to get the current aggregate customer book. It compares this against the current netting positions (from GetNetting) to compute the delta that needs hedging. Only positions with `IsComputeForHedge=1` AND `StatusID=1` (open) are included - settled, closed, or computation-excluded positions are filtered out.

---

## 2. Business Logic

### 2.1 Hedge-Eligible Open Position Aggregation

**What**: Aggregates AmountInUnitsDecimal for open, hedge-eligible positions, grouped by the three dimensions that define a distinct hedge book entry.

**Columns/Parameters Involved**: `IsComputeForHedge`, `StatusID`, `InstrumentID`, `HedgeServerID`, `IsBuy`, `AmountInUnitsDecimal`

**Rules**:
- `IsComputeForHedge = 1`: excludes positions opted out of hedge computation (e.g., CFD positions not requiring physical hedge, or positions in test/sandbox accounts)
- `StatusID = 1`: open positions only - closed positions (StatusID=2) do not require ongoing hedge coverage
- GROUP BY (InstrumentID, HedgeServerID, IsBuy): three-dimensional aggregation
  - InstrumentID: separate hedge book per instrument (EUR/USD and GBP/USD hedge independently)
  - HedgeServerID: each hedge server manages its own subset of customer book
  - IsBuy: long and short exposures aggregate separately - they cannot net against each other at this level (netting happens in the hedge server logic, not here)
- SUM(AmountInUnitsDecimal): uses the decimal-precision unit column rather than a rounded integer field, ensuring accurate aggregate exposure

**Diagram**:
```
Trade.PositionTbl (all open customer positions, IsComputeForHedge=1, StatusID=1)
  |
  v
GROUP BY InstrumentID=1, HedgeServerID=1, IsBuy=1 -> Amount=500,000,000
GROUP BY InstrumentID=1, HedgeServerID=1, IsBuy=0 -> Amount=50,000,000
GROUP BY InstrumentID=5, HedgeServerID=1, IsBuy=1 -> Amount=225,000,000
...
  |
  v
Hedge server computes: net per instrument = long_amount - short_amount
  InstrumentID=1: net = 500M - 50M = 450M long -> need 450M hedge coverage
  InstrumentID=5: net = 225M long -> need 225M hedge coverage
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters.*

**Output columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The financial instrument. Groups all customer positions in the same instrument together for a single aggregate exposure figure. FK to Trade.Instrument. |
| 2 | HedgeServerID | int | NO | - | VERIFIED | The hedge server responsible for covering positions in this instrument. Each hedge server manages a subset of the customer book (partitioned by instrument, account type, or other routing logic). FK to Trade.HedgeServer. |
| 3 | Amount | decimal | NO | - | VERIFIED | Total units of customer open exposure for this (InstrumentID, HedgeServerID, IsBuy) combination. Computed as SUM(AmountInUnitsDecimal) from Trade.PositionTbl. This is the raw exposure figure the hedge server must cover. Units are in eToro's internal denomination (requires conversion via Hedge.GetProviderUnitConversion for LP order sizing). |
| 4 | IsBuy | bit | NO | - | VERIFIED | Direction of the aggregated customer exposure. 1=Long (customers bought this instrument), 0=Short (customers sold). The hedge server must take the OPPOSITE position with the LP (if customers are net long, hedge goes short to neutralize). Long and short are returned separately; the hedge server computes the net offset internally. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.PositionTbl | SELECT aggregate | Source of all customer open positions. Filtered to hedge-eligible, open positions and aggregated into net exposure per (instrument, server, direction). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called periodically to compute current customer book exposure for hedge calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetOpenPositionsAmountByHedgeServer (procedure)
└── Trade.PositionTbl (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Read with NOLOCK - aggregated to compute net customer book exposure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - used to compute exposure delta vs current netting book |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. The query uses `WITH (NOLOCK)` to avoid blocking during the aggregation. Performance depends on Trade.PositionTbl indexes for IsComputeForHedge + StatusID + HedgeServerID lookups.

### 7.2 Constraints

N/A for Stored Procedure. Important behavior note: the query filters `DATENAME`-style conditions are NOT applied here (unlike HedgeCostReport) - all open positions are included regardless of day of week. Weekend open positions are included in the exposure calculation.

---

## 8. Sample Queries

### 8.1 Get current aggregate exposure (equivalent to what the procedure returns)
```sql
SELECT  InstrumentID,
        HedgeServerID,
        SUM(AmountInUnitsDecimal) AS Amount,
        IsBuy
FROM    [Trade].[PositionTbl] WITH (NOLOCK)
WHERE   IsComputeForHedge = 1
  AND   StatusID = 1
GROUP BY InstrumentID, HedgeServerID, IsBuy
ORDER BY HedgeServerID, InstrumentID;
```

### 8.2 Net exposure per instrument per server (after calling the procedure)
```sql
-- After loading the SP result into a temp table:
SELECT  InstrumentID,
        HedgeServerID,
        SUM(CASE WHEN IsBuy = 1 THEN Amount ELSE -Amount END) AS NetExposure
FROM    [Trade].[PositionTbl] WITH (NOLOCK)
WHERE   IsComputeForHedge = 1
  AND   StatusID = 1
GROUP BY InstrumentID, HedgeServerID
HAVING  SUM(CASE WHEN IsBuy = 1 THEN Amount ELSE -Amount END) <> 0
ORDER BY ABS(SUM(CASE WHEN IsBuy = 1 THEN Amount ELSE -Amount END)) DESC;
```

### 8.3 Exposure breakdown for a specific hedge server
```sql
SELECT  InstrumentID,
        SUM(AmountInUnitsDecimal) AS Amount,
        IsBuy,
        COUNT(*) AS PositionCount
FROM    [Trade].[PositionTbl] WITH (NOLOCK)
WHERE   IsComputeForHedge = 1
  AND   StatusID = 1
  AND   HedgeServerID = 1
GROUP BY InstrumentID, IsBuy
ORDER BY InstrumentID, IsBuy;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetOpenPositionsAmountByHedgeServer | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetOpenPositionsAmountByHedgeServer.sql*
