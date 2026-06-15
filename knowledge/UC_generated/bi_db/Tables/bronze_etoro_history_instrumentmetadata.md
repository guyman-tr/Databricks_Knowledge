---
object_fqn: main.bi_db.bronze_etoro_history_instrumentmetadata
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_history_instrumentmetadata
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 40
row_count: null
generated_at: '2026-05-19T12:12:48Z'
upstreams:
- etoro.History.InstrumentMetaData
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md
  source_database: etoro
  source_schema: History
  source_table: InstrumentMetaData
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/History/InstrumentMetaData
  copy_strategy: Append
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 37
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 3
  unverified_columns: 0
---

# bronze_etoro_history_instrumentmetadata

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.History.InstrumentMetaData`). 37 of 40 columns inherited from Tier 1 source wiki; 3 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_history_instrumentmetadata` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 40 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Feb 24 13:18:43 UTC 2025 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.History.InstrumentMetaData` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md`.

- Lake path: `Bronze/etoro/History/InstrumentMetaData`
- Copy strategy: `Append`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `History.InstrumentMetaData`
- 37 of 40 columns inherited; 3 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | INT | YES | The instrument this history version belongs to. PK in Trade.InstrumentMetaData (one live row per instrument). Multiple history rows here for the same InstrumentID capture its metadata evolution (Tier 2 — inherited from etoro.History.InstrumentMetaData). |
| 1 | InstrumentDisplayName | STRING | YES | Human-readable display name shown in the eToro UI for this instrument (e.g., "EUR/USD", "Apple", "Bitcoin"). Audited by AuditInsert/Update/Delete triggers -> History.AuditHistory (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 2 | InstrumentTypeImage | STRING | YES | URL or path to the image representing the instrument type category (not the instrument itself) (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 3 | Ticker | STRING | YES | Ticker symbol used for price feed lookup. Observed value: "/ticker" - may be overridden per instrument (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 4 | ChartTicker | STRING | YES | Ticker symbol used specifically for charting data source lookups. May differ from Ticker for some instruments (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 5 | InstrumentImageSmall | STRING | YES | URL to the small (thumbnail) icon image for this instrument, displayed in instrument lists (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 6 | InstrumentImageMedium | STRING | YES | URL to the medium-size image for this instrument (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 7 | InstrumentImageLarge | STRING | YES | URL to the large image for this instrument, used in instrument detail pages (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 8 | Exchange | STRING | YES | Exchange name as a free-text string (e.g., "NASDAQ", "NYSE"). Supplemented by ExchangeID (the structured FK). This column may be a legacy display field (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 9 | Industry | STRING | YES | Industry classification for stock instruments (e.g., "Technology", "Healthcare"). Audited by ASM triggers -> History.AuditHistory. NULL for non-stock instruments (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 10 | CompanyInfo | STRING | YES | Free-text company description displayed on the instrument detail page. Rich text describing the company's business and background (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 11 | DailyRolloverFee | DECIMAL | YES | Daily overnight/rollover fee rate applied to leveraged CFD positions in this instrument. Expressed as a percentage or absolute value per day. NULL = fee not configured (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 12 | WeekendRolloverFee | DECIMAL | YES | Weekend-specific rollover fee charged for positions held over the weekend (Friday close to Monday open, typically 3x daily). NULL = not configured (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 13 | ContractRolloverFee | DECIMAL | YES | Rollover fee applied when a futures contract rolls to the next expiry period. Audited by ASM triggers. NULL for non-futures instruments (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 14 | InstrumentVisible | INT | YES | Visibility flag: 1=visible to customers (default), 0=hidden. Controls whether the instrument appears in search and trading interfaces. Audited by ASM triggers -> History.AuditHistory (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 15 | Symbol | STRING | YES | Short trading symbol for the instrument (e.g., "EURUSD", "AAPL"). Used in price feeds and internal references. Audited by ASM triggers (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 16 | CandleTimeframeGroup | INT | YES | FK to Trade.CandleIntervalGroups (FK_InstrumentMetaData_CandleIntervalGroups). Determines which candle timeframe intervals are available for this instrument's charts (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 17 | SymbolFull | STRING | YES | Fully-qualified unique symbol string for the instrument (e.g., "Drm.797" for dormant instruments). UNIQUE constraint on Trade.InstrumentMetaData (UNQ_TradeInstrumentMetaData_SymbolFull). Audited by ASM triggers (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 18 | Tradable | BOOLEAN | YES | Whether customers can currently trade this instrument: 1=tradable, 0=not tradable (suspended, delisted, or not yet launched). Audited by ASM triggers -> History.AuditHistory (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 19 | ExchangeID | INT | YES | FK to Trade.Exchange (structural). Identifies the exchange where this instrument is traded. Validated on UPDATE by trigger trg_update_Trade_InstrumentMetaData - prevents assignment to an exchange without a fee definition in Trade.ExchangeInstrumentFeeDefinition (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 20 | StocksIndustryID | INT | YES | Numeric ID of the stock's industry sector. FK to a stocks industry lookup table. NULL for non-stock instruments. Supplements the free-text Industry column with a structured classification (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 21 | ISINCode | STRING | YES | International Securities Identification Number for the instrument. Audited by ASM triggers -> History.AuditHistory. NULL for instruments not mapped to a global security identifier (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 22 | ISINCountryCode | STRING | YES | Country code component of the ISIN (first 2 characters of ISIN, e.g., "US", "GB"). Audited by ASM triggers (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 23 | ContractExpire | BOOLEAN | YES | Whether this futures/CFD instrument has a contract expiry date: 0=perpetual (no expiry), 1=expires. DEFAULT 0. Audited by ASM triggers -> History.AuditHistory. Triggers futures rollover processing when 1 (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 24 | InstrumentTypeSubCategoryID | INT | YES | Sub-category classification within the instrument's type. Provides finer granularity than InstrumentTypeID (e.g., distinguishing ETFs from indices within the same type group) (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 25 | InstrumentTypeID | INT | YES | Instrument type classification. FK to Dictionary.CurrencyType (FK_InstrumentMetaData_InstrumentType). Observed: 1=FX pair, 4=Index/ETF, 10=custom/synthetic. Determines trading rules, fee schedules, and hedging behavior (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 26 | PriceSourceID | INT | YES | ID of the price data source for this instrument. DEFAULT 0 = default/unspecified source. Used by the Price engine to route price feed subscriptions (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 27 | Cusip | STRING | YES | CUSIP identifier (Committee on Uniform Securities Identification Procedures). US-centric securities identifier. Indexed in Trade.InstrumentMetaData (IX_Cusip). NULL for non-US or non-CUSIP instruments (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 28 | CreateDate | TIMESTAMP | YES | UTC timestamp when the instrument metadata row was first created. DEFAULT getutcdate() set at row insertion (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 29 | UnderlyingExchangeID | INT | YES | For derivative instruments (futures, CFDs), the exchange of the underlying asset. May differ from ExchangeID when eToro lists a derivative on one exchange tracking an asset traded on another (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 30 | DbLoginName | STRING | YES | Materialized snapshot of suser_name() at version close time. Identifies who changed the metadata. Observed: "DevTradingSTG" for automated batch updates (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 31 | AppLoginName | STRING | YES | Materialized snapshot of context_info() at version close time. Typically NULL (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 32 | SysStartTime | TIMESTAMP | YES | Start of validity for this metadata version. Set by SQL Server temporal engine. Rows with SysStartTime=SysEndTime are insert artifacts from Tr_T_InstrumentMetaData_INSERT (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 33 | SysEndTime | TIMESTAMP | YES | End of validity for this metadata version. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 34 | SEDOL | STRING | YES | Stock Exchange Daily Official List identifier. UK-centric securities identifier (7-character alphanumeric). NULL for non-SEDOL instruments (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 35 | SubCategory | STRING | YES | Freeform sub-category label providing additional classification context beyond InstrumentTypeSubCategoryID (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 36 | CFICode | STRING | YES | Classification of Financial Instruments code (ISO 10962). 6-character standardized code describing the instrument type at the international regulatory level (e.g., "ESVUFR" for common equity) (Tier 1 — inherited from etoro.History.InstrumentMetaData). |
| 37 | etr_y | INT | YES | Source: etoro.History.InstrumentMetaData.etr_y. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 38 | etr_ym | STRING | YES | Source: etoro.History.InstrumentMetaData.etr_ym. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |
| 39 | etr_ymd | DATE | YES | Source: etoro.History.InstrumentMetaData.etr_ymd. No upstream wiki cached as of 2026-05-19 (Tier N — bronze-passthrough; column not documented in Tier 1 source wiki). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.History.InstrumentMetaData` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.History.InstrumentMetaData
        │
        ▼
main.bi_db.bronze_etoro_history_instrumentmetadata   ←── this object
        │
        ▼
main.bi_output.bi_output_finance_external_table_bi_db_sharelending_custodyreconciliation_external
main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation
main.bi_output.bi_output_finance_tables_bi_db_sharelending_custodyreconciliation_eu
... (2 more downstream)
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentDisplayName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentTypeImage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Ticker | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ChartTicker | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentImageSmall | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentImageMedium | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentImageLarge | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Exchange | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Industry | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| CompanyInfo | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| DailyRolloverFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| WeekendRolloverFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ContractRolloverFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentVisible | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Symbol | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| CandleTimeframeGroup | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| SymbolFull | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Tradable | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| StocksIndustryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ISINCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ISINCountryCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| ContractExpire | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentTypeSubCategoryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| InstrumentTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| PriceSourceID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| Cusip | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| UnderlyingExchangeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| DbLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| AppLoginName | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| SysStartTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| SysEndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| SEDOL | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| SubCategory | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| CFICode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.History.InstrumentMetaData) |
| etr_y | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` but column `etr_y` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ym | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` but column `etr_ym` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |
| etr_ymd | would inherit from `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.InstrumentMetaData.md` but column `etr_ymd` not present in source wiki | N | (Tier N — bronze-passthrough-no-source-row) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 37 T1, 0 T2, 0 T3, 0 T4, 0 T5, 3 TN, 0 U | Elements: 40/40 | Source: bronze_tier1_inheritance*
