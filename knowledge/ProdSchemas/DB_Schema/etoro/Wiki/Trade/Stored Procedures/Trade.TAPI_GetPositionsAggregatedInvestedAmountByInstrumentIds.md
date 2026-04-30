# Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds

> Trading API procedure that returns the total USD amount invested per instrument for a customer's direct, unlevered, long real-stock positions, filtered by a caller-supplied list of instrument IDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @InstrumentIDs TVP (real stock portfolio aggregation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers a single question: "How much does customer X currently have invested in each of these specific instruments, across their real stock positions?" It powers the invested-amount display in portfolio and instrument detail views where the Trading API needs to show a customer their aggregated dollar exposure per stock.

The filter combination - `IsSettled = 1, MirrorID = 0, IsBuy = 1, Leverage = 1` - precisely identifies direct real-stock long positions: the customer owns actual shares (not a CFD derivative), placed manually (not via a copy-trade session), in the long direction, with no leverage multiplier. This is the "direct stock ownership" portfolio slice.

The TVP parameter (`@InstrumentIDs Trade.InstrumentIDsTbl`) allows the caller to pass a batch of instruments they care about in one call, rather than making one call per instrument. The result set is one row per instrument (only instruments with matching positions appear - instruments with no positions are silently omitted).

No StatusID filter is applied - positions in both Open (StatusID=1) and Closed-but-not-yet-archived (StatusID=2) states are included. Since closed positions are typically moved to History.Position shortly after close, the practical result is dominated by open positions.

---

## 2. Business Logic

### 2.1 Real Stock Direct Long Filter

**What**: Selects only direct, unlevered, long real-stock positions for the specified customer.

**Columns/Parameters Involved**: `IsSettled`, `MirrorID`, `IsBuy`, `Leverage`, `CID`, `InstrumentID`

**Rules**:
- `CID = @CID` - scopes results to the specified customer
- `IsSettled = 1` - real stock positions only (customer owns actual shares). 0 = CFD.
- `MirrorID = 0` - manual positions only; copy-trade positions (MirrorID > 0) are excluded
- `IsBuy = 1` - long positions only; short positions (IsBuy = 0) are excluded
- `Leverage = 1` - no leverage; positions with leverage > 1 are excluded
- `InstrumentID IN (SELECT InstrumentID FROM @InstrumentIDs)` - further scoped to the caller-supplied instrument set
- No `StatusID` filter - includes both open positions (StatusID=1) and recently-closed pre-archive positions (StatusID=2)
- WITH (NOLOCK) on Trade.PositionTbl for read performance

### 2.2 Invested Amount Aggregation

**What**: Computes total invested amount per instrument across all matching positions.

**Columns/Parameters Involved**: `InstrumentID`, `Amount`, `TotalInvestedAmount`

**Rules**:
- `GROUP BY tpl.InstrumentID` - one output row per instrument
- `SUM(tpl.Amount) AS TotalInvestedAmount` - sum of position sizes in USD across all matching positions for that instrument
- Amount in Trade.PositionTbl is stored in dollars (PositionOpen divides incoming cents by 100)
- Instruments with no matching positions return no row (implicit exclusion via IN clause)
- Result is unordered (no ORDER BY)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Scopes all position aggregation to this customer's own positions. |
| 2 | @InstrumentIDs | Trade.InstrumentIDsTbl READONLY | NO | - | CODE-BACKED | Table-valued parameter. Caller provides the set of InstrumentIDs to aggregate. Only instruments in this list are returned. Typically the instruments visible in the current portfolio view. |

### Output - Invested Amount per Instrument

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. Only instruments with at least one matching position are returned. |
| 2 | TotalInvestedAmount | MONEY | NO | - | CODE-BACKED | Sum of Trade.PositionTbl.Amount across all matching positions for this instrument. Represents the total USD invested in direct real-stock long unlevered positions for this customer and instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, IsSettled, MirrorID, IsBuy, Leverage | Trade.PositionTbl | Lookup (READ) | Source of all position data for the aggregation |
| @InstrumentIDs | Trade.InstrumentIDsTbl | TVP Parameter | Defines the instrument scope passed by the caller |
| InstrumentID | Trade.Instrument | Implicit FK | Identifies the traded asset |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds (procedure)
├── Trade.PositionTbl (table)
└── Trade.InstrumentIDsTbl (UDT - TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of position data (CID, InstrumentID, Amount, IsSettled, MirrorID, IsBuy, Leverage) |
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for the @InstrumentIDs parameter |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Query likely uses `IX_CID_InstrumentIdNew1` on Trade.PositionTbl (CID, MirrorID, InstrumentID, Leverage, IsBuy, StatusID) which aligns well with the WHERE clause.

### 7.2 Constraints

None. Key behavioral characteristics:
- No StatusID filter - includes open AND recently-closed (pre-archive) positions
- No result row for instruments with no matching positions (implicit exclusion)
- No ORDER BY - result is unordered; caller is responsible for ordering
- READONLY TVP prevents modification of the input set within the procedure
- WITH (NOLOCK) allows dirty reads for performance

---

## 8. Sample Queries

### 8.1 Get invested amounts for specific instruments

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl;
INSERT INTO @Instruments (InstrumentID) VALUES (1001), (1002), (1003);

EXEC Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds
    @CID = 12345,
    @InstrumentIDs = @Instruments;
```

### 8.2 Preview directly - same filter logic

```sql
SELECT
    tpl.InstrumentID,
    SUM(tpl.Amount) AS TotalInvestedAmount
FROM Trade.PositionTbl tpl WITH (NOLOCK)
WHERE tpl.CID = 12345
    AND tpl.IsSettled = 1
    AND tpl.MirrorID = 0
    AND tpl.IsBuy = 1
    AND tpl.Leverage = 1
    AND tpl.InstrumentID IN (1001, 1002, 1003)
GROUP BY tpl.InstrumentID
```

### 8.3 Check what qualifies as a direct real-stock position

```sql
-- Direct, unlevered, long real-stock positions for a customer
SELECT
    tpl.PositionID,
    tpl.InstrumentID,
    tpl.Amount,
    tpl.IsSettled,
    tpl.MirrorID,
    tpl.IsBuy,
    tpl.Leverage,
    tpl.StatusID,
    tpl.InitDateTime
FROM Trade.PositionTbl tpl WITH (NOLOCK)
WHERE tpl.CID = 12345
    AND tpl.IsSettled = 1
    AND tpl.MirrorID = 0
    AND tpl.IsBuy = 1
    AND tpl.Leverage = 1
ORDER BY tpl.InstrumentID, tpl.InitDateTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds.sql*
