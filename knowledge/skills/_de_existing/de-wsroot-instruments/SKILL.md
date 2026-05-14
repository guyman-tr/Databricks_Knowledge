---
id: instruments
name: "Instrument Detection & Lookup"
description: "Instrument identification and filtering for eToro assets (stocks, crypto, ETFs, indices, commodities). Covers the mandatory two-part filter pattern (Symbol/Name + InstrumentTypeID), one-asset-many-IDs problem, suffix meanings (.RTH, .24-7, .EUR, .CALL), enriched view flags (IsFuture, Tradeable, IsSQF), and per-asset-class query patterns. Load when filtering data by a specific instrument, joining to dim_instrument, or when a user mentions an asset by ticker or name."
triggers:
  - instrument filter
  - InstrumentTypeID
  - dim_instrument
  - ticker lookup
  - symbol lookup
  - by instrument
  - by asset
  - ETH filter
  - BTC filter
  - stock filter
  - crypto filter
  - ETF filter
  - instrument type
  - TSLA
  - InstrumentID
required_tables:
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
  - main.bi_output.bi_ouput_v_dim_instrumenttype
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-07"
---

# Instrument Detection & Lookup

## When to Use
- Filtering any fact table by a specific instrument (stock, crypto, ETF, index)
- Joining to `dim_instrument` for instrument details
- A user mentions an asset by name, ticker, or display name (e.g., "Tesla", "ETH", "Bitcoin ETF")
- Building queries that reference instruments by asset class

## Scope
In scope: Instrument identification, two-part filter pattern, InstrumentTypeID reference, suffix meanings, enriched view flags, per-asset-class patterns, common ticker mappings, key columns (ISINCode, CUSIP, Exchange)
Out of scope: Revenue amounts by instrument (→ `revenue` skill), trading volumes by instrument (→ `trading-volumes` skill), PnL by instrument (→ `portfolio-value` skill)
Last verified: 2026-05-07

## Critical Warnings
1. A ticker-only filter WITHOUT InstrumentTypeID produces wrong results — `ETH` matches Eurotech SpA (Stocks, TypeID=5), not Ethereum. ALWAYS pair Symbol/Name with InstrumentTypeID.
2. One logical asset = MANY InstrumentIDs (e.g., Tesla has 8 IDs: main, .RTH, .24-7, .EUR, .CALL1/.CALL2/.PUT1/.PUT2). Filtering by a single InstrumentID misses trading sessions.
3. NEVER filter on `InstrumentDisplayName` — it's not unique ("Tesla Motors, Inc." maps to 3 IDs), inconsistent ("Tesla Motors, Inc." vs "Tesla 24/7"), and has trailing spaces. Use `Symbol` or `Name` column.
4. Crypto micro futures share InstrumentTypeID=10 with spot crypto — use `IsFuture = 0` (enriched view) or `Symbol NOT LIKE '%.%'` (fallback) to exclude derivatives.
5. ETFs named after crypto (IBIT, ETHA, GBTC) are InstrumentTypeID=6, NOT crypto (10). "Bitcoin ETF revenue" is ETF revenue, not crypto revenue.
6. Options are typed as Stocks (TypeID=5) with `.CALL`/`.PUT` suffixes — TypeID 9 exists but has zero instruments assigned.
7. Ethereum Classic (ETC) ≠ Ethereum (ETH). `LIKE 'ETH%'` does NOT match ETC (good). But `LIKE '%ethereum%'` on InstrumentDisplayName WOULD match both — always use Symbol/Name, not DisplayName.

---

## Tables

| Table | Use For |
|---|---|
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | **PREFERRED.** Adds `IsFuture`, `Tradeable`, `IsSQF`, `Is_245_Instrument`, `PlatformSector`, `PlatformIndustry`, `OperationMode`. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Base instrument master (47 columns). Use when enriched view unavailable. |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | Complete InstrumentTypeID → name mapping. |
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | Fact table with InstrumentID FK — use for instrument-level metric queries. |

---

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **InstrumentID** | Unique PK per instrument variant. One logical asset has MANY IDs. | instrument key |
| **Symbol** | Ticker with optional suffix: `TSLA`, `TSLA.RTH`, `TSLA.24-7`. **Primary lookup column.** | ticker |
| **Name** | Full trade pair: `TSLA/USD`, `ETH/EUR`. Best for crypto filtering. | trade pair |
| **InstrumentTypeID** | Asset class numeric FK. **Mandatory boundary filter.** | type ID, asset class |
| **IsFuture** | 1 = futures/derivative contract. Enriched view only. | futures flag |
| **Tradeable** | 1 = currently tradeable. 0 = inactive (options, delisted). Enriched view only. | active flag |
| **IsSQF** | 1 = Special Qualifying Flag (Group 59). Enriched view only. | SQF |

### Key Columns for Identification

| Column | Type | Example (Tesla) | Use For |
|---|---|---|---|
| `InstrumentID` | INT | 1111 | Joins to fact tables |
| `Symbol` | STRING | TSLA, TSLA.RTH | **Primary lookup column** |
| `SymbolFull` | STRING | TSLA, TSLA.RTH | Redundant with Symbol |
| `Name` | STRING | TSLA/USD, TSLA.RTH/USD | Full trade pair name |
| `InstrumentDisplayName` | STRING | "Tesla Motors, Inc." | Display only — NEVER filter on this |
| `InstrumentTypeID` | INT | 5 | **MANDATORY boundary filter** |
| `ISINCode` | STRING | US88160R1014 | Regulatory/financial lookup |
| `CUSIP` | STRING | 88160R101 | US equity lookup |
| `Exchange` | STRING | NASDAQ | Market identification |
| `Industry` | STRING | Technology | Sector analysis |
| `AssetClass` | STRING | Equity | Bloomberg-style classification |

### InstrumentTypeID Reference

| InstrumentTypeID | InstrumentType | Count | Notes |
|---|---|---|---|
| 1 | Currencies | 153 | EUR/USD, GBP/USD — FX pairs |
| 2 | Commodities | 503 | Gold, Silver, Oil — also nano BTC futures |
| 4 | Indices | 247 | SPX500, DJ30 — also CME futures |
| 5 | Stocks | 12,849 | TSLA, AAPL — also options (.CALL/.PUT) |
| 6 | ETF | 1,287 | IBIT (Bitcoin ETF), SPY, ETHA |
| 10 | Crypto Currencies | 667 | BTC, ETH, XRP — spot + cross-pairs + micro futures |
| 0 | NA | 1 | Placeholder/unknown |
| 3, 7, 8, 9 | Reserved | 0 | CFD, Bonds, TrustFunds, Options — defined but empty |

### Tesla Example (8 InstrumentIDs, 4 active)

| InstrumentID | Symbol | DisplayName | Tradeable | 2026 Actions |
|---|---|---|---|---|
| 1111 | TSLA | Tesla Motors, Inc. | 1 | 2.7M |
| 8752 | TSLA.RTH | Tesla Motors, Inc. | 1 | 59K |
| 14259 | TSLA.EUR | Tesla Motors, Inc. | 1 | 4K |
| 15200 | TSLA.24-7 | Tesla 24/7 | 1 | 309 |
| 1376 | TSLA.CALL1 | Tesla option (CALL 1) | **0** | **0** |
| 1381 | TSLA.CALL2 | Tesla option (CALL 2) | **0** | **0** |
| 1384 | TSLA.PUT1 | Tesla option (PUT 1) | **0** | **0** |
| 1386 | TSLA.PUT2 | Tesla option (PUT 2) | **0** | **0** |

### Suffix Meanings

| Suffix | Meaning | Include for "give me X"? |
|---|---|---|
| (none) | Main instrument, USD-denominated | Always |
| `.RTH` | Regular Trading Hours session | Yes |
| `.24-7` | 24/7 extended hours session (launched April 2026) | Yes |
| `.EUR` | EUR-denominated version | Yes |
| `.CALL*`, `.PUT*` | Options (Tradeable=0, zero activity ever) | **No** |
| `.JAN26`, `.FEB26`... | Micro futures (IsFuture=1) | **No** |
| `.SPOT`, `.Fut` | Futures variants | **No** |

### Enrichment Columns (v_dim_instrument_enriched only)

| Column | What it tells you |
|---|---|
| `IsFuture` | 1 = futures/derivative — exclude with `IsFuture = 0` |
| `Tradeable` | 1 = currently tradeable — exclude inactive with `Tradeable = 1` |
| `IsSQF` | 1 = Special Qualifying Flag (Group 59) |
| `Is_245_Instrument` | 1 = 24/5 trading schedule |
| `PlatformSector` | eToro platform sector ("Consumer Durables", "Technology") |
| `PlatformIndustry` | eToro platform industry ("Motor Vehicles") |
| `OperationMode` | 0 = standard, 1 = special mode (e.g., Eurotech SpA = 1) |
| `Multiplier` | Contract multiplier (futures/leveraged products) |
| `SettlementTime` | Settlement period |

---

## The Mandatory Two-Part Filter Pattern

**Every instrument filter MUST have:**
1. A ticker/name pattern (LIKE or IN)
2. An InstrumentTypeID constraint

### Preferred Pattern (enriched view)
```sql
WHERE i.Symbol LIKE '{TICKER}%'
  AND i.InstrumentTypeID = {EXPECTED_TYPE}
  AND i.IsFuture = 0
  AND i.Tradeable = 1
```

### Fallback Pattern (base table)
```sql
WHERE i.Symbol LIKE '{TICKER}%'
  AND i.InstrumentTypeID = {EXPECTED_TYPE}
  AND i.Symbol NOT LIKE '%.CALL%'
  AND i.Symbol NOT LIKE '%.PUT%'
```

### Per-Asset-Class Patterns

**Stocks (TypeID = 5):**
```sql
-- "Give me Tesla" = all trading sessions, no options
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
-- Matches: TSLA, TSLA.RTH, TSLA.24-7, TSLA.EUR
-- Excludes: TSLA.CALL1, TSLA.PUT2 (Tradeable = 0)
```

**Crypto (TypeID = 10):**
```sql
-- "Give me Ethereum" = ETH spot, no futures
-- Use Name (not Symbol) for crypto — cleaner parsing
WHERE i.Name LIKE 'ETH/%'
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 0
-- Matches: ETH/USD, ETH/EUR, ETH/GBP, ETH/BTC (cross-pair)
-- Excludes: ETH.JAN26 (IsFuture=1), ETHA (TypeID=6), ETH.MI/Eurotech (TypeID=5)
```

**Crypto fiat-only (no cross-pairs):**
```sql
WHERE i.Name LIKE 'ETH/%'
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 0
  AND SPLIT(i.Name, '/')[1] IN ('USD','EUR','GBP','JPY','AUD','NZD','CAD','CHF','CNH')
```

**ETFs (TypeID = 6):**
```sql
-- "Bitcoin ETF revenue"
WHERE i.InstrumentTypeID = 6
  AND (LOWER(i.InstrumentDisplayName) LIKE '%bitcoin%'
       OR i.Symbol IN ('IBIT', 'GBTC', 'ARKB'))
```

### Canonical InstrumentID (when you need a single ID)
```sql
WHERE Symbol = 'TSLA' AND InstrumentTypeID = 5   -- Tesla canonical
WHERE Symbol = 'ETH' AND InstrumentTypeID = 10    -- Ethereum canonical
WHERE Symbol = 'BTC' AND InstrumentTypeID = 10    -- Bitcoin canonical
```

---

## ETH — The Worst Case

`ETH` collides across 5 InstrumentTypeIDs. Without `InstrumentTypeID = 10`, queries return an Italian tech stock:

| TypeID | What Matches | Is it "Ethereum"? |
|---|---|---|
| 10 (Crypto) | ETH/USD, ETH/EUR, ETH/GBP | **Yes** |
| 10 (Crypto) | ETH.JAN26 (IsFuture=1) | No — derivative |
| 10 (Crypto) | ETH/BTC, ETH/LTC (cross-pairs) | Yes (include by default) |
| 6 (ETF) | ETHA (iShares Ethereum Trust), CETH.DE | No — ETF |
| 5 (Stocks) | ETH.MI = **Eurotech SpA** | No — Italian stock! |
| 4 (Indices) | ETH.Fut/USD (CME Future) | No — futures |
| 2 (Commodities) | XAU/ETH (Gold/Ethereum pair) | No — commodities |

---

## Common Ticker Mappings

| User Says | Ticker | TypeID | Filter |
|---|---|---|---|
| Tesla, TSLA | TSLA | 5 | `Symbol LIKE 'TSLA%' AND TypeID=5 AND IsFuture=0 AND Tradeable=1` |
| Apple, AAPL | AAPL | 5 | `Symbol LIKE 'AAPL%' AND TypeID=5 AND Tradeable=1` |
| Google, Alphabet | GOOG | 5 | `Symbol LIKE 'GOOG%' AND TypeID=5` (includes GOOGL — Class C + Class A) |
| Bitcoin, BTC | BTC | 10 | `Name LIKE 'BTC/%' AND TypeID=10 AND IsFuture=0` |
| Ethereum, ETH | ETH | 10 | `Name LIKE 'ETH/%' AND TypeID=10 AND IsFuture=0` |
| Bitcoin ETF | IBIT | 6 | `TypeID=6 AND DisplayName LIKE '%Bitcoin%'` |
| Ethereum ETF | ETHA | 6 | `TypeID=6 AND DisplayName LIKE '%Ethereum%'` |
| S&P 500 | SPX500 | 4 | `Symbol LIKE 'SPX500%' AND TypeID=4` |

---

## Query Patterns

### Pattern 1 — Metric view + join after aggregation (recommended)
```sql
WITH metrics AS (
  SELECT `date`, `instrument_id`, MEASURE(`some_metric`) AS `metric`
  FROM main.etoro_kpi.mv_some_metric_view
  WHERE `date` >= '2026-01-01'
  GROUP BY ALL
)
SELECT m.`date`, SUM(m.`metric`) AS `metric`
FROM metrics m
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i ON m.instrument_id = i.InstrumentID
WHERE i.Name LIKE 'ETH/%'
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 0
GROUP BY m.`date`
ORDER BY m.`date` ASC;
```
**Use when:** Querying metric views that expose `instrument_id` — aggregate first, join to dim after.

### Pattern 2 — Direct fact table query
```sql
SELECT f.DateID, SUM(f.FullCommissionTotal) AS fullcommission
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics f
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i ON f.InstrumentID = i.InstrumentID
WHERE i.Symbol LIKE 'TSLA%'
  AND i.InstrumentTypeID = 5
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND f.DateID >= 20260401
GROUP BY f.DateID
ORDER BY f.DateID;
```
**Use when:** "Tesla revenue", "revenue from a specific stock", any instrument-filtered metric on fact tables

### Pattern 3 — Discovery query ("what instruments match?")
```sql
SELECT InstrumentTypeID, InstrumentType, InstrumentID, Symbol, Name,
       InstrumentDisplayName, IsFuture, Tradeable, PlatformSector
FROM main.etoro_kpi_prep.v_dim_instrument_enriched
WHERE LOWER(InstrumentDisplayName) LIKE LOWER('%{USER_INPUT}%')
   OR Symbol LIKE '{USER_INPUT}%'
   OR Name LIKE '{USER_INPUT}/%'
ORDER BY InstrumentTypeID, Symbol;
```
**Use when:** "what instruments match X?", validating a ticker before filtering, checking for collisions

### Pattern 4 — All active instruments for an asset class
```sql
SELECT Symbol, Name, InstrumentDisplayName, PlatformSector
FROM main.etoro_kpi_prep.v_dim_instrument_enriched
WHERE InstrumentTypeID = 5
  AND Tradeable = 1
  AND IsFuture = 0
ORDER BY Symbol;
```
**Use when:** "list all tradeable stocks", "active instruments in asset class"

---

## Key Rules Summary

1. **Use `Name LIKE '{TICKER}/%'` for crypto** (not Symbol LIKE) — `Name` has clean format `TICKER/CURRENCY`.
2. **Use `Symbol LIKE '{TICKER}%'` for stocks** — suffixes use dots (TSLA.RTH).
3. **Prefer enriched view flags** (`IsFuture=0`, `Tradeable=1`) over suffix pattern matching.
4. **Validate before filtering** — always run a discovery query to check for cross-type collisions.
5. **Google has two tickers**: GOOG (Class C) and GOOGL (Class A). `LIKE 'GOOG%'` gets both.
6. **Crypto cross-pairs (ETH/BTC)** are TypeID=10 same as spot — include by default, exclude only if user asks fiat-only.
