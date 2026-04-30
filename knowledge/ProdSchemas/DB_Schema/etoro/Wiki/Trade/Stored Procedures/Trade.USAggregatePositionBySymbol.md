# Trade.USAggregatePositionBySymbol

> Aggregates daily buy and sell activity (dollar value and share count) for specified symbols, scoped to US-regulated customers (ApexID IS NOT NULL), combining open positions from PositionTbl with closed positions from History.PositionSlim.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SymbolsInput / @SymbolsSeparetors (comma-separated); modifies none - read-only reporting |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

eToro's US regulatory framework (via Apex Clearing) requires monitoring of daily trading volumes by instrument symbol. This procedure produces the daily aggregate view of buy and sell activity for US customers (those with a non-null ApexID in Customer.CustomerStatic) - reporting gross notional value and share count for both buy and sell sides.

The output is used for regulatory reporting and Apex Clearing compliance, where eToro must demonstrate position concentrations and trading volumes for US-regulated instruments. The @SymbolsInput and @SymbolsSeparetors parameters accept comma-separated symbol lists from two different input paths, accommodating different calling conventions. If no valid symbols are provided (or none match), the procedure falls back to all instruments on exchanges 4 and 5 (the US exchanges).

The companion procedure `Trade.USAggregatePositionBySymbolForMonitor` is a simplified version of this procedure used for monitoring dashboards.

---

## 2. Business Logic

### 2.1 Symbol Resolution and US Exchange Fallback

**What**: Resolves input symbols to InstrumentIDs; falls back to all US exchange instruments if none match.

**Columns/Parameters Involved**: `@SymbolsInput`, `@SymbolsSeparetors`, `#cte_id`, `ExchangeID`

**Rules**:
- Both @SymbolsInput and @SymbolsSeparetors are split on ',' and inserted into @Symbols TVP (Trade.SymbolsList)
- The two parameters allow callers to pass symbols through either mechanism or both simultaneously
- #cte_id is populated from Trade.InstrumentMetaData WHERE Symbol IN (@Symbols)
- If no rows matched (i.e., none of the input symbols exist) -> fallback: INSERT all InstrumentIDs WHERE ExchangeID IN (4, 5)
- ExchangeID 4 and 5 = US stock exchanges (NYSE and NASDAQ or equivalent)
- @CurrentTradeDay defaults to current UTC date if NULL

**Diagram**:
```
@SymbolsInput + @SymbolsSeparetors
    -> STRING_SPLIT(',') -> @Symbols TVP
    -> InstrumentMetaData WHERE Symbol IN @Symbols -> #cte_id
    -> if #cte_id empty: fallback to ExchangeID IN (4,5) -> #cte_id
```

### 2.2 US Customer Scoping via ApexID

**What**: Limits all position data to US-regulated customers only.

**Columns/Parameters Involved**: `ApexID`, `#cid`, `Customer.CustomerStatic`

**Rules**:
- #cid = all CID values from Customer.CustomerStatic WHERE ApexID IS NOT NULL
- Only customers with an Apex Clearing account ID are included
- This excludes non-US customers and demo accounts (which typically lack ApexID)
- All position queries JOIN to #cid to enforce this scoping

### 2.3 Dual-Source Aggregation: Open and Closed Positions

**What**: Aggregates buy activity from active positions and sell activity from position history, combining into a unified result set.

**Columns/Parameters Involved**: `Trade.PositionTbl`, `History.PositionSlim`, `StatusID`, `Occurred`, `CloseOccurred`

**Rules**:
- **Buy side** (opens): FROM Trade.PositionTbl WHERE StatusID = 1 (active) AND Occurred BETWEEN @CurrentTradeDay AND @CurrentTradeDay+1
  - Amount = position invested amount; InitialUnits = share count
  - Grouped by InstrumentID + Occurred (date)
- **Sell side** (closes): FROM History.PositionSlim WHERE CloseOccurred BETWEEN @CurrentTradeDay AND @CurrentTradeDay+1
  - Amount = LastOpPriceRate * AmountInUnitsDecimal (close price * units)
  - Share count = AmountInUnitsDecimal
- Both sets inserted into #Final; final SELECT aggregates with SUM across both
- OPTION(RECOMPILE) at the sell-side INSERT for plan stability with variable predicates

**Diagram**:
```
Buy:  PositionTbl (StatusID=1, Occurred in @CurrentTradeDay)
                -> Amount=invested, Shares=InitialUnits
Sell: History.PositionSlim (CloseOccurred in @CurrentTradeDay)
                -> Amount=LastOpPriceRate*Units, Shares=AmountInUnitsDecimal
Both filtered by #cid (ApexID IS NOT NULL) and #cte_id (symbol filter)
  -> #Final -> GROUP BY InstrumentID, Occurred
  -> SELECT: GrossNationalValueOfBuyOrders, NumberOfBuyShares,
             GrossNationalValueOfSellOrders, NumberOfSellShares, NetValue
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrentTradeDay | DATE | YES | NULL (defaults to GETUTCDATE()) | CODE-BACKED | The trade date to aggregate. If NULL, defaults to the current UTC date. Positions opened (Occurred) and closed (CloseOccurred) on this date are included; the filter uses BETWEEN @CurrentTradeDay AND DATEADD(DAY,1,@CurrentTradeDay) to capture the full calendar day. |
| 2 | @SymbolsInput | nvarchar(max) | YES | NULL | CODE-BACKED | Primary symbol filter. Comma-separated list of instrument symbols (e.g., 'AAPL,MSFT,TSLA'). Split by STRING_SPLIT on ',' and merged with @SymbolsSeparetors into a shared TVP. If no symbols match any InstrumentMetaData.Symbol, falls back to all ExchangeID IN (4,5) instruments. |
| 3 | @SymbolsSeparetors | nvarchar(max) | YES | NULL | CODE-BACKED | Secondary/alternate symbol filter. Same format and behavior as @SymbolsInput. Both parameters are merged before symbol resolution, accommodating different caller conventions where the separator may vary. Despite the name ("Separetors" is a legacy misspelling), this is a comma-separated symbol list. |

**Output columns:**

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | Instrument identifier |
| 2 | Symbol | Instrument ticker symbol |
| 3 | TradeDate | The trade date (Occurred/CloseOccurred) |
| 4 | GrossNationalValueOfBuyOrders | Total USD value of buy (open) orders for this instrument/date |
| 5 | NumberOfBuyShares | Total share count of buy orders |
| 6 | GrossNationalValueOfSellOrders | Total USD value of sell (close) orders |
| 7 | NumberOfSellShares | Total share count of sell orders |
| 8 | NetValue | GrossNationalValueOfBuyOrders - GrossNationalValueOfSellOrders |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SymbolsInput / @SymbolsSeparetors | Trade.SymbolsList | User Defined Type (TVP) | Internal TVP used to hold parsed symbol values before InstrumentID lookup |
| Symbol-to-InstrumentID lookup | Trade.InstrumentMetaData | Reader | Resolves symbols to InstrumentIDs; ExchangeID IN (4,5) fallback |
| US customer filter | Customer.CustomerStatic | Reader (cross-schema) | Filters to ApexID IS NOT NULL customers only |
| Buy-side data | Trade.PositionTbl | Reader | Active open positions opened on @CurrentTradeDay |
| Sell-side data | History.PositionSlim | Reader (cross-schema) | Closed positions where close occurred on @CurrentTradeDay |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.USAggregatePositionBySymbolForMonitor | Conceptual peer | Simplified variant | The monitor version uses the same logic but no parameters and outputs Apex limit column names instead |
| US regulatory reporting jobs / Apex compliance processes | EXECUTE | Caller | Called by regulatory reporting workflows to generate daily US position concentration reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.USAggregatePositionBySymbol (procedure)
├── Trade.SymbolsList (type - TVP for symbol parsing)
├── Trade.InstrumentMetaData (table - symbol -> InstrumentID)
├── Customer.CustomerStatic (table - ApexID filter, cross-schema)
├── Trade.PositionTbl (table - open position buy data)
└── History.PositionSlim (table - closed position sell data, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SymbolsList | User Defined Type (TVP) | Internal TVP type for holding symbol strings parsed from @SymbolsInput and @SymbolsSeparetors |
| Trade.InstrumentMetaData | Table | Resolves input symbols to InstrumentIDs; ExchangeID IN (4,5) fallback for US exchange instruments |
| Customer.CustomerStatic | Table | ApexID IS NOT NULL filter to scope to US-regulated customers |
| Trade.PositionTbl | Table | Source for buy-side (open position) data: Amount and InitialUnits for active positions on trade date |
| History.PositionSlim | Table | Source for sell-side (closed position) data: LastOpPriceRate, AmountInUnitsDecimal for positions closed on trade date |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| US regulatory / Apex Clearing reporting | External process | Calls this procedure to generate daily trading volume summaries for US compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOCOUNT OFF | Session setting | Explicitly set OFF - row counts are returned to the caller (unlike most procedures that suppress them with NOCOUNT ON). This may be intentional for caller-side logging. |
| OPTION(RECOMPILE) | Query hint | Applied to the sell-side aggregate INSERT to force plan recompilation per execution, preventing parameter-sniffing issues when @CurrentTradeDay varies. |
| ExchangeID IN (4,5) fallback | Business logic | If no input symbols match any instrument, defaults to all instruments on exchanges 4 and 5 (US exchanges), ensuring the report always produces output for the US market. |
| StatusID = 1 (buy side) | Business logic | Only active open positions (StatusID=1) are counted on the buy side. Pending or cancelled orders are excluded. |

---

## 8. Sample Queries

### 8.1 Run the report for specific US symbols today

```sql
EXEC Trade.USAggregatePositionBySymbol
    @CurrentTradeDay = NULL,  -- defaults to today UTC
    @SymbolsInput = N'AAPL,MSFT,TSLA,AMZN',
    @SymbolsSeparetors = NULL
```

### 8.2 Run for all US exchange instruments on a specific trade date

```sql
EXEC Trade.USAggregatePositionBySymbol
    @CurrentTradeDay = '2026-03-17',
    @SymbolsInput = NULL,     -- NULL -> falls back to ExchangeID IN (4,5)
    @SymbolsSeparetors = NULL
```

### 8.3 Check US customer count (ApexID-filtered)

```sql
-- How many US customers would be included in this report
SELECT COUNT(*) AS USCustomerCount
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE ApexID IS NOT NULL
```

### 8.4 Preview instruments on US exchanges (the fallback set)

```sql
SELECT
    InstrumentID,
    Symbol,
    InstrumentDisplayName,
    ExchangeID
FROM Trade.InstrumentMetaData WITH (NOLOCK)
WHERE ExchangeID IN (4, 5)
ORDER BY Symbol
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.USAggregatePositionBySymbol | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.USAggregatePositionBySymbol.sql*
