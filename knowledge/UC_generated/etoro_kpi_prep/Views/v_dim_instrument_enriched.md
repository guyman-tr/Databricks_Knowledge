---
object_fqn: main.etoro_kpi_prep.v_dim_instrument_enriched
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi_prep.v_dim_instrument_enriched
schema: etoro_kpi_prep
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 50
row_count: null
generated_at: '2026-05-19T12:26:23Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.trading.bronze_etoro_trade_instrumentmetadata_daily / main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
- main.trading.bronze_etoro_trade_instrumentgroups
- main.trading.bronze_etoro_trade_instrumentmetadata_daily
- main.trading.bronze_etoro_trade_providertoinstrument
- main.trading.bronze_etoro_trade_instrumentmetadata
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql
concept_count: 4
formula_count: 50
tier_breakdown:
  tier1_columns: 33
  tier2_columns: 15
  tier3_columns: 2
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# v_dim_instrument_enriched

> View in `main.etoro_kpi_prep`. 4 business concept(s) in §2; 48 of 50 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_instrument_enriched` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 50 |
| **Concepts** | 4 (see §2) |
| **Downstream consumers** | 5 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Apr 28 14:09:26 UTC 2026 |

---

## 1. Business Meaning

`v_dim_instrument_enriched` is a view in `main.etoro_kpi_prep` that composes 3 CASE-based classifier flag(s) computed from upstream IDs, 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`. Additional upstreams: 5 object(s), listed in §5 Lineage.

Of its 50 columns: 33 inherit byte-for-byte from upstream wikis (Tier 1), 15 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `Tradeable` discriminator: `VisibleInternallyOnly = 0` (visible to all per upstream wiki), `Tradable = 1` (orders allowed per upstream wiki), `InstrumentVisible = 1` → set to 1 else 0
**What**: Computed flag on `Tradeable` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `Tradeable`
**Rules**:
- `VisibleInternallyOnly = 0` (visible to all per upstream wiki)
- `Tradable = 1` (orders allowed per upstream wiki)
- `InstrumentVisible = 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql` etoro_kpi_prep.sql L78-L84
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.trading.bronze_etoro_trade_instrumentmetadata_daily`

### 2.2 `IsSQF` computed flag
**What**: Computed flag on `IsSQF` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsSQF`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql` etoro_kpi_prep.sql L85-L88
**Source(s)**: `main.trading.bronze_etoro_trade_instrumentgroups`

### 2.3 `Is_245_Instrument` computed flag
**What**: Computed flag on `Is_245_Instrument` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `Is_245_Instrument`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql` etoro_kpi_prep.sql L89-L92
**Source(s)**: `main.trading.bronze_etoro_trade_instrumentmetadata_daily`, `main.trading.bronze_etoro_trade_providertoinstrument`

### 2.4 Filter on scope `rth_instruments`: `ExchangeID = 33`
**What**: `WHERE` clause at the top of scope `rth_instruments` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `ExchangeID`
**Rules**:
- `ExchangeID = 33`
**Evidence**: `knowledge/UC_generated/etoro_kpi_prep/_discovery/source_code/v_dim_instrument_enriched.sql` L15

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsSQF = 1`-style filters on the precomputed flag columns (`IsSQF`, `Is_245_Instrument`, `Tradeable`) instead of recomputing the underlying CASE predicates downstream. |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- Scope `rth_instruments` applies `ExchangeID = 33` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 — Trade.GetInstrument) |
| 1 | InstrumentTypeID | INT | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInstrument) |
| 2 | InstrumentType | STRING | YES | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument) |
| 3 | Name | STRING | YES | Display name computed by Trade.GetInstrument as BuyCurrency Abbreviation + '/' + SellCurrency Abbreviation (e.g., EUR/USD for forex, AAPL/USD for stocks). Not a company name; see InstrumentDisplayName for human-readable labels. |
| 4 | DWHInstrumentID | INT | YES | Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. (Tier 1 — Trade.GetInstrument) |
| 5 | StatusID | INT | YES | Hardcoded to 1 for all data rows; NULL for sentinel row (InstrumentID=0). (Tier 2 — SP_Dim_Instrument) |
| 6 | BuyCurrencyID | INT | YES | Buy-side currency abbreviation. For forex: base currency code; for stocks: the asset code (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument (Tier 1 - Trade.GetInstrument) |
| 7 | SellCurrencyID | INT | YES | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 8 | BuyCurrency | STRING | YES | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviation via buy-side join. (Tier 1 — Dictionary.Currency) |
| 9 | SellCurrency | STRING | YES | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) |
| 10 | TradeRange | INT | YES | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 11 | DollarRatio | DECIMAL | YES | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 12 | PipDifferenceThreshold | LONG | YES | Max pip difference for price validation. From Trade.Instrument. (Tier 1 — Trade.GetInstrument) |
| 13 | IsMajorID | INT | YES | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). (Tier 1 — Trade.GetInstrument) |
| 14 | IsMajor | STRING | YES | ETL-computed label from IsMajorID: 'Yes' when IsMajor=1, 'No' otherwise. (Tier 2 — SP_Dim_Instrument) |
| 15 | UpdateDate | TIMESTAMP | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 16 | InsertDate | TIMESTAMP | YES | ETL housekeeping timestamp. Set to GETDATE() at each SP_Dim_Instrument run. (Tier 2 — SP_Dim_Instrument) |
| 17 | InstrumentDisplayName | STRING | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) |
| 18 | Industry | STRING | YES | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData) |
| 19 | CompanyInfo | STRING | YES | Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) |
| 20 | Exchange | STRING | YES | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 — Trade.InstrumentMetaData) |
| 21 | ISINCode | STRING | YES | International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. (Tier 1 — Trade.InstrumentMetaData) |
| 22 | ISINCountryCode | STRING | YES | Country prefix of ISIN (e.g., "US"). Audit-tracked. (Tier 1 — Trade.InstrumentMetaData) |
| 23 | Tradable | INT | YES | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. (Tier 1 — Trade.InstrumentMetaData) |
| 24 | Symbol | STRING | YES | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. (Tier 1 — Trade.InstrumentMetaData) |
| 25 | ReceivedOnPriceServer | TIMESTAMP | YES | Earliest price-server timestamp from PriceLog_History_CurrencyPrice_Active for the prior day, persisted via Ext_Dim_Instrument_ReceivedOnPriceServerStatic. (Tier 2 — SP_Dim_Instrument) |
| 26 | BonusCreditUsePercent | INT | YES | Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 27 | SymbolFull | STRING | YES | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — Trade.InstrumentMetaData) |
| 28 | CUSIP | STRING | YES | CUSIP code sourced from Trade.InstrumentCusip (not InstrumentMetaData). Committee on Uniform Securities Identification Procedures identifier for US/Canada securities. NULL for forex, crypto, and many non-US instruments. |
| 29 | Precision | INT | YES | Decimal places for price display and rounding. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 30 | AllowBuy | INT | YES | 1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 31 | AllowSell | INT | YES | 1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 32 | AssetClass | STRING | YES | Asset class classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. NULL for 13,557 of 15,707 rows. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 33 | IndustryGroup | STRING | YES | Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| 34 | ADV_Last3Months | DECIMAL | YES | Average daily trading volume over the last 3 months (TTM). From Rankings.StockInfo.InstrumentData MetadataID=8557. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 35 | MKTcap | DECIMAL | YES | Market capitalization. ISNULL(MarketCapitalization-TTM, CryptoMarketCap) — uses stock market cap when available, falls back to crypto market cap. From Rankings.StockInfo MetadataID=8735/9315. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 36 | SharesOutStanding | DECIMAL | YES | Current shares outstanding (annual). From Rankings.StockInfo.InstrumentData MetadataID=8444. (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 37 | VisibleInternallyOnly | INT | YES | 1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. (Tier 1 — Trade.ProviderToInstrument) |
| 38 | PlatformSector | STRING | YES | Platform-level sector classification from Rankings.StockInfo MetadataID=8436 (StrVal pivot). E.g., "Electronic Technology", "Technology Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 39 | PlatformIndustry | STRING | YES | Platform-level industry classification from Rankings.StockInfo MetadataID=8280 (StrVal pivot). E.g., "Telecommunications Equipment", "Internet Software Or Services". (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) |
| 40 | IsFuture | INT | YES | 1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. (Tier 2 — SP_Dim_Instrument) |
| 41 | Multiplier | DECIMAL | YES | Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). (Tier 1 — Trade.FuturesMetaData) |
| 42 | ProviderID | INT | YES | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tribe). From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 43 | ProviderMarginPerLot | DECIMAL | YES | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. (Tier 1 — Trade.FuturesInstrumentsInitialMarginByProviderMapping) |
| 44 | eToroMarginPerLot | DECIMAL | YES | Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. (Tier 1 — Trade.ProviderToInstrument) |
| 45 | SettlementTime | TIMESTAMP | YES | Time-of-day settlement from Trade.FuturesMetaData, reformatted in SP_Dim_Instrument via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00') and cast to TIME. Primarily relevant for futures instruments. NULL for non-futures. |
| 46 | OperationMode | INT | YES | Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). From Trade.Instrument. (Tier 1 — Trade.Instrument) |
| 47 | Tradeable | INT | NO | `Tradeable` discriminator: `VisibleInternallyOnly = 0` (visible to all per upstream wiki), `Tradable = 1` (orders allowed per upstream wiki), `InstrumentVisible = 1` → set to 1 else 0. Formula: `CASE WHEN VisibleInternallyOnly = 0 AND Tradable = 1 AND InstrumentVisible = 1 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`, `main.trading.bronze_etoro_trade_instrumentmetadata_daily`) |
| 48 | IsSQF | INT | NO | `IsSQF` computed flag. Formula: `CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.trading.bronze_etoro_trade_instrumentgroups`) |
| 49 | Is_245_Instrument | INT | NO | `Is_245_Instrument` computed flag. Formula: `CASE WHEN InstrumentID IS NOT NULL THEN 1 ELSE 0 END`. (Tier 2 — from `main.trading.bronze_etoro_trade_instrumentmetadata_daily`, `main.trading.bronze_etoro_trade_providertoinstrument`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata_daily / main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata_daily` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Views/Trade.InstrumentMetaData_Daily.md` |
| `main.trading.bronze_etoro_trade_providertoinstrument` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.trading.bronze_etoro_trade_instrumentmetadata_daily / main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument
main.trading.bronze_etoro_trade_instrumentgroups
... (3 more upstream(s))
        │
        ▼
main.etoro_kpi_prep.v_dim_instrument_enriched   ←── this object
        │
        ▼
main.bi_output_stg.etoro_kpi_prep_stg_factcustomeraction_w_metrics
main.etoro_kpi_prep.v_fact_customeraction_w_metrics
main.etoro_kpi_prep.v_trading_volume_and_amount
... (2 more downstream)
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=50 runtime=50 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`)
- **JOIN/UNION upstreams**: 5 additional object(s)
- **Wiki coverage**: 4/5 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_output_stg.etoro_kpi_prep_stg_factcustomeraction_w_metrics`
- `main.etoro_kpi_prep.v_fact_customeraction_w_metrics`
- `main.etoro_kpi_prep.v_trading_volume_and_amount`
- `main.etoro_kpi_prep.v_trading_volume_positionlevel`
- `main.etoro_kpi_prep_stg.v_fact_customeraction_w_metrics`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 4 | Formulas: 50 | Tiers: 33 T1, 15 T2, 2 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 50/50 | Source: view_definition*
