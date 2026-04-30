# Trade.GetPublicPositionsDataWithCIDForAPI

> Returns a reduced public-safe subset of open position fields for all positions belonging to a given customer, from Trade.Position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a limited, public-safe set of open position fields for all open positions belonging to a customer. It is the "public" variant of `Trade.GetPositionsDataWithCIDForAPI` - it returns only 10 position fields compared to the 35+ columns in the full internal version. Fields such as Amount, Leverage, SettlementTypeID, EndOfWeekFee, and PnL-related columns are intentionally excluded to avoid exposing sensitive financial data in public-facing API responses.

The "Public" naming convention in eToro indicates that this procedure feeds public API endpoints accessible to external consumers (e.g., social feed, public portfolio pages) rather than the internal trading engine. The returned fields are sufficient to reconstruct a positional summary (instrument, direction, open rate, SL/TP, copy-trade lineage) without revealing the financial risk profile.

Data reads from `Trade.Position` (the open-positions view), so only positions with StatusID=1 are returned. Nullable fields (MirrorID, OrderID, ParentPositionID) are coerced to 0 via ISNULL to provide a clean, non-null response for the API layer.

---

## 2. Business Logic

### 2.1 Public Field Subset Selection

**What**: Exposes only non-sensitive positional fields to external API consumers, deliberately omitting financial exposure fields.

**Columns/Parameters Involved**: All output columns are from `Trade.Position`

**Rules**:
- No Amount, Leverage, EndOfWeekFee, SettlementTypeID, IsSettled - financial sensitivity excluded.
- No OrderForCloseID, RedeemStatus, PnlVersion - lifecycle/state excluded.
- ISNULL coercion on MirrorID, OrderID, ParentPositionID - zero-safe for public display.
- INNER JOIN semantics from Trade.Position view ensure only open positions are returned.

**Diagram**:
```
@cid
  |
  v
Trade.Position (view - StatusID=1 open positions only)
  WHERE CID = @cid
  |
  OUTPUT (public subset - 10 fields):
    PositionID, CID, InitDateTime, InitForexRate,
    InstrumentID, IsBuy, LimitRate, StopRate,
    MirrorID, OrderID, ParentPositionID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID whose public open positions to retrieve. All open positions for this customer are returned. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | VERIFIED | Unique position identifier. From Trade.PositionTbl PK via Trade.Position view. |
| 3 | CID | INT | NO | - | VERIFIED | Customer ID. ISNULL(CID, 0) - zero-safe output. Identifies the position owner. |
| 4 | InitDateTime | DATETIME | NO | - | VERIFIED | Timestamp when position was opened. App property: Position.OpenDateTime. |
| 5 | InitForexRate | DECIMAL | NO | - | VERIFIED | Instrument price at position open (open rate). Used by public portfolio display. App property: Position.OpenRate. |
| 6 | InstrumentID | INT | NO | - | VERIFIED | The traded instrument (e.g., 1=EURUSD, 5=GBPUSD). FK to Trade.Instrument. |
| 7 | IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy/Long, 0=Sell/Short. |
| 8 | LimitRate | DECIMAL | NO | - | VERIFIED | Take-profit rate. 0 if no take-profit set. App property: Position.TakeProfitRate. LimitRate IS the take-profit rate. |
| 9 | StopRate | DECIMAL | NO | - | VERIFIED | Stop-loss rate. 0 if no stop-loss set. App reads as stopLossRate parameter in Position constructor. |
| 10 | MirrorID | INT | NO | - | VERIFIED | CopyTrader mirror ID. ISNULL(MirrorID, 0) - 0=manual/non-copy trade, >0=copy-trade linked to mirror. FK to Trade.Mirror. |
| 11 | OrderID | BIGINT | NO | - | VERIFIED | Opening order ID. ISNULL(OrderID, 0) - 0 if position has no associated order. FK to Trade.Orders. |
| 12 | ParentPositionID | BIGINT | NO | - | VERIFIED | Leader's position this was copied from. ISNULL(ParentPositionID, 0) - 0=root/manual position, >0=copied child. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid / all output | Trade.Position | Reader | Primary data source - open positions view filtered by customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @cid | Application call | Public portfolio endpoint - customer's open positions for external display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicPositionsDataWithCIDForAPI (procedure)
+-- Trade.Position (view)
      +-- Trade.PositionTbl (table)
      +-- Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT open positions for the customer - provides all output columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Returns customer open positions for public portfolio pages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED for API performance |
| Trade.Position view | Implicit filter | Only StatusID=1 (open) positions returned |

---

## 8. Sample Queries

### 8.1 Get public position data for a customer

```sql
EXEC Trade.GetPublicPositionsDataWithCIDForAPI @cid = 14952810;
```

### 8.2 Equivalent inline query showing public field selection

```sql
SELECT p.PositionID,
       ISNULL(p.CID, 0) AS CID,
       p.InitDateTime,
       p.InitForexRate,
       p.InstrumentID,
       p.IsBuy,
       p.LimitRate,
       p.StopRate,
       ISNULL(p.MirrorID, 0) AS MirrorID,
       ISNULL(p.OrderID, 0) AS OrderID,
       ISNULL(p.ParentPositionID, 0) AS ParentPositionID
FROM Trade.Position p WITH (NOLOCK)
WHERE p.CID = 14952810;
```

### 8.3 Count copy-trade vs manual open positions for a customer

```sql
SELECT
    CASE WHEN ISNULL(MirrorID, 0) = 0 THEN 'Manual' ELSE 'CopyTrade' END AS PositionType,
    COUNT(*) AS PositionCount
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 14952810
GROUP BY CASE WHEN ISNULL(MirrorID, 0) = 0 THEN 'Manual' ELSE 'CopyTrade' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicPositionsDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicPositionsDataWithCIDForAPI.sql*
