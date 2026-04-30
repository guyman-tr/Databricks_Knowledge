# Trade.GetHistoryAndLivePrivatePositionsByCid

> Returns paginated private (non-copy) positions - both open and historical - for a given customer within a date range. Built for MIMO trade data export.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a paginated list of a customer's private positions (both currently open and closed/historical) within a date range. It was created for RD-15320 (Yinon Cohen, 2019-11-04) to support MIMO (trade data for regulatory reporting or data export). The "slim" view provides a lightweight column set suitable for external consumption.

The procedure exists to serve the MIMO integration with paginated trade history. It returns position details with amounts converted from internal cents to dollars, ISNULL-wrapped nullable columns for null safety, and column aliases friendly to external consumers (e.g., `Units` instead of `AmountInUnitsDecimal`, `TotalFees` instead of `EndOfWeekFee`, `StopLossVersion` instead of `SLManualVer`).

Data flow: caller passes @cid, @startTime, @endTime, @pageNumber, @itemsPerPage. The SP enforces a maximum 1-year lookback (clamping @startTime). It queries Trade.GetPositionDataSlim filtered by CID and date range, ordered by OpenOccurred DESC, with OFFSET/FETCH pagination. Uses OPTION(RECOMPILE) for parameter sniffing mitigation.

---

## 2. Business Logic

### 2.1 Maximum Lookback Enforcement

**What**: Prevents queries from scanning more than one year of data.

**Columns/Parameters Involved**: `@startTime`

**Rules**:
- If @startTime is NULL or more than 1 year in the past, it is clamped to `DATEADD(year, -1, GETUTCDATE())`
- Uses UTC time for consistency
- This protects against expensive full-table scans on large position history

### 2.2 Cents-to-Dollars Conversion

**What**: Converts internal cents-based amounts to dollar display values.

**Columns/Parameters Involved**: `InitialAmountCents`, `UnitsBaseValueCents`

**Rules**:
- `InitialAmountInDollars` = `InitialAmountCents / 100` (integer division)
- `UnitsBaseValueDollars` = `CONVERT(DECIMAL(12,2), UnitsBaseValueCents) / 100` (decimal precision preserved)

### 2.3 InitialUnits Fallback

**What**: Handles positions opened before the InitialUnits column existed.

**Columns/Parameters Involved**: `InitialUnits`, `AmountInUnitsDecimal`

**Rules**:
- `InitialUnits` = `ISNULL(InitialUnits, ISNULL(AmountInUnitsDecimal, 0))`
- Falls back to current unit count for legacy positions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID to retrieve positions for. |
| 2 | @startTime | DATETIME | YES | - | CODE-BACKED | Start of date range. Clamped to max 1 year ago if NULL or older. |
| 3 | @endTime | DATETIME | NO | - | CODE-BACKED | End of date range for OpenOccurred filter. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number for pagination. |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Number of positions per page. Used with OFFSET/FETCH. |
| 6 | PositionID (output) | BIGINT | NO | - | CODE-BACKED | Unique position identifier. |
| 7 | CID (output) | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL wrapped to 0). |
| 8 | OpenOccurred (output) | DATETIME | - | - | CODE-BACKED | When the position was opened. Used for date range filter and sort order. |
| 9 | CloseOccurred (output) | DATETIME | YES | - | CODE-BACKED | When the position was closed. NULL for open positions. |
| 10 | InitForexRate (output) | DECIMAL | - | - | CODE-BACKED | Forex conversion rate at position open. |
| 11 | EndForexRate (output) | DECIMAL | YES | - | CODE-BACKED | Forex conversion rate at close. |
| 12 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Financial instrument. FK to Trade.Instrument. |
| 13 | IsBuy (output) | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 14 | LimitRate (output) | DECIMAL | YES | - | CODE-BACKED | Take-profit rate. |
| 15 | StopRate (output) | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate. |
| 16 | MirrorID (output) | BIGINT | NO | 0 | CODE-BACKED | Copy relationship ID (ISNULL to 0). 0 = private/non-copy position. |
| 17 | ParentPositionID (output) | BIGINT | NO | 0 | CODE-BACKED | Parent position in copy hierarchy (ISNULL to 0). 0 = no parent. |
| 18 | Amount (output) | DECIMAL | - | - | CODE-BACKED | Position amount in cents. |
| 19 | Leverage (output) | INT | - | - | CODE-BACKED | Leverage multiplier. |
| 20 | OrderID (output) | BIGINT | NO | 0 | CODE-BACKED | Associated order ID (ISNULL to 0). |
| 21 | Units (output) | DECIMAL | NO | 0 | CODE-BACKED | Amount in units (aliased from AmountInUnitsDecimal, ISNULL to 0). |
| 22 | TotalFees (output) | DECIMAL | YES | - | CODE-BACKED | Total fees (aliased from EndOfWeekFee - includes overnight/weekend fees). |
| 23 | InitialAmountInDollars (output) | INT | - | - | CODE-BACKED | Initial investment in dollars. Computed: InitialAmountCents / 100. |
| 24 | IsTslEnabled (output) | BIT | - | - | CODE-BACKED | Trailing Stop Loss enabled flag. |
| 25 | StopLossVersion (output) | INT | - | - | CODE-BACKED | SL version counter (aliased from SLManualVer). |
| 26 | IsSettled (output) | BIT | - | - | CODE-BACKED | Legacy settlement flag: 1=real stock, 0=CFD. |
| 27 | SettlementTypeID (output) | TINYINT | - | - | CODE-BACKED | Settlement type: 0=CFD, 1=Real, 2=TRS, 5=MarginTrade. See [Settlement Type](../../_glossary.md#settlement-type). |
| 28 | RedeemStatus (output) | INT | NO | 0 | CODE-BACKED | Redeem/copy-stop status (ISNULL to 0). 0=no redeem. |
| 29 | InitialUnits (output) | DECIMAL | NO | 0 | CODE-BACKED | Original unit count at open. Falls back to AmountInUnitsDecimal for legacy positions. |
| 30 | UnitsBaseValueDollars (output) | DECIMAL(12,2) | - | - | CODE-BACKED | Base value of units in dollars. Computed: CONVERT(DECIMAL(12,2), UnitsBaseValueCents) / 100. |
| 31 | NetProfit (output) | DECIMAL | - | - | CODE-BACKED | Net profit/loss of the position. |
| 32 | ClosePositionActionType (output) | INT | YES | - | CODE-BACKED | How the position was closed (aliased from ActionType). NULL for open positions. |
| 33 | TreeID (output) | INT | - | - | CODE-BACKED | Copy-trade tree identifier. |
| 34 | InitConversionRate (output) | DECIMAL | - | - | CODE-BACKED | Initial currency conversion rate. |
| 35 | PnLVersion (output) | INT | - | - | CODE-BACKED | P&L calculation formula version. |
| 36 | OriginalPositionID (output) | BIGINT | YES | - | CODE-BACKED | Original position ID for reopened/adjusted positions. |
| 37 | IsNoStopLoss (output) | BIT | - | - | CODE-BACKED | Whether the position has no stop loss set. |
| 38 | IsNoTakeProfit (output) | BIT | - | - | CODE-BACKED | Whether the position has no take profit set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetPositionDataSlim | FROM (view) | Source of all position data (both open and historical) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHistoryAndLivePrivatePositionsByCid (procedure)
+-- Trade.GetPositionDataSlim (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataSlim | View | FROM - source of position data filtered by CID and date range |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses TRY/CATCH with THROW for error propagation.

---

## 8. Sample Queries

### 8.1 Execute with pagination

```sql
EXEC Trade.GetHistoryAndLivePrivatePositionsByCid
    @cid = 12345,
    @startTime = '2025-06-01',
    @endTime = '2026-03-16',
    @pageNumber = 1,
    @itemsPerPage = 50;
```

### 8.2 Get all pages for last 6 months

```sql
EXEC Trade.GetHistoryAndLivePrivatePositionsByCid
    @cid = 12345,
    @startTime = '2025-09-16',
    @endTime = '2026-03-16',
    @pageNumber = 1,
    @itemsPerPage = 100;
```

### 8.3 Query source view directly with NOLOCK

```sql
SELECT  PositionID, CID, OpenOccurred, CloseOccurred, InstrumentID, IsBuy,
        Amount, Leverage, NetProfit, SettlementTypeID
FROM    Trade.GetPositionDataSlim WITH (NOLOCK)
WHERE   CID = 12345
AND     OpenOccurred BETWEEN '2025-06-01' AND '2026-03-16'
ORDER BY OpenOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Jira RD-15320 cited in SP comment ("Trades Data for MIMO").

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 38 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHistoryAndLivePrivatePositionsByCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetHistoryAndLivePrivatePositionsByCid.sql*
