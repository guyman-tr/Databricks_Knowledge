# Trade.SSRS_CustomerCopyPositions

> SSRS report procedure that returns all copy-trading positions (open and closed) for a customer, combining live and historical data with optional instrument filtering.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT (customer filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers SQL Server Reporting Services (SSRS) reports that display a customer's complete copy-trading position history. It returns every position the customer held as a copy trader (a follower, not a leader), including both currently open positions and fully closed/historical positions.

The procedure exists to give operations and support teams a unified view of a customer's copy-trading activity across time. Without it, analysts would need to query both the live `Trade.PositionTbl` and the historical archive `History.PositionSlim` separately and manually union the results.

Data flows through this procedure as follows: open copy positions are read from `Trade.PositionTbl` where `MirrorID > 0 AND ParentPositionID > 0` (identifying the position as a copy-trade child, not the leader's original), while closed positions are read from `History.PositionSlim` using the same filter criteria. Both sets are merged into a temporary staging table and returned enriched with instrument symbol and a human-readable side label.

---

## 2. Business Logic

### 2.1 Copy Position Identification

**What**: Identifies positions that were opened as part of a copy-trading relationship (the customer is a copier, not the original trader).

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`

**Rules**:
- `MirrorID > 0`: The position is linked to an active copy-trading mirror (Trade.Mirror). A value of 0 indicates a manual trade.
- `ParentPositionID > 0`: The position is a copy of a leader's position. A value of 0 would indicate the leader's original position.
- Both conditions must be true simultaneously to qualify as a copy-trade child position.
- This filter is applied identically to both open (Trade.PositionTbl) and historical (History.PositionSlim) datasets.

**Diagram**:
```
Copy Position Filter:
  MirrorID > 0        -> position belongs to a copy-trade mirror
  ParentPositionID > 0 -> position is a copy (not the leader's original)
  Both required       -> identifies copier's child positions only

  Trade.PositionTbl  (open positions)  --+
                                          |--> #position_temp --> final result
  History.PositionSlim (closed positions) --+
```

### 2.2 Optional Instrument Filter

**What**: Controls whether the report returns all copy positions or only those for a specific instrument.

**Columns/Parameters Involved**: `@InstrumentID`

**Rules**:
- `@InstrumentID = 0` (default): All instruments are returned. The WHERE clause uses `@InstrumentID = 0 AND (CID = @CID AND MirrorID > 0 AND ParentPositionID > 0)`.
- `@InstrumentID > 0`: Only positions for the specified instrument are returned.
- The same two-branch logic is applied to both Trade.PositionTbl and History.PositionSlim inserts.

**Diagram**:
```
@InstrumentID = 0  -> all copy positions for customer
@InstrumentID > 0  -> copy positions for that specific instrument only
```

### 2.3 Dead Mirror Join (Legacy Pattern)

**What**: A LEFT JOIN to Trade.Mirror exists in the final SELECT but no columns from it are used in the output.

**Columns/Parameters Involved**: `MirrorID`, `@CID`

**Rules**:
- The subquery `OpenPositions` selects MirrorIDs from Trade.Mirror for the given CID.
- This is joined as LEFT JOIN - all positions from #position_temp are returned regardless.
- No OpenPositions columns are in the SELECT list.
- This appears to be a legacy remnant - the join was likely originally used to flag whether a position's mirror is still active, but the flag column was removed from output while the join was left in place.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID (CID) for whom copy positions are retrieved. Filters both Trade.PositionTbl and History.PositionSlim. FK to Customer schema customer identifier. |
| 2 | @InstrumentID | INT | YES | 0 | CODE-BACKED | Optional instrument filter. When 0 (default), returns copy positions for all instruments. When > 0, restricts results to the specified instrument. FK to Trade.InstrumentMetaData.InstrumentID. |

### Output Columns (Result Set)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier. Sourced from Trade.PositionTbl (open) or History.PositionSlim (closed). PK of the position record. |
| 2 | MirrorID | INT | YES | - | CODE-BACKED | Copy-trading mirror identifier linking this position to the Trade.Mirror relationship. Always > 0 for positions returned by this procedure (filter condition). |
| 3 | CID | INT | YES | - | CODE-BACKED | Customer ID of the copier who holds this position. Matches the @CID input parameter for all returned rows. |
| 4 | Side | VARCHAR | NO | - | CODE-BACKED | Human-readable trade direction: 'BUY' when IsBuy = 1 (long position), 'SELL' when IsBuy = 0 (short position). Computed in procedure via IIF(IsBuy = 1, 'BUY', 'SELL'). |
| 5 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol (e.g., 'AAPL', 'EUR/USD'). Sourced from Trade.InstrumentMetaData joined on InstrumentID. NULL if instrument has no metadata record. |
| 6 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.InstrumentMetaData.InstrumentID. Identifies the traded asset. |
| 7 | AmountInUnitsDecimal | DECIMAL(16,6) | YES | - | CODE-BACKED | Position size in instrument units (e.g., number of shares or contracts). Decimal precision supports fractional units for crypto and fractional share trading. |
| 8 | InitDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the position was originally opened/created. From Trade.PositionTbl or History.PositionSlim. |
| 9 | Occurred | DATETIME | YES | - | CODE-BACKED | Timestamp when a position-state event occurred (typically the close time for historical positions). NULL for open positions sourced from Trade.PositionTbl (set to NULL explicitly in the PositionSlim insert - note: open positions also produce NULL here since PositionTbl insert reads TP.Occurred which may be NULL for open positions). Ordered DESC in the final result. |
| 10 | NetProfit | MONEY | NO | - | CODE-BACKED | Net profit or loss of the position at the time of the query. For open positions from PositionTbl, this reflects current unrealized or realized P&L. For closed positions from PositionSlim, this is the final realized P&L. |
| 11 | Amount | MONEY | NO | - | CODE-BACKED | Invested amount in the position's currency (typically USD). Represents the monetary value allocated to open this copy position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Trade.PositionTbl | Lookup (READ) | Reads open copy positions filtered by CID, MirrorID > 0, ParentPositionID > 0 |
| (source table) | History.PositionSlim | Lookup (READ) | Reads closed/historical copy positions with the same filter criteria |
| MirrorID | Trade.Mirror | Lookup (JOIN - LEFT, unused output) | LEFT JOINs to Mirror to find mirrors owned by @CID; no output columns selected from this join |
| InstrumentID | Trade.InstrumentMetaData | Lookup (JOIN) | LEFT JOINs to retrieve instrument Symbol for the output result set |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This procedure is an SSRS report procedure - it is called directly from SSRS report server, not from other stored procedures or application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SSRS_CustomerCopyPositions (procedure)
├── Trade.PositionTbl (table)
├── History.PositionSlim (table - cross-schema)
├── Trade.Mirror (table)
└── Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT source for open copy positions (MirrorID > 0, ParentPositionID > 0) |
| History.PositionSlim | Table (cross-schema) | SELECT source for closed/historical copy positions (same filter) |
| Trade.Mirror | Table | LEFT JOIN in final SELECT to subquery of mirrors owned by @CID (legacy - no output columns used) |
| Trade.InstrumentMetaData | Table | LEFT JOIN to retrieve Symbol column for final result set |

### 6.2 Objects That Depend On This

No dependents found. Called directly from SSRS report server.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all copy positions for a customer

```sql
EXEC Trade.SSRS_CustomerCopyPositions @CID = 12345
```

### 8.2 Get copy positions for a specific instrument

```sql
EXEC Trade.SSRS_CustomerCopyPositions @CID = 12345, @InstrumentID = 7 -- e.g., EUR/USD
```

### 8.3 Preview underlying copy position data directly

```sql
SELECT TOP 10
    TP.PositionID,
    TP.MirrorID,
    TP.CID,
    IIF(TP.IsBuy = 1, 'BUY', 'SELL') AS Side,
    TIM.Symbol,
    TP.NetProfit,
    TP.Amount
FROM Trade.PositionTbl TP WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData TIM WITH (NOLOCK)
    ON TP.InstrumentID = TIM.InstrumentID
WHERE TP.CID = 12345
    AND TP.MirrorID > 0
    AND TP.ParentPositionID > 0
ORDER BY TP.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SSRS_CustomerCopyPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SSRS_CustomerCopyPositions.sql*
