# Hedge.CustomerClosedPositions_New

> Table-valued parameter type carrying aggregated realized P&L data per hedge server and instrument, used to insert customer closed-position snapshots in bulk.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | User Defined Type (TABLE type) |
| **Key Identifier** | No primary key (heap TVP) |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

`Hedge.CustomerClosedPositions_New` is a Table-Valued Parameter (TVP) type that carries a batch of aggregated realized position data - grouped by hedge server and instrument - into a stored procedure. Each row represents the total net P&L, commission charged at close, and execution volume for a HedgeServer/Instrument combination within a computation period.

This type exists to support the "_New" data flow, where realized customer position data is sourced from a newer data feed or computation path (as opposed to the legacy flow). The "New" suffix in both this type and its consumer procedure (`AddCustomerRealizedData`) and reader (`GetCustomerClosedPositionsData_NewData`) indicates a parallel data pipeline built alongside the original one.

Data flows into this TVP from the calling service after it has aggregated closed position PnL. The populated TVP is passed to `Hedge.AddCustomerRealizedData`, which inserts the rows into the underlying `Hedge.CustomerClosedPositions` table (or a "_New" variant).

---

## 2. Business Logic

### 2.1 Realized P&L Aggregation Payload

**What**: Each TVP row is a pre-aggregated tuple of realized financial outcomes for one HedgeServer/Instrument pair.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`, `NetPL`, `CommissionOnClose`, `ExecutionVolumeInUSD`

**Rules**:
- All financial columns (`NetPL`, `CommissionOnClose`, `ExecutionVolumeInUSD`) are `decimal(18,6)` and nullable - a NULL means the caller did not have data for that measure in this period.
- `NetPL` represents the sum of customer realized profit/loss on this instrument via this hedge server - positive means customers profited (hedge server lost), negative means customers lost (hedge server gained).
- `CommissionOnClose` captures fees collected from customers when positions were closed.
- `ExecutionVolumeInUSD` tracks the total notional volume executed, used for hedge cost ratio reporting.
- No PK constraint - the TVP is a heap, so duplicate HedgeServerID/InstrumentID combinations are allowed (caller must deduplicate before passing if needed).

**Diagram**:
```
Caller (computation service)
  |
  | aggregates closed positions by (HedgeServerID, InstrumentID)
  |
  | passes Hedge.CustomerClosedPositions_New TVP
  v
Hedge.AddCustomerRealizedData (SP)
  |
  v
Hedge.CustomerClosedPositions (or _New variant table)
```

---

## 3. Data Overview

N/A for User Defined Type. This is an in-memory parameter container; no rows are stored persistently.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeServerID | int | YES | - | CODE-BACKED | Identifier of the hedge server instance through which the customer positions were hedged. Groups realized P&L by server for hedge cost reconciliation. Implicit FK to Trade.HedgeServer. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Identifier of the trading instrument (stock, crypto, forex pair, etc.) for which the P&L is aggregated. Implicit FK to Trade.Instrument. |
| 3 | NetPL | decimal(18,6) | YES | - | CODE-BACKED | Net realized profit/loss for this HedgeServer/Instrument combination in the computation period, in USD. Positive = customer profit (hedge short), negative = customer loss (hedge profit). Precision 18,6 supports sub-cent accuracy for large portfolios. |
| 4 | CommissionOnClose | decimal(18,6) | YES | - | CODE-BACKED | Total spread/commission fees collected from customers when closing positions on this instrument via this hedge server, in USD. Part of the eToro revenue component in hedge cost analysis. |
| 5 | ExecutionVolumeInUSD | decimal(18,6) | YES | - | CODE-BACKED | Total notional execution volume in USD for positions closed on this instrument via this hedge server. Used to calculate hedge cost as a percentage of volume in HedgeCostReport procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies which hedge server's customer PnL is being reported |
| InstrumentID | Trade.Instrument | Implicit | Identifies which trading instrument the aggregated PnL belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddCustomerRealizedData | @CustomerClosedPositions parameter | TVP parameter | Receives this TVP to bulk-insert realized customer P&L data |
| Hedge.GetCustomerClosedPositionsData_NewData | @CustomerClosedPositions parameter | TVP parameter | May use this TVP to read/validate the new data feed |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf TVP type).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddCustomerRealizedData | Stored Procedure | Declares a parameter of this type to receive bulk realized P&L data for insert |
| Hedge.GetCustomerClosedPositionsData_NewData | Stored Procedure | References this type in its parameter signature |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for realized data insert
```sql
DECLARE @ClosedPos [Hedge].[CustomerClosedPositions_New]
INSERT INTO @ClosedPos (HedgeServerID, InstrumentID, NetPL, CommissionOnClose, ExecutionVolumeInUSD)
VALUES (1, 100, -12500.500000, 350.250000, 2500000.000000),
       (1, 200,   8200.100000, 120.000000,  800000.000000)

EXEC [Hedge].[AddCustomerRealizedData] @CustomerClosedPositions = @ClosedPos
```

### 8.2 Check current realized P&L in the underlying table
```sql
SELECT TOP 10 HedgeServerID, InstrumentID, NetPL, CommissionOnClose, ExecutionVolumeInUSD, OccurredAt
FROM [Hedge].[CustomerClosedPositions] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

### 8.3 Aggregate execution volume by hedge server
```sql
SELECT HedgeServerID, SUM(ExecutionVolumeInUSD) AS TotalVolumeUSD
FROM [Hedge].[CustomerClosedPositions] WITH (NOLOCK)
WHERE OccurredAt >= DATEADD(day, -1, GETUTCDATE())
GROUP BY HedgeServerID
ORDER BY TotalVolumeUSD DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.CustomerClosedPositions_New | Type: User Defined Type | Source: etoro/etoro/Hedge/User Defined Types/Hedge.CustomerClosedPositions_New.sql*
