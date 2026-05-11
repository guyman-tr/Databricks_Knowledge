---
id: lp-contracts-and-cogs
name: "LP Contracts & Cost-of-Goods-Sold (Hedge-Side)"
description: "Liquidity-provider contracts, unit/lot conversion, per-provider order configuration, hedge-strategy boundaries, and the hedge-side cost-of-goods-sold (COGS) view of trading. Anchored on Trade.LiquidityProviderContracts (the instrument↔LP mapping with exchange ticker and validity windows), Trade.LiquidityProviders (LP instance registry — FXCM, FD, BMFN, etc.), Hedge.ProviderUnitConversionRatio (the central reference for translating eToro internal units to each LP's native order quantity system), and the Hedge.* configuration family for routing, boundaries, circuit breakers, and execution scaling. Cost-of-goods perspective — what eToro pays to hedge, not what eToro charges customers."
triggers:
  - LP contract
  - liquidity provider contract
  - Trade.LiquidityProviderContracts
  - Trade.LiquidityProviders
  - liquidity provider type
  - LP type
  - LP instance
  - ProviderUnitConversionRatio
  - unit conversion
  - lot size
  - ProviderInstrumentConfiguration
  - hedge strategy
  - boundaries strategy
  - circuit breaker
  - execution factor
  - hedge cost
  - cost of goods sold
  - COGS
  - hedge book
  - portfolio conversion
  - rolling futures
  - synthetic instrument
  - instrument boundary
  - HRL
  - hedge risk limit
required_tables:
  - main.general.bronze_etoro_trade_liquidityprovidercontracts
  - main.trading.bronze_etoro_trade_liquidityproviders
  - main.bi_db.bronze_etoro_trade_liquidityprovidertype
  - main.bi_db.bronze_etoro_hedge_providerunitconversionratio
  - main.dealing.bronze_etoro_hedge_instrumentboundaries
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# LP Contracts & Cost-of-Goods-Sold (Hedge-Side)

This sub-skill is about the **hedge-side cost of trading** — the contracts, configurations, and accounting that determine what eToro pays its liquidity providers to neutralize customer-trade exposure. It is the **mirror image** of `domain-revenue-and-fees`: revenue is what eToro charges customers; this is what eToro pays providers. The two are linked by `InstrumentID` and `Date`. A positive trading-revenue P&L equals (Customer-fees − LP-cost). When the user asks "are we making money on trading?", they're asking for this delta — but the COGS half lives here.

**This skill is NOT about revenue.** If a question is about commission, rollover, ticket fees, dividends-pass-through, conversion fees, share lending revenue, staking revenue, etc. — that's `domain-revenue-and-fees`. If a question is about what eToro paid Goldman/JPM/IG/Apex this quarter, that's here.

## When to Use

Load when the question is about:

- "Which LPs hold contracts for instrument X?", "what's the LP coverage for crypto?"
- "How are eToro's units converted to LP lots?" (each LP has a native order-quantity system)
- "LP contract validity windows", "when did instrument Y move from LP A to LP B?"
- "Per-provider order configuration" — market vs limit vs GTD, limit price offset
- "Hedge-strategy boundaries", "open / close thresholds for instrument Z"
- "Circuit-breaker thresholds for over/under-hedged exposure"
- "What's our cost of hedging crypto this quarter?" (LP-side ledger)
- "Rolling-futures hedge configuration"
- "Per-account-instrument execution config" (rounding precision, throttling)
- "Hedge-server-to-liquidity-account mapping"

Do **not** load for:

- Hedge-execution events / order audit → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD recon against LP custodian files → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Revenue / fees CHARGED to customers → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Pricing inputs → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Best-execution / NBBO analysis (uses LP data but at a different level) → [`best-execution.md`](best-execution.md)

## Scope

In scope: `Trade.LiquidityProviderContracts` (the instrument↔LP mapping with exchange-specific tickers and validity windows), `Trade.LiquidityProviders` (LP instance registry — FXCM Real, FD Production, BMFN Demo, etc.), `Trade.LiquidityProviderType` (LP type configurations — eToro internal, FXCM, BMFN, FD), `Trade.GetLiquidityProviders` (joined view of instances + types), `History.LiquidityProviderContracts` (temporal history of the mapping), `History.LiquidityProviders` / `History.LiquidityProviderType` (temporal history of registries), `History.TradonomiToLiquidityProviderContracts` (Tradonomi CFD → LP contract mapping history), `Hedge.ProviderUnitConversionRatio` (the central per-provider, per-instrument unit/lot conversion reference), `Hedge.ProviderInstrumentConfiguration` (per-provider order-submission config — market vs limit vs GTD, limit price offset, validity window; **currently empty**), `Hedge.ExecutionFactorConfiguration` (per-strategy, per-instrument execution-scaling multiplier — partial or amplified hedging), `Hedge.PortfolioConversionConfigurations` (synthetic-instrument → futures contract mapping with weighting multiplier — enables rolling futures hedge), `Hedge.InstrumentBoundaries` (CBH "Boundaries" strategy: OpenThresholdUSD, CloseThresholdPercentage, HedgeRiskLimitUSD per HedgeServer × Instrument; 111K rows over 32 servers × 10,498 instruments), `Hedge.BoundariesConfiguration` (per-strategy boundary tier), `Hedge.ExposureCircuitBreakerThresholds` (per-instrument, direction-aware over/under-hedged alert + trigger), `Hedge.InstrumentConfiguration` (per-instrument order-size and circuit-breaker config), `Hedge.AccountInstrumentConfiguration` (per-account rounding/throttling), `Hedge.SupportedInstrumentsAccount` (per-account instrument allowlist), `Hedge.HedgeServerToLiquidityAccount` (hedge-server ↔ liquidity-account mapping), `Hedge.InstrumentGroups` + `Hedge.InstrumentGroupsMapping` (instrument-group routing), `Trade.HedgeServer` (hedge-server registry), the cost-of-goods-sold framing.
Out of scope: hedge-execution events (`dealing-investigation-and-execution.md`), EOD LP recon (`broker-and-lp-reconciliation.md`), revenue CHARGED to customers (`../domain-revenue-and-fees/SKILL.md`), customer-side position state (`position-state-and-grain.md`), pricing inputs (`pricing-and-currency-history.md`), best-execution (`best-execution.md`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — This skill is COST OF GOODS SOLD, not revenue. Do NOT confuse with `domain-revenue-and-fees`.** Customer-charged fees and LP-paid hedge costs are different sides of the trading P&L. The trading-platform NET P&L = Customer fees (revenue side) − LP costs (this side). Both halves must align by `InstrumentID × Date` to compute trading margin.
2. **Tier 1 — `Trade.LiquidityProviderContracts` has validity windows.** A single instrument can be hedged via different LPs at different points in time. The temporal history table `History.LiquidityProviderContracts` records every superseded version — use it for point-in-time questions ("which LP was hedging TSLA on 2024-06-01?"). The current table only tells you who's hedging it now.
3. **Tier 1 — `Hedge.ProviderUnitConversionRatio` is the central reference for unit translation.** eToro internally denominates orders in its own unit system; each LP has its own native lot size (Saxo: shares; Marex: lots; Apex: shares; etc.). The conversion ratio in this table is the **only** authoritative source for translating between them. Hedge-side analyses that don't go through this ratio silently miscompare quantities across providers.
4. **Tier 2 — Several hedge config tables are EMPTY (designed, not yet active).** `Hedge.ProviderInstrumentConfiguration` and `Hedge.HedgeServerInstrumentConfiguration` are designed but currently empty per their authored comments. Joining or filtering against them returns zero rows — don't interpret that as "no overrides configured", interpret as "feature inactive".
5. **Tier 2 — Rolling futures hedge uses `Hedge.PortfolioConversionConfigurations`.** When a futures contract expires, the operations team sets the expiring contract's `Multiplier = 0` and the next contract's `Multiplier = 1` — that's how the synthetic non-expiry instrument the customer sees gets seamlessly rolled to the new underlying. Querying for futures contracts WITHOUT checking the multiplier may return the expired contract as if it were active.
6. **Tier 3 — `Hedge.InstrumentBoundaries` is the CBH "Boundaries" strategy config and has audit-trigger DML.** Changes are recorded via ASM-generated DML triggers (visible upstream of the bronze ingest). 111K rows × 32 servers × 10,498 instruments — every (server, instrument) tuple has its own OpenThresholdUSD, CloseThresholdPercentage, and HedgeRiskLimitUSD (HRL). When investigating "why didn't this hedge fire?", the OpenThresholdUSD is the first thing to check.
7. **Tier 3 — `Hedge.ExposureCircuitBreakerThresholds` is direction-aware.** Over-hedged and under-hedged states get **separate** alert + trigger thresholds. Don't assume symmetric — they're set differently for risk-asymmetric instruments.

## Tables — the LP-and-hedge configuration map

### Contract registry (instrument ↔ LP mapping)

| Table | Use For |
|---|---|
| `main.general.bronze_etoro_trade_liquidityprovidercontracts` | Per-instrument current mapping to LP type with exchange ticker and validity window. |
| `main.bi_db.bronze_etoro_history_liquidityprovidercontracts` | **Temporal history** of the above — point-in-time which LP hedged which instrument. |
| `main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts` | Tradonomi CFD → LP contract mapping history. |

### LP instance + type registry

| Table | Use For |
|---|---|
| `main.trading.bronze_etoro_trade_liquidityproviders` | LP instance registry (FXCM Real, FD Production, BMFN Demo). Provider type + instance-specific settings. |
| `main.bi_db.bronze_etoro_trade_liquidityprovidertype` | LP type definitions (eToro internal, FXCM, BMFN, FD) with pluggable price + execution provider configs. |
| `main.bi_db.bronze_etoro_trade_getliquidityproviders` | Joined view of instances + types with provider names, settings XML, configs. |
| `main.trading.bronze_etoro_history_liquidityproviders` | Temporal history of the instance registry. |
| `main.trading.bronze_etoro_history_liquidityprovidertype` | Temporal history of the type registry. |

### Unit conversion (central translation reference)

| Table | Use For |
|---|---|
| `main.bi_db.bronze_etoro_hedge_providerunitconversionratio` | Per-provider, per-instrument unit/lot conversion. Translates eToro internal units to LP native quantity. **Authoritative** for any quantity comparison across providers. |

### Order-routing config (per-provider, per-instrument)

| Table | Use For |
|---|---|
| `main.dealing.bronze_etoro_hedge_providerinstrumentconfiguration` *(currently empty)* | Per-provider, per-instrument order config: market vs limit vs GTD, limit price offset percentage, GTD validity window. |

### Strategy boundaries + circuit breakers

| Table | Use For |
|---|---|
| `main.dealing.bronze_etoro_hedge_instrumentboundaries` | CBH "Boundaries" strategy: per `(HedgeServer, Instrument)`: `OpenThresholdUSD`, `CloseThresholdPercentage`, `HedgeRiskLimitUSD` (HRL). 111K rows. |
| `main.dealing.bronze_etoro_hedge_boundariesconfiguration` | Per-strategy, per-instrument boundary configuration — band-based hedge rebalancing. |
| `main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds` | Per-instrument, direction-aware over-/under-hedged alert + trigger thresholds. |
| `main.bi_db.bronze_etoro_hedge_instrumentconfiguration` | Per-instrument order-size limits, circuit breakers, HBC deal-size guards. |
| `main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration` | Per-account, per-instrument limit-order price-rounding precision + execution unit throttling. |
| `main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount` | Per-account instrument allowlist (multi-account hedge servers). |
| `main.dealing.bronze_etoro_hedge_executionfactorconfiguration` | Per-strategy, per-instrument execution-scaling multiplier (partial / amplified hedging). |
| `main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations` | Synthetic-instrument → real-futures-contract mapping with weighting multiplier (rolling futures). |

### Routing + grouping

| Table | Use For |
|---|---|
| `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | Hedge-server ↔ liquidity-account mapping. Optionally a separate account for alternative rates. |
| `main.bi_db.bronze_etoro_history_hedgeservertoliquidityaccount` | Temporal history of the above. |
| `main.bi_db.bronze_etoro_hedge_instrumentgroups` | Named instrument groups (apply routing rules collectively). |
| `main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping` | Junction: instrument ↔ group. |
| `main.general.bronze_etoro_trade_hedgeserver` | Hedge-server registry. |

---

## Query Patterns

### Pattern 1 — Which LP hedges instrument X currently?
```sql
SELECT lpc.InstrumentID, lp.LiquidityProviderID, lpt.Name AS lp_type, lp.Name AS lp_instance,
       lpc.ExchangeTicker, lpc.ValidFrom, lpc.ValidTo
FROM main.general.bronze_etoro_trade_liquidityprovidercontracts lpc
JOIN main.trading.bronze_etoro_trade_liquidityproviders lp
  ON lpc.LiquidityProviderID = lp.LiquidityProviderID
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lp.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
WHERE lpc.InstrumentID = 1111
  AND CURRENT_DATE BETWEEN lpc.ValidFrom AND COALESCE(lpc.ValidTo, '9999-12-31');
```
**Use when:** "who hedges Tesla?", "current LP coverage for instrument X"

### Pattern 2 — LP coverage by asset class
```sql
SELECT lpt.Name AS lp_type,
       i.InstrumentTypeID,
       it.InstrumentType,
       COUNT(DISTINCT lpc.InstrumentID) AS instruments_covered
FROM main.general.bronze_etoro_trade_liquidityprovidercontracts lpc
JOIN main.trading.bronze_etoro_trade_liquidityproviders lp
  ON lpc.LiquidityProviderID = lp.LiquidityProviderID
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lp.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
JOIN main.etoro_kpi_prep.v_dim_instrument_enriched i
  ON lpc.InstrumentID = i.InstrumentID
JOIN main.bi_output.bi_ouput_v_dim_instrumenttype it
  ON i.InstrumentTypeID = it.InstrumentTypeID
WHERE CURRENT_DATE BETWEEN lpc.ValidFrom AND COALESCE(lpc.ValidTo, '9999-12-31')
GROUP BY lpt.Name, i.InstrumentTypeID, it.InstrumentType
ORDER BY lp_type, instruments_covered DESC;
```
**Use when:** "which LPs hedge crypto?", "stocks coverage by LP"

### Pattern 3 — When did the LP for instrument X change?
```sql
SELECT InstrumentID, LiquidityProviderID, ValidFrom, ValidTo
FROM main.bi_db.bronze_etoro_history_liquidityprovidercontracts
WHERE InstrumentID = 1111
ORDER BY ValidFrom;
```
**Use when:** "who hedged Tesla on 2024-06-01?", point-in-time LP coverage

### Pattern 4 — Unit conversion lookup for cross-provider quantity comparison
```sql
SELECT LiquidityProviderID, InstrumentID,
       ConversionRatio, LotSize, MinLotSize, MaxLotSize
FROM main.bi_db.bronze_etoro_hedge_providerunitconversionratio
WHERE InstrumentID = 1111;
```
**Use when:** "translate eToro units to Apex shares", "what's the lot size at Saxo for instrument X?"

### Pattern 5 — Boundaries config — "why didn't this hedge fire?"
```sql
SELECT HedgeServer, InstrumentID,
       OpenThresholdUSD, CloseThresholdPercentage, HedgeRiskLimitUSD
FROM main.dealing.bronze_etoro_hedge_instrumentboundaries
WHERE HedgeServer = 'HSrv01'  -- replace
  AND InstrumentID = 1111;
```
**Use when:** "why didn't the hedge fire on this position?", investigation of hedge-trigger thresholds

### Pattern 6 — Circuit-breaker thresholds (direction-aware)
```sql
SELECT InstrumentID, Direction,
       AlertThresholdUSD, TriggerThresholdUSD
FROM main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
WHERE InstrumentID = 1111;
```
**Use when:** "what's the circuit-breaker for TSLA?", risk-management config audit

### Pattern 7 — Rolling-futures contract mapping (active multipliers only)
```sql
SELECT SyntheticInstrumentID, UnderlyingContractID, Multiplier, EffectiveFrom
FROM main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations
WHERE Multiplier > 0
ORDER BY SyntheticInstrumentID, EffectiveFrom DESC;
```
**Use when:** "which real futures contract is the active underlying for synthetic X?", futures-roll audit

---

## Cost-of-goods-sold framing

The trading-platform P&L computation:

```
Trading-platform NET P&L
  = Revenue (charged to customers)         [domain-revenue-and-fees]
  − LP hedge costs                         [this sub-skill]
  − Operational costs                      [out of scope]
```

The revenue side is well-documented in `domain-revenue-and-fees` (all 15+ revenue streams with `IncludedInTotalRevenue = 1`). The LP-cost side is **NOT a single fact table** today — it's reconstructed from a mix of:

- Hedge.ExecutionLog (LP fill rate × LP rate × spread) — see [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- LP-recon trade-activity tables (`ApexRecon_TradeActivity`, etc.) — see [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- LP contracts and conversion ratios (this skill)

A unified hedge-cost fact is not currently published in DDR. When the dealing-analyst skills land, they may publish such a fact — at which point this sub-skill will incorporate it. **Until then, treat hedge-cost questions as research workflows joining the three sources above.**

## Cross-references

- Hedge-execution events (the LP-side audit log) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP recon (custodian-file matching, downstream of contracts) → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Revenue side of trading P&L → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Pricing inputs (LP-confirmed vs eToro-spread-adjusted) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Instrument metadata → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Customer-side position lifecycle → [`position-state-and-grain.md`](position-state-and-grain.md)

## Provenance

Authored from Unity Catalog table-level comments harvested 2026-05-11 on the LP-contract family (`Trade.LiquidityProviderContracts` + history + Tradonomi-mapping history), the LP-registry family (`Trade.LiquidityProviders`, `Trade.LiquidityProviderType`, `Trade.GetLiquidityProviders` + histories), and the Hedge.* configuration family (`ProviderUnitConversionRatio`, `ProviderInstrumentConfiguration`, `ExecutionFactorConfiguration`, `PortfolioConversionConfigurations`, `InstrumentBoundaries`, `BoundariesConfiguration`, `ExposureCircuitBreakerThresholds`, `InstrumentConfiguration`, `AccountInstrumentConfiguration`, `SupportedInstrumentsAccount`, `HedgeServerToLiquidityAccount`, `InstrumentGroups` + mapping). Source-of-truth wikis under `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/`, `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Hedge/Tables/`, and `.../History/Tables/`. A unified hedge-cost fact may be published by the dealing-analyst skill set; this skill will incorporate it when delivered.
