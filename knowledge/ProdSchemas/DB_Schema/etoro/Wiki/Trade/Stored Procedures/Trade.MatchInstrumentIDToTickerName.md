# Trade.MatchInstrumentIDToTickerName

> For a given liquidity provider, matches a batch of ticker names to their eToro InstrumentIDs, filtering to stock instruments only (InstrumentTypeID=5).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @liquidityProviderID + @instrumetTickerNames TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.MatchInstrumentIDToTickerName resolves a set of stock ticker symbols to eToro internal InstrumentIDs for a specific liquidity provider. Given a liquidity provider ID and a list of ticker names (e.g., "AAPL", "TSLA"), it returns only those tickers that are (a) contracted with the specified LP and (b) classified as real stocks (InstrumentTypeID=5). This supports LP onboarding and reconciliation workflows where the LP sends a list of tickers it can trade, and the system needs to determine which eToro instruments those correspond to.

This procedure exists because eToro instruments and LP tickers are not always in 1:1 correspondence - tickers may have whitespace, multiple LPs may cover different subsets of stocks, and only stock instruments (not CFDs, crypto, ETFs) are relevant for certain LP contracts. The whitespace trimming and InstrumentTypeID=5 filter ensure clean, relevant results.

Data flows: called by DBA operations (PROD_BIadmins has permission). Returns a result set of (TickerName, InstrumentID) pairs - the caller uses these to update mappings or validate LP coverage.

---

## 2. Business Logic

### 2.1 LP + Ticker + Stock Type Triple Filter

**What**: Returns only (Ticker, InstrumentID) pairs that satisfy all three conditions: LP match, ticker name match, and stock type.

**Columns/Parameters Involved**: `@liquidityProviderID`, `@instrumetTickerNames`, `Trade.LiquidityProviderContracts.Ticker`, `Trade.GetInstrument.InstrumentTypeID`

**Rules**:
- Condition 1: LiquidityProviderID = @liquidityProviderID - only contracts for the specified LP.
- Condition 2: LTRIM(RTRIM(TLPC.Ticker)) EXISTS IN @instrumetTickerNames (case-sensitive depending on collation) - only tickers supplied by the caller.
- Condition 3: TGI.InstrumentTypeID = 5 - only real stocks (not CFDs, crypto, ETFs, indices).
- LEFT JOIN to Trade.GetInstrument means contracts with no matching instrument (InstrumentTypeID NULL) are included in the WHERE EXISTS subquery but excluded by InstrumentTypeID=5 filter.
- DISTINCT ensures no duplicate (TickerName, InstrumentID) pairs even if multiple LP contract rows exist per ticker.
- Ticker whitespace is trimmed in both the output column and the EXISTS comparison.

**Diagram**:
```
@instrumetTickerNames (Trade.TicketNames TVP): ["AAPL", "TSLA", "GOOG"]
         |
         v
Trade.LiquidityProviderContracts (WHERE LiquidityProviderID=@liquidityProviderID)
         |
LEFT JOIN Trade.GetInstrument (WHERE InstrumentTypeID=5 Stocks only)
         |
EXISTS filter: Ticker (trimmed) must match one of the TVP entries
         |
         v
Output: (TickerName="AAPL", InstrumentID=1234), (TickerName="TSLA", InstrumentID=5678)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @liquidityProviderID | INT | NO | - | CODE-BACKED | ID of the liquidity provider whose contracts are searched. Filters Trade.LiquidityProviderContracts.LiquidityProviderID. Only tickers contracted with this specific LP are returned. |
| 2 | @instrumetTickerNames | Trade.TicketNames (READONLY TVP) | NO | - | CODE-BACKED | Batch of ticker names to look up. Each row has a TicketName (varchar(50)). The procedure returns InstrumentIDs only for tickers that both appear in this TVP and exist in the LP's contracts for stock instruments. READONLY TVP - see Trade.TicketNames UDT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @liquidityProviderID, Ticker | Trade.LiquidityProviderContracts | JOIN/Read | Primary source of ticker-to-instrument mapping per LP |
| InstrumentID | Trade.GetInstrument | LEFT JOIN/Read | Filters to InstrumentTypeID=5 (Stocks only); provides instrument metadata |
| @instrumetTickerNames | Trade.TicketNames | UDT Reference | TVP type for input ticker name batch |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SP callers found) | - | - | Called by DBA/admin tools or external applications for LP onboarding and ticker reconciliation; no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.MatchInstrumentIDToTickerName (procedure)
├── Trade.TicketNames (type - TVP)
├── Trade.LiquidityProviderContracts (table)
└── Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TicketNames | User Defined Type | TVP parameter type (TicketName varchar(50)) |
| Trade.LiquidityProviderContracts | Table | Read NOLOCK; filtered by LiquidityProviderID; provides Ticker and InstrumentID |
| Trade.GetInstrument | View | LEFT JOINed NOLOCK ON InstrumentID; WHERE InstrumentTypeID=5 restricts to stocks |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Result set consumed by caller; no stored procedure dependents. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find all stock instruments for a liquidity provider

```sql
SELECT DISTINCT LTRIM(RTRIM(TLPC.Ticker)) AS TickerName, TLPC.InstrumentID
FROM Trade.LiquidityProviderContracts AS TLPC WITH (NOLOCK)
LEFT JOIN Trade.GetInstrument AS TGI WITH (NOLOCK) ON TLPC.InstrumentID = TGI.InstrumentID
WHERE TLPC.LiquidityProviderID = <LiquidityProviderID>
  AND TGI.InstrumentTypeID = 5;
```

### 8.2 Check which tickers in a batch have no LP contract for stocks

```sql
SELECT src.TicketName
FROM (VALUES ('AAPL'), ('TSLA'), ('UNKNOWN')) AS src(TicketName)
WHERE NOT EXISTS (
    SELECT 1
    FROM Trade.LiquidityProviderContracts AS TLPC WITH (NOLOCK)
    LEFT JOIN Trade.GetInstrument AS TGI WITH (NOLOCK) ON TLPC.InstrumentID = TGI.InstrumentID
    WHERE TLPC.LiquidityProviderID = <LiquidityProviderID>
      AND TGI.InstrumentTypeID = 5
      AND LTRIM(RTRIM(TLPC.Ticker)) = LTRIM(RTRIM(src.TicketName))
);
```

### 8.3 View LP contracts for stock instruments by provider

```sql
SELECT TLPC.LiquidityProviderID, LTRIM(RTRIM(TLPC.Ticker)) AS Ticker,
       TLPC.InstrumentID, TGI.InstrumentTypeID
FROM Trade.LiquidityProviderContracts AS TLPC WITH (NOLOCK)
LEFT JOIN Trade.GetInstrument AS TGI WITH (NOLOCK) ON TLPC.InstrumentID = TGI.InstrumentID
WHERE TLPC.LiquidityProviderID = <LiquidityProviderID>
  AND TGI.InstrumentTypeID = 5
ORDER BY TLPC.Ticker;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.MatchInstrumentIDToTickerName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.MatchInstrumentIDToTickerName.sql*
