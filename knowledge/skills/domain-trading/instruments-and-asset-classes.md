---
id: instruments-and-asset-classes
name: "Instruments & Asset Classes"
description: "Instrument identification and filtering for eToro assets (stocks, crypto, ETFs, indices, commodities, FX, options, futures). Covers the mandatory two-part filter pattern (Symbol/Name + InstrumentTypeID), the one-asset-many-IDs problem (Tesla = 8 InstrumentIDs across trading sessions), suffix meanings (.RTH, .24-7, .EUR, .CALL/.PUT, .JAN26), enriched-view flags (IsFuture, Tradeable, IsSQF, Is_245_Instrument, OperationMode), and per-asset-class query patterns. Load when filtering data by a specific instrument, joining to dim_instrument, or when a user mentions an asset by ticker or name."
triggers:
  - instrument
  - InstrumentID
  - InstrumentTypeID
  - dim_instrument
  - v_dim_instrument_enriched
  - by instrument
  - by asset class
  - by ticker
  - by symbol
  - TSLA
  - AAPL
  - ETH
  - BTC
  - SPX500
  - IBIT
  - ETHA
  - real stocks
  - real crypto
  - stocks
  - crypto
  - ETF
  - commodities
  - indices
  - forex
  - FX pair
  - options
  - futures
  - IsFuture
  - Tradeable
  - IsSQF
  - Bitcoin ETF
  - Ethereum ETF
  - Tesla
  - Apple
  - Bitcoin
  - Ethereum
required_tables:
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
  - main.bi_output.bi_ouput_v_dim_instrumenttype
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Instruments & Asset Classes

eToro's instrument catalogue is **not flat**. One logical asset (e.g. "Tesla") maps to 8 distinct `InstrumentID`s for different trading sessions, currency denominations, and option chains. One ticker symbol (e.g. `ETH`) collides across 5 different `InstrumentTypeID`s — including an Italian tech stock. A filter that says "give me Tesla" but only constrains the symbol misses 7 out of 8 sessions. A filter that says "give me Ethereum" but doesn't constrain the type matches a stock called Eurotech SpA.

This sub-skill teaches the **two-part filter pattern** — Symbol/Name *plus* InstrumentTypeID *plus* (preferably) `IsFuture = 0` and `Tradeable = 1` — that makes instrument filters trustworthy. It is mandatory reading for any question filtered by ticker, name, or asset class.

## When to Use

Load when:

- Filtering any fact table by a specific instrument (stock, crypto, ETF, index)
- Joining to `Dim_Instrument` or `v_dim_instrument_enriched` for instrument details
- A user mentions an asset by name, ticker, or display name ("Tesla", "ETH", "Bitcoin ETF", "S&P 500")
- Building queries that reference instruments by asset class (stocks, crypto, ETFs)
- Validating a ticker before authoring a production filter

Do **not** load for:

- Position-state questions (lifecycle, MirrorID at open, partial closes) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Aggregated trading volume by asset class → [`trading-volumes.md`](trading-volumes.md) (uses this skill's rules)
- AUM / PnL by instrument → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md) (uses this skill's rules)
- Revenue by instrument → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md) (uses this skill's rules)

## Scope

In scope: Instrument identification, the mandatory two-part filter pattern, `InstrumentTypeID` reference map (1=FX, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto), suffix meanings (.RTH, .24-7, .EUR, .CALL, .PUT, .JAN26, .Fut, .SPOT), enriched-view flags (`IsFuture`, `Tradeable`, `IsSQF`, `Is_245_Instrument`, `OperationMode`, `Multiplier`, `SettlementTime`), per-asset-class query patterns (Stocks, Crypto, ETF, Forex, Indices, Commodities), common ticker mappings, key columns for identification (`ISINCode`, `CUSIP`, `Exchange`, `Industry`, `AssetClass`, `PlatformSector`, `PlatformIndustry`).
Out of scope: Revenue amounts by instrument (→ `domain-revenue-and-fees`), trading volumes by instrument (→ `trading-volumes.md`), PnL by instrument (→ `portfolio-value-aum-pnl.md`), position state at open (→ `position-state-and-grain.md`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — A ticker-only filter WITHOUT `InstrumentTypeID` produces wrong results.** `Symbol LIKE 'ETH%'` AND `InstrumentTypeID = 10` returns Ethereum. The same filter WITHOUT the type-ID also matches Eurotech SpA (Stocks, TypeID=5) and an iShares Ethereum Trust ETF (TypeID=6). Always pair Symbol/Name with `InstrumentTypeID`.
2. **Tier 1 — One logical asset = MANY InstrumentIDs.** Tesla has 8 IDs (main + .RTH + .24-7 + .EUR + 4 options variants). Filtering by a single `InstrumentID = 1111` misses 7 of those trading sessions and ALL EUR-denominated Tesla trades. Use the Symbol/Name pattern with appropriate suffix-handling flags.
3. **Tier 2 — NEVER filter on `InstrumentDisplayName`.** It's not unique ("Tesla Motors, Inc." maps to 3 IDs), inconsistent ("Tesla Motors, Inc." vs "Tesla 24/7"), and has trailing spaces. Use the `Symbol` or `Name` column. Display name is for display only.
4. **Tier 2 — Crypto micro futures share `InstrumentTypeID = 10` with spot crypto.** A "give me Ethereum" filter using `InstrumentTypeID = 10` alone picks up `ETH.JAN26` micro futures alongside `ETH/USD` spot. Use `IsFuture = 0` (enriched view) or `Symbol NOT LIKE '%.%'` (fallback) to exclude derivatives.
5. **Tier 2 — ETFs named after crypto (IBIT, ETHA, GBTC) are `InstrumentTypeID = 6`, NOT crypto (10).** "Bitcoin ETF revenue" is ETF revenue, not crypto revenue. Filter accordingly.
6. **Tier 3 — Options are typed as Stocks (TypeID = 5) with `.CALL`/`.PUT` suffixes.** TypeID 9 exists in the type table but has zero instruments assigned. Exclude options either via `Tradeable = 1` (options are `Tradeable = 0`) or `Symbol NOT LIKE '%.CALL%' AND Symbol NOT LIKE '%.PUT%'`.
7. **Tier 3 — Ethereum Classic (`ETC`) ≠ Ethereum (`ETH`).** `Symbol LIKE 'ETH%'` does NOT match `ETC` (good). But `InstrumentDisplayName LIKE '%ethereum%'` WOULD match both — another reason to never filter on DisplayName.

## Tables

| Table | Use For |
|---|---|
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | **PREFERRED.** Adds enriched flags: `IsFuture`, `Tradeable`, `IsSQF`, `Is_245_Instrument`, `PlatformSector`, `PlatformIndustry`, `OperationMode`, `Multiplier`, `SettlementTime`. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Base instrument master (47 columns). Use when the enriched view is unavailable or you need a column not exposed by the view. |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | Complete `InstrumentTypeID` → name mapping. |
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | The fact to join into when answering "tickerwise" metric questions. |

---

## Core Concepts

### Key identification columns

| Concept | What It Is | Aliases |
|---|---|---|
| **InstrumentID** | Unique PK per instrument variant. One logical asset has MANY IDs. | instrument key |
| **Symbol** | Ticker with optional suffix: `TSLA`, `TSLA.RTH`, `TSLA.24-7`. **Primary lookup column for stocks.** | ticker |
| **Name** | Full trade pair: `TSLA/USD`, `ETH/EUR`. **Best for crypto filtering.** | trade pair |
| **InstrumentTypeID** | Asset class numeric FK. **Mandatory boundary filter.** | type ID, asset class |
| **IsFuture** | 1 = futures/derivative contract. Enriched view only. | futures flag |
| **Tradeable** | 1 = currently tradeable. 0 = inactive (options, delisted). Enriched view only. | active flag |
| **IsSQF** | 1 = Special Qualifying Flag (GroupID 59). Enriched view only. | SQF |

### Key columns for identification (full)

| Column | Type | Example (Tesla) | Use For |
|---|---|---|---|
| `InstrumentID` | INT | 1111 | Joins to fact tables |
| `Symbol` | STRING | `TSLA`, `TSLA.RTH` | **Primary lookup column** |
| `SymbolFull` | STRING | `TSLA`, `TSLA.RTH` | Redundant with Symbol |
| `Name` | STRING | `TSLA/USD`, `TSLA.RTH/USD` | Full trade pair name |
| `InstrumentDisplayName` | STRING | "Tesla Motors, Inc." | Display only — **NEVER filter on this** |
| `InstrumentTypeID` | INT | 5 | **MANDATORY boundary filter** |
| `ISINCode` | STRING | US88160R1014 | Regulatory / financial lookup |
| `CUSIP` | STRING | 88160R101 | US equity lookup |
| `Exchange` | STRING | NASDAQ | Market identification |
| `Industry` | STRING | Technology | Sector analysis |
| `AssetClass` | STRING | Equity | Bloomberg-style classification |

### `InstrumentTypeID` reference

| TypeID | Type | Count | Notes |
|---|---|---|---|
| 1 | Currencies | 153 | EUR/USD, GBP/USD — FX pairs |
| 2 | Commodities | 503 | Gold, Silver, Oil — also nano BTC futures |
| 4 | Indices | 247 | SPX500, DJ30 — also CME futures |
| 5 | Stocks | 12,849 | TSLA, AAPL — also options (`.CALL`/`.PUT`) |
| 6 | ETF | 1,287 | IBIT (Bitcoin ETF), SPY, ETHA |
| 10 | Crypto Currencies | 667 | BTC, ETH, XRP — spot + cross-pairs + micro futures |
| 0 | NA | 1 | Placeholder / unknown |
| 3, 7, 8, 9 | Reserved | 0 | CFD, Bonds, TrustFunds, Options — defined but empty |

### Tesla example (8 InstrumentIDs, 4 active)

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

### Suffix meanings

| Suffix | Meaning | Include for "give me X"? |
|---|---|---|
| (none) | Main instrument, USD-denominated | Always |
| `.RTH` | Regular Trading Hours session | Yes |
| `.24-7` | 24/7 extended hours session (launched April 2026) | Yes |
| `.EUR` | EUR-denominated version | Yes |
| `.CALL*`, `.PUT*` | Options (`Tradeable = 0`, zero activity ever) | **No** |
| `.JAN26`, `.FEB26`… | Micro futures (`IsFuture = 1`) | **No** |
| `.SPOT`, `.Fut` | Futures variants | **No** |

### Enrichment columns (v_dim_instrument_enriched only)

| Column | What it tells you |
|---|---|
| `IsFuture` | 1 = futures / derivative — exclude with `IsFuture = 0` |
| `Tradeable` | 1 = currently tradeable — exclude inactive with `Tradeable = 1` |
| `IsSQF` | 1 = Special Qualifying Flag (GroupID 59) |
| `Is_245_Instrument` | 1 = 24/5 trading schedule |
| `PlatformSector` | eToro platform sector ("Consumer Durables", "Technology") |
| `PlatformIndustry` | eToro platform industry ("Motor Vehicles") |
| `OperationMode` | 0 = standard, 1 = special mode (e.g. Eurotech SpA = 1) |
| `Multiplier` | Contract multiplier (futures / leveraged products) |
| `SettlementTime` | Settlement period |

---

## The Mandatory Two-Part Filter Pattern

**Every instrument filter MUST have:**

1. A ticker / name pattern (`LIKE` or `IN`)
2. An `InstrumentTypeID` constraint

### Preferred Pattern (enriched view)
```sql
WHERE i.Symbol LIKE '{TICKER}%'
  AND i.InstrumentTypeID = {EXPECTED_TYPE}
  AND i.IsFuture = 0
  AND i.Tradeable = 1
```

### Fallback Pattern (base table only)
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
-- Excludes: ETH.JAN26 (IsFuture=1), ETHA (TypeID=6), ETH.MI / Eurotech (TypeID=5)
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

## ETH — the worst-case collision

`ETH` collides across 5 `InstrumentTypeID`s. Without `InstrumentTypeID = 10`, queries return an Italian tech stock:

| TypeID | What Matches | Is it "Ethereum"? |
|---|---|---|
| 10 (Crypto) | ETH/USD, ETH/EUR, ETH/GBP | **Yes** |
| 10 (Crypto) | ETH.JAN26 (`IsFuture = 1`) | No — derivative |
| 10 (Crypto) | ETH/BTC, ETH/LTC (cross-pairs) | Yes (include by default) |
| 6 (ETF) | ETHA (iShares Ethereum Trust), CETH.DE | No — ETF |
| 5 (Stocks) | ETH.MI = **Eurotech SpA** | No — Italian stock! |
| 4 (Indices) | ETH.Fut/USD (CME Future) | No — futures |
| 2 (Commodities) | XAU/ETH (Gold / Ethereum pair) | No — commodities |

---

## Common ticker mappings

| User says | Ticker | TypeID | Filter |
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
**Use when:** "Tesla revenue", "revenue from a specific stock", any instrument-filtered metric on the granular fact.

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
**Use when:** "what instruments match X?", validating a ticker before filtering, checking for collisions. **Run this FIRST whenever you author a new filter.**

### Pattern 4 — All active instruments for an asset class
```sql
SELECT Symbol, Name, InstrumentDisplayName, PlatformSector
FROM main.etoro_kpi_prep.v_dim_instrument_enriched
WHERE InstrumentTypeID = 5
  AND Tradeable = 1
  AND IsFuture = 0
ORDER BY Symbol;
```
**Use when:** "list all tradeable stocks", "active instruments in asset class".

---

## Key rules summary

1. **Use `Name LIKE '{TICKER}/%'` for crypto** (not Symbol LIKE) — `Name` has clean format `TICKER/CURRENCY`.
2. **Use `Symbol LIKE '{TICKER}%'` for stocks** — suffixes use dots (`TSLA.RTH`).
3. **Prefer enriched-view flags** (`IsFuture = 0`, `Tradeable = 1`) over suffix pattern matching.
4. **Validate before filtering** — always run a discovery query (Pattern 3) to check for cross-type collisions.
5. **Google has two tickers**: GOOG (Class C) and GOOGL (Class A). `LIKE 'GOOG%'` gets both.
6. **Crypto cross-pairs (ETH/BTC)** are TypeID = 10 same as spot — include by default, exclude only if user asks fiat-only.

## Cross-references

- Position state, copy detection → [`position-state-and-grain.md`](position-state-and-grain.md)
- Volume aggregates by asset class → [`trading-volumes.md`](trading-volumes.md)
- PnL by instrument → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue by instrument → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)

## Provenance

This sub-skill deeply incorporates the DataPlatform DE workspace-root skill `instruments` (`/Workspace/.assistant/skills/instruments/SKILL.md`, version 2, `last_validated_at` 2026-05-07). The original is scheduled for removal once this incorporated version is validated. All counts (TypeID populations, Tesla example, ETH collision matrix) verified against the source skill on 2026-05-11.
