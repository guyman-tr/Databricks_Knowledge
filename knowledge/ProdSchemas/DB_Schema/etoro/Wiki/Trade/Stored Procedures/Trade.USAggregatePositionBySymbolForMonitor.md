# Trade.USAggregatePositionBySymbolForMonitor

> Simplified parameterless variant of USAggregatePositionBySymbol that reports today's US exchange position activity with Apex Clearing limit column names, designed for monitoring dashboards.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; always runs for today UTC; modifies none - read-only reporting |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the monitoring-dashboard variant of `Trade.USAggregatePositionBySymbol`. It applies the same core logic - aggregating daily buy and sell activity for US-regulated customers (ApexID IS NOT NULL) across US exchange instruments - but with three simplifications designed for automated monitoring:

1. **No parameters** - always runs for the current UTC date, making it safe to call from a monitoring job without arguments
2. **Always scopes to ExchangeID IN (4,5)** - no symbol filter input; always reports all US exchange instruments
3. **Apex Clearing limit column names** - output columns are named "Apex Limit $4M Daily" and "Apex Limit 40,000 Shares" to directly express the regulatory thresholds being monitored

The Apex Clearing agreement imposes a $4 million daily gross national value limit and a 40,000 shares limit on US instrument trading. This procedure's output is designed to be compared directly against those limits in a monitoring dashboard or alert system.

---

## 2. Business Logic

### 2.1 Fixed Scope: Today UTC, All US Exchange Instruments

**What**: No input parameters; scope is always current UTC date and all ExchangeID 4/5 instruments.

**Columns/Parameters Involved**: `@CurrentTradeDay`, `ExchangeID`

**Rules**:
- @CurrentTradeDay = CAST(GETUTCDATE() AS DATE) - always today, hardcoded in the procedure
- #cte_id always populated from Trade.InstrumentMetaData WHERE ExchangeID IN (4, 5)
- No symbol filter input path - the fallback logic from the parent procedure becomes the only path
- Clustered index on #cte_id(InstrumentID); clustered index on #cid(CID) for join efficiency

### 2.2 Dual-Source Aggregation (Same Pattern as Parent)

**What**: Combines open positions (buy) from PositionTbl and closed positions (sell) from History.PositionSlim.

**Columns/Parameters Involved**: `Trade.PositionTbl`, `History.PositionSlim`, `StatusID`, `Occurred`, `CloseOccurred`

**Rules**:
- Buy side: PositionTbl WHERE StatusID=1 AND Occurred BETWEEN today AND today+1, joined to #cid (ApexID IS NOT NULL) and #cte_id (US instruments)
- Sell side: History.PositionSlim WHERE CloseOccurred BETWEEN today AND today+1, joined to #cid and #cte_id
- OPTION(RECOMPILE) on BOTH inserts (unlike the parent which only applies it to the sell side)
- Nonclustered index on #Final(InstrumentID) added after both inserts for join efficiency in the final SELECT

### 2.3 Apex Limit Column Names in Output

**What**: Output columns are labeled with the Apex Clearing thresholds for direct dashboard comparison.

**Columns/Parameters Involved**: `[Apex Limit $4M Daily]`, `[Apex Limit 40,000 Shares]`

**Rules**:
- Only buy-side metrics are in the output (GrossNationalValue and ShareCount for buys only)
- Sell-side data is computed (to keep #Final consistent) but not included in the final SELECT
- Column "[Apex Limit $4M Daily]" = Sum(AmountBuy) - gross notional value of buy orders today
- Column "[Apex Limit 40,000 Shares]" = SUM(NumberOfSharesUsersBuy) - share count of buy orders today
- These names indicate that these values should be compared against the $4M daily notional limit and 40,000 shares limit in Apex Clearing's regulatory agreement

**Diagram**:
```
#Final (same as parent procedure)
  |
  Final SELECT:
    InstrumentID, Symbol, Occurred AS TradeDate
    Sum(AmountBuy)              -> [Apex Limit $4M Daily]
    SUM(NumberOfSharesUsersBuy) -> [Apex Limit 40,000 Shares]
    (AmountSell, NumberOfSharesUsersSell NOT selected)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It is always called without arguments.

**Output columns:**

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | Instrument identifier (US exchange instruments only) |
| 2 | Symbol | Instrument ticker symbol |
| 3 | TradeDate | Today's UTC date (from Occurred/CloseOccurred) |
| 4 | Apex Limit $4M Daily | Total gross notional value of buy orders today (USD). Monitor against the $4M Apex Clearing daily limit. |
| 5 | Apex Limit 40,000 Shares | Total share count of buy orders today. Monitor against the 40,000 shares Apex Clearing limit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| US instrument scope | Trade.InstrumentMetaData | Reader | ExchangeID IN (4,5) to identify all US exchange instruments |
| US customer filter | Customer.CustomerStatic | Reader (cross-schema) | ApexID IS NOT NULL filter to scope to US-regulated customers |
| Buy-side data | Trade.PositionTbl | Reader | Active open positions (StatusID=1) opened today UTC |
| Sell-side data | History.PositionSlim | Reader (cross-schema) | Positions closed today UTC (used for #Final completeness but not final output) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.USAggregatePositionBySymbol | Conceptual peer | Parent procedure | Full-featured version with symbol filtering and both buy and sell output columns |
| Monitoring dashboards / Apex compliance alerts | EXECUTE | Caller | Called by automated monitoring jobs to check daily US trading volumes against Apex Clearing limits |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.USAggregatePositionBySymbolForMonitor (procedure)
├── Trade.InstrumentMetaData (table - US exchange instrument scope)
├── Customer.CustomerStatic (table - ApexID filter, cross-schema)
├── Trade.PositionTbl (table - open position buy data)
└── History.PositionSlim (table - closed position data, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | ExchangeID IN (4,5) scope - identifies US exchange instruments |
| Customer.CustomerStatic | Table | ApexID IS NOT NULL filter for US-regulated customer scoping |
| Trade.PositionTbl | Table | Buy-side data: Amount (AmountBuy) and InitialUnits (NumberOfSharesUsersBuy) for active positions today |
| History.PositionSlim | Table | Sell-side data loaded into #Final (not in final output but computed for completeness) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex Clearing compliance monitoring | External process | Calls this procedure to check daily US buy activity against $4M and 40,000 share regulatory limits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No parameters | Design | Intentionally parameterless to enable safe invocation by monitoring jobs without argument handling |
| OPTION(RECOMPILE) on both inserts | Query hint | Applied to both buy and sell INSERT statements (unlike the parent procedure which only applies it to the sell side). Forces plan recompilation for dynamic row count estimation. |
| Nonclustered index on #Final | Performance | Added after both inserts to support the final GROUP BY join on InstrumentID |
| Buy-side only output | Business decision | Only buy metrics appear in the final SELECT despite sell data being computed. This reflects the Apex monitoring focus on buy concentration limits. |

---

## 8. Sample Queries

### 8.1 Run the monitor report for today

```sql
EXEC Trade.USAggregatePositionBySymbolForMonitor
-- No parameters - always runs for current UTC date, all US instruments
```

### 8.2 Check which instruments are approaching the $4M daily limit

```sql
-- After running the monitor, compare against the Apex threshold
-- (This query pattern would be used in a monitoring wrapper)
DECLARE @t TABLE (
    InstrumentID INT,
    Symbol NVARCHAR(50),
    TradeDate DATE,
    ApexDailyValue DECIMAL(16,8),
    ApexShareCount DECIMAL(16,4)
)
INSERT INTO @t
EXEC Trade.USAggregatePositionBySymbolForMonitor

SELECT
    Symbol,
    TradeDate,
    ApexDailyValue,
    ApexShareCount,
    ROUND(ApexDailyValue / 4000000.0 * 100, 2) AS PctOfDollarLimit,
    ROUND(ApexShareCount / 40000.0 * 100, 2) AS PctOfShareLimit
FROM @t
WHERE ApexDailyValue > 1000000  -- alert at 25% of limit
ORDER BY ApexDailyValue DESC
```

### 8.3 Compare with the full-featured version for a specific symbol

```sql
-- Full-featured version allows historical dates and specific symbols
EXEC Trade.USAggregatePositionBySymbol
    @CurrentTradeDay = '2026-03-17',
    @SymbolsInput = N'AAPL,MSFT',
    @SymbolsSeparetors = NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.USAggregatePositionBySymbolForMonitor | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.USAggregatePositionBySymbolForMonitor.sql*
