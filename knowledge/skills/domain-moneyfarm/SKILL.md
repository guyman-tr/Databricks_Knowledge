---
name: domain-moneyfarm
description: "MoneyFarm UK ISA / robo-advisor platform via Cosmos-MoneyFarm and the
  sub-accounts EventHub stream — eToro's 2024 acquisition of the digital wealth-manager
  Moneyfarm. Anchored on three production prep views in main.etoro_kpi_prep that feed
  the cross-platform DDR: v_moneyfarm_aum (daily per-(date, GCID) GBP AUM with USD
  conversion via fact_currencypricewithsplit InstrumentID=2; portfolio_count and
  is_funded), v_moneyfarm_mimo (per-(date, GCID) deposit and withdrawal events from
  compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts filtered
  ProviderName='Moneyfarm' and EventType IN PORTFOLIO_DEPOSIT/PORTFOLIO_WITHDRAW;
  is_ftd derived as min-deposit-date per GCID), and v_moneyfarm_fees — which is
  currently a PLACEHOLDER (WHERE 1=0, all NULL casts). MoneyFarm fees are NOT
  ingested into UC today; the customer-facing fee schedule lives in Confluence as
  knowledge but no per-portfolio fee deduction lands in any UC table. Sources are
  the Cosmos-MoneyFarm export (general.bronze_moneyfarm_users — 24K rows with
  _rid/_self/_etag CosmosDB metadata), the SFTP-fed silver AUM
  (money_farm.silver_moneyfarm_etoro_mf_aum), the curated bizops facts
  (bi_output.bi_output_moneyfarm_customers — 99K rows / fact_portfolio_snapshot 40K /
  fact_transactions per-event), and the auxiliary Fivetran reference
  (experience.bronze_fivetran_experience_money_farm_product_names — 9 rows).
  Identity bridge to eToro GCID is via bi_db.bronze_sub_accounts_accounts with
  providerName='Moneyfarm' (capital M, single word — events store the
  single-word lowercase variant). Three product lines as of Oct 2025:
  Stocks-and-Shares ISA (March 2023, points to MoneyFarm public pricing),
  Managed ISA (Oct 21 2025, tiered AUM fee documented Confluence-side), and
  eToro Cash ISA (Oct 21 2025, Standard Variable Rate with 12-month boost).
  Eligibility per V2 HLD: countryID=UK + designatedRegulation=FCA +
  playerStatus=Normal + at-least-one-Approved-deposit + non-legacy
  (legacy = registered to Moneyfarm from eToro funnel pre-acquisition).
  Payments dictionary: AccountTypeID=4, FundingTypeID=44, PaymentMethodTypeId=44,
  FTDPlatformID=4 are all 'MoneyFarm' across the etoro DB / MoneyBusDB /
  CustomerFinanceDB; DefaultCurrency=5=GBP. Surfaces Ben Thompson's five
  ISA-project Tableau workbooks under UK/ISA: AM-ISA-Performance-V1,
  ISA-Focussed-Acquisition-Funnel, ISA-Market-Value-SFTP-data,
  ISA-MIMO-Events-API-data, UK-Funded-by-MoneyFarm-and-eToro;
  plus the CS-team ISACustomerLookupDashboard (CID-level MoneyFarm
  External-ID lookup). Knowledge owner: Ben Thompson (UK analyst).
  Cross-references the UK BA Genie space [WIP]
  (id 01f122020cb3178380de2efa0b990279 — 30 tables / 52 join_specs;
  16 of them touch MoneyFarm objects with explicit instructions
  about providerName='Moneyfarm' filter and 1:N GCID-to-PortfolioID
  cardinality)."
triggers:
  - moneyfarm
  - money farm
  - money-farm
  - MoneyFarm
  - Moneyfarm
  - ben thompson
  - benth
  - uk isa
  - isa
  - individual savings account
  - stocks and shares isa
  - managed isa
  - cash isa
  - cosmos moneyfarm
  - cosmos-moneyfarm
  - cosmosdb moneyfarm
  - robo advisor
  - robo-advisor
  - digital wealth management
  - moneyfarmUserId
  - externalUserId
  - portfolio_id moneyfarm
  - PORTFOLIO_DEPOSIT
  - PORTFOLIO_WITHDRAW
  - PORTFOLIO_CREATED
  - USER_CASH_ACCOUNT_ACTIVATED
  - sub-accounts eventhub
  - sub-accounts event hub
  - bronze_event_hub_prod_event_streaming_we_sub_accounts
  - sub-accounts-experience-worker
  - AccountTypeID 4
  - FundingTypeID 44
  - PaymentMethodTypeId 44
  - FTDPlatformID 4
  - providerName moneyfarm
  - v_moneyfarm_aum
  - v_moneyfarm_mimo
  - v_moneyfarm_fees
  - silver_moneyfarm_etoro_mf_aum
  - bronze_moneyfarm_users
  - bi_output_moneyfarm_customers
  - bi_output_moneyfarm_fact_portfolio_snapshot
  - bi_output_moneyfarm_fact_transactions
  - moneyfarm_population_grouped
  - bronze_fivetran_experience_money_farm_product_names
  - UK BA Genie space
  - UK BA WIP
  - ISACustomerLookupDashboard
  - ISACustomerDashboard
  - moneyfarm aum
  - moneyfarm mimo
  - moneyfarm fees
  - moneyfarm ftd
  - moneyfarm cashback
  - moneyfarm acquisition funnel
required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.general.bronze_moneyfarm_users
  - main.experience.bronze_fivetran_experience_money_farm_product_names
  - main.bi_db.bronze_sub_accounts_accounts
  - main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
sub_skills:
  - source-tables.md
  - metric-definitions.md
  - views-architecture.md
  - dashboard-queries.md
  - data-patterns.md
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# MoneyFarm Skill (UK ISA / robo-advisor / Cosmos-sourced)

## When to Use
Load this skill when the user asks about:
- MoneyFarm AUM, MIMO, FTD, Funded customers, or fees
- The eToro UK ISA product line (Stocks-and-Shares ISA / Managed ISA / Cash ISA)
- Ben Thompson's `UK/ISA` Tableau workbooks (`AM - ISA Performance V1`, `ISA Focussed Acquisition Funnel`, `ISA Market Value (SFTP data)`, `ISA MIMO (Events API data)`, `UK Funded - by MoneyFarm & eToro`)
- The CS-team `ISACustomerLookupDashboard` MoneyFarm External-ID lookup
- The three `etoro_kpi_prep.v_moneyfarm_*` prep views
- The `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` MoneyFarm event stream (`PORTFOLIO_DEPOSIT`, `PORTFOLIO_WITHDRAW`, `PORTFOLIO_CREATED`, `USER_CASH_ACCOUNT_ACTIVATED`)
- The Cosmos-MoneyFarm bronze ingest (`general.bronze_moneyfarm_users`)
- The SFTP-fed silver AUM (`money_farm.silver_moneyfarm_etoro_mf_aum`)
- The bizops fact tables (`bi_output.bi_output_moneyfarm_*`)
- Identity bridge from MoneyFarm `externalUserId` / `moneyfarmUserId` to eToro `GCID` via `bi_db.bronze_sub_accounts_accounts` with `providerName = 'Moneyfarm'`
- Payment-side dictionary: `AccountTypeID = 4` / `FundingTypeID = 44` / `PaymentMethodTypeId = 44` / `FTDPlatformID = 4` all = MoneyFarm
- Eligibility: `countryID=UK + designatedRegulation=FCA + playerStatus=Normal + ≥1 Approved deposit + non-legacy`
- The UK BA Genie space (id `01f122020cb3178380de2efa0b990279`) — 16 join_specs touching MoneyFarm objects
- DDR rows where `AccountTypeID = 4` (MoneyFarm contribution to `BI_DB_DDR_Fact_AUM` and `BI_DB_DDR_Fact_MIMO_AllPlatforms`)

## Scope
**In scope:** Cosmos-MoneyFarm bronze ingest, SFTP silver AUM, sub-accounts EventHub MoneyFarm event stream, bizops customers / portfolio_snapshot / transactions facts, the 3 prep views, MoneyFarm V2 onboarding eligibility, Ben Thompson's 5 ISA workbooks, the UK BA Genie space joins, the MoneyFarm-side payments-dictionary mappings (AccountTypeID=4 et al.), the documented Confluence fee schedule (informational only — not data-backed).

**Out of scope:**
- eToro main-platform trading → `domain-trading`
- eToro main-platform deposits/withdrawals → `domain-payments` (`mimo-panel-and-ddr`) — but note MoneyFarm MIMO does roll up into `BI_DB_DDR_Fact_MIMO_AllPlatforms`
- eToro main-platform revenue (PFOF, transactional fees) → `domain-revenue-and-fees`
- Customer master / GCID semantics → `domain-customer-and-identity`
- Spaceship (separate acquired robo, BigQuery-sourced not Cosmos) → `domain-spaceship`
- Compliance / KYC for MoneyFarm-side onboarding (sits on the MoneyFarm production stack, not in eToro UC) → out of scope entirely
- Booked fee revenue (Finance ledger) — not in UC; ask Finance directly

Last verified: 2026-05-31

## Sub-File Index

| File | Load when | Contents |
|------|-----------|----------|
| `source-tables.md` | Exploring raw MoneyFarm UC data, "what table holds X", schema/PII lookups | 21-table catalog across 9 schemas (`general` / `experience` / `money_farm` / `money_farm_stg` / `bi_output` / `bi_output_stg` / `bizops_output` / `bizops_output_stg` / `regtech_stg` / `etoro_kpi_prep`) — Cosmos→Bronze→Silver→Gold ladder with PII flags and CosmosDB-metadata callouts |
| `metric-definitions.md` | Computing KPIs, QA, "how is MoneyFarm FTD calculated" | AUM (GBP / USD), MIMO (deposits / withdrawals / net flow), FTD (`is_ftd` per the live event stream — Oct 2025 onwards), Funded (`Current_Market_Value_GBP > 0`), Cohort (V2-eligibility scope, ProductName segmentation, Source_Type provenance), Fee schedule (informational — Managed ISA tiered AUM fee from Confluence; Cash ISA SVR + boost; Stocks-and-Shares points to MoneyFarm public pricing). **Includes the explicit warning that fee data is NOT in UC.** |
| `views-architecture.md` | Building or fixing prep-view-backed queries, DDR root-cause | Full DDLs + CTE walkthrough for `v_moneyfarm_aum`, `v_moneyfarm_mimo`, `v_moneyfarm_fees` (placeholder) — including the GBP/USD FX join, the `compliance.bronze_event_hub_*` source filter, and the per-CTE row-grain reasoning |
| `dashboard-queries.md` | Tableau dashboard work, replicating Ben's charts, mapping a KPI back to UC | Ben Thompson's 5 ISA workbooks (lineage, custom SQL preamble, field inventory) + the UK BA Genie space WIP (16 MoneyFarm join_specs verbatim) + 6 sample queries lifted from existing wiki and adapted |
| `data-patterns.md` | Writing any MoneyFarm SQL query | Reusable CTEs: `providerName='Moneyfarm'` filter (case-sensitive), AccountTypeID=4 join, GBP→USD via fact_currencypricewithsplit InstrumentID=2, transaction-ID hash(GCID, valueDate, Amount), 1:N GCID-to-PortfolioID handling, Source_Type='Live Event' vs 'Silver History' vs 'Bronze Table (Recent)' segmentation, dedup by `SourceFile` for double-send days |

**Routing guidance**: Most questions need `data-patterns.md` (CTEs) + one of the others. Load `data-patterns.md` first when writing queries; load `views-architecture.md` first when reading existing DDR / prep-view logic; load `dashboard-queries.md` when replicating a Ben Thompson workbook.

## Product Structure

eToro acquired MoneyFarm in 2024. MoneyFarm is a UK-headquartered digital wealth-management / robo-advisor platform that runs its own production stack on **CosmosDB** (server: `Cosmos-MoneyFarm`). MoneyFarm ships data into eToro's lake **only as a read-only feed** — there is no write-back. This is fundamentally different from Spaceship (BigQuery-sourced) so even though both are "acquired-platform robo-advisors", the bronze-table shapes are NoSQL key-value blobs vs Spaceship's relational shapes.

**Three customer-facing ISA product lines** (per the CS Confluence page `11942330382`, last updated 2026-04-24):

| Product line | Launch | Description | Fee model |
|---|---|---|---|
| **Stocks & Shares ISA** | Mar 7, 2023 | Tax-free brokerage-style ISA (UK-eligible UK stocks, ETFs, bonds, mutual funds — NO CFDs, NO crypto). Two flavours since Phase 3 (Feb 2025): **DIY** (self-directed) and **Managed-by-us** (Moneyfarm experts allocate one of seven risk-tiered portfolios). | "Same fees as standard MoneyFarm pricing" — points externally to `moneyfarm.com/uk/pricing/`. **Not documented in eToro Confluence.** |
| **Managed ISA** | Oct 21, 2025 | Pure robo-advisor — questionnaire-driven investor profile, ESG vs regular asset mix, time horizon, monthly contribution. Risk band determines portfolio composition (similar pattern to a Smart Portfolio). | **Tiered AUM fee, documented in Confluence** — Under £100K: 0.75% / 0.70% / 0.65% / 0.60% across £10K / £20K / £50K / £100K bands. Over £100K: 0.45% / 0.40% / 0.35% across £250K / £500K / £500K+ bands. |
| **eToro Cash ISA** | Oct 21, 2025 | Tax-free cash savings — interest accrues, no investment risk. | Standard Variable Rate + 12-month boost (0.80% Oct 22 2025–Mar 24 2026; 1.00% Mar 25–Apr 30 2026), then reverts to SVR. Boosted-rate eligibility requires keeping ≥£500 in account and ≤3 withdrawals over 12 months. |

**Cohort segmentation**: per the V2 HLD, eligibility is restricted to `countryID=UK + designatedRegulation=FCA + playerStatus=Normal + ≥1 Approved deposit + non-legacy`. **"Legacy users"** are eToro customers who registered to MoneyFarm directly (pre-acquisition, via the old eToro→Moneyfarm funnel) — they're routed to `https://app.moneyfarm.com/gb/sign-in` rather than the V2 SSO flow.

**Annual ISA allowance** is set by HMRC: £20,000 for tax year 2025-04-06 → 2026-04-05. Customers can split across Cash / S&S / other ISAs.

**Cashback offers (FTD / first-transfer)** are NOT fee revenue but a marketing cost on eToro's side. Per CS Confluence page:
- New cashback (Oct 22 2025 – Apr 30 2026): 2% / 2.5% / 3% banded by Club tier (Bronze-Silver-Gold / Platinum-Plus / Diamond), capped at £10K cashback. Paid into ISA cash balance by Feb 28 2026. Withdrawing principal pre-24-months claws the cashback back.
- Old cashback (Feb 4 – Apr 30 2025): 2% on min £1K invested, capped at £5K (£250K investment cap).

## Layer Architecture in UC

| Layer | UC Schema | Table family | What it is |
|---|---|---|---|
| Bronze (raw Cosmos) | `general.*` | `bronze_moneyfarm_users` | 24K user docs from Cosmos export with `_rid`/`_self`/`_etag`/`_attachments` metadata. **PII-bearing.** |
| Bronze (Fivetran aux) | `experience.*` | `bronze_fivetran_experience_money_farm_product_names` | 9-row product-name reference table |
| Silver (SFTP-fed) | `money_farm.*` | `silver_moneyfarm_etoro_mf_aum`, `silver_moneyfarm_historical_events` | Per-(`etr_ymd`, `Portfolio_Id`) AUM rollup from MoneyFarm's nightly SFTP drop (`SourceFile` like `ETORO-MF-AUM-...`). The historical_events table holds reconstructed pre-stream events. |
| Silver staging | `money_farm_stg.*` | `moneyfarm_population_grouped`, `silver_moneyfarm_etoro_mf_aum` | Population-grouped view + staging copy of silver AUM |
| Gold (bizops curated) | `bi_output.*` | `bi_output_moneyfarm_customers`, `bi_output_moneyfarm_fact_portfolio_snapshot`, `bi_output_moneyfarm_fact_transactions` | 99K customers / 40K portfolio rows / per-event transactions facts. **Already have rich UC comments deployed** (Tier-1 from Confluence anchors). |
| Gold staging | `bi_output_stg.*` | mirror of `bi_output.*` | Pre-publish staging |
| Bizops output | `bizops_output.*`, `bizops_output_stg.*` | `bizops_output_moneyfarm_*` | DDR-side cuts |
| Regtech | `regtech_stg.*` | `silver_moneyfarm_etoro_mf_aum_parquet` | Parquet-format silver for regtech consumers |
| KPI prep | `etoro_kpi_prep.*` | `v_moneyfarm_aum`, `v_moneyfarm_mimo`, `v_moneyfarm_fees` | Three rollup views feeding cross-platform DDR. **`v_moneyfarm_fees` is a placeholder.** |

**Naming inconsistency vs Spaceship**: MoneyFarm's KPI views live in `etoro_kpi_prep.*` (NOT `etoro_kpi.*` like Spaceship). Both schemas exist; both are valid; this asymmetry is historical.

## Identity Bridge

| MoneyFarm-side ID | UC location | Cross-ref to eToro GCID |
|---|---|---|
| `externalUserId` (alias `moneyfarmUserId`) | `general.bronze_moneyfarm_users` (raw Cosmos export); `bi_output.bi_output_moneyfarm_customers.GCID` (already-resolved by the bizops pipeline) | Via `main.bi_db.bronze_sub_accounts_accounts` filter `providerName = 'Moneyfarm'` (capital M, single word). The bridge pattern is identical to Spaceship's. |
| `Identifier_Value` (in silver AUM) | `money_farm.silver_moneyfarm_etoro_mf_aum.Identifier_Value` | Same — joins to `bronze_sub_accounts_accounts.externalUserId` per UK BA Genie space join_spec. |
| `gcid` (already-resolved on the event stream) | `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts.EventPayloadRowData.EventMetadata.Gcid` | Direct — no bridge needed. The deposit-event HLD (`MF additions - Support for Money Farm Deposit Event`, Confluence page `13551468545`) describes how the `sub-accounts-experience-worker` enriches events with GCID before they land. |

See `domain-customer-and-identity/SKILL.md` for the full identity-layer model.

## Critical Warnings

### Tier 1 — Silent wrong numbers

1. **`v_moneyfarm_fees` is a PLACEHOLDER** — the DDL is literally `SELECT ... WHERE 1=0` returning all NULL casts (`date`, `dateid`, `gcid`, `total_fees_gbp`, `total_fees_usd`). **No fee data exists in any UC MoneyFarm table.** Querying this view will always return zero rows. The customer-facing fee schedule lives in Confluence (page `11942330382`) but is informational only — see `metric-definitions.md` for the documented tiers. For booked fee revenue, ask Finance directly; it is not in eToro UC.
2. **MoneyFarm fees do NOT flow into `BI_DB_DDR_Fact_Revenue_Generating_Actions`** — the DDR revenue fact is eToro-native (PFOF, TX fees, overnight) only. Don't expect MoneyFarm fee rows to appear there.
3. **MoneyFarm AUM and MIMO DO roll up** into `BI_DB_DDR_Fact_AUM` and `BI_DB_DDR_Fact_MIMO_AllPlatforms` respectively. Cross-platform AUM/MIMO totals therefore include MoneyFarm; product-line drill-downs filter on `AccountTypeID = 4`.
4. **`providerName = 'Moneyfarm'` is the canonical case** — capital M, single word, no space. The source events store the single-word lowercase variant. **Don't use `'MoneyFarm'`, `'Money Farm'`, or `'money_farm'`.** This casing matters in the WHERE clause of `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` filter, in the `bi_db.bronze_sub_accounts_accounts` join filter, and everywhere `EventPayloadRowData.ProviderName` appears. The 3 prep views encode the correct case; raw-bronze queries must match it manually.
5. **`v_moneyfarm_mimo` only has data from Oct 2025 onwards** — the live event-stream pipeline (sub-accounts EventHub → sub-accounts-experience-worker → MoneyFarm bronze) only started feeding deposit/withdrawal events in October 2025. Pre-Oct-2025 deposits are NOT in this view. For the historical universe of MoneyFarm customers, use `bi_output.bi_output_moneyfarm_customers` (99K rows; spans the back-fill via `Date_Source_Type='Bronze Table (Recent)'` and `'Silver AUM Snapshot (Legacy)'`).
6. **`AccountTypeID = 4 = MoneyFarm`** in eToro DB / MoneyBusDB / CustomerFinanceDB. Same value flows through as **`FundingTypeID = 44`**, **`PaymentMethodTypeId = 44`**, and **`FTDPlatformID = 4`** (the latter being the join key on `Dim_Customer.FTDPlatformID` for "first deposit happened on MoneyFarm"). All four IDs are MoneyFarm; the choice of column depends on which dictionary table you join. `DefaultCurrency = 5 = GBP` per `Dictionary.FundingType`.
7. **One GCID can hold many `PortfolioID`s** — Managed ISA + DIY ISA + Cash ISA can co-exist for the same customer (1:N cardinality). Joining `bi_output_moneyfarm_fact_portfolio_snapshot.GCID = silver_moneyfarm_etoro_mf_aum.GCID` produces ONE row per (GCID, date, portfolio) — careful when aggregating to customer-level. Per the UK BA Genie instruction: *"A single GCID can have multiple Portfolios (PortfolioIDs) and rows for each portfolio in each table. Therefore when joining on GCID there are multiple different rows for a GCID on left and right."*
8. **`bi_db.bronze_sub_accounts_accounts` is 1:N on GCID** — must filter `providerName = 'Moneyfarm'` to keep it as the "one" side of the relationship. Per the UK BA Genie instruction: *"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."*
9. **No timezone conversion in `v_moneyfarm_mimo`** — `date` is `EventMetadata.CreatedAt` UTC truncated to date. Spaceship's MIMO converts UTC→Sydney; MoneyFarm does NOT. UK is GMT/BST so UTC is close most of the year, but cross-domain panels need to handle the discrepancy.
10. **Currency is GBP, not USD** — `silver_moneyfarm_etoro_mf_aum.Market_Value` is GBP; `bi_output_moneyfarm_fact_portfolio_snapshot.Current_Market_Value_GBP` is GBP; the deposit / withdrawal amounts in the event stream are GBP. The 3 prep views convert to USD via `fact_currencypricewithsplit InstrumentID=2` (GBP/USD pair) using `(Ask + Bid) / 2` mid-rate. **Missing rate row → USD = 0.0** (the views `COALESCE` to 0). Always check `total_deposits_gbp > 0 AND total_deposits_usd = 0` to detect missing-rate days.

### Tier 2 — Aggregate / interpretation

11. **`Source_Type` provenance flag in `bi_output_moneyfarm_fact_portfolio_snapshot`** — values are `Live Event` (49,189 rows: streamed from sub-accounts EH; `PORTFOLIO_DEPOSIT` / `USER_CASH_ACCOUNT_ACTIVATED`), `Bronze Table (Recent)` (45,270 rows), `Silver History` (1,797 rows: back-fill from silver AUM). For "live" MoneyFarm activity counts, filter `Source_Type = 'Live Event'`. The same provenance flag exists in `bi_output_moneyfarm_customers.Date_Source_Type` with values `'Live Event (New)'` / `'Bronze Table (Recent)'` / `'Silver AUM Snapshot (Legacy)'` (note the slight value-string variations).
12. **`Current_Market_Value_GBP = 0.00` is common** — interpreted as freshly-onboarded portfolios where the daily NAV mark hasn't run yet OR portfolios that have been fully withdrawn (`PortfolioDefunded = TRUE`). Always pair with `Source_Type` and `Product_Onboarding_Date` (or Ben's `PortfolioCreatedDate` / `PortfolioCreatedDate_Source` lineage fields) for context.
13. **`Portfolio_Risk_Level` semantics not Confluence-anchored** — values like `P0` / `P7` / NULL appear in samples; the public MoneyFarm site implies P0 = Cash and P7 = Equity-heavy, but this mapping is NOT confirmed by any cached eToro doc. Treat as opaque code unless analyst confirms.
14. **`TransactionId` in `bi_output_moneyfarm_fact_transactions` is the hash** — generated by `sub-accounts-experience-worker` as `hash(GCID, valueDate, Amount)` per the deposit-event HLD. Two transactions with the same triple collide. The `event_correlation_ID` is the genuine per-event PK (`{EventId UUID}_{EventType}`).
15. **`Full Withdrawal` is NOT distinguished in `v_moneyfarm_mimo`** — the upstream EH stream has only `PORTFOLIO_WITHDRAW` (no separate full-withdrawal event type), so the view aggregates them with normal withdrawals into `total_withdrawals_gbp` / `count_withdrawals`. The 3-value `TransactionType` enum (`Deposit` / `Withdrawal` / `Full Withdrawal`) lives only on `bi_output_moneyfarm_fact_transactions` — use that table to distinguish.
16. **`is_ftd = TRUE` only on dates where the user actually had a deposit** — unlike Spaceship's MIMO there is no orphan-FTD row synthesis. `is_ftd = TRUE` always coincides with `total_deposits_gbp > 0`.
17. **MoneyFarm Cash ISA "fees" are interest payouts to customers, not fees from customers** — the boost-rate offer (0.80% / 1.00% over SVR) is a marketing cost, not revenue. Don't include it in any "fee revenue" aggregation.

### Tier 3 — Operational

18. **Cosmos metadata columns in `bronze_moneyfarm_users`** — `_rid` / `_self` / `_etag` / `_attachments` are CosmosDB internal IDs and should be ignored in analytics SQL. They're not business columns.
19. **Schema split is intentional but non-obvious** — MoneyFarm assets live across 9 schemas (`general` / `experience` / `money_farm` / `money_farm_stg` / `bi_output` / `bi_output_stg` / `bizops_output` / `bizops_output_stg` / `regtech_stg`) plus the 3 `etoro_kpi_prep` views. The `_stg` schemas are pre-publish staging; the production-grade tables for analytics are the non-`_stg` versions. See `source-tables.md` for the full table-to-schema mapping.
20. **`SourceFile` deduplication on silver AUM** — Ben Thompson's custom SQL preamble explicitly notes: *"there are sometimes instances of 'double sends' on one day creating two rows, so taking the row with the most recent SourceFile"*. The SourceFile string format is `ETORO-MF-AUM-{date}-{seq}`. Always dedupe by `(etr_ymd, Portfolio_Id)` taking max `SourceFile` lexicographically when reading raw silver.
21. **Daily refresh notebook** — `databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb` (Jupyter, last modified 2025-05-13) writes the silver AUM. The bizops `bi_output_moneyfarm_*` family is written by a separate BI-team pipeline (no source SQL in the local DataPlatform repo).

## Three Prep Views (the DDR backbone)

| View | Cols | Purpose | Source bronze tables |
|---|---|---|---|
| `v_moneyfarm_aum` | 7 | One row per (`date`, `gcid`) — daily MoneyFarm AUM (GBP + USD), portfolio_count, is_funded | `money_farm.silver_moneyfarm_etoro_mf_aum` + `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (InstrumentID=2 for GBP/USD) |
| `v_moneyfarm_mimo` | 12 | One row per (`date`, `gcid`) — MIMO with FTD detection, deposit/withdrawal counts and amounts | `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` (filtered `ProviderName='Moneyfarm'` and `EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')`) + `fact_currencypricewithsplit` |
| `v_moneyfarm_fees` | 5 | **PLACEHOLDER** — `WHERE 1=0`, all NULLs. No fee data ingested. | None — view body is `SELECT NULL CASTS WHERE 1=0` |

Full DDLs and CTE walkthroughs in `views-architecture.md`.

## Tableau Dashboard Reference

**Repository**: `https://reports.etorocorp.com/#/projects/76` (UK project) → project 485 (`UK/ISA`). **5 active workbooks**, all owned by Ben Thompson:

| Workbook | ID | Last modified | What it shows | Notes |
|---|---|---|---|---|
| **AM - ISA Performance V1** | 7741 | 2026-02-26 | Account-Manager attribution + 30-day pre-FTF contact flags + portfolio funding state | "AM" = Account Manager (NOT Asset Management). 27 fields, 2 sheets (`CID Level`, `AM Aggregated`), Custom SQL on Silver-first portfolio panel. **No fee fields.** |
| **ISA Focussed Acquisition Funnel** | TBD | 2026-04-30 | Eligible → Registered → FTF onboarding funnel | Most recently updated of the 5 workbooks. |
| **ISA Market Value (SFTP data)** | TBD | 2026-02-26 | AUM trend from `silver_moneyfarm_etoro_mf_aum` (the SFTP-fed silver) | "SFTP data" = the nightly Moneyfarm-side SFTP drop, not the EventHub stream. |
| **ISA MIMO (Events API data)** | TBD | 2026-03-25 | Deposits + withdrawals from the EventHub stream | "Events API data" = the live `compliance.bronze_event_hub_*` stream, powering `v_moneyfarm_mimo`. |
| **UK Funded - by MoneyFarm & eToro** | TBD | 2026-04-08 | Cross-product UK funded customers (MF + eToro main) | UK BA cross-platform pivot. |

Plus the CS-team **`ISACustomerLookupDashboard / ISACustomerDashboard`** (referenced from CS Confluence page `13209534657`) — used by CS TLs for MoneyFarm External-ID lookup during ISA Tmail handling.

Full per-workbook field inventory + custom-SQL preambles + the UK BA Genie space's 16 MoneyFarm join_specs in `dashboard-queries.md`.

## ETL Pipeline (one-paragraph summary)

MoneyFarm runs its own production stack on **CosmosDB** (`Cosmos-MoneyFarm` server). Two parallel ingest paths land in eToro UC: (1) **the Cosmos export path** — `Cosmos-MoneyFarm/users` → `general.bronze_moneyfarm_users` (24K rows with `_rid`/`_self`/`_etag` metadata) — feeding analyst-only PII access; (2) **the SFTP path** — Moneyfarm-side nightly SFTP drop (`SourceFile` like `ETORO-MF-AUM-{date}-{seq}`) → `databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb` (Jupyter, daily) → `money_farm.silver_moneyfarm_etoro_mf_aum` — feeding AUM views and Ben's `ISA Market Value (SFTP data)` workbook. Plus a third **live event** path: MoneyFarm-side `PORTFOLIO_DEPOSIT` / `PORTFOLIO_WITHDRAW` / `PORTFOLIO_CREATED` / `USER_CASH_ACCOUNT_ACTIVATED` events → Infra `event-streaming` EventHub (`sub-accounts` entity) → `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` → `sub-accounts-experience-worker` (subscribes via CCM `MoneyfarmEventHubEventTypes = [USER_CASH_ACCOUNT_ACTIVATED, PORTFOLIO_DEPOSIT]`) calls eToro CustomerFinance WebApi for FTD lookup, generates `TransactionId = hash(GCID, valueDate, Amount)`, and publishes to `payments-metrics` Service Bus — feeding `v_moneyfarm_mimo` and Ben's `ISA MIMO (Events API data)` workbook. The bizops `bi_output_moneyfarm_*` fact tables are written by a separate BI-team pipeline that subscribes to the same event stream and back-fills from silver. **No fee deductions land in any of these paths today.**

## Source of Truth

- **MoneyFarm V2 - HLD** (Confluence XP `12216961926`, last updated 2024-02-15) — eligibility criteria, redirect URLs, CCM feature-flag keys, Splunk monitoring index. Full body cached at `knowledge/uc_domains/moneyfarm/_discovery/confluence_pages/...XP__12216961926.md`.
- **MF additions - Support for Money Farm Deposit Event** (Confluence XP `13551468545`) — full event-schema HLD; `sub-accounts-experience-worker` flow; `TransactionId` hash logic; `AccountTypeId=4` and `PaymentMethodTypeId=44` hardcodes; CCM `MoneyfarmEventHubEventTypes` array. Full body cached at `..._XP__13551468545.md`.
- **MoneyFarm - global payments configurations** (Confluence MG `13600227427`, 2025-11-02) — SQL inserts into `Dictionary.AccountTypes`, `Dictionary.FundingType`, `Customer.CutOffDateConfiguration`. Confirms `AccountTypeID=4`, `FundingTypeID=44`, `DefaultCurrency=5`. Full body cached at `..._MG__13600227427.md`.
- **Individual Savings Account (ISA) - MoneyFarm** (Confluence CS `11942330382`, last updated 2026-04-24) — three-product-line description (S&S / Managed / Cash ISA), launch dates, eligibility text, Managed-ISA tiered fee schedule, cashback offers, CS TL procedure with `ISACustomerLookupDashboard` link. **Primary source for the documented fee schedule.**
- **Individual Savings Account (ISA) - MoneyFarm For CS TLs** (Confluence CS `13209534657`, Tier-2) — CS-team operational guide, links to `ISACustomerLookupDashboard`. Full body cached at `..._CS__13209534657.md`.
- **UK BA space [WIP]** Genie space (id `01f122020cb3178380de2efa0b990279`) — 30 tables, **52 join_specs**, 16 of which touch MoneyFarm objects with explicit `instruction` text. The Tier-3 goldmine. Cached at `knowledge/uc_domains/moneyfarm/_discovery/genie_spaces/01f122020cb3178380de2efa0b990279__uk-ba-space-wip.json` (256KB).
- **Existing local domain card** — `knowledge/uc_domains/moneyfarm/_domain_card.md` carries the result of a 6-phase discovery process (P0–P5 done, P6 deferred); `_deploy-index.md` shows 6 deployed wiki files (3 bi_output tables + 3 etoro_kpi_prep views).
- **Existing per-table wiki** — `knowledge/uc_domains/moneyfarm/schemas/{bi_output,etoro_kpi_prep}/{Tables,Views}/*.md` hold full per-column tier-tagged documentation already deployed to UC as ALTER COMMENT statements (Batch 4 deployed 2026-05-04).
- **Existing sub-skill** — `knowledge/skills/domain-revenue-and-fees/revenue-moneyfarm.md` (188 lines) is a revenue-side cut covering similar ground; superseded by this skill (kept as a redirect).
- **Knowledge owner**: **Ben Thompson** (`benth@etoro.com`, UK analyst) — owns the 5 ISA-project Tableau workbooks; primary SME for MoneyFarm KPIs, FTF logic, AM attribution, and the SFTP vs EventHub provenance distinction.

## SMEs (people)

- **Ben Thompson** (`benth@etoro.com`) — UK analyst, owner of the 5 `UK/ISA` Tableau workbooks; primary SME for MoneyFarm KPI logic.
- **Eyal Boas** (`eyalbo@etoro.com`) — owner of `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` and the BI-side bizops pipeline.
- **Itzik Gattegno** (`itzikga@etoro.com`) — author of the global-payments-configurations Confluence page; owns the AccountTypeID/FundingTypeID dictionary inserts.
- **Karina Streger** (`karinast@etoro.com`) — author of the CS-side ISA documentation pages.

## Cross-references shared with other skills

- **DDR / cross-platform AUM**: MoneyFarm AUM rolls up into `BI_DB_DDR_Fact_AUM`. See `domain-payments/mimo-panel-and-ddr.md` for the cross-platform aggregation (eToro + Spaceship + MoneyFarm).
- **DDR / cross-platform MIMO**: MoneyFarm MIMO rolls up into `BI_DB_DDR_Fact_MIMO_AllPlatforms` filtered `AccountTypeID = 4`.
- **Identity bridge**: see `domain-customer-and-identity/SKILL.md` for the full GCID model and the Acquired-platform user IDs lookup.
- **Spaceship comparison**: `domain-spaceship/SKILL.md` covers the parallel BigQuery-sourced robo-advisor. Contrast: Spaceship has UC comments on `v_spaceship_fees` (rich); MoneyFarm has UC comments on the 3 prep views and on the bi_output customers/portfolio_snapshot/transactions facts (also rich, deployed Batch 4 2026-05-04). Spaceship has 0 Genie spaces; MoneyFarm has 3 (UK BA WIP being the goldmine).
- **The placeholder**: when fees do eventually land in UC (e.g. via Finance shipping a booked-fee feed, or via a synthetic-estimator agreed with Ben/Finance), the DDL of `v_moneyfarm_fees` is the natural swap point. The placeholder is intentional — it reserves the surface area in `etoro_kpi_prep` so downstream Tableau/Genie queries against `v_moneyfarm_fees` won't break when populated.

## Skill provenance

Authored 2026-05-31. Source materials:
- 4 cached Confluence pages (3 Tier-1: V2 HLD / Deposit Event HLD / Global Payments Configurations; 1 Tier-2: ISA CS TLs page); 1 additional CS page (`11942330382`) fetched live for the fee schedule.
- 3 prep view DDLs (`SHOW CREATE TABLE`) for `v_moneyfarm_aum`, `v_moneyfarm_mimo`, `v_moneyfarm_fees` (placeholder confirmed).
- UC inventory query (`main.information_schema.tables`) — 21 MoneyFarm tables across 9 schemas.
- UC fee-column scan (`main.information_schema.columns`) — confirmed zero fee columns outside the placeholder view.
- Tableau live browse — UK project (id 76) → ISA sub-project (id 485) → 5 workbooks owned by Ben Thompson, plus the `AM - ISA Performance V1` lineage tab capturing 27 fields and the Custom SQL preamble.
- UK BA Genie space JSON (256KB cached) — 16 MoneyFarm join_specs with explicit `instruction` text.
- Existing local domain card + 6 deployed per-object wiki files + the existing `revenue-moneyfarm.md` sub-skill.

Naming: `domain-moneyfarm` (lowercase one word) is the kebab-case form. The product spelling varies in the source: Confluence and CS use `MoneyFarm` (camel-case, two words); the events stream stores `Moneyfarm` (capital M, single word — this is the canonical case for `providerName` filters); the marketing site uses `Moneyfarm`. **Triggers cover all four spellings.**
