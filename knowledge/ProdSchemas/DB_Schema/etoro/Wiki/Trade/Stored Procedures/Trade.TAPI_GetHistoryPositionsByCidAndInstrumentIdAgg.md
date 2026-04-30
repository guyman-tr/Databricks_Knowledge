# Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg

> Trading API procedure that returns aggregate totals (count, invested, P&L, fees, lot count) for a customer's closed manual positions on a specific instrument - the summary header for the per-instrument position list.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @instrumentId INT (composite aggregate, single row output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the aggregate companion to `TAPI_GetHistoryPositionsByCidAndInstrumentId`. It applies the same filter (customer + instrument + manual trades only + optional date range) but instead of returning individual position rows, it returns a single summary row with totals: total count, total invested, total P&L, total fees (split into fee type breakdown), and total lot count.

This summary row powers the header or summary card shown above the paginated position list in the per-instrument drill-down view. For example: "You made 5 trades in AAPL. Total invested: $5,000. Net profit: +$342. Total fees: $18.50." The application calls both this procedure (for the header) and `TAPI_GetHistoryPositionsByCidAndInstrumentId` (for the list below).

It always returns exactly one row (even if there are zero matching positions, ISNULL ensures zeros rather than NULL).

---

## 2. Business Logic

### 2.1 Same Filter as List Companion

**What**: Identical WHERE clause to `TAPI_GetHistoryPositionsByCidAndInstrumentId` - ensures the aggregate matches the list.

**Columns/Parameters Involved**: `@cid`, `@instrumentId`, `MirrorID`, `@startTime`, `CloseOccurred`

**Rules**:
- `WHERE CID = @cid AND InstrumentID = @instrumentId AND MirrorID = 0 AND (CloseOccurred >= @startTime OR @startTime IS NULL)`
- Exactly mirrors the list procedure filter - any position in the list is counted in these totals
- No pagination - returns one row for all matching positions

### 2.2 Fee Decomposition

**What**: Breaks fees into four components for detailed fee attribution.

**Columns/Parameters Involved**: `EndOfWeekFee`, `CloseTotalFees`, `CloseTotalTaxes`, `OpenTotalFees`, `OpenTotalTaxes`

**Rules**:
- `TotalFeesDollars = SUM(EndOfWeekFee)` - overnight/weekend holding fees only
- `CloseTotalFees = SUM(CloseTotalFees)` - fees at close (spread, commission)
- `CloseTotalTaxes = SUM(CloseTotalTaxes)` - taxes at close
- `OpenTotalFees = SUM(OpenTotalFees)` - fees at open
- `OpenTotalTaxes = SUM(OpenTotalTaxes)` - taxes at open
- All ISNULL-wrapped to return 0 when no matching positions exist

### 2.3 Lot Count Aggregation

**What**: Sums total lot count for the filtered positions.

**Columns/Parameters Involved**: `LotCountDecimal`, `TotalLotCount`

**Rules**:
- `TotalLotCount = ISNULL(SUM(LotCountDecimal), 0)` - total size of all positions expressed in lots
- Useful for lot-based fee calculations and compliance reporting

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Scopes aggregation to this customer's positions only. |
| 2 | @instrumentId | INT | NO | - | CODE-BACKED | Instrument ID. Only closed positions for this specific instrument are included in aggregates. FK to Trade.InstrumentMetaData. |
| 3 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional period start. When NULL: aggregates all-time history. When provided: only positions with CloseOccurred >= @startTime. Must match the @startTime passed to the companion list procedure `TAPI_GetHistoryPositionsByCidAndInstrumentId`. |

### Output - Aggregate Totals (Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Total | INT | NO | 0 | CODE-BACKED | Total count of closed manual positions for @cid + @instrumentId in the period. COUNT(1) ISNULL-wrapped; returns 0 when no positions match. |
| 2 | TotalInitialInvestmentDollars | DECIMAL | NO | 0 | CODE-BACKED | Sum of initial invested amounts in USD. Derived: ISNULL(SUM(InitialAmountCents), 0) / 100. Converts cents to dollars after summing for precision. |
| 3 | TotalAmountDollars | DECIMAL | NO | 0 | CODE-BACKED | Sum of Amount (position invested amount field) across all matching positions in USD. |
| 4 | TotalNetProfitDollars | DECIMAL | NO | 0 | CODE-BACKED | Total realized P&L across all matching positions in USD. Positive = net gain, negative = net loss. |
| 5 | TotalFeesDollars | DECIMAL | NO | 0 | CODE-BACKED | Sum of EndOfWeekFee (overnight/weekend holding fees) across all matching positions. Does not include open/close fees (those are in CloseTotalFees and OpenTotalFees). |
| 6 | CloseTotalFees | DECIMAL | NO | 0 | CODE-BACKED | Sum of close-time fees (spread, commission) across all matching positions. |
| 7 | CloseTotalTaxes | DECIMAL | NO | 0 | CODE-BACKED | Sum of taxes collected at close across all matching positions. |
| 8 | OpenTotalFees | DECIMAL | NO | 0 | CODE-BACKED | Sum of fees charged at open across all matching positions. |
| 9 | OpenTotalTaxes | DECIMAL | NO | 0 | CODE-BACKED | Sum of taxes collected at open across all matching positions. |
| 10 | TotalLotCount | DECIMAL | NO | 0 | CODE-BACKED | Sum of LotCountDecimal across all matching positions - total position size expressed in lots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, MirrorID, CloseOccurred | History.PositionSlim | Lookup (READ) | Source of all aggregated data; same filter as the companion list procedure |
| InstrumentID | Trade.InstrumentMetaData | Implicit FK | Identifies the traded asset being aggregated |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Always paired with `Trade.TAPI_GetHistoryPositionsByCidAndInstrumentId` - the application calls both together.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg (procedure)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of all aggregated position data |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Key behavioral characteristics:
- Always returns exactly one row (aggregate with ISNULL defaults ensures no NULL/empty result)
- No pagination parameters - aggregates all matching rows
- No ORDER BY - single-row result needs no ordering
- WITH (NOLOCK) on History.PositionSlim
- TotalInitialInvestmentDollars sum order: SUM(InitialAmountCents) first, then /100 - preserves cents-level precision in the sum before conversion

---

## 8. Sample Queries

### 8.1 Get aggregate summary for a specific instrument

```sql
EXEC Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg
    @cid = 12345,
    @instrumentId = 1,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE())
```

### 8.2 Get all-time aggregate for an instrument

```sql
EXEC Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg
    @cid = 12345,
    @instrumentId = 1,
    @startTime = NULL
```

### 8.3 Reproduce the aggregate directly

```sql
SELECT
    ISNULL(COUNT(1), 0) AS Total,
    ISNULL(SUM(hp.InitialAmountCents), 0) / 100 AS TotalInitialInvestmentDollars,
    ISNULL(SUM(hp.Amount), 0) AS TotalAmountDollars,
    ISNULL(SUM(hp.NetProfit), 0) AS TotalNetProfitDollars,
    ISNULL(SUM(hp.EndOfWeekFee), 0) AS TotalFeesDollars,
    ISNULL(SUM(hp.LotCountDecimal), 0) AS TotalLotCount
FROM History.PositionSlim hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND hp.InstrumentID = 1
    AND hp.MirrorID = 0
    AND (hp.CloseOccurred >= DATEADD(YEAR, -1, GETUTCDATE()) OR 1=0)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPositionsByCidAndInstrumentIdAgg.sql*
