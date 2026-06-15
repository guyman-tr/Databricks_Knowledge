---
name: domain-moneyfarm
description: "Catalog of every MoneyFarm UC table — 23 objects across 10 schemas
  arranged by Cosmos→Bronze→Silver→Gold→KPI-prep ladder. Covers the raw Cosmos
  user export (general.bronze_moneyfarm_users with _rid/_self/_etag PII metadata),
  the Fivetran auxiliary product-name lookup (experience.bronze_fivetran_experience
  _money_farm_product_names), the SFTP-fed silver AUM
  (money_farm.silver_moneyfarm_etoro_mf_aum) and its staging mirror, the historical
  events back-fill table (money_farm.silver_moneyfarm_historical_events), the BI
  team's bizops fact triplet (bi_output.bi_output_moneyfarm_customers /
  fact_portfolio_snapshot / fact_transactions plus the _stg mirrors), the
  parallel bizops_output schema (3 production + 3 staging tables; carries the
  bizops_output_moneyfarm_dim_customers customer dimension that bi_output does
  not), the regtech parquet copy (regtech_stg.silver_moneyfarm_etoro_mf_aum_parquet),
  the SharePoint export (sharepoint.silver_sharepoint_experience_money_farm
  _product_names), and the 3 KPI prep views (etoro_kpi_prep.v_moneyfarm_aum /
  v_moneyfarm_mimo / v_moneyfarm_fees — the last being a placeholder).
  Also covers the population-grouped staging view (money_farm_stg.moneyfarm
  _population_grouped). Each entry lists key fields, PII flags, deploy-status
  flags from the local domain card, and which downstream prep view consumes it."
triggers:
  - moneyfarm tables
  - bronze_moneyfarm_users
  - silver_moneyfarm_etoro_mf_aum
  - silver_moneyfarm_historical_events
  - bi_output_moneyfarm_customers
  - bi_output_moneyfarm_fact_portfolio_snapshot
  - bi_output_moneyfarm_fact_transactions
  - bizops_output_moneyfarm
  - bizops_output_moneyfarm_dim_customers
  - moneyfarm_population_grouped
  - cosmos export moneyfarm
  - sftp moneyfarm
  - moneyfarm raw tables
  - moneyfarm bronze
  - moneyfarm silver
  - moneyfarm gold
  - moneyfarm fivetran
  - rnd_output_experience_clubactivitieseodedentestmoneyfarmfilterbyproduct
sample_questions:
  - "What MoneyFarm tables exist in UC?"
  - "Where does the Cosmos-MoneyFarm export land?"
  - "What's the difference between bi_output_moneyfarm_* and bizops_output_moneyfarm_*?"
  - "Which schema holds the SFTP-fed silver AUM?"
  - "What's the source of bi_output_moneyfarm_fact_portfolio_snapshot?"
  - "Which MoneyFarm tables carry PII?"
  - "What is rnd_output_experience_clubactivitieseodedentestmoneyfarmfilterbyproduct?"
required_tables:
  - main.general.bronze_moneyfarm_users
  - main.experience.bronze_fivetran_experience_money_farm_product_names  # historical name, table is now stale
  - main.experience.rnd_output_experience_clubactivitieseodedentestmoneyfarmfilterbyproduct
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.money_farm.silver_moneyfarm_historical_events
  - main.money_farm_stg.silver_moneyfarm_etoro_mf_aum
  - main.money_farm_stg.moneyfarm_population_grouped
  - main.regtech_stg.silver_moneyfarm_etoro_mf_aum_parquet
  - main.sharepoint.silver_sharepoint_experience_money_farm_product_names
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.bi_output_stg.bi_output_moneyfarm_customers
  - main.bi_output_stg.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output_stg.bi_output_moneyfarm_fact_transactions
  - main.bizops_output.bizops_output_moneyfarm_fact_portfolio_snapshot
  - main.bizops_output.bizops_output_moneyfarm_fact_transactions
  - main.bizops_output_stg.bizops_output_moneyfarm_dim_customers
  - main.bizops_output_stg.bizops_output_moneyfarm_fact_portfolio_snapshot
  - main.bizops_output_stg.bizops_output_moneyfarm_fact_transactions
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-04"
---

# MoneyFarm — UC Source Tables Catalog

23 tables across 10 schemas. Inventory pulled live from `main.information_schema.tables` 2026-05-31.

## Layer ladder (logical)

```
Cosmos-MoneyFarm (production NoSQL, MoneyFarm-side)
    |
    | (1) Cosmos doc export
    v
Bronze (general.bronze_moneyfarm_users)            # 24K rows, _rid/_self/_etag metadata, PII
    |
    | (2) BizOps pipeline subscribes to live event stream + back-fills from silver
    v
Gold-staging (bi_output_stg.* + bizops_output_stg.*)
    |
    v
Gold (bi_output.* / bizops_output.*)               # 99K customers / 40K portfolios / per-event TX
    |
    | (3) etoro_kpi_prep ladder — eToro-side analytics
    v
KPI prep views (etoro_kpi_prep.v_moneyfarm_*)      # 3 views: aum, mimo, fees(placeholder)


Parallel SFTP path (Moneyfarm-side nightly drop)
    |
    | (4) databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb (Jupyter, daily)
    v
Silver (money_farm.silver_moneyfarm_etoro_mf_aum)  # daily AUM ladder; SourceFile for dedup
    |
    | (5) Regtech / SharePoint copies for downstream consumers
    v
regtech_stg.silver_moneyfarm_etoro_mf_aum_parquet
sharepoint.silver_sharepoint_experience_money_farm_product_names
```

The **live event** path also feeds `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` (out-of-domain) which is filtered `ProviderName='Moneyfarm'` by `v_moneyfarm_mimo` and the bizops pipelines. See `moneyfarm-views-architecture.md` for the full DDLs.

## Bronze (raw / Cosmos)

### `main.general.bronze_moneyfarm_users` (EXTERNAL)
**Source**: Cosmos-MoneyFarm `users` collection export (raw NoSQL doc shape).
**Row count**: ~24K.
**Carries PII**: yes — masked_email / masked_name / phoneNumber / nationalInsuranceNumber. Treat as restricted.
**Cosmos metadata columns** to ignore in analytics: `_rid`, `_self`, `_etag`, `_attachments`, `_ts`.
**Key business columns**: `id` (Cosmos doc ID), `userId`, `externalUserId` (the join key into eToro `bronze_sub_accounts_accounts.externalUserId`), `email_masked`, `firstName_masked`, `lastName_masked`, `dateOfBirth`, `address.*` (struct), `kycStatus`, `riskProfile`.
**Used by**: `bi_output_moneyfarm_customers` `Date_Source_Type='Bronze Table (Recent)'` rung (~45K rows back-fill).
**Pipeline owner**: BI / DataPlatform — Cosmos export is a continuous-replication feed; check freshness via `MAX(_ts)`.

## Silver (SharePoint auxiliary)

### `main.sharepoint.silver_sharepoint_experience_money_farm_product_names` (EXTERNAL) — LIVE
**Source**: Excel workbook on SharePoint, ingested via Fivetran connector. Replaces the pre-2026 `experience.bronze_fivetran_experience_money_farm_product_names` Google-Sheets pipeline.
**Row count**: 9 (small dimension).
**Purpose**: lookup table for product-name → MoneyFarm-side product code.
**Used by**: occasionally surfaces in Tableau workbooks needing the product display name; not used by the 3 prep views (which use `Product_Name` directly from `bi_output_moneyfarm_fact_portfolio_snapshot`).

### `main.experience.bronze_fivetran_experience_money_farm_product_names` (EXTERNAL) — STALE / HISTORICAL
**Status**: superseded. Last `_fivetran_synced` = 2025-06-13. Do NOT query for current product names. Listed here only so analysts who encounter the name in old notebooks / SP code can locate the live replacement above.

### `main.experience.rnd_output_experience_clubactivitieseodedentestmoneyfarmfilterbyproduct` (EXTERNAL)
**Source**: an experimental output (`rnd_output_*` naming convention = R&D / experimentation).
**Purpose**: filter-by-product variant of a club-activities cohort, MoneyFarm-side. **NOT a production table** — `rnd_output_*` is the eToro convention for non-canonical analyst outputs.
**Use**: ignore unless explicitly cited by an analyst. Not registered in any cached Tableau or Genie space.

## Silver (SFTP-fed daily AUM ladder)

### `main.money_farm.silver_moneyfarm_etoro_mf_aum` (EXTERNAL) — **canonical AUM source**
**Source**: nightly SFTP drop from MoneyFarm → `databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb` (Jupyter).
**Granularity**: one row per `(etr_ymd, Identifier_Value, Portfolio_Id)`.
**Key columns**:
- `etr_ymd` — the eToro daily ladder date.
- `Identifier_Value` — joins to `bronze_sub_accounts_accounts.externalUserId` per UK BA Genie space join_spec.
- `GCID` — already-resolved (the Daily notebook joins on the bridge before writing).
- `Portfolio_Id` — UUID per portfolio (note snake_case here vs `PortfolioID` PascalCase in `bi_output_moneyfarm_fact_portfolio_snapshot`).
- `Product` — text product name (`Managed ISA` / `DIY ISA` / `Cash ISA`).
- `Market_Value` — DOUBLE GBP balance.
- `SourceFile` — `ETORO-MF-AUM-{date}-{seq}` — used for dedup; per Ben's preamble, double-send days produce two rows and you keep the one with the lexicographically-max SourceFile.

**Used by**: `v_moneyfarm_aum` (the canonical AUM source — NOT the live event stream); Ben's `ISA Market Value (SFTP data)` Tableau workbook.

### `main.money_farm.silver_moneyfarm_historical_events` (EXTERNAL)
**Source**: reconstructed pre-stream events back-fill (Moneyfarm-side history before the EH pipeline).
**Used by**: pre-Oct-2025 backfill for the bizops pipelines (events that pre-date the live `compliance.bronze_event_hub_*` stream).

### `main.money_farm_stg.silver_moneyfarm_etoro_mf_aum` (EXTERNAL)
Pre-publish staging mirror of the canonical `money_farm.silver_moneyfarm_etoro_mf_aum`. Same granularity, same columns. Used by the daily refresh pipeline as a write-target before atomic swap.

### `main.money_farm_stg.moneyfarm_population_grouped` (VIEW)
A population-grouped helper view layered over the silver AUM. Likely groups GCIDs by funding state / tenure / product mix for cohort dashboards. Definition not cached in this skill — query `SHOW CREATE TABLE` if needed.

## Silver (downstream copies)

### `main.regtech_stg.silver_moneyfarm_etoro_mf_aum_parquet` (EXTERNAL)
Parquet-format copy of the silver AUM for regtech-team consumers. Same content as `money_farm.silver_moneyfarm_etoro_mf_aum`; format-converted for an external regulator pipeline.

### `main.sharepoint.silver_sharepoint_experience_money_farm_product_names` (EXTERNAL)
SharePoint-distributed copy of the product-name reference table. Likely created so non-Databricks consumers (e.g. business teams using SharePoint Lists or Excel) can pull it without a Databricks connection.

## Gold (bizops curated facts) — `bi_output.*`

These three are the BI-team's MoneyFarm fact triplet — **already have rich UC comments deployed** (Batch 2 + Batch 4 on 2026-05-04, full per-column tier-tagged documentation). Each has an `_stg` staging mirror under `bi_output_stg.*` (same shape, pre-publish).

### `main.bi_output.bi_output_moneyfarm_customers` (EXTERNAL, 4 cols, ~96K rows)
**Granularity**: one row per `GCID` (eToro Global Customer ID).
**Columns**:
- `GCID` (LONG) — primary key.
- `MF_Journey_Beginning` (DATE) — earliest date this GCID was observed as a MoneyFarm customer (NOT the eToro account creation).
- `Date_Source_Type` (STRING) — provenance: `Live Event (New)` / `Bronze Table (Recent)` / `Silver AUM Snapshot (Legacy)` (the 3-rung ladder; the snapshot fact uses a 2-rung subset).
- `UpdateDate` (TIMESTAMP) — refresh marker.

**Owner**: BI / data-platform.
**Detailed wiki**: `knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_customers.md`.

### `main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` (EXTERNAL Delta, 10 cols, 40,885 rows)
**Granularity**: one row per `(GCID, PortfolioID)`, refreshed daily.
**Owner**: `eyalbo@etoro.com` (per `DESCRIBE EXTENDED`).
**Location**: `abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/BI_OUTPUT/Moneyfarm/Fact_Portfolio_Snapshot`.
**Columns** (full doc in cached wiki):
- `GCID` (LONG) — eToro PK; FK to `bronze_sub_accounts_accounts.gcid` filter `providerName='Moneyfarm'`.
- `PortfolioID` (STRING UUID v4) — one GCID can hold many portfolios (1:N).
- `Product_Onboarding_Date` (DATE) — onboarding date for this product (NOT row-insert).
- `Product_Name` (STRING) — `Managed ISA` / `DIY ISA` / `Cash ISA`.
- `Current_Market_Value_GBP` (DECIMAL) — current GBP NAV; 0.00 common (freshly-onboarded or pre-NAV).
- `Portfolio_Risk_Level` (STRING) — opaque code (`P0`/`P7`/NULL); band semantics not Confluence-anchored.
- `Last_Risk_Level_Change_Date` (STRING) — usually NULL.
- `Previous_Risk_Level` (STRING) — usually NULL.
- `Source_Type` (STRING) — `Live Event` (49,189) / `Silver History` (1,797).
- `UpdateDate` (TIMESTAMP) — snapshot marker.

**Tier breakdown deployed**: 4 / 10 Tier-1 (Confluence-anchored) + 4 Tier-4 + 2 Tier-5 reviewed. Three Tier-4 columns (`Portfolio_Risk_Level`, `Last_Risk_Level_Change_Date`, `Previous_Risk_Level`) are NOT deployed in UC pending analyst confirmation.
**Detailed wiki**: `knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_fact_portfolio_snapshot.md`.

### `main.bi_output.bi_output_moneyfarm_fact_transactions` (EXTERNAL, ~per-event)
**Granularity**: one row per MoneyFarm event. Per-event grain (NOT day-aggregated like `v_moneyfarm_mimo`).
**Key columns**:
- `event_correlation_ID` (STRING) — true per-event PK, format `{EventId UUID}_{EventType}`.
- `GCID` (LONG).
- `PortfolioID` (STRING UUID v4) — joins to `fact_portfolio_snapshot.PortfolioID`.
- `TransactionType` (STRING) — `Deposit` / `Withdrawal` / `Full Withdrawal` (the only place where Full Withdrawal is distinguished — the live EH only has `PORTFOLIO_WITHDRAW`).
- `Transaction_Date` (DATE).
- `Amount_GBP` (DOUBLE).
- `TransactionId` (STRING) — hash of `(GCID, valueDate, Amount)` per Confluence XP/13551468545. **Not a true PK** (collisions possible); use `event_correlation_ID` for uniqueness.
- `UpdateDate` (TIMESTAMP).

**Detailed wiki**: cached in `knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_fact_transactions.md` (companion to the snapshot).

## Gold staging — `bi_output_stg.*`

| Object | Notes |
|--------|-------|
| `bi_output_stg.bi_output_moneyfarm_customers` | Pre-publish staging mirror — same shape as the production version |
| `bi_output_stg.bi_output_moneyfarm_fact_portfolio_snapshot` | Pre-publish staging mirror |
| `bi_output_stg.bi_output_moneyfarm_fact_transactions` | Pre-publish staging mirror |

Use the production `bi_output.*` versions for analytics; staging is for the publish pipeline only.

## Bizops curated — `bizops_output.*`

These are the DDR-side cuts (different consumer than `bi_output.*` which is BI-team consumer). Two production tables exist:

| Object | Notes |
|--------|-------|
| `bizops_output.bizops_output_moneyfarm_fact_portfolio_snapshot` | Bizops cut of the snapshot fact — likely identical shape to `bi_output.*` but with the bizops audit columns. Not detailed in cached wiki. |
| `bizops_output.bizops_output_moneyfarm_fact_transactions` | Bizops cut of the transactions fact. |

**Note**: `bizops_output.*` does **NOT** contain a `customers` table — that's only on `bi_output.*`. The customer dim equivalent on bizops sits in the staging schema:

## Bizops staging — `bizops_output_stg.*`

| Object | Notes |
|--------|-------|
| `bizops_output_stg.bizops_output_moneyfarm_dim_customers` | The bizops side's customer dimension — **distinct from `bi_output_moneyfarm_customers`** (which is on `bi_output.*` not `bizops_output.*`). May carry additional bizops-curated attrs not present on bi_output side. Worth `DESCRIBE`-ing if a query needs customer-level attrs that are missing from `bi_output_moneyfarm_customers`. |
| `bizops_output_stg.bizops_output_moneyfarm_fact_portfolio_snapshot` | Pre-publish staging |
| `bizops_output_stg.bizops_output_moneyfarm_fact_transactions` | Pre-publish staging |

## KPI prep views — `etoro_kpi_prep.*`

| View | Cols | Granularity | Comment |
|------|------|-------------|---------|
| `v_moneyfarm_aum` | 7 | `(date, gcid)` | Daily AUM (GBP + USD), portfolio_count, is_funded — silver-AUM-fed |
| `v_moneyfarm_mimo` | 12 | `(date, gcid)` | Daily MIMO (deposits + withdrawals + net) — live-event-fed; Oct 2025+ |
| `v_moneyfarm_fees` | 5 | `(date, gcid)` | **Placeholder** — `WHERE 1=0`, all NULL CASTs |

Full DDLs in `moneyfarm-views-architecture.md`. Detailed per-view wiki at `knowledge/uc_domains/moneyfarm/schemas/etoro_kpi_prep/Views/v_moneyfarm_*.md`.

## Cross-domain joins (where MoneyFarm meets eToro)

| Other-domain table | Join column on MoneyFarm side | Join column on eToro side | Filter required |
|---|---|---|---|
| `main.bi_db.bronze_sub_accounts_accounts` | `GCID` (or `externalUserId` from raw bronze) | `gcid` (or `externalUserId`) | `providerName='Moneyfarm'` (capital M, single word) |
| `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` | (event-level) | `EventPayloadRowData.EventMetadata.Gcid` | `EventPayloadRowData.ProviderName='Moneyfarm'` AND `EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW',…)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `GCID` | `RealCID` | (none — `RealCID = GCID` semantics for resolved customers) |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | (FX leg) | `InstrumentID = 2` (GBP/USD) | `InstrumentID = 2` |

Full join pattern with SQL bodies in `moneyfarm-data-patterns.md`.

## Tables explicitly NOT in this skill's scope

- `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` — out-of-domain (compliance schema). The MoneyFarm prep views filter into it; it itself belongs to `domain-customer-and-identity` / cross-domain.
- `main.bi_db.bronze_sub_accounts_accounts` — out-of-domain (bi_db). Identity-bridge concern.
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` — out-of-domain (dwh). Customer dim concern.
- All Synapse-side BI_DB tables (e.g. `BI_DB_DDR_Fact_AUM`, `BI_DB_DDR_Fact_MIMO_AllPlatforms`) — DDR roll-up is in `domain-payments/mimo-panel-and-ddr.md`.

## Inventory query (reproduce)

```sql
SELECT table_schema, table_name, table_type
FROM main.information_schema.tables
WHERE LOWER(table_name) LIKE '%money_farm%'
   OR LOWER(table_name) LIKE '%moneyfarm%'
   OR LOWER(table_name) LIKE '%money%farm%'
ORDER BY table_schema, table_name
```

Result captured 2026-05-31: 23 rows.
