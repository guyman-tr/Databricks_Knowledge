---
name: domain-trading
description: "Instrument identification and filtering for eToro assets (stocks, crypto, ETFs, indices, commodities, FX, futures). Covers the mandatory two-part filter pattern (Symbol/Name + InstrumentTypeID), the one-asset-many-IDs problem (Tesla = 8 InstrumentIDs across trading sessions, options, EUR), suffix meanings (.RTH, .24-7, .EUR, .CALL/.PUT, .JAN26), the Tradable-vs-Tradeable distinction (3,005 instruments differ — Tradable is the production flag, Tradeable is the enriched/business-rules version), enriched-view flags (IsFuture, Tradeable, IsSQF=GroupID 59, Is_245_Instrument, OperationMode, Multiplier, DollarRatio), per-asset-class query patterns, and the UC-comment health caveats on the enriched view. Load when filtering data by a specific instrument, joining to dim_instrument, or when a user mentions an asset by ticker or name. Broker-side — InstrumentID maps THROUGH to the dealer side via Trade.ProviderToInstrument, so the same dim is the entry point for both."
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
  - futures
  - micro futures
  - JAN26
  - 24/7 instrument
  - RTH
  - regular trading hours
  - IsFuture
  - Tradeable
  - Tradable
  - IsSQF
  - Is_245_Instrument
  - DollarRatio
  - IsMajor
  - OperationMode
  - ProviderID
  - Bitcoin ETF
  - Ethereum ETF
  - ENS
  - Eurotech
  - Tesla
  - Apple
  - Bitcoin
  - Ethereum
  - SymbolFull
  - ISIN
  - CUSIP
  - Exchange
required_tables:
  - main.etoro_kpi_prep.v_dim_instrument_enriched
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
  - main.bi_output.bi_ouput_v_dim_instrumenttype
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Instruments & Asset Classes

eToro's instrument catalogue is **not flat**. One logical asset (e.g. "Tesla") maps to **8 distinct `InstrumentID`s** for different trading sessions, currency denominations, and option chains. One ticker symbol (e.g. `ETH`) collides across **5 different `InstrumentTypeID`s** — including an Italian tech stock (`Eurotech SpA`, Symbol=`ETH`) that is `Tradeable=1` today. A filter that says "give me Tesla" but only constrains `Symbol` misses 7 out of 8 sessions; a filter that says "give me Ethereum" but doesn't constrain the type matches the Italian stock.

This sub-skill teaches the **two-part filter pattern** — `Symbol` or `Name` + `InstrumentTypeID` + (preferably) `IsFuture = 0` + `Tradeable = 1` — that makes instrument filters trustworthy. It is **mandatory reading** for any question filtered by ticker, name, or asset class. Every sibling sub-skill (`trading-volumes`, `portfolio-value-aum-pnl`, `best-execution`, the Revenue & Fees super-domain) refers back here for the instrument-filter rule.

**Side classification**: this is a **broker-side** sub-skill. The instrument catalogue is shared between broker and dealer sides (every `InstrumentID` carries `ProviderID` — the LP that quotes it — making this dim the natural entry point for broker→dealer joins), but the filtering rules and identity model documented here are about the customer-facing catalogue.

## When to Use

Load when:

- Filtering any fact table by a specific instrument (stock, crypto, ETF, index, commodity, FX pair, futures)
- Joining to `Dim_Instrument` or `v_dim_instrument_enriched` for instrument details
- A user mentions an asset by name, ticker, or display name ("Tesla", "ETH", "Bitcoin ETF", "S&P 500", "Apple")
- Building queries that reference instruments by asset class (real stocks, crypto, ETFs, FX, futures)
- Validating a ticker before authoring a production filter (the **Discovery query** in Pattern 3 is the entry point)
- Resolving the "ETH" collision (Ethereum vs Eurotech SpA vs Ethereum-future vs ENS vs Ethereum ETF)
- Choosing between `Tradable` and `Tradeable` (they differ on 3,005 instruments)
- Identifying the LP that quotes an instrument (`ProviderID` — broker→dealer bridge)

Do **not** load for:

- Position-state questions (lifecycle, MirrorID at open, partial closes) → [`position-state-and-grain.md`](position-state-and-grain.md)
- Aggregated trading volume by asset class (the volume-aggregation table joins back here) → [`trading-volumes.md`](trading-volumes.md)
- AUM / PnL by instrument → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Revenue by instrument → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Pricing history (`Fact_CurrencyPriceWithSplit`) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Per-LP routing decisions, hedge cost → dealer-side sub-skills (`broker-and-lp-reconciliation`, `lp-contracts-and-cogs`, `best-execution`)

## Scope

In scope: Instrument identification, the mandatory two-part filter pattern, `InstrumentTypeID` reference (10 types — only 6 populated), suffix meanings, the **`Tradable` vs `Tradeable` distinction**, enriched-view flags (`IsFuture`, `Tradeable`, `IsSQF`, `Is_245_Instrument`, `OperationMode`, `Multiplier`, `DollarRatio`, `IsMajor`/`IsMajorID`), per-asset-class query patterns (Stocks, Crypto, ETF, Forex, Indices, Commodities, Futures, Options), common ticker mappings, key columns for identification (`ISINCode`, `CUSIP`, `Exchange`, `Industry`, `AssetClass`, `PlatformSector`, `PlatformIndustry`), refresh cadence, daily snapshot table, and the UC comment health caveats (the **enriched view has missing or misattributed comments** on three columns).

Out of scope: Revenue amounts by instrument (→ `domain-revenue-and-fees`), trading volumes by instrument (→ `trading-volumes.md`), PnL by instrument (→ `portfolio-value-aum-pnl.md`), position state at open (→ `position-state-and-grain.md`), pricing history (→ `pricing-and-currency-history.md`), per-LP routing & hedge cost (→ dealer-side sub-skills).

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — A ticker-only filter WITHOUT `InstrumentTypeID` produces wrong results.** `Symbol = 'ETH'` AND `InstrumentTypeID = 10` returns Ethereum spot. The same filter WITHOUT the type-ID also matches **Eurotech SpA (Symbol='ETH', InstrumentTypeID=5, Tradeable=1 — InstrumentID 1061380)**. Same trap on `BTC` (Bitcoin vs `BTCETC` cross-pair), `ETHA` (`ETHA.US` iShares Ethereum ETF, TypeID=6 vs `ETHA` Ethereum/VAULTA cross-pair, TypeID=10), and many three-letter tickers. Always pair `Symbol`/`Name` with `InstrumentTypeID`.

2. **Tier 1 — One logical asset = MANY InstrumentIDs.** Tesla has 8 IDs: main USD (`TSLA`), Regular Trading Hours (`TSLA.RTH`), 24/7 extended hours (`TSLA.24-7`), EUR-denominated (`TSLA.EUR`), and 4 options variants (`.CALL1`, `.CALL2`, `.PUT1`, `.PUT2`). Filtering by a single `InstrumentID` misses all the other sessions. Use `Symbol LIKE 'TSLA%'` for the whole family, then exclude derivatives with `IsFuture = 0` and `Tradeable = 1`.

3. **Tier 1 — `Tradable` (no e) and `Tradeable` (with e) are DIFFERENT columns and disagree on 3,005 instruments (≈19% of the catalogue).** `Tradable` is the production flag passed through from `Trade.InstrumentMetaData` — it says "the trade engine allows orders". `Tradeable` is added in the enriched view and applies additional business rules (most prominently, it sets options to 0 even though their `Tradable=1` flag is on). Live counts (May 2026): `Tradable=1, Tradeable=1` 11,165 / `Tradable=1, Tradeable=0` 3,005 / `Tradable=0, Tradeable=0` 2,139. The 3,005 differ-set is spread across all type IDs — predominantly Stocks (1,627), Commodities (492), Crypto (383). **Default to `Tradeable = 1`** for analytical "is this currently usable?" filters; reach for `Tradable = 1` only when the question is specifically about the production flag value.

4. **Tier 1 — UC column comments on `v_dim_instrument_enriched` have known defects on three flag columns.** As of 2026-05-11: `Tradeable` and `IsSQF` have **empty comments**; `Is_245_Instrument` has a **misattributed comment** (the text describes the InstrumentID primary key instead). Also, the `OperationMode` comment's count (~83 OperationMode=1 instruments) is stale — live data has 2,566. The Synapse Function wiki (`Function_Instrument_Snapshot_Enriched.md`) is the authoritative source for these flag semantics — see the "Enrichment flags" table below.

5. **Tier 1 — `IsTicketFeePercentInstrument` is documented in the Synapse function wiki but is NOT exposed by the UC view.** The wiki for `Function_Instrument_Snapshot_Enriched` defines column 8 as `IsTicketFeePercentInstrument` (= `CASE WHEN Bid = BidSpreaded AND InstrumentTypeID = 10 THEN 1 ELSE 0` — flags crypto instruments where eToro charges a ticket fee instead of a spread). The UC `v_dim_instrument_enriched` does NOT include this column (50 columns exposed, but `IsTicketFeePercentInstrument` is missing). If you need this flag, either compute it ad-hoc from `Fact_CurrencyPriceWithSplit` (`Bid = BidSpreaded` join), or query the underlying Synapse function directly.

6. **Tier 2 — NEVER filter on `InstrumentDisplayName`.** It's not unique ("Tesla Motors, Inc." maps to 3 IDs — main, RTH, EUR), inconsistent ("Tesla Motors, Inc." vs "Tesla 24/7" for different sessions of the same asset), and contains trailing spaces. Use `Symbol` or `Name`. `DisplayName` is for display only.

7. **Tier 2 — `Symbol` is NOT unique; `SymbolFull` IS.** Across the 12,849 Stock instruments, there are only 12,707 distinct `Symbol` values (142 duplicates — typically the same ticker listed on multiple exchanges or in multiple market sessions). In production, `Trade.InstrumentMetaData.SymbolFull` carries a UNIQUE constraint. When you need an exact-match lookup with no ambiguity, prefer `SymbolFull = 'AAPL'` over `Symbol = 'AAPL'`. For pattern-match (LIKE) usage, `Symbol` is fine.

8. **Tier 2 — Crypto micro futures share `InstrumentTypeID = 10` with spot crypto.** ETH spot (`Name='ETH/USD'`) and ETH micro futures (`Name='ETH.JAN26/USD'`, `IsFuture=1`) both carry `InstrumentTypeID = 10`. A "give me Ethereum" filter using `InstrumentTypeID = 10` alone picks up `ETH.JAN26`, `ETH.FEB26`, `ETH.APR26`, `ETH.NOV25` alongside the spot pair. Use `IsFuture = 0` (enriched view) or `Symbol NOT LIKE '%.JAN%' AND ...` (fallback) to exclude. Same rule applies to BTC, BNB, and most major crypto.

9. **Tier 2 — ETFs named after crypto (`IBIT`, `ETHA.US`, `GBTC`, `CETH.DE`) are `InstrumentTypeID = 6`, NOT crypto (10).** "Bitcoin ETF revenue" is ETF revenue, not crypto revenue. Filter on TypeID 6 + symbol/displayname pattern.

10. **Tier 2 — Within the Ethereum family there are several Ethereum-adjacent crypto instruments that are NOT Ethereum.** `ETC` (Ethereum Classic, separate asset), `ENS` (Ethereum Name Service, separate asset), and many cross-pairs (`ETH/BTC`, `BTC/ETH`, `ZEC/ETH`, etc.). `Symbol LIKE 'ETH%'` does NOT match `ETC` (good) but DOES match `ETHA` (the Ethereum/VAULTA cross-pair, TypeID=10 — also caught) and `ETHFI` (Ether.fi, separate asset). A filter on `Name LIKE 'ETH/%'` is cleaner because it constrains ETH as the buy-side of a pair.

11. **Tier 2 — Options are typed as Stocks (`InstrumentTypeID = 5`) with `.CALL*`/`.PUT*` suffixes.** Only 4 options instruments exist in the catalogue today (all Tesla CALL1, CALL2, PUT1, PUT2). `InstrumentTypeID = 9` (Options) is defined in the type lookup but has zero instruments assigned. All 4 options are `Tradable=1` but `Tradeable=0` — confirming that `Tradeable` filters out options. Use `Tradeable = 1` (enriched) or `Symbol NOT LIKE '%.CALL%' AND Symbol NOT LIKE '%.PUT%'` (fallback) to exclude.

12. **Tier 3 — `DollarRatio` is a price-scaling factor, not a divisor.** Most instruments = 1. **JPY pairs = 100** (because JPY is quoted in 100ths). Used in P&L and conversion-rate calculations. If you are doing manual price math (rare — usually fed by `Fact_CurrencyPriceWithSplit`), do not apply `DollarRatio` blindly without understanding what scale your price column is already in.

13. **Tier 3 — Refresh cadence is daily truncate-and-reload via `SP_Dim_Instrument`.** NOT real-time. An instrument added to production today appears in `Dim_Instrument` tomorrow. The `UpdateDate` / `InsertDate` columns reflect the ETL load time, NOT the production-side modification time. For point-in-time historical state, use `Dim_Instrument_Snapshot` (date-partitioned).

14. **Tier 3 — `AssetClass` is NULL for 13,557 of 15,707 rows (86%) and `Multiplier` is NULL for 15,464 (98%, populated only for futures).** These are post-load enrichment columns and `LEFT JOIN` semantics leave most rows NULL. Don't use them as filter predicates without understanding the coverage gap.

## Tables

| Table | Use For |
|---|---|
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | **PREFERRED.** Latest-DateID slice of the Synapse `Function_Instrument_Snapshot_Enriched` (50 columns). Adds: `IsFuture`, `Tradeable` (NOT same as `Tradable`!), `IsSQF`, `Is_245_Instrument`. Sentinel row (InstrumentID=0) is pre-filtered out. 16,309 rows live. |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Base instrument master (47 columns). Use when you specifically need `Tradable` (not the enriched `Tradeable`), or a column the enriched view doesn't expose. Includes the InstrumentID=0 sentinel — filter with `InstrumentID > 0` for aggregations. 15,707+ rows. |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | Complete `InstrumentTypeID` → name mapping (all 10 types, including the empty ones: 3=CFD, 7=Bonds, 8=TrustFunds, 9=Options). |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_snapshot` | Date-partitioned historical instrument state. Use when the question is "what was this instrument's metadata on date X" (rare, but the only way to recover pre-update state — current dim is truncate-and-reload). |
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | The granular customer-action fact. Join `InstrumentID` to filter actions by instrument. |

---

## Core Concepts

### Key identification columns

| Concept | What It Is | When to Use |
|---|---|---|
| **InstrumentID** | Unique PK per instrument variant. Allocated by `Internal.GetInstrumentID` during `Trade.InstrumentAdd`. Range: 0 (sentinel) to ~21,100,110. One logical asset has MANY IDs. | The only safe key for joins. |
| **Symbol** | Ticker with optional dot-suffix: `TSLA`, `TSLA.RTH`, `TSLA.24-7`. **Primary lookup column for stocks/equities.** NOT unique. | Stocks, ETFs, indices, commodities, futures. |
| **SymbolFull** | Full canonical symbol. **UNIQUE** in production (Trade.InstrumentMetaData enforces it). | Exact-match lookups when ambiguity matters. |
| **Name** | Trade pair: `TSLA/USD`, `ETH/EUR`, `EUR/USD`. **Best for crypto and forex** (clean `BUY/SELL` format). | Crypto, FX. |
| **InstrumentTypeID** | Asset class numeric FK. **Mandatory boundary filter.** | EVERY instrument filter. |
| **BuyCurrencyID / SellCurrencyID** | The instrument-pair definition. For forex: real currencies. For stocks/ETFs/crypto: `BuyCurrencyID = the asset's CurrencyID`, `SellCurrencyID = denomination` (USD, EUR, GBX = pence). UNIQUE pair constraint via `TISR_PAIR` index in OLTP. | Cross-instrument analysis, denomination filters. |
| **Tradable** | Production tradability flag (0/1) cast from bit. **Trade.InstrumentMetaData passthrough.** Says "trade engine allows orders". | When you want the raw production-side flag. |
| **Tradeable** | Enriched-view-only flag (0/1). Applies business rules beyond Tradable — most prominently, sets options to 0. **Default this for analytical "currently usable" filters.** | Analytical filters; "is this currently usable?". |
| **IsFuture** | 1 = futures/derivative contract. Enriched view only. Computed from `Trade.InstrumentGroups.GroupID = 25`. 243 instruments futures-flagged. | Exclude derivatives with `IsFuture = 0`. |
| **IsSQF** | 1 = **SpotQuotedFuture** — smaller-contract-size variant of eToro RealFutures, traded on the **CME (Chicago Mercantile Exchange)**. Computed via membership in `Trade.InstrumentGroups` WHERE `GroupID = 59`. Enriched view only. **8 instruments live** (4 indices + 4 crypto, all also `IsFuture=1`). NOT "Sustainable & Quality-Focused" (fabricated narrative purged from DDR wikis 2026-05-14), NOT "Small Quantity Fee", NOT a UK regulatory flag. | Micro-futures slicing on indices / crypto; futures-product-mix analyses. |
| **Is_245_Instrument** | 1 = instrument is enabled for 24/7 / extended-hours session. **NOT** "24/5 only". 563 instruments flagged (559 Stocks + 4 ETFs). For Tesla: the main USD row (`TSLA`) AND `TSLA.24-7` are flagged 1; the `TSLA.RTH` row is flagged 0 (it's RTH-only). | Filtering for extended-hours-eligible instruments. |
| **IsMajor / IsMajorID** | `IsMajor` is `varchar('Yes'/'No')`; `IsMajorID` is the integer (0/1). Affects spread calculations and ESMA regulatory leverage caps. 6,963 instruments flagged major. **Filter on `IsMajorID`, never on `IsMajor`.** | ESMA leverage-cap analyses, major-FX-only filters. |
| **OperationMode** | 0 = Standard (~13,743 instruments). 1 = Alternate (~2,566 instruments, primarily European stock CFDs traded in non-USD denominations like EUR, GBX). Note: the UC column comment says "~83" — this is stale. Live data is 2,566. | European/non-USD CFD analyses. |
| **DollarRatio** | Price scaling factor. Most = 1. **JPY pairs = 100.** Used in P&L and conversion math. | Manual price math (rare). |
| **ProviderID** | FK to `Trade.Provider`. The LP that quotes this instrument. **This is the broker → dealer bridge** at the instrument level (the LP routing decision before any specific trade). NULL for instruments without a provider mapping. | Joining instruments to LP / dealer-side data. |

### `InstrumentTypeID` reference (live counts as of 2026-05-11)

| TypeID | Type | Count | Notes |
|---|---|---|---|
| 1 | Currencies | 228 | EUR/USD, GBP/USD — FX pairs. 91 are futures (CME-listed FX futures). |
| 2 | Commodities | 743 | Gold, Silver, Oil — also nano BTC futures (337 futures total). |
| 4 | Indices | 319 | SPX500, DJ30 — also CME index futures (140 futures total). All 4 IsSQF are here. |
| 5 | Stocks | 12,849 | TSLA, AAPL — includes the 4 options instruments (`.CALL*` / `.PUT*`) and 557 `.RTH` variants. 12,707 distinct `Symbol`s → 142 dup-symbols. |
| 6 | ETF | 1,347 | IBIT, SPY, ETHA.US, CETH.DE. 4 are `Is_245_Instrument=1`. |
| 10 | Crypto Currencies | 823 | BTC, ETH, XRP — spot + cross-pairs (BTC/ETH, etc.) + micro futures (196 futures total). All 4 IsSQF crypto are here. |
| 0 | NA | 1 row | Sentinel (only in base dim, not in enriched view). |
| 3, 7, 8, 9 | Reserved | 0 | CFD (3), Bonds (7), TrustFunds (8), Options (9) — defined in `bi_ouput_v_dim_instrumenttype` but no rows assigned. |

### Tesla — the 8-ID worked example (live, verified 2026-05-11)

| InstrumentID | Symbol | Name | DisplayName | TypeID | Tradable | Tradeable | IsFuture | Is_245_Instrument | Filter behaviour |
|---|---|---|---|---|---|---|---|---|---|
| 1111 | TSLA | TSLA/USD | Tesla Motors, Inc. | 5 | 1 | 1 | 0 | **1** | Main USD-denominated row; 24/7-eligible |
| 8752 | TSLA.RTH | TSLA.RTH/USD | Tesla Motors, Inc. | 5 | 1 | 1 | 0 | 0 | Regular trading hours session |
| 14259 | TSLA.EUR | TSLA.EUR/EUR | Tesla Motors, Inc. | 5 | 1 | 1 | 0 | 0 | EUR-denominated session |
| 15200 | TSLA.24-7 | TSLA.24-7/USD | Tesla 24/7 | 5 | 1 | 1 | 0 | **1** | 24/7 extended-hours row |
| 1376 | TSLA.CALL1 | TSLA.CALL1/USD | Tesla option (CALL 1) | 5 | **1** | **0** | 0 | 0 | Option — Tradable but enriched-Tradeable=0 |
| 1381 | TSLA.CALL2 | TSLA.CALL2/USD | Tesla option (CALL 2) | 5 | **1** | **0** | 0 | 0 | Option — Tradable but enriched-Tradeable=0 |
| 1384 | TSLA.PUT1 | TSLA.PUT1/USD | Tesla option (PUT 1) | 5 | **1** | **0** | 0 | 0 | Option — Tradable but enriched-Tradeable=0 |
| 1386 | TSLA.PUT2 | TSLA.PUT2/USD | Tesla option (PUT 2) | 5 | **1** | **0** | 0 | 0 | Option — Tradable but enriched-Tradeable=0 |

**Key observation**: production `Tradable=1` on ALL 8 rows, but enriched `Tradeable=0` only on the 4 options. This is exactly the rule: **prefer `Tradeable` for analytical filters; the enriched view has done the options exclusion for you.**

### Suffix meanings

| Suffix | Meaning | Include for "give me X"? | Flag to filter |
|---|---|---|---|
| (none) | Main instrument, USD-denominated | Always | — |
| `.RTH` | Regular Trading Hours session (US equity) | Yes | — |
| `.24-7` | 24/7 extended hours session (launched April 2026) | Yes | `Is_245_Instrument = 1` to find |
| `.EUR` | EUR-denominated version (UK/EU customers) | Yes | — |
| `.CALL*`, `.PUT*` | Options (4 instruments total, all `Tradeable = 0`) | **No** | `Tradeable = 1` excludes |
| `.JAN26`, `.FEB26`, `.APR26`, `.NOV25`… | Micro futures (`IsFuture = 1`) | **No** (default) | `IsFuture = 0` excludes |
| `.SPOT`, `.Fut` | Futures variants (CME-listed) | **No** (default) | `IsFuture = 0` excludes |
| `.MI`, `.US`, `.DE`, etc. | Exchange suffixes on `Name` (e.g. Eurotech `ETH.MI/EUR`) | Depends on intent | — |

### Enrichment flags — the canonical definitions (from BI_DB function wiki)

| Column | Definition |
|---|---|
| `IsFuture` | `1 if InstrumentID ∈ (SELECT InstrumentID FROM Trade.InstrumentGroups WHERE GroupID = 25) else 0`. 243 flagged. |
| `IsSQF` | `1 if InstrumentID ∈ (SELECT InstrumentID FROM Trade.InstrumentGroups WHERE GroupID = 59) else 0`. 8 flagged (4 indices + 4 crypto, all also IsFuture=1). **SpotQuotedFuture** = smaller-contract-size variant of eToro RealFutures, traded on the CME. (Tier 5 user expert correction 2026-05-14 — supersedes "Sustainable & Quality-Focused" / "Small Quantity Fee" / "UK Special Qualifying" — all of which were fabrications.) |
| `IsTicketFeePercentInstrument` *(missing in UC view!)* | `1 if Bid = BidSpreaded AND InstrumentTypeID = 10 else 0`. Flags crypto with no-spread / ticket-fee economics. Defined in `Function_Instrument_Snapshot_Enriched` but NOT exposed in `v_dim_instrument_enriched`. |
| `Tradeable` | Enriched-view-only. Applies business rules beyond production `Tradable`. Most prominently, `Tradeable = 0` for all options even though their production `Tradable = 1`. Differs from `Tradable` on 3,005 rows. |
| `Is_245_Instrument` | `1 if InstrumentID is in the RTH-extended set` (the regular tradable RTH base set AND the regular-ticker rows matched to RTH base via ISIN/CUSIP). Effectively: "this instrument is enabled for the 24/7 schedule." Tesla main USD + TSLA.24-7 = 1; TSLA.RTH = 0. |

---

## The Mandatory Two-Part Filter Pattern

**Every instrument filter MUST have:**

1. A ticker / name pattern (`LIKE` or `IN`)
2. An `InstrumentTypeID` constraint

### Preferred Pattern (enriched view)
```sql
WHERE i.Symbol LIKE '{TICKER}%'    -- or Name LIKE for crypto/forex
  AND i.InstrumentTypeID = {EXPECTED_TYPE}
  AND i.IsFuture = 0                -- exclude futures unless user wants them
  AND i.Tradeable = 1               -- enriched: excludes options + other ineligibles
```

### Fallback Pattern (base table — no enriched flags)
```sql
WHERE i.Symbol LIKE '{TICKER}%'
  AND i.InstrumentTypeID = {EXPECTED_TYPE}
  AND i.Tradable = 1                -- production flag
  AND i.Symbol NOT LIKE '%.CALL%'
  AND i.Symbol NOT LIKE '%.PUT%'
  AND i.InstrumentID > 0            -- exclude sentinel
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
-- "Give me Ethereum" = ETH spot, no futures, ETH-as-buy-side only
WHERE i.Name LIKE 'ETH/%'
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 0
  AND i.Tradeable = 1
-- Matches: ETH/USD, ETH/EUR, ETH/GBP, ETH/JPY, ETH/AUD, ETH/NZD, ETH/CAD, ETH/CHF, ETH/CNH, ETH/BTC, ETH/XLM (cross-pairs)
-- Excludes: ETH.JAN26 (IsFuture=1), ETHA.US (TypeID=6 ETF), ETH.MI/Eurotech (TypeID=5), ETC (Ethereum Classic), ENS (Ethereum Name Service), BTC/ETH (ETH on sell side)
```

**Crypto fiat-only (no cross-pairs):**
```sql
WHERE i.Name LIKE 'ETH/%'
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 0
  AND i.Tradeable = 1
  AND SPLIT(i.Name, '/')[1] IN ('USD','EUR','GBP','JPY','AUD','NZD','CAD','CHF','CNH')
```

**Crypto futures-only (e.g. "ETH micro futures volume"):**
```sql
WHERE i.Symbol LIKE 'ETH.%'      -- dot-suffix means future
  AND i.InstrumentTypeID = 10
  AND i.IsFuture = 1
```

**ETFs (TypeID = 6) — "Bitcoin ETF":**
```sql
WHERE i.InstrumentTypeID = 6
  AND i.Tradeable = 1
  AND (LOWER(i.InstrumentDisplayName) LIKE '%bitcoin%'
       OR i.Symbol IN ('IBIT', 'GBTC', 'ARKB'))
```

**ETFs — "Ethereum ETF" (note the symbol collision with the crypto cross-pair):**
```sql
WHERE i.InstrumentTypeID = 6                       -- the type constraint resolves the collision
  AND i.Tradeable = 1
  AND (LOWER(i.InstrumentDisplayName) LIKE '%ethereum%'
       OR i.Symbol IN ('ETHA.US', 'CETH.DE'))
```

**Forex (TypeID = 1):**
```sql
WHERE i.Name = 'EUR/USD'             -- exact pair
  AND i.InstrumentTypeID = 1
  AND i.IsFuture = 0
-- For major-only: AND i.IsMajorID = 1
```

**Indices (TypeID = 4):**
```sql
WHERE i.Symbol LIKE 'SPX500%'
  AND i.InstrumentTypeID = 4
  AND i.IsFuture = 0                  -- excludes CME-listed index futures
```

**European stock CFDs in non-USD (OperationMode = 1):**
```sql
WHERE i.InstrumentTypeID = 5
  AND i.OperationMode = 1             -- ~2,566 European CFDs in EUR / GBX
  AND i.Tradeable = 1
```

### Canonical InstrumentID (when you need a single ID)

```sql
-- For Tesla canonical (main USD), use the JOIN that picks the .RTH=0 / .EUR=0 row:
WHERE Symbol = 'TSLA' AND InstrumentTypeID = 5    -- InstrumentID 1111
WHERE Symbol = 'ETH'  AND InstrumentTypeID = 10   -- InstrumentID 100001 (Ethereum spot)
WHERE Symbol = 'BTC'  AND InstrumentTypeID = 10   -- InstrumentID 100000 (Bitcoin spot — verify)
```

---

## ETH — the worst-case collision (live verified, 2026-05-11)

`ETH` collides across **5 `InstrumentTypeID`s + extra Ethereum-adjacent traps**:

| TypeID | InstrumentID | Symbol / Name | DisplayName | Tradable / Tradeable | "Ethereum"? |
|---|---|---|---|---|---|
| 10 | 100001 | ETH / ETH/USD | Ethereum | 1 / 1 | **Yes** (canonical spot) |
| 10 | 100110-100224 | ETHEUR, ETHGBP, ETHJPY, … / ETH/{fiat} | Ethereum/{fiat} | 1 / 1 | **Yes** (fiat cross-pair) |
| 10 | 100133, 100131, 100213, 100125 | ETHBTC, ETHXLM, ZECETH, ETHA / ETH/{crypto} | Ethereum/{crypto} | mixed | Yes — crypto cross-pairs (include by default) |
| 10 | 216000-216003 | ETH.JAN26, ETH.FEB26, ETH.APR26, ETH.NOV25 | Micro Ether {Month} Future | 0 / 0 | No — derivative (`IsFuture = 1`) |
| 6 | 12152, 14234 | ETHA.US, CETH.DE | iShares Ethereum Trust ETF, CoinShares Physical Staked Ethereum | 1 / 1 | No — ETF |
| 5 | **1061380** | **ETH / ETH.MI/EUR** | **Eurotech SpA** | **1 / 1** | **No — Italian stock! Tradeable today!** |
| 4 | 316 | ETH.Fut / ETH.Fut/USD | ETH Future CME | 1 / 0 | No — CME futures |
| 2 | 100116, 100191 | GLDETH, SILVERETH / XAU/ETH, XAG/ETH | Gold/Ethereum, Silver/Ethereum | 0 / 0 | No — commodity quoted in ETH |

**Extra Ethereum-adjacent traps**: `ETC` (Ethereum Classic, InstrumentID 100007), `ENS` (Ethereum Name Service, 100089), `ETHFI` (Ether.fi). `ETHA` is doubly ambiguous: TypeID=10 InstrumentID 100125 is the ETH/VAULTA cross-pair, while TypeID=6 InstrumentID 12152 is the iShares Ethereum ETF.

**Lesson**: a substring filter on "ETH" is fundamentally untrustworthy. Use the **two-part pattern** + the **`Name LIKE 'ETH/%'`** form (ETH on the buy side of a pair) for clean Ethereum results.

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
| Ethereum ETF | ETHA.US | 6 | `TypeID=6 AND (DisplayName LIKE '%Ethereum%' OR Symbol IN ('ETHA.US','CETH.DE'))` |
| S&P 500 | SPX500 | 4 | `Symbol LIKE 'SPX500%' AND TypeID=4 AND IsFuture=0` |
| EUR/USD | EUR/USD | 1 | `Name = 'EUR/USD' AND TypeID=1` |
| Gold | XAU | 2 | `Symbol LIKE 'XAU%' AND TypeID=2 AND IsFuture=0` |

---

## Query Patterns

### Pattern 1 — Metric view + join after aggregation (recommended for AI/SQL agents)
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
  AND i.Tradeable = 1
GROUP BY m.`date`
ORDER BY m.`date` ASC;
```
**Use when:** querying metric views that expose `instrument_id` — aggregate first, join to dim after.

### Pattern 2 — Direct fact-table query (Tesla revenue example)
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

### Pattern 3 — Discovery query ("what instruments match?") — RUN THIS FIRST
```sql
SELECT InstrumentTypeID, InstrumentType, InstrumentID, Symbol, Name,
       InstrumentDisplayName, Tradable, Tradeable, IsFuture, Is_245_Instrument,
       PlatformSector, ProviderID
FROM main.etoro_kpi_prep.v_dim_instrument_enriched
WHERE LOWER(InstrumentDisplayName) LIKE LOWER('%{USER_INPUT}%')
   OR Symbol LIKE '{USER_INPUT}%'
   OR Name LIKE '{USER_INPUT}/%'
   OR Name LIKE '%/{USER_INPUT}'        -- catches sell-side matches (USD/JPY's JPY)
ORDER BY InstrumentTypeID, Symbol;
```
**Use when:** "what instruments match X?", validating a ticker before filtering, checking for collisions. **Run this FIRST whenever you author a new filter.**

### Pattern 4 — All active instruments for an asset class
```sql
SELECT Symbol, Name, InstrumentDisplayName, PlatformSector, ProviderID
FROM main.etoro_kpi_prep.v_dim_instrument_enriched
WHERE InstrumentTypeID = 5
  AND Tradeable = 1
  AND IsFuture = 0
ORDER BY Symbol;
```
**Use when:** "list all tradeable stocks", "active instruments in asset class".

### Pattern 5 — Broker → dealer bridge via `ProviderID` (instrument-level LP routing)
```sql
SELECT i.InstrumentTypeID, i.Symbol, i.InstrumentDisplayName, i.ProviderID, COUNT(*) AS instrument_count
FROM main.etoro_kpi_prep.v_dim_instrument_enriched i
WHERE i.Tradeable = 1
GROUP BY i.InstrumentTypeID, i.Symbol, i.InstrumentDisplayName, i.ProviderID
ORDER BY instrument_count DESC;
```
**Use when:** mapping instruments to their LP. `ProviderID` is the broker-side FK to `Trade.Provider`; the dealer-side sub-skills (`broker-and-lp-reconciliation`, `lp-contracts-and-cogs`) use this to trace settlement and hedge cost.

### Pattern 6 — Historical instrument state (rare)
```sql
SELECT DateID, InstrumentID, Symbol, InstrumentDisplayName, Tradable, OperationMode
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_snapshot
WHERE DateID = 20260301      -- the date you care about
  AND InstrumentID = 1111    -- Tesla
ORDER BY DateID;
```
**Use when:** "what did this instrument look like on date X?" — the snapshot table is the only retrospective source (current dim is truncate-and-reload). Slow; partition-aware filtering required.

---

## Key rules summary

1. **`Symbol LIKE '{TICKER}%'` for stocks/equities/indices/commodities/futures** — suffixes use dots (`TSLA.RTH`, `ETH.JAN26`).
2. **`Name LIKE '{TICKER}/%'` for crypto and forex** — clean `BUY/SELL` format.
3. **Always pair with `InstrumentTypeID = {EXPECTED}`**. No exceptions.
4. **Prefer `Tradeable = 1` (enriched) over `Tradable = 1` (production)** — they differ on 3,005 instruments, mostly because Tradeable excludes options. Reach for Tradable only when the question is specifically about the production-side flag.
5. **`IsFuture = 0` to exclude derivatives** by default (243 futures total — most TypeID=2 / 4 / 10).
6. **Validate before filtering** — always run Pattern 3 first when the user gives you a ticker.
7. **`Name LIKE 'ETH/%'` is safer than `Symbol LIKE 'ETH%'`** for crypto — the buy-side-of-a-pair pattern avoids most collisions.
8. **Google has two listings**: GOOG (Class C) and GOOGL (Class A). `LIKE 'GOOG%'` gets both — confirm intent.
9. **Use `SymbolFull` for exact-match lookups when ambiguity matters** (it's UNIQUE in production).
10. **The sentinel row (InstrumentID=0) is in base dim but NOT in the enriched view** — no `InstrumentID > 0` filter needed on `v_dim_instrument_enriched`.

## Cross-references

- Position state, ActionTypeID semantics → [`position-state-and-grain.md`](position-state-and-grain.md)
- Volume aggregates (by instrument, by asset class, real vs CFD, IsCopy / IsCopyFund flags) → [`trading-volumes.md`](trading-volumes.md)
- PnL by instrument, AUM by asset class → [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md)
- Pricing history (`Fact_CurrencyPriceWithSplit`) — joins instrument metadata to intraday price → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Revenue by instrument (commission, rollover, ticket fee by `InstrumentID`) → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- LP routing & hedge cost (the dealer-side use of `ProviderID`) → `broker-and-lp-reconciliation.md`, `lp-contracts-and-cogs.md`, `best-execution.md`

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: S = Synapse-first, L = Lake-first. `Tier`: 1a wiki, 1b UC comment, 2 review-needed, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| dim_instrument | S | 1a | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.{md,lineage.md,review-needed.md} | 47-col reference, lineage, SP_Dim_Instrument; DollarRatio + OperationMode definitions; AssetClass/Rankings vendor caveats |
| dim_instrument | S | 1a | knowledge/ProdSchemas/.../etoro/Wiki/Trade/Tables/Trade.Instrument.md | OLTP master: Internal.GetInstrumentID allocator, (BuyCurrencyID, SellCurrencyID) UNIQUE, History.Instrument temporal table |
| v_dim_instrument_enriched | L | 1a | knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.md | The BI_DB function the UC view materializes. **Found `IsTicketFeePercentInstrument` defined but NOT exposed in UC view.** Canonical definitions for IsSQF, Is_245_Instrument, Tradeable |
| v_dim_instrument_enriched | L | 1b | UC information_schema.columns (live) | 50 cols. Tradeable + IsSQF EMPTY comments. Is_245_Instrument MISATTRIBUTED. OperationMode count stale. |
| dim_instrument | S | 1b | UC information_schema.columns (live) | 47 cols, clean comments on base dim |
| bi_ouput_v_dim_instrumenttype | L | 4 | UC SELECT * (live) | 10 TypeIDs defined; only 6 populated (3=CFD, 7=Bonds, 8=TrustFunds, 9=Options are empty) |
| (any) | - | 4 | UC distincts (live) | TypeID counts (Stocks 12,849 / ETF 1,347 / Crypto 823 / Commodities 743 / Indices 319 / Currencies 228); Tradable vs Tradeable delta (3,005); Tesla 8 IDs; ETH 50-row collision; OperationMode 13,743/2,566 (contradicts UC); IsSQF 8 rows; Is_245 563 rows; Symbol dup 142 in Stocks |

## Provenance

This sub-skill (v2) was rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5 (classify-then-reach content sourcing). It deeply incorporates and **fully supersedes** the legacy DE workspace-root skill `instruments` (formerly at `/Workspace/.assistant/skills/instruments/SKILL.md`, v2 from 2026-05-07) — that legacy skill was tombstoned on 2026-05-28 / DA-72 (redirect-only); all instrument knowledge now lives here. Adds seven knowledge sources surfaced during the rebuild — the Dim_Instrument wiki + lineage + review-needed files, the BI_DB `Function_Instrument_Snapshot_Enriched` wiki, the OLTP `Trade.Instrument` wiki, live UC schema for both the base dim and the enriched view, and 7 live UC distinct-value verifications. **Key v2 additions over the legacy:** the `Tradable` vs `Tradeable` distinction (Warning #3, 3,005-row delta), UC comment health caveats on the enriched view (Warning #4), the `IsTicketFeePercentInstrument` content gap (Warning #5), `Symbol` non-uniqueness vs `SymbolFull` (Warning #7), `DollarRatio` (Warning #12), `IsMajor`/`IsMajorID` and corrected `Is_245_Instrument` semantics, the Broker-Dealer framing (`ProviderID` as broker→dealer bridge, Pattern 5), live catalogue refresh (+602 instruments since wiki snapshot), and extra Ethereum-adjacent traps (`ETC` / `ENS` / `ETHFI` / `ETHA`-cross-pair vs `ETHA.US` ETF).
