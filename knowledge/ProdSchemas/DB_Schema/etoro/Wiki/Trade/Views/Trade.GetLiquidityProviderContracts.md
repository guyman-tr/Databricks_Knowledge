# Trade.GetLiquidityProviderContracts

> View joining LiquidityProviderContracts with LiquidityProviders, Instrument, and Currency to expose contracts with provider names and instrument display names (Abbreviation format: BUY\SELL for forex, single code for non-forex).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ContractID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLiquidityProviderContracts enriches Trade.LiquidityProviderContracts with liquidity provider instance names, instrument data, and a human-readable **Abbreviation** display name. Each row represents a mapping from an eToro instrument to a liquidity provider with a provider-specific ticker symbol and validity window (FromDate, ToDate). The Abbreviation column uses the same logic as Trade.GetInstrumentsBuyNames: for forex (CurrencyTypeID=1) it shows "BUY\SELL" (backslash), for non-forex it shows just the buy-side abbreviation (e.g., PARAA for a stock).

This view exists because Hedge.GetLiquidityProviderContracts, Trade.GetInstrumentContracts, price subsystems, and admin UIs need contract data with provider and instrument names resolved. Without it, each would repeat the JOIN chain (LiquidityProviderContracts + LiquidityProviders + Instrument + Dictionary.Currency x2) and the Abbreviation CASE logic. The view centralizes that and provides a single read path.

Data flows from Trade.LiquidityProviderContracts, Trade.LiquidityProviders, Trade.Instrument, and Dictionary.Currency (buy and sell). Hedge.GetLiquidityProviderContracts procedure and related views consume this view. Rows are created by Trade.InsertLiquidityProviderContract, Internal.Newcurrency, Stocks.AddNewStock, and Trade.InsertInstrumentMetadataSecurityOpsAPI.

---

## 2. Business Logic

### 2.1 Abbreviation Display Name

**What**: The Abbreviation column formats instrument names for display. Forex pairs show "BUY\SELL" (e.g., EUR\USD); non-forex (stocks, crypto, commodities) show only the buy-side abbreviation.

**Columns/Parameters Involved**: `Abbreviation` (computed), `CurrencyTypeID` (from buy-side Currency)

**Rules**:
- When DCRR.CurrencyTypeID <> 1 (not forex): Abbreviation = DCRR.Abbreviation (single code, e.g., PARAA, IQ.US).
- When DCRR.CurrencyTypeID = 1 (forex): Abbreviation = DCRR.Abbreviation + '\' + C2.Abbreviation (e.g., EUR\USD). Note backslash, not forward slash.

**Diagram**:
```
Forex EUR/USD:   Abbreviation = "EUR\USD"
Stock PARAA:     Abbreviation = "PARAA"
Crypto BTC:      Abbreviation = "BTC"
```

### 2.2 Contract Validity Window

**What**: FromDate and ToDate define when the provider-instrument ticker mapping is valid.

**Columns/Parameters Involved**: `FromDate`, `ToDate`

**Rules**:
- Contract is active when query date is between FromDate and ToDate.
- Trade.GetAvailableLiquidityProviderContracts and Price.SwapContracts use these for overlap checks and rollover logic.

---

## 3. Data Overview

| ContractID | InstrumentID | Abbreviation | LiquidityProviderName | Ticker | Meaning |
|------------|--------------|--------------|------------------------|--------|---------|
| 169702 | 10029 | PARAA | ACT | PARAA | PARAA stock at BMFN (ACT). Same ticker across providers for stocks. |
| 240883 | 10029 | PARAA | FD RealStream Production REAL 208.100.16.162 | PARAA | Same instrument, FD provider. Multiple providers can hedge the same stock. |
| 280428 | 10029 | PARAA | FD Demo Provider | PARAA | FD demo environment - same ticker as real. |
| 264610 | 10029 | PARAA | FD RSRM Real 70.42.76.153 | PARAA | FD RSRM instance. |
| 193429 | 10029 | PARAA | FD RSRM Real NY4 70.42.76.154 | PARAA | FD NY4 instance. |

**Selection criteria**: First 5 rows for InstrumentID 10029 (PARAA stock) show multiple providers with same ticker. Abbreviation is single code for stocks.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ContractID | int | NO | IDENTITY | CODE-BACKED | Surrogate key from Trade.LiquidityProviderContracts. Unique per row. Used by Trade.TradonomiToLiquidityProviderContracts. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The eToro instrument being mapped. From Trade.LiquidityProviderContracts. |
| 3 | Abbreviation | varchar | - | - | CODE-BACKED | Computed in view: CASE WHEN DCRR.CurrencyTypeID <> 1 THEN DCRR.Abbreviation ELSE DCRR.Abbreviation + '\' + C2.Abbreviation END. Display name: single code for non-forex (stocks, crypto), "BUY\SELL" for forex. Backslash delimiter. |
| 4 | LiquidityProviderID | int | NO | - | CODE-BACKED | FK to Trade.LiquidityProviders. Provider instance (e.g., ACT=0, FD=5). From Trade.LiquidityProviderContracts. |
| 5 | LiquidityProviderName | varchar(250) | YES | - | CODE-BACKED | Resolved from Trade.LiquidityProviders via JOIN. Human-readable provider instance name (e.g., "ACT", "FD RealStream Production REAL 208.100.16.162"). |
| 6 | FromDate | datetime | NO | - | CODE-BACKED | Start of validity window. Contract active when query date >= FromDate. From Trade.LiquidityProviderContracts. |
| 7 | ToDate | datetime | NO | - | CODE-BACKED | End of validity window. Contract active when query date <= ToDate. From Trade.LiquidityProviderContracts. |
| 8 | Ticker | varchar(150) | YES | - | CODE-BACKED | Provider-specific ticker symbol (e.g., EUR/USD, PARAA). Used by Price.GetTickerInfo and Hedge.GetLiquidityProviderContracts. From Trade.LiquidityProviderContracts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | eToro instrument being mapped. |
| LiquidityProviderID | Trade.LiquidityProviders | FK | Provider instance. |
| BuyCurrencyID, SellCurrencyID | Dictionary.Currency | FK | Resolved via Instrument for Abbreviation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetLiquidityProviderContracts | Procedure | Returns contracts by LiquidityProviderID. |
| Trade.GetInstrumentContracts | View | May JOIN for contract data. |
| Trade.GetAvailableLiquidityProviderContracts | Function | Overlap checks with FromDate/ToDate. |
| Price.GetTickerInfo | Procedure | Resolves ticker for price lookups. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLiquidityProviderContracts (view)
├── Trade.LiquidityProviderContracts (table)
├── Trade.LiquidityProviders (table)
├── Trade.Instrument (table)
└── Dictionary.Currency (table) [buy and sell JOINs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | FROM - base table |
| Trade.LiquidityProviders | Table | INNER JOIN on LiquidityProviderID for LiquidityProviderName |
| Trade.Instrument | Table | INNER JOIN on InstrumentID for BuyCurrencyID, SellCurrencyID |
| Dictionary.Currency | Table | INNER JOIN on BuyCurrencyID (DCRR) and SellCurrencyID (C2) for Abbreviation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetLiquidityProviderContracts | Procedure | Returns contracts - may read view or table. |
| Trade.GetInstrumentContracts | View | May JOIN. |
| Trade.GetAvailableLiquidityProviderContracts | Function | Contract overlap logic. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Contracts for a specific instrument
```sql
SELECT ContractID, InstrumentID, Abbreviation, LiquidityProviderName,
       FromDate, ToDate, Ticker
  FROM Trade.GetLiquidityProviderContracts WITH (NOLOCK)
 WHERE InstrumentID = 10029
 ORDER BY LiquidityProviderID
```

### 8.2 Active contracts for a provider (valid today)
```sql
SELECT ContractID, InstrumentID, Abbreviation, Ticker, FromDate, ToDate
  FROM Trade.GetLiquidityProviderContracts WITH (NOLOCK)
 WHERE LiquidityProviderID = 5
   AND FromDate <= CAST(GETUTCDATE() AS DATE)
   AND ToDate >= CAST(GETUTCDATE() AS DATE)
 ORDER BY InstrumentID
```

### 8.3 Resolve InstrumentID to display name with provider
```sql
SELECT GLPC.ContractID, GLPC.InstrumentID, GLPC.Abbreviation,
       LP.LiquidityProviderName, GLPC.Ticker
  FROM Trade.GetLiquidityProviderContracts GLPC WITH (NOLOCK)
  JOIN Trade.LiquidityProviders LP WITH (NOLOCK)
    ON LP.LiquidityProviderID = GLPC.LiquidityProviderID
 WHERE GLPC.InstrumentID IN (1, 5, 10029)
 ORDER BY GLPC.InstrumentID, GLPC.LiquidityProviderID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [DBA : How To Article : Insert new Instruments](https://etoro.atlassian.net/wiki/spaces/DROD/pages/11765612545) | Confluence | LiquidityProviderContracts populated in "Add Price" step. Sanity test: `SELECT * FROM Trade.LiquidityProviderContracts WHERE DATEDIFF(dd, SysStartTime, getdate()) = 0` |
| [Instrument Insertion - new model](https://etoro.atlassian.net/wiki/spaces/DROD/pages/13308395583) | Confluence | May describe updated instrument/contract insertion workflow. |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4+ analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.GetLiquidityProviderContracts | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetLiquidityProviderContracts.sql*
