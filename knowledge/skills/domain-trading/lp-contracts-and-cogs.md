---
name: domain-trading
description: "Dealer-side hedge plumbing — Liquidity Provider (LP) registry hierarchy (Type → Instance → Account → HedgeServer), per-(provider, instrument) unit/lot conversion ratios, CBH-strategy `Hedge.InstrumentBoundaries` thresholds (276K rows × 39 servers × 13.7K instruments — Open/Close/HRL), direction-aware `ExposureCircuitBreakerThresholds` (12.6K rows), per-(server, instrument) and per-(provider, instrument) and per-(account, instrument) override layers, rolling-futures synthetic-to-contract mapping (68 rows × 45 synthetics × 53 contracts), multi-account routing allowlist (95.5K rows). LP catalog: 145 distinct provider types and 187 instances spanning forex CFD (FXCM, FD, BMFN, Currenex, GFT, Saxo), equities (FD Stocks, IB, GS, JPM, Marex-OMS, IEX, ICE), OMS aggregators (OMS, MarketMakerHBC, JaneStreet, Wintermute, Citadel, Jump, Virtu), crypto (BitStamp, Kraken, Coinbase, B2C2, Cumberland, Genesis, Galaxy, Talos×), staking, and Bloomberg/QuantHouse/Vision/ICE pricing-only sources. **This is the COGS / hedge-cost-of-trading view**, the mirror image of `domain-revenue-and-fees`."
triggers:
  - LP contract
  - liquidity provider contract
  - Trade.LiquidityProviderContracts
  - Trade.LiquidityProviders
  - Trade.LiquidityProviderType
  - Trade.LiquidityAccounts
  - liquidity account
  - LiquidityAccount
  - LP type
  - LP instance
  - 145 provider types
  - ProviderUnitConversionRatio
  - unit conversion
  - lot size
  - ProviderInstrumentConfiguration
  - HedgeServerInstrumentConfiguration
  - AccountInstrumentConfiguration
  - SupportedInstrumentsAccount
  - hedge server
  - hedge strategy
  - CBH boundaries
  - boundaries strategy
  - InstrumentBoundaries
  - OpenThresholdUSD
  - HedgeRiskLimitUSD
  - HRL
  - CloseThresholdPercentage
  - circuit breaker
  - circuit breaker threshold
  - ExposureCircuitBreakerThresholds
  - over-hedged
  - under-hedged
  - execution factor
  - ExecutionFactor
  - rolling futures
  - non-expiry instrument
  - synthetic instrument
  - PortfolioConversionConfigurations
  - InstrumentIDToHedge
  - hedge cost
  - cost of goods sold
  - COGS
  - cost of hedging
  - hedge book
  - LP-side ledger
  - LP routing
  - HedgeServerToLiquidityAccount
  - AltRatesLiquidityAccountID
  - HBC threshold
  - HBCDealSizeThresholdAlertInEToroUnits
  - HBCMaxDealSizeThresholdRejectInEToroUnits
  - MinOrderSizeForExecutionInEToroUnits
  - ManualMaxDealSizeInEToroUnits
  - IM routing
  - MinAmountForIM
  - instrument group
  - InstrumentGroupsMapping
required_tables:
  - main.general.bronze_etoro_trade_liquidityprovidercontracts
  - main.trading.bronze_etoro_trade_liquidityproviders
  - main.bi_db.bronze_etoro_trade_liquidityprovidertype
  - main.trading.bronze_etoro_trade_liquidityaccounts
  - main.bi_db.bronze_etoro_hedge_providerunitconversionratio
  - main.dealing.bronze_etoro_hedge_instrumentboundaries
  - main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
  - main.bi_db.bronze_etoro_hedge_instrumentconfiguration
  - main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount
  - main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount
  - main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations
  - main.dealing.bronze_etoro_hedge_executionfactorconfiguration
  - main.trading.bronze_etoro_hedge_providerinstrumentconfiguration
  - main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration
  - main.trading.bronze_etoro_hedge_boundariesconfiguration
  - main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration
  - main.general.bronze_etoro_trade_hedgeserver
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# LP Contracts & Cost-of-Goods-Sold (Dealer-Side)

**Dealer-side. COGS view.** This is the hedge-pipeline configuration layer — instrument↔LP routing, unit/lot translation, hedge-strategy thresholds, circuit breakers, futures rolling. Where `domain-revenue-and-fees` is "what eToro charges the customer," this skill is "what eToro pays the LP to neutralize that customer's exposure." Trading P&L margin only makes sense once both halves are joined by `InstrumentID × Date`.

## When to Use

Load when the question is about:

- "Which LP type currently hedges instrument X?" / "What's the LP coverage for crypto?"
- "Which actual liquidity *account* / hedge server routes this instrument?" (multi-layer routing)
- "How are eToro internal units translated to LP native order quantity / lot size?"
- "LP contract validity windows" / "When did instrument Y move from LP A to LP B?"
- "Per-(server, instrument) Open / Close / HRL boundary thresholds" — CBH "Boundaries" strategy
- "Per-instrument circuit-breaker thresholds, over- vs under-hedged direction"
- "Rolling-futures contract mapping" — Multiplier=0/1 for expiring vs front-month
- "Per-(account, instrument) limit-order rounding precision" / "Min IM-routing amount"
- "HBC deal-size alert / reject thresholds per instrument" / "Manual max deal size"
- "Multi-account hedge servers — which account handles which instrument?"
- "What's the cost-of-hedging structure for crypto / forex / equities?" (LP-side ledger)
- "Per-server execution scaling — is this instrument partially hedged?"

Do **not** load for:

- Hedge-execution events / order audit / LP fill rate → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD recon against LP custodian files → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Revenue / fees CHARGED to customers → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Pricing inputs / quote feed → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Best-execution / TCA / NBBO analysis → [`best-execution.md`](best-execution.md)

## Scope

In scope: the **LP registry hierarchy** (`Trade.LiquidityProviderType` 145 rows, `Trade.LiquidityProviders` 187 instances, `Trade.LiquidityAccounts` 391 accounts, `Trade.HedgeServer`), the **instrument↔LP contract** (`Trade.LiquidityProviderContracts` 200K rows + history + `Trade.TradonomiToLiquidityProviderContracts`), **unit conversion** (`Hedge.ProviderUnitConversionRatio` 5.8K rows × 27 LP types × 1,784 instruments), **CBH boundaries** (`Hedge.InstrumentBoundaries` 276K rows × 39 servers × 13.7K instruments; `Hedge.BoundariesConfiguration` 124K rows for band-rebalance strategy), **circuit breakers** (`Hedge.ExposureCircuitBreakerThresholds` 12.6K rows direction-aware + per-instrument single in `Hedge.InstrumentConfiguration`), **per-instrument hedge config** (`Hedge.InstrumentConfiguration` 16.2K rows — HBC thresholds, min order, manual max), **override layers** (`Hedge.HedgeServerInstrumentConfiguration` 5K rows, `Hedge.ProviderInstrumentConfiguration` 1.3K rows, `Hedge.AccountInstrumentConfiguration` 153K rows × 39 accounts), **execution scaling** (`Hedge.ExecutionFactorConfiguration` 2.9K rows partial/amplified hedge), **rolling futures** (`Hedge.PortfolioConversionConfigurations` 68 rows × 45 synthetics × 53 contracts), **routing infrastructure** (`Hedge.HedgeServerToLiquidityAccount` 78 rows × 43 servers, `Hedge.SupportedInstrumentsAccount` 95.5K rows multi-account allowlist, `Hedge.InstrumentGroups` + mapping), **regulatory mapping** (`silver_sharepoint_reg_liquidityaccountid_to_lei` for LEI), the **COGS framing** (hedge-cost reconstruction since no unified DDR fact exists).
Out of scope: hedge-execution events ([`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)), EOD LP recon ([`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)), revenue ([`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)), customer positions ([`position-state-and-grain.md`](position-state-and-grain.md)), pricing inputs ([`pricing-and-currency-history.md`](pricing-and-currency-history.md)), best-execution ([`best-execution.md`](best-execution.md)).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — This skill is COST OF GOODS SOLD, not revenue.** Trading-platform NET P&L = (customer fees from `domain-revenue-and-fees`) − (LP hedge costs reconstructed here) − operational costs. Align both halves on `InstrumentID × Date`. Never mix the two ledgers.
2. **Tier 1 — `LiquidityProviderID` column name lies in 3 places.** It actually stores a **LiquidityProviderTypeID** (FK target = `Trade.LiquidityProviderType.LiquidityProviderTypeID`) in: `Trade.LiquidityProviderContracts.LiquidityProviderID`, `Hedge.ProviderUnitConversionRatio.LiquidityProviderID`, **and** in places where the wiki notes "despite the name, stores provider TYPE not provider instance." A true *provider instance* (FXCM Real, FD Production STP) lives in `Trade.LiquidityProviders.LiquidityProviderID`. JOINing instance-id to a column that holds type-id will silently mis-resolve everything.
3. **Tier 1 — Wiki snapshots are stale; live UC counts are 2–1000× larger.** The `Hedge/Tables/*.md` wikis under `ProdSchemas/DB_Schema/etoro/Wiki/` claim several config tables are "empty / designed but not active". Live UC contradicts every one of them: `BoundariesConfiguration` (wiki: 0 → live: 124,918), `ExposureCircuitBreakerThresholds` (0 → 12,618), `ExecutionFactorConfiguration` (0 → 2,895), `ProviderInstrumentConfiguration` (0 → 1,338), `HedgeServerInstrumentConfiguration` (0 → 5,048), `AccountInstrumentConfiguration` (147 → 153,364), `InstrumentBoundaries` (111K → 276,422), `SupportedInstrumentsAccount` (10K → 95,542), `PortfolioConversionConfigurations` (2 → 68). **Always verify against live UC before answering** — these features are now operational.
4. **Tier 1 — Active LP routing has consolidated dramatically.** Only **2 LP types currently have active contracts** (i.e. `ToDate > current_date()`) in `Trade.LiquidityProviderContracts`: **Virtu (LiquidityProviderTypeID=83, 2,456 active contracts)** and **OMS (10002, 2,296 active contracts)**. Most of the 200K rows in the contract table are historical. Filter by `ToDate >= current_date()` (or use the `History.LiquidityProviderContracts` temporal shadow table for point-in-time questions) — otherwise you'll over-count by ~40x.
5. **Tier 1 — ZBFX (LiquidityProviderTypeID=69) is gone from unit conversion.** The wiki dated 2026-03-19 said ZBFX dominated `ProviderUnitConversionRatio` with 5,213 rows. Live data has **0 rows for LP 69**. The active providers in `ProviderUnitConversionRatio` (27 LP types, 5,819 rows) are now: Marex-OMS (84, 766 rows), ED&F Man (99, 567), Virtu (83, 493), OMS (10002, 490), JP Morgan (44, 469), EMSX JPM (80, 469), SAXO 4.4 (116, 467), IB (11, 353), Saxo (23, 336), IG Execution (12, 321), GSEMSX (81, 225), Talos Coinbase (128, 164), MarketMakerHBC (1250, 164), MarketMaker Direct (125, 164), Talos Hidden Road (333, 163). The forex-era providers (FXCM 2 rows, FD 3 rows, BMFN 0 rows) are vestigial.
6. **Tier 1 — `Hedge.ProviderUnitConversionRatio` is the only authoritative unit-translation source.** Cross-LP quantity comparisons MUST go through it. Formula: `providerQty = eToroUnits × UnitConversionRatio`. Ratios range 1e-6 to 250,000. LotSize ranges 1e-6 to 3,000. Reader procedure `Hedge.GetProviderUnitConversion` defaults missing ratio→1.0 and missing lot→1000 (Forex) or 1 (other) via ISNULL fallback — so an apparent ratio=1 may actually be a default, not a real configured value.
7. **Tier 2 — `Hedge.InstrumentBoundaries` is the live CBH "Boundaries" strategy config.** 276,422 rows × 39 hedge servers × 13,732 instruments. Per-(server, instrument): `OpenThresholdUSD` (range $10 to $5M — note the $10 floor: even tiny exposures trigger), `CloseThresholdPercentage` (typical 50%), `HedgeRiskLimitUSD = HRL` (range $0 to $2.5M; HRL=0 means hedge entire excess above the open threshold, NO cap). When a hedge "didn't fire" on a position, OpenThresholdUSD is the first thing to check. All changes audited column-by-column to `History.AuditHistory` via ASM-generated DML triggers — do NOT manually drop/alter those triggers.
8. **Tier 2 — `Hedge.InstrumentConfiguration` has 4 distinct safety/sizing knobs per instrument**, not one. (a) `MinOrderSizeForExecutionInEToroUnits` — floor: smaller orders dropped. (b) `HBCDealSizeThresholdAlertInEToroUnits` — soft warn. (c) `HBCMaxDealSizeThresholdRejectInEToroUnits` — hard reject. (d) `ManualMaxDealSizeInEToroUnits` — cap on manual-path orders. Plus `CircuitBreakerLimit` / `CircuitBreakerWarningLimit` (per-instrument single, undirected; NULL = not configured; 0 = explicitly disabled; non-zero = active). Columns `SpreadReturnFactor`, `RestrictManualActions`, `LotSizeForView` are present in DDL but uniform across all rows — reserved/unused.
9. **Tier 2 — Two different circuit-breaker tables, two different semantics.** `Hedge.InstrumentConfiguration.CircuitBreakerLimit` is a single undirected per-instrument limit. `Hedge.ExposureCircuitBreakerThresholds` (12.6K rows) is **direction-aware** — separate `CircuitBreakerAlertThresholdUSD` and `CircuitBreakerTriggerThresholdUSD` per `(InstrumentID, IsOverHedged)`. Don't assume symmetric thresholds for over-hedge vs under-hedge — that's the entire point of the table.
10. **Tier 2 — Rolling-futures hedge uses `Multiplier`, not visual contract names.** `Hedge.PortfolioConversionConfigurations` schema is `(InstrumentID, InstrumentIDToHedge, Multiplier)`. 68 live rows across 45 synthetic non-expiry instruments × 53 underlying contracts. To find the *currently active* underlying for a synthetic, filter `Multiplier > 0` — querying expired contracts (`Multiplier = 0`) is the rolled-out leg, not the live hedge.
11. **Tier 2 — Multi-account routing is a conditional code path.** `Hedge.GetHedgeSupportedInstruments` first counts non-pricing accounts per server. **If count=1** → returns all `Trade.LiquidityProviderContracts` instruments for that LP type (the allowlist table is bypassed). **If count>1** → JOINs `Hedge.SupportedInstrumentsAccount` to restrict per account. The 95K rows in `SupportedInstrumentsAccount` only matter for multi-account servers (OMS-IM3/IM4, ZBFX legacy carry-over). For single-account servers, ignore this table.
12. **Tier 2 — Account-type 4 ("Pricing") is excluded everywhere.** Procedures `GetHSUnitConversionRatio`, `GetHedgeSupportedInstruments`, `GetAccountSupportedInstruments` all filter `AccountTypeID != 4` — pricing accounts (OMS IM Pricing) provide quotes only, never execute. Don't include them in "active routing" counts.
13. **Tier 3 — The LP hierarchy is 4 layers deep, each with its own naming.** `LiquidityProviderType` (145 types — abstract source: FXCM, FD, BMFN, OMS, Virtu, …) → `LiquidityProviders` (187 instances — concrete deployments: "FXCM Real", "FD RealStream Production REAL 208.100.16.161") → `LiquidityAccounts` (391 accounts — login credentials per instance per env) → `HedgeServerToLiquidityAccount` (78 rows — assigns accounts to one of 43 hedge servers). An "LP" question is ambiguous; always clarify which layer.
14. **Tier 3 — `AltRatesLiquidityAccountID` is the secondary pricing-only account on a hedge server.** NULL in all 78 live rows currently (the architecture supports it but it's not deployed). HedgeServerID=8 (OMS) has 2 accounts (IM3 IM Pricing + IM4 IM Hedging) — that's done via TWO rows in `HedgeServerToLiquidityAccount`, NOT via AltRates. Easy to confuse.
15. **Tier 3 — No `BI_DB_DDR_*` hedge-cost fact exists, but a canonical HC ledger DOES exist outside DDR.** The dealing-team-produced `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1` (1.65M rows, 9 asset classes, refreshed daily from the `eToro/HedgeCostAgent` pipeline) IS the canonical realised-HC ledger. Use it for hedge-cost rollups, ICC HC, per-asset-class HC trends, and "net trading revenue" questions (join to revenue side on `(AssetClass, date)`). See [`hedge-cost-recon.md`](hedge-cost-recon.md). The reconstruction-via-ExecutionLog + recon-files workflow described historically here is now a **deep-methodology forensic path**, not an analytical default — only used when investigating WHY the HC ledger has a specific value, not WHAT it is.

## Tables — the LP-and-hedge configuration map

### LP registry — the 4-layer hierarchy

| Layer | Table | Live count | Use For |
|---|---|---|---|
| 1. Provider TYPE (abstract category, .NET assembly config) | `main.bi_db.bronze_etoro_trade_liquidityprovidertype` | 145 types | Resolving `LiquidityProviderID` in contracts/unit-conv to a human name (FXCM, OMS, Virtu, JPM, B2C2, Talos Kraken, …). Includes price/execution class definitions per type. |
| 2. Provider INSTANCE (concrete deployment) | `main.trading.bronze_etoro_trade_liquidityproviders` | 187 instances | "FXCM Real" vs "FXCM Demo" vs "FD RealStream Production REAL 208.100.16.161". One type can have many instances (real/demo/IP-specific). |
| 3. LIQUIDITY ACCOUNT (login credentials) | `main.trading.bronze_etoro_trade_liquidityaccounts` | 391 accounts × 154 distinct provider IDs | Actual auth/account endpoint at each LP. AccountTypeID=4 = pricing-only (excluded from routing). |
| 4. HEDGE SERVER assignment | `main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount` | 78 rows × 43 servers | One account → one server (PK on `LiquidityAccountID`). One server may have multiple accounts (e.g., OMS server has IM3 Pricing + IM4 Hedging). `AltRatesLiquidityAccountID` is NULL in all 78 — designed but unused. |

### Instrument↔LP contract (the routing mapping)

| Table | Live count | Use For |
|---|---|---|
| `main.general.bronze_etoro_trade_liquidityprovidercontracts` | 200,350 rows × 15,084 instruments × 85 LP type IDs | The instrument↔LP-type mapping with ticker, exchange, validity window. **Filter `ToDate >= current_date()` for active** — only ~4,752 active across Virtu (83) + OMS (10002). |
| `main.bi_db.bronze_etoro_history_liquidityprovidercontracts` | temporal shadow | Point-in-time: "Which LP type was hedging Tesla on 2024-06-01?" |
| `main.general.bronze_etoro_history_tradonomitoliquidityprovidercontracts` | temporal shadow | Tradonomi CFD → LP-contract-id mapping history. |

### Unit conversion (the central translation reference)

| Table | Live count | Use For |
|---|---|---|
| `main.bi_db.bronze_etoro_hedge_providerunitconversionratio` | 5,819 rows × 27 LP types × 1,784 instruments | Per-(LP-type, instrument) `UnitConversionRatio` (eToroUnits → provider native qty) + `LotSize` (rounding boundary). **Only authoritative source for cross-LP quantity comparison.** Top providers by row count: Marex-OMS (766), ED&F Man (567), Virtu (493), OMS (490), JPM (469), EMSX-JPM (469), SAXO 4.4 (467). |

### Per-instrument hedge config (single-row-per-instrument)

| Table | Live count | Use For |
|---|---|---|
| `main.bi_db.bronze_etoro_hedge_instrumentconfiguration` | 16,242 rows (one per instrument) | HBC alert+reject thresholds, `MinOrderSizeForExecution`, `ManualMaxDealSize`, `CircuitBreakerLimit` + `CircuitBreakerWarningLimit` (NULL/0/non-zero). |

### Strategy boundaries + circuit breakers

| Table | Live count | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_instrumentboundaries` | 276,422 rows × 39 servers × 13,732 instruments | CBH "Boundaries" strategy per `(HedgeServer, Instrument)`. `OpenThresholdUSD` (min $10), `CloseThresholdPercentage` (typical 50), `HedgeRiskLimitUSD = HRL` (max $2.5M; 0 = no cap). |
| `main.trading.bronze_etoro_hedge_boundariesconfiguration` | 124,918 rows | Band-based rebalance strategy: `LowerThresholdUSD`/`UpperThresholdUSD` (dead-band) + `LowerBoundaryDesiredExposureUSD`/`UpperBoundaryDesiredExposureUSD` (rebalance targets), per `(StrategyID, InstrumentID)`. **Live, not empty as old wiki said.** |
| `main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds` | 12,618 rows | Direction-aware CB per `(InstrumentID, IsOverHedged)`: separate Alert + Trigger USD thresholds. |

### Override layers (server / provider / account dimension × instrument)

| Table | Live count | Use For |
|---|---|---|
| `main.trading.bronze_etoro_hedge_hedgeserverinstrumentconfiguration` | 5,048 rows | Per-(server, instrument) overrides: `AllowHBCFailover`, `PriceSource`, `AllowClosePositionMaxDealSizeCheck`, `MinAmountForIM`. |
| `main.trading.bronze_etoro_hedge_providerinstrumentconfiguration` | 1,338 rows | Per-(LP-type, instrument): `OrderType` (market/limit/GTD), `LimitOffsetPercentage`, `GTDTimeSpanInSeconds`. |
| `main.bi_db.bronze_etoro_hedge_accountinstrumentconfiguration` | 153,364 rows × 39 accounts × 10,631 instruments | Per-(account, instrument): `LimitRoundPrecision` (active; values 1/2/4/-1) + designed-but-NULL throttling cols (`MaxExecutionUnitsThreshold`, etc.). |

### Execution scaling + rolling futures

| Table | Live count | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_executionfactorconfiguration` | 2,895 rows | Per-(strategy, instrument) `ExecutionFactor` decimal multiplier — partial (0.5 = 50%) or amplified (1.2 = 120%) hedging. Filter `IsActive = 1`. |
| `main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations` | 68 rows × 45 synthetics × 53 contracts | Synthetic non-expiry instrument → real futures contract. Schema: `(InstrumentID, InstrumentIDToHedge, Multiplier)`. Filter `Multiplier > 0` for active. |

### Multi-account routing + allowlists

| Table | Live count | Use For |
|---|---|---|
| `main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount` | 95,542 rows × 80 accounts × 11,926 instruments | Per-account instrument allowlist. **Only consulted for multi-account hedge servers** — single-account paths bypass it. |
| `main.bi_db.bronze_etoro_hedge_instrumentgroups` | 78 groups | Named instrument groups (collective routing). |
| `main.bi_db.bronze_etoro_hedge_instrumentgroupsmapping` | 27,335 rows × 10,768 instruments | Instrument ↔ group junction. |
| `main.general.bronze_etoro_trade_hedgeserver` | Server registry | Hedge-server names, strategies, etc. |

### Regulatory / external mappings

| Table | Layer | Use For |
|---|---|---|
| `main.sharepoint.silver_sharepoint_reg_liquidityaccountid_to_lei` | silver | LEI registry for liquidity accounts (regulatory reporting). |
| `main.sharepoint.silver_sharepoint_dealing_aggspreads_instruments_to_liquidityaccounts` | silver | Aggregate-spreads instrument↔account mapping (SharePoint-managed). |
| `main.sharepoint.silver_sharepoint_dealing_aggspreads_liquidityaccounts_names` | silver | Friendly account names for spread aggregation reports. |

---

## Core Concepts

### The 4-layer LP hierarchy — naming gotchas

```
Trade.LiquidityProviderType  (145 abstract types: FXCM, OMS, Virtu, JPM, B2C2, Saxo 4.4, …)
    ↓ FK LiquidityProviderTypeID
Trade.LiquidityProviders     (187 instances: "FXCM Real", "FD STP Production NY4", …)
    ↓ FK LiquidityProviderID  (= instance id, NOT type id, here)
Trade.LiquidityAccounts      (391 accounts: per-LP login + env settings)
    ↓ FK LiquidityAccountID
Hedge.HedgeServerToLiquidityAccount  (assigns 78 account-rows to 43 servers)
    ↓ FK HedgeServerID
Trade.HedgeServer            (the execution process)
```
**The naming pitfall (Warning #2):** `Trade.LiquidityProviderContracts.LiquidityProviderID` is actually a **TypeID** (FK to `LiquidityProviderType`). Same for `Hedge.ProviderUnitConversionRatio.LiquidityProviderID`. To resolve a contract row to a human-readable provider name, JOIN on `LiquidityProviderType.LiquidityProviderTypeID`, NOT on `LiquidityProviders.LiquidityProviderID`.

### CBH "Boundaries" strategy semantics (`Hedge.InstrumentBoundaries`)

For each (HedgeServer, Instrument):

- **OpenThresholdUSD** — when `|NetClientExposureUSD|` exceeds this, hedge server starts placing hedge orders.
- **HedgeRiskLimitUSD (HRL)** — target hedged amount. Stop adding hedge when `HedgedUSD >= HRL`. **HRL=0 = no upper cap**, fully hedge the entire exposure above the open threshold.
- **CloseThresholdPercentage** — when exposure drops below `OpenThresholdUSD × CloseThresholdPercentage / 100`, reduce/close the hedge. Prevents whipsawing. Typical = 50 (close at half).

Example: Server 1, EUR/USD: Open=$50K, Close=50%, HRL=$0. Hedge opens when exposure > $50K; hedges *all* of it (no cap); closes when exposure drops below $25K.

### Unit conversion formula (`Hedge.ProviderUnitConversionRatio`)

```
ProviderNativeQuantity = eToroInternalUnits × UnitConversionRatio
```
- Ratio < 1: eToro units larger than provider's (e.g. eToro deals in $1, LP in $1000 lots).
- Ratio > 1: opposite.
- Reader-procedure `GetProviderUnitConversion` defaults missing values via `ISNULL` to ratio=1.0, lot=1000 (Forex) / 1 (other). **A ratio of 1.0 in result-set may be a default, not a real config — always check the source table directly for null-vs-1 distinction.**

### Active LP routing today (2026-05)

| Layer | Active LP-types | Notes |
|---|---|---|
| `LiquidityProviderContracts` (`ToDate > today`) | Virtu (83), OMS (10002) | Just 2 LP types; ~4,752 active contracts across 4,752 instruments. |
| `ProviderUnitConversionRatio` (any row) | 27 LP types | Marex-OMS (84), ED&F Man (99), Virtu (83), OMS (10002), JPM (44), EMSX-JPM (80), SAXO 4.4 (116), IB (11), Saxo (23), IG Execution (12), GSEMSX (81), Talos Coinbase (128), MarketMakerHBC (1250), MarketMaker Direct (125), Talos Hidden Road (333) lead the list. |
| Hedge-server count | 43 servers (with at least 1 account) | OMS server (HedgeServerID=8) has dual pricing+hedging account. |

**Interpretation:** historical contracts are preserved (200K rows total) but execution has consolidated heavily onto a few aggregators (Virtu, OMS, Marex). The wiki's narrative of "FXCM/FD/BMFN as primary forex hedge providers" is from a prior era — those LP types have 2–3 rows in unit-conv now and minimal active contracts.

---

## Query Patterns

### Pattern 1 — Active LP type for a given instrument (with type name)
```sql
SELECT lpc.InstrumentID, lpc.LiquidityProviderID AS lp_type_id, lpt.Name AS lp_type_name,
       lpc.Ticker, lpc.ExchangeID, lpc.FromDate, lpc.ToDate
FROM main.general.bronze_etoro_trade_liquidityprovidercontracts lpc
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lpc.LiquidityProviderID = lpt.LiquidityProviderTypeID  -- naming-gotcha (Warning #2)
WHERE lpc.InstrumentID = 1111
  AND current_date() BETWEEN lpc.FromDate AND COALESCE(lpc.ToDate, '9999-12-31');
```
**Use when:** "who hedges Tesla currently?", "current LP coverage for instrument X"

### Pattern 2 — Currently active LP routing landscape (the consolidated view)
```sql
SELECT lpt.LiquidityProviderTypeID, lpt.Name AS lp_type,
       COUNT(*) AS active_contracts, COUNT(DISTINCT lpc.InstrumentID) AS instruments
FROM main.general.bronze_etoro_trade_liquidityprovidercontracts lpc
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lpc.LiquidityProviderID = lpt.LiquidityProviderTypeID
WHERE COALESCE(lpc.ToDate, '9999-12-31') > current_date()
GROUP BY lpt.LiquidityProviderTypeID, lpt.Name
ORDER BY active_contracts DESC;
```
**Use when:** "which LPs are eToro currently using?", quick state-of-routing snapshot. **Caveat:** for hedging-only LP types (Apex, GS for stocks, etc.), check `Hedge.ProviderUnitConversionRatio` instead — they may not maintain entries in `LiquidityProviderContracts`.

### Pattern 3 — Resolve LP name from id, navigating both the type-id-as-LiquidityProviderID gotcha and instance lookup
```sql
-- For a TYPE id (most common — contracts, unit-conv, hedge config):
SELECT Name FROM main.bi_db.bronze_etoro_trade_liquidityprovidertype
WHERE LiquidityProviderTypeID = 84;  -- Marex-OMS

-- For an INSTANCE id (LiquidityAccounts.LiquidityProviderID; HedgeServerToLiquidityAccount via account):
SELECT lpi.LiquidityProviderName, lpt.Name AS type_name
FROM main.trading.bronze_etoro_trade_liquidityproviders lpi
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON lpi.LiquidityProviderTypeID = lpt.LiquidityProviderTypeID
WHERE lpi.LiquidityProviderID = 4;  -- "FD RealStream Production REAL 208.100.16.161"
```

### Pattern 4 — Unit-conversion lookup for cross-LP quantity comparison
```sql
SELECT pcr.LiquidityProviderID AS lp_type_id, lpt.Name AS lp_type, pcr.InstrumentID,
       pcr.UnitConversionRatio, pcr.LotSize
FROM main.bi_db.bronze_etoro_hedge_providerunitconversionratio pcr
JOIN main.bi_db.bronze_etoro_trade_liquidityprovidertype lpt
  ON pcr.LiquidityProviderID = lpt.LiquidityProviderTypeID
WHERE pcr.InstrumentID = 1111
ORDER BY pcr.LiquidityProviderID;
```
**Use when:** "what's the lot size at Saxo for Tesla?", "translate eToro units to Marex native quantity"

### Pattern 5 — Boundaries config — "why didn't this hedge fire?"
```sql
SELECT HedgeServerID, InstrumentID, OpenThresholdUSD,
       CloseThresholdPercentage, HedgeRiskLimitUSD,
       OpenThresholdUSD * CloseThresholdPercentage / 100.0 AS close_threshold_usd
FROM main.dealing.bronze_etoro_hedge_instrumentboundaries
WHERE HedgeServerID = 1  -- replace
  AND InstrumentID = 1111;
```
**Use when:** investigation of hedge non-fires; OpenThresholdUSD is the first thing to check.

### Pattern 6 — Direction-aware circuit-breaker thresholds
```sql
SELECT InstrumentID,
       CASE WHEN IsOverHedged=1 THEN 'Over-Hedged' ELSE 'Under-Hedged' END AS direction,
       CircuitBreakerAlertThresholdUSD, CircuitBreakerTriggerThresholdUSD
FROM main.bi_db.bronze_etoro_hedge_exposurecircuitbreakerthresholds
WHERE InstrumentID = 1111
ORDER BY IsOverHedged;
```
**Use when:** risk-management config audit; identify asymmetric thresholds

### Pattern 7 — Rolling-futures: which contract is the active underlying?
```sql
SELECT InstrumentID AS synthetic, InstrumentIDToHedge AS underlying_contract,
       Multiplier, SysStartTime
FROM main.dealing.bronze_etoro_hedge_portfolioconversionconfigurations
WHERE Multiplier > 0  -- exclude rolled-out contracts
ORDER BY InstrumentID, Multiplier DESC;
```
**Use when:** "which futures contract is the active hedge for Oil Non-Expiry?", roll audit; 45 synthetics × 53 contracts currently.

### Pattern 8 — Multi-account routing: which account handles instrument X for server Y?
```sql
SELECT hsla.HedgeServerID, hsla.LiquidityAccountID, sia.InstrumentID
FROM main.bi_db.bronze_etoro_hedge_hedgeservertoliquidityaccount hsla
JOIN main.dealing.bronze_etoro_hedge_supportedinstrumentsaccount sia
  ON hsla.LiquidityAccountID = sia.LiquidityAccountID
WHERE hsla.HedgeServerID = 8  -- OMS server
  AND sia.InstrumentID = 1111;
```
**Use when:** multi-account hedge servers (single-account servers bypass the allowlist).

### Pattern 9 — Hedge cost: ROUTE to the canonical HC ledger
```sql
-- For ANALYTICAL HC questions ("hedge cost YTD", "ICC HC last month", "Real Stocks HC trend",
-- "net trading revenue by asset class"), use the canonical HC ledger directly:
SELECT AssetClass, ROUND(SUM(Hedge_Cost)/1e6, 2) AS hc_usd_m
FROM main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1
WHERE etr_ymd >= '2026-01-01'
GROUP BY AssetClass ORDER BY hc_usd_m;
```
**Use when:** any hedge-cost rollup — load [`hedge-cost-recon.md`](hedge-cost-recon.md). The historic ExecutionLog + recon + contract-mapping reconstruction is only for FORENSIC deep-dives ("why is the HC ledger value X on date Y?"), not for analytical defaults.

---

## Cost-of-Goods-Sold framing

```
Trading-platform NET P&L
  = Revenue from customers              [domain-revenue-and-fees]
  − Hedge cost                          [hedge-cost-recon.md — main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1]
  − Operational costs                   [out of scope]
```

**Canonical HC source:** `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1` — daily EOD ledger from the `eToro/HedgeCostAgent` pipeline. See [`hedge-cost-recon.md`](hedge-cost-recon.md) for the table and query patterns.

This LP-config skill provides the **upstream pipeline truth** (which LP, which contract, which unit-conversion ratio) — used during HC investigations to explain WHY a row has its value. For ANALYTICAL HC, go straight to the HC ledger.

Forensic reconstruction sources (only when the HC ledger value itself is being audited):

- `Hedge.ExecutionLog` (LP fill rate, slippage vs eToro execution-rate-at-send) — see [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md).
- LP-recon trade-activity tables (`ApexRecon_TradeActivity`, Marex non-futures, JPM trade activity) — see [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md).
- LP contracts + conversion ratios (this skill).

---

## Cross-references

- **Realised hedge cost (canonical HC ledger)** → [`hedge-cost-recon.md`](hedge-cost-recon.md) — `main.bi_dealing_stg.bi_output_dealing_HC_auto_agent_v1`. Default destination for any "hedge cost" rollup.
- Hedge-execution events / LP fill audit log → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- EOD LP recon → [`broker-and-lp-reconciliation.md`](broker-and-lp-reconciliation.md)
- Revenue side of trading P&L → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Pricing inputs (LP-confirmed vs eToro spread-adjusted) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Instrument metadata → [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md)
- Customer-side position lifecycle → [`position-state-and-grain.md`](position-state-and-grain.md)
- Best-execution / TCA → [`best-execution.md`](best-execution.md)

## Sources Consulted

| Source | Type | Insight delta vs v1 |
|---|---|---|
| `knowledge/ProdSchemas/.../Trade/Tables/Trade.LiquidityProviderContracts.md` | OLTP wiki | Naming gotcha — `LiquidityProviderID` is actually TypeID; PK is composite (Instrument, LP-type, Exchange); validity windows; ASM-managed history; 12 columns including RateConversionFactor. |
| `knowledge/ProdSchemas/.../Trade/Tables/Trade.LiquidityProviders.md` | OLTP wiki | Instance registry distinct from type — "FXCM Real" vs "FXCM Demo" vs "FD RealStream …". |
| `knowledge/ProdSchemas/.../Trade/Tables/Trade.LiquidityProviderType.md` | OLTP wiki | 145-type catalog with .NET assembly class definitions (priceClassInfo, PCSClassInfo, executionClassInfo, HedgingProviderClassInfo). |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ProviderUnitConversionRatio.md` | OLTP wiki | Formula `providerQty = eToroUnits × ratio`; ISNULL fallback in reader; LotSize not audit-tracked; old ZBFX dominance now obsolete. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.InstrumentBoundaries.md` | OLTP wiki | OpenThresholdUSD/CloseThresholdPercentage/HRL semantics, HRL=0 = no cap, column-level ASM audit. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.BoundariesConfiguration.md` | OLTP wiki | Wiki says EMPTY → live UC has 124,918 rows. Band-based rebalance: lower/upper dead-band thresholds + desired-exposure targets. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ExposureCircuitBreakerThresholds.md` | OLTP wiki | Wiki says EMPTY → live UC has 12,618 rows. Direction-aware Alert vs Trigger. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.PortfolioConversionConfigurations.md` | OLTP wiki | Schema (InstrumentID, InstrumentIDToHedge, Multiplier); v1 invented "SyntheticInstrumentID/UnderlyingContractID" — corrected. 45 synthetics × 53 contracts now (was 2). |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ExecutionFactorConfiguration.md` | OLTP wiki | Wiki says EMPTY → live UC has 2,895 rows. Filter `IsActive=1`. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.InstrumentConfiguration.md` | OLTP wiki | Per-instrument 4 sizing knobs + single (undirected) CB; SpreadReturnFactor/RestrictManualActions/LotSizeForView are uniform (unused). |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.HedgeServerToLiquidityAccount.md` | OLTP wiki | PK on LiquidityAccountID, multi-account-per-server pattern, AltRates NULL in all rows. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.SupportedInstrumentsAccount.md` | OLTP wiki | Conditional reader — bypassed for single-account servers; AccountTypeID=4 excluded. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.AccountInstrumentConfiguration.md` | OLTP wiki | LimitRoundPrecision active, throttling cols designed-but-NULL; live row count is 1000× wiki snapshot. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.ProviderInstrumentConfiguration.md` | OLTP wiki | Wiki says EMPTY → live has 1,338 rows. OrderType + LimitOffset + GTD validity. |
| `knowledge/ProdSchemas/.../Hedge/Tables/Hedge.HedgeServerInstrumentConfiguration.md` | OLTP wiki | Wiki says EMPTY → live has 5,048 rows. AllowHBCFailover / PriceSource / AllowClosePositionMaxDealSizeCheck / MinAmountForIM. |
| `user-databricks_sql` execute_sql_read_only | Live UC | All row counts above; distribution of LP types in `ProviderUnitConversionRatio` (Marex-OMS dominant, ZBFX absent); active LP routing consolidated on Virtu+OMS; 145-row LP type catalog; absence of any `fact_hedge%` / `fact_lp%` table in DDR. |

## Provenance

v1 (2026-05-10): seed from harvested UC table-comments — many "empty/designed but not active" claims later proven false against live data.
**v2 (2026-05-11): full SpecKit Phase 2.5 rebuild.** Authoritative wikis: 15 Trade.* + Hedge.* OLTP wikis under `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/`. Live UC verification across all 18 anchor tables. Critical Warnings expanded from 7 → 15 with five new Tier 1 items: naming gotcha, wiki-vs-live divergence, active-routing consolidation on Virtu+OMS, ZBFX disappearance from unit conversion, unit conversion as the only authoritative cross-LP translation source. Tables section restructured into 7 functional zones with row counts. Provenance footer.
