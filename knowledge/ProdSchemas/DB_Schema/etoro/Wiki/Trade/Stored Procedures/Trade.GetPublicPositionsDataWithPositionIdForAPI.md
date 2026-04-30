# Trade.GetPublicPositionsDataWithPositionIdForAPI

> Returns a reduced public-safe subset of open position fields for a single position by PositionID, from Trade.Position. Single-record lookup variant of GetPublicPositionsDataWithCIDForAPI.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @positionId BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a limited, public-safe set of open position fields for a single position identified by PositionID. It is the single-record lookup variant of `Trade.GetPublicPositionsDataWithCIDForAPI` (which returns all positions for a customer). It returns the same 10 public-safe fields - omitting sensitive financial data such as Amount, Leverage, and EndOfWeekFee.

The "Public" naming indicates this feeds public API endpoints (social feed, public portfolio, external position views) rather than internal trading operations. As with the CID variant, it reads from `Trade.Position` (open positions view), so a request for a closed position returns 0 rows.

Change history: PositionID parameter was changed from INT to BIGINT on 17/11/2021 (noted in the DDL comment: "Bonnie - Change positionID to bigint") to accommodate the growing position ID space.

---

## 2. Business Logic

### 2.1 Single Public Position Lookup by PositionID

**What**: Returns the public-safe fields for one specific open position.

**Columns/Parameters Involved**: `@positionId`, `Trade.Position`

**Rules**:
- Returns 0 rows if the position is closed (not present in Trade.Position view).
- Returns 0 rows if the position does not exist.
- ISNULL coercion on MirrorID, OrderID, ParentPositionID - zero-safe for public display.

**Diagram**:
```
@positionId (BIGINT)
  |
  v
Trade.Position (view - open positions only, StatusID=1)
  WHERE PositionID = @positionId
  |
  OUTPUT (10 public fields):
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
| 1 | @positionId | BIGINT | NO | - | CODE-BACKED | The specific open position to retrieve. Changed from INT to BIGINT on 2021-11-17 to support large position ID values. Returns 0 rows if position is closed or non-existent. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | VERIFIED | Unique position identifier. Echoed from the input filter. |
| 3 | CID | INT | NO | - | VERIFIED | Customer ID who owns the position. ISNULL(CID, 0) - zero-safe. |
| 4 | InitDateTime | DATETIME | NO | - | VERIFIED | Timestamp when position was opened. App property: Position.OpenDateTime. |
| 5 | InitForexRate | DECIMAL | NO | - | VERIFIED | Instrument price at open (open rate). Used by public portfolio display. App property: Position.OpenRate. |
| 6 | InstrumentID | INT | NO | - | VERIFIED | The traded instrument. FK to Trade.Instrument. |
| 7 | IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Buy/Long, 0=Sell/Short. |
| 8 | LimitRate | DECIMAL | NO | - | VERIFIED | Take-profit rate. 0 if not set. App property: Position.TakeProfitRate. |
| 9 | StopRate | DECIMAL | NO | - | VERIFIED | Stop-loss rate. 0 if not set. |
| 10 | MirrorID | INT | NO | - | VERIFIED | CopyTrader mirror ID. ISNULL(MirrorID, 0) - 0=manual, >0=copy trade. FK to Trade.Mirror. |
| 11 | OrderID | BIGINT | NO | - | VERIFIED | Opening order ID. ISNULL(OrderID, 0) - 0 if no associated order. FK to Trade.Orders. |
| 12 | ParentPositionID | BIGINT | NO | - | VERIFIED | Leader's position this was copied from. ISNULL(ParentPositionID, 0) - 0=root/manual. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @positionId / all output | Trade.Position | Reader | Open position data for the specified position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @positionId | Application call | Single position public detail lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicPositionsDataWithPositionIdForAPI (procedure)
+-- Trade.Position (view)
      +-- Trade.PositionTbl (table)
      +-- Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT single open position filtered by PositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Single position public field retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED for API performance |
| Trade.Position view | Implicit filter | Only StatusID=1 (open) positions returned |
| @positionId BIGINT | Parameter type | Changed from INT to BIGINT on 2021-11-17 (DDL comment: "Bonnie - Change positionID to bigint") |

---

## 8. Sample Queries

### 8.1 Get public position data for a specific position

```sql
EXEC Trade.GetPublicPositionsDataWithPositionIdForAPI @positionId = 123456789012;
```

### 8.2 Equivalent inline query

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
WHERE p.PositionID = 123456789012;
```

### 8.3 Check if a position is still open (returns row) or closed (returns 0 rows)

```sql
-- Returns 1 row if open, 0 rows if closed or non-existent
SELECT COUNT(*) AS IsOpen
FROM Trade.Position WITH (NOLOCK)
WHERE PositionID = 123456789012;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicPositionsDataWithPositionIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicPositionsDataWithPositionIdForAPI.sql*
