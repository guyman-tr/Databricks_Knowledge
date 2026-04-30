# Hedge.GetLiquidityProviderContracts

> Retrieves all trading contracts registered for a specific liquidity provider, returning the instrument-level binding between eToro instruments and the provider's exchange-specific contract identifiers, validity periods, and rate conversion factors used by the hedge engine.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityProviderID - filters output to one provider |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetLiquidityProviderContracts` is the hedge server's bootstrap reader for liquidity provider contract metadata. When the hedge engine initializes or refreshes its configuration, it calls this procedure to discover which instruments it can hedge through a given liquidity provider, the provider's native ticker for each instrument, which exchange the contract trades on, and the rate conversion factor required for order size translation.

This procedure exists because different LPs have different contracts for the same underlying instrument: one LP might identify EUR/USD as ticker "EURUSD" on exchange "CME" while another uses "EUR/USD" on "LMAX". Without this contract map, the hedge engine could not construct correctly formatted FIX orders for each provider. The `RateConversionFactor` is especially critical: it scales eToro's internal rate/price representation to match the provider's quoted price format.

Data flows from `Trade.LiquidityProviderContracts`, which is a Trade-schema table maintained as part of LP setup. The hedge engine reads it on startup per provider and caches the contract map for the session. The `GetProviderUnitConversion` procedure complements this one by providing unit/lot conversion for the same LP contracts, together forming the complete order translation config.

---

## 2. Business Logic

### 2.1 Provider-Scoped Contract Filtering

**What**: All columns are returned for all contracts belonging to the requested liquidity provider, with no date/validity filtering - active and expired contracts are both included.

**Columns/Parameters Involved**: `@LiquidityProviderID`, `LiquidityProviderID`, `FromDate`, `ToDate`

**Rules**:
- WHERE clause filters only on `LiquidityProviderID = @LiquidityProviderID`
- `FromDate`/`ToDate` are returned but not used as filters - the consuming application decides which contracts are currently active
- One row per instrument per provider; multiple instruments can share the same ExchangeID
- `RateConversionFactor` defaults to 1.0 for most instruments; non-1 values indicate an LP that quotes prices in a different unit scale than eToro's internal rate representation

**Diagram**:
```
Hedge engine startup -> GetLiquidityProviderContracts(@LiquidityProviderID=10)
     |
     v
Trade.LiquidityProviderContracts
  InstrumentID=1 (EUR/USD), Ticker="EURUSD", ExchangeID=5, RateConversionFactor=1.0
  InstrumentID=100000 (BTC), Ticker="BTC/USD", ExchangeID=12, RateConversionFactor=1.0
  ...
     |
     v
Hedge engine caches: instrument -> (ticker, exchange, rate_conversion_factor)
Used when building FIX order messages for this LP
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | int | NO | - | CODE-BACKED | The liquidity provider instance ID to filter by. Corresponds to Trade.LiquidityProviderContracts.LiquidityProviderID. Each distinct value represents one LP's full set of tradeable contracts. Pass the provider's Trade.LiquidityAccounts-derived ID to retrieve only that provider's instrument bindings. |

**Output columns** (from Trade.LiquidityProviderContracts):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | int | NO | - | CODE-BACKED | eToro's internal instrument identifier. FK to Trade.Instrument. Used by the hedge engine to match this contract to the corresponding customer position instrument. |
| 3 | LiquidityProviderID | int | NO | - | CODE-BACKED | Echoed from the filter - identifies which LP this contract belongs to. All rows will equal @LiquidityProviderID. |
| 4 | Ticker | varchar | YES | - | CODE-BACKED | The provider's native ticker symbol for this instrument (e.g., "EURUSD", "BTC/USD"). Used verbatim when constructing FIX protocol order messages sent to this LP. |
| 5 | ExchangeID | int | YES | - | CODE-BACKED | The exchange on which this LP contract trades, as an eToro exchange identifier. Used to route orders to the correct exchange feed and for market range validation. |
| 6 | FromDate | datetime | YES | - | CODE-BACKED | Start of the contract's validity period. The hedge engine may use this to determine which contracts are currently tradeable vs historical. No DB-side filter is applied - the application handles validity logic. |
| 7 | ToDate | datetime | YES | - | CODE-BACKED | End of the contract's validity period. NULL means the contract has no expiry (ongoing). Non-NULL values indicate a futures-style contract that expires on a specific date. |
| 8 | RateConversionFactor | decimal | YES | - | VERIFIED | Multiplier applied to eToro's internal rate/price to get the LP's expected quote format. For most instruments = 1.0 (rates match). Non-1 values correct for scale differences between eToro and LP quote conventions. Used in hedge unit conversion together with Hedge.ProviderUnitConversionRatio. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.LiquidityProviderContracts | SELECT | Reads LP contract registry. All returned columns originate from this table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins.sql | - | Permission grant | BI admin role has EXECUTE permission on this procedure. |
| Trade.GetLiquidityProviderContracts | - | Related | A view in the Trade schema references the same underlying table. |
| Internal.GetLiquidityProviderContractsID | - | Related | An Internal schema procedure references this proc name (likely a wrapper or caller). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetLiquidityProviderContracts (procedure)
└── Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | SELECTed with NOLOCK - source of all returned columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | Called on startup to load LP contract map for FIX order construction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all contracts for the main LP (provider ID 10)
```sql
EXEC [Hedge].[GetLiquidityProviderContracts] @LiquidityProviderID = 10;
```

### 8.2 Inspect all contracts for a given LP with validity status
```sql
EXEC [Hedge].[GetLiquidityProviderContracts] @LiquidityProviderID = 10;
-- Then in application: filter WHERE FromDate <= GETUTCDATE() AND (ToDate IS NULL OR ToDate > GETUTCDATE())
```

### 8.3 Cross-reference with instrument names (join in application after SP call)
```sql
-- After calling the procedure, join with instrument metadata:
SELECT  lpc.InstrumentID,
        ti.InstrumentName,
        lpc.Ticker,
        lpc.ExchangeID,
        lpc.RateConversionFactor,
        lpc.FromDate,
        lpc.ToDate
FROM    [Trade].[LiquidityProviderContracts] lpc WITH (NOLOCK)
JOIN    [Trade].[Instrument] ti WITH (NOLOCK) ON lpc.InstrumentID = ti.InstrumentID
WHERE   lpc.LiquidityProviderID = 10
ORDER BY lpc.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED (table cols), 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (this IS the procedure) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetLiquidityProviderContracts | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetLiquidityProviderContracts.sql*
