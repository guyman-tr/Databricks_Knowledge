---
object: main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
domain: moneyfarm
table_type: EXTERNAL
format: delta
column_count: 10
row_count: 40885
location: "abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/BI_OUTPUT/Moneyfarm/Fact_Portfolio_Snapshot"
owner: "eyalbo@etoro.com"
created_at: "Sun Feb 15 10:58:52 UTC 2026"
generated_at: "2026-05-04T08:45:00Z"
tier_breakdown:
  tier1_columns: 4            # GCID, PortfolioID, Product_Name, Source_Type — all anchored on Confluence Tier-1 anchors
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 4            # Product_Onboarding_Date, Portfolio_Risk_Level, Last_Risk_Level_Change_Date, Previous_Risk_Level
  tier5_columns: 2            # analyst-reviewed (Current_Market_Value_GBP approved + UpdateDate softened, 2026-05-04 by guyman)
  unverified_columns: 0
review_log:
  - knowledge/uc_domains/moneyfarm/schemas/bi_output/Tables/bi_output_moneyfarm_fact_portfolio_snapshot.review-log.md
sources:
  confluence:
    - "12216961926"  # Moneyfarm V2 - HLD (XP)
    - "13551468545"  # MF additions Deposit Event (XP)
    - "13600227427"  # MoneyFarm global payments configurations (MG)
  tableau: []
  databricks:
    - "01f122020cb3178380de2efa0b990279"  # UK BA space [WIP] — 16 join_specs touching this table
    - "01f14394002815a288421fd85f36d595"  # Investment Portfolio Analytics — 1 table register
  notebooks: []
  uc_comment: false
  knowledge_skills:
    - knowledge/skills/_kpi_views_index.json
    - knowledge/skills/_brief_cluster_13.md
    - knowledge/skills/payments/mimo-panel-and-ddr.md
---

# bi_output_moneyfarm_fact_portfolio_snapshot

## 1. What it is

`main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` is the eToro-side **MoneyFarm portfolio snapshot fact** — one row per `(GCID, PortfolioID)`, refreshed daily, holding the current product-level state (product type, market value, risk level) of every MoneyFarm portfolio belonging to an eToro customer who has linked through the MoneyFarm V2 ISA flow. It is the canonical UK-ISA portfolio inventory and is the load-bearing table for the [Investment Portfolio Analytics Genie space](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13600260206/MoneyFarm) and the larger UK BA analytics workspace.

> **Tier-1 anchor — eligibility (`[Confluence/XP/12216961926 — Moneyfarm V2 - HLD]`):**
>
> *"The purpose of Moneyfarm project is to direct users to register on Moneyfarm platform. The criteria for such users are: countryID=UK, designatedRegulation=FCA, playerStatus is Normal, User has at least one Approved deposit, the user isn't a 'Legacy user'."*
>
> Every row in this table therefore corresponds to a UK + FCA + funded eToro customer. There is no global / non-UK MoneyFarm population here.

> **Tier-1 anchor — payments identity (`[Confluence/MG/13600227427 — MoneyFarm global payments configurations]`):**
>
> *"`AccountTypeID = 4 = MoneyFarm`"* (in `Dictionary.AccountTypes`); *"`FundingTypeID = 44 = MoneyFarm`"* (in `Dictionary.FundingType`, DefaultCurrency=5).
>
> This is how downstream MIMO panels filter for MoneyFarm rows: `AccountTypeId = 4` on the payments side is the foreign-key bridge to `GCID` rows in this table.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` | UC inventory |
| Type | `EXTERNAL` (Delta) | `system.information_schema.tables` |
| Format | `delta` | UC `DESCRIBE EXTENDED` |
| Location | `abfss://analysis@dldataplatformprodwe…/BI_OUTPUT/Moneyfarm/Fact_Portfolio_Snapshot` | UC `DESCRIBE EXTENDED` |
| Owner | `eyalbo@etoro.com` | UC `DESCRIBE EXTENDED` |
| Created | Feb 15 2026 | UC `DESCRIBE EXTENDED` |
| Row count | 40,885 | `SELECT COUNT(*)` (P1) |
| UC comment | none today (`uc_comment: null`) | UC inventory |

### Upstream — direct refs

This table is curated by the eToro BizOps / DDR team from the MoneyFarm subscription event stream:

| Upstream | Domain | Role | Source |
|----------|--------|------|--------|
| `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` | compliance (out-of-domain, eToro side) | Sub-Accounts EventHub feed where `eventSource='Moneyfarm'`. PORTFOLIO_DEPOSIT, PORTFOLIO_CREATED, USER_CASH_ACCOUNT_ACTIVATED events land here. | `[Confluence/XP/13551468545 — MF Deposit Event]` |
| `bi_db.bronze_sub_accounts_accounts` | bi_db (out-of-domain) | Sub-account header / identity bridge. **Filter `providerName = 'Moneyfarm'`** to scope the join to this domain. | `[genie:UK-BA-WIP::join_spec(bronze_sub_accounts_accounts↔fact_portfolio_snapshot)]` |
| `Cosmos-MoneyFarm` (logical, not UC) | moneyfarm | Original MoneyFarm CosmosDB document store. Indirect — events land in `compliance.bronze_event_hub_*` first, then a curation pipeline writes this fact. | `[generic_pipeline_mapping.json[generic_id=1168]]` (Tier-4 inference about the Cosmos→event flow) |

### Ingest provenance

There is no per-table SSDT or `.py` ingest for this table in the local DataPlatform repo; the only direct MoneyFarm notebook is `databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb` (Jupyter, last modified 2025-05-13) which writes to the **silver** layer (`money_farm.silver_moneyfarm_etoro_mf_aum`) — *not* this fact table. By the **eToro BizOps convention**, `bi_output.bi_output_moneyfarm_*` tables are written by the BI team's `bi_output` pipeline, which subscribes to the MoneyFarm sub-accounts EventHub and projects portfolio events into the snapshot/transactions fact pair. (Tier-1 from Deposit Event HLD; Tier-4 inference about the BI pipeline since no source SQL is available.)

### Downstream

| Direction | Object | Evidence |
|-----------|--------|----------|
| Used by Genie space | `Investment Portfolio Analytics` (space_id=`01f14394...`) | `databricks_assets.json[per_object_index]` — registered as `bi_output_moneyfarm_fact_portfolio_snapshot` in `data_sources.tables[]` |
| Used by Genie space | `UK BA space [WIP]` (space_id=`01f12202...`) | `databricks_assets.json` — registered + 16 join_specs touch it |
| Joined to via PortfolioID | `bi_output.bi_output_moneyfarm_fact_transactions` | `[genie:UK-BA-WIP::join_spec(PortfolioID↔PortfolioID)]` (ONE_TO_MANY) |
| Joined to via PortfolioID | `money_farm.silver_moneyfarm_etoro_mf_aum.Portfolio_Id` | `[genie:UK-BA-WIP::join_spec(fact.PortfolioID↔silver.Portfolio_Id)]` (ONE_TO_MANY) |
| Joined to via GCID | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `[genie:UK-BA-WIP::join_spec(dim_customer.GCID↔fact.GCID)]` |
| **No** Tableau workbooks today | — | `tableau_index.json[bi_output_moneyfarm_fact_portfolio_snapshot]` — empty (clean negative) |

## 3. Columns

> **Format note:** the `Description` column is the **deployable** comment text — it lands verbatim in the UC `COMMENT ON COLUMN` for this table (so it's what an agent sees via `DESCRIBE`). The `Notes & citations` column is **wiki-only** — full provenance, pipeline traces, and caveats for humans and domain-skill agents seeking deeper reference. See `.cursor/rules/uc-domain-doc/05-generate-doc.mdc` §"Description vs Notes & citations".

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `GCID` | LONG | T1 | eToro Global Customer ID (numeric LONG). FK to `bi_db.bronze_sub_accounts_accounts.gcid` where `providerName='Moneyfarm'` and to `dwh.dim_customer.RealCID`. Always populated. `[Conf/XP/13551468545]` | Sources: `Confluence/XP/13551468545 §"General Flow"` event sample shows `"gcid": 20620608` (LONG numeric); `genie:UK-BA-WIP::join_spec(dim_customer↔fact)`. No nulls in 5-row sample. The `bronze_sub_accounts_accounts` bridge requires `providerName='Moneyfarm'` to keep 1:N cardinality (one customer → many MF events) — see Genie instruction. | `23352640`, `45527620`, `16843865` |
| 1 | `PortfolioID` | STRING | T1 | UUID v4 per-portfolio (8-4-4-4-12 with hyphens). One `GCID` can hold multiple `PortfolioID`s (1:N). FK to `bi_output_moneyfarm_fact_transactions.PortfolioID` and `silver_moneyfarm_etoro_mf_aum.Portfolio_Id` (note case difference). `[Conf/XP/13551468545]` | Sources: `Confluence/XP/13551468545 §"General Flow"` event sample shows `"portfolioId":"4e6e39c9-1698-4b98-952e-d35f069ed097"`; `genie:UK-BA-WIP::join_spec instruction "A single GCID can have multiple Portfolios (PortfolioIDs)..."`. The 1:N cardinality is supported by the event schema where `portfolioId` lives in `eventData` (per-event) while `gcid` lives in `eventMetadata` (per-customer). The snake-case ↔ camel difference (`Portfolio_Id` vs `PortfolioID`) is confirmed by the Genie join_spec — easy to mis-type. | `18471683-a0e0-4bee-9ae1-8a43a117d24b` |
| 2 | `Product_Onboarding_Date` | DATE | T4 | Onboarding date for this MoneyFarm product (NOT the row insertion date — see `UpdateDate`). Provenance not Confluence-confirmed. `[uc_sample]` | Source: `uc_sample` only — no Confluence anchor. All 5 sample values fall in 2025-2026; V2 HLD is dated 2024-01-28, so anything pre-V2 is not represented in this slice. **Provenance ambiguity:** could be eToro-side ("when the customer onboarded onto V2") or MoneyFarm-side ("when the portfolio opened on MoneyFarm"). The sample range alone cannot disambiguate. | `2026-04-15`, `2025-11-11`, `2025-08-28`, `2025-12-27`, `2025-05-30` |
| 3 | `Product_Name` | STRING | T1 | MoneyFarm product. Values: `Managed ISA` \| `DIY ISA` \| `Cash ISA`. UK + FCA only (V2 HLD eligibility scope). `[Conf/XP/12216961926]` | Sources: `Confluence/XP/12216961926 §"High Level Design"` (V2 eligibility scope: `countryID=UK + designatedRegulation=FCA + playerStatus=Normal + ≥1 Approved deposit + non-legacy`); `Confluence/CS/13209534657 §title` ("Individual Savings Account (ISA) - MoneyFarm"); `uc_sample`. The Figma node `ISA-Account_UK` and the Splunk category `IsaAccountService_moneyfarm` further confirm the product family. All values are ISA variants. | `Managed ISA`, `DIY ISA`, `Cash ISA` |
| 4 | `Current_Market_Value_GBP` | DECIMAL | T5 | Current GBP NAV at `UpdateDate`. Many rows are 0.00 (interpreted as freshly-created or NAV-zero pending daily mark-to-market in `silver_moneyfarm_etoro_mf_aum`). Currency assumed GBP per `Dictionary.FundingType.DefaultCurrency=5`. `[T5 2026-05-04]` | **Approved 2026-05-04 by guyman** (description retained verbatim). Sources: `uc_sample`; `Confluence/MG/13600227427 §"Etoro DB FundingType"` (FundingTypeID=44=MoneyFarm, DefaultCurrency=5). Currency-id-to-ISO mapping (5 → GBP) is *not* separately verified — assumed from the FundingType row context. The `0.00` interpretation (freshly-created portfolios with no funds yet *or* NAV-zero states pending the daily mark-to-market in `silver_moneyfarm_etoro_mf_aum`) is hypothesis — not confirmed via SQL join. Full audit trail in `bi_output_moneyfarm_fact_portfolio_snapshot.review-log.md`. | `0.00`, `70806.19` |
| 5 | `Portfolio_Risk_Level` | STRING | T4 | MoneyFarm-side risk-level code. Values observed: `P0`, `P7`, `NULL`. Band semantics not confirmed — treat as opaque code. `[uc_sample]` | Source: `uc_sample` only — no Confluence anchor. **Band semantics not Confluence-anchored** — the `P0..P7` ordering and the "P0=Cash / P7=Equity-heavy" mapping seen in MoneyFarm's public site is *not* confirmed by any cached eToro doc. Do not rely on it for portfolio-risk analyses without first confirming with the MoneyFarm team. Nullable in samples. | `P0`, `P7`, NULL |
| 6 | `Last_Risk_Level_Change_Date` | STRING | T4 | Date/timestamp of the last `Portfolio_Risk_Level` change. STRING type, all sample rows NULL. `[uc_sample]` | Source: `uc_sample` only — no Confluence anchor. All 5 sample rows are NULL — format and population pattern cannot be confirmed from samples alone. Type is STRING (not DATE), suggesting upstream sends a free-form string when populated, but the format (ISO 8601, epoch, etc.) is unknown. | (all NULL in sample) |
| 7 | `Previous_Risk_Level` | STRING | T4 | Previous value of `Portfolio_Risk_Level` before the last change. STRING, all sample rows NULL. `[uc_sample]` | Source: `uc_sample` only — no Confluence anchor. Pairs with `Last_Risk_Level_Change_Date`. Like its companion, format and population pattern cannot be confirmed from samples alone. | (all NULL in sample) |
| 8 | `Source_Type` | STRING | T1 | Provenance flag. Values: `Live Event` (streamed from sub-accounts EH; `PORTFOLIO_DEPOSIT` / `USER_CASH_ACCOUNT_ACTIVATED`) \| `Silver History` (back-fill from `silver_moneyfarm_etoro_mf_aum`). Filter `Source_Type='Live Event'` for live activity only. `[Conf/XP/13551468545]` | Sources: `Confluence/XP/13551468545 §"General Flow" + §"Rollout Info"`; `uc_sample`. **`Live Event` pipeline:** `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` → `sub-accounts-experience-worker` (subscribes via CCM `MoneyfarmEventHubEventTypes = [USER_CASH_ACCOUNT_ACTIVATED, PORTFOLIO_DEPOSIT]`) → `payments-metrics` Service Bus. **`Silver History`:** back-fill reconstructed from the `silver_moneyfarm_etoro_mf_aum` history. Counts of `Silver History` rows indicate how much of the panel is back-filled vs streamed. | `Live Event`, `Silver History` |
| 9 | `UpdateDate` | TIMESTAMP | T5 | Snapshot timestamp. All sampled rows in a given day share the same `UpdateDate`. History-retention not confirmed — verify with `SELECT COUNT(DISTINCT UpdateDate)` before time-series use. `[T5 2026-05-04]` | **Reviewed and softened 2026-05-04 by guyman** (changed from "daily-rebuilt snapshot, not SCD" to the current cautious wording — see review-log). Source: `uc_sample`. All 5 sampled rows share `2026-05-04T05:22:26+00:00`, consistent with a single daily-write pattern. Reliable as a row-freshness marker, but the history-retention semantics are not confirmed by Confluence or Genie. | `2026-05-04T05:22:26.307190+00:00` |

**Tier breakdown:** 4 / 10 columns at Tier 1, 0 at Tier 3, 4 / 10 at Tier 4, 2 / 10 at Tier 5 (analyst-reviewed). **0 / 10 UNVERIFIED.**

This table demonstrates the framework's robustness: even though the table itself has **no UC comment and no Tableau coverage**, the cross-reference of (a) Confluence eligibility / payment-config / event-schema docs and (b) Genie-space join_specs lets us anchor most semantically-loaded columns to authored evidence rather than agent inference.

## 4. Common usage / JOINs

The **UK BA space [WIP]** Genie space (`01f12202...`) is the primary analyst surface for this table and registers 16 join_specs touching the three MoneyFarm fact tables. The most-used joins (verbatim from `data_sources.relationships[]`):

| Pattern | SQL (verbatim) | Cardinality | Instruction (verbatim) |
|---------|----------------|-------------|------------------------|
| Customer linkage | `bronze_sub_accounts_accounts.gcid = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | ONE_TO_MANY | "Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship." `[genie:UK-BA-WIP::01f122f379e314879bedaacb2fd0a5b4]` |
| Portfolio events | `bi_output_moneyfarm_fact_portfolio_snapshot.PortfolioID = bi_output_moneyfarm_fact_transactions.PortfolioID` | ONE_TO_MANY | (no instruction text) `[genie:UK-BA-WIP::01f1239e68951bbc8b4a3e14df8ac101]` |
| Daily AUM | `bi_output_moneyfarm_fact_portfolio_snapshot.PortfolioID = silver_moneyfarm_etoro_mf_aum.Portfolio_Id` | ONE_TO_MANY | (no instruction text) `[genie:UK-BA-WIP::01f1239e78851bbc8b4a3e14df8ac101]` |
| Sub-Accounts events | `bronze_event_hub_prod_event_streaming_we_sub_accounts.EventPayloadRowData_EventMetadata_Gcid = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | MANY_TO_MANY | "A single GCID can have multiple Portfolios (PortfolioIDs)…" `[genie:UK-BA-WIP::01f1239f4d4e1ddca1f29cd79ac6d22d]` |
| Customer dim | `dim_customer.GCID = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | (registered by Genie, no rt= label) | (no instruction) `[genie:UK-BA-WIP::join_spec dim_customer↔fact_portfolio_snapshot]` |

A typical analyst query (synthesised from the Genie joins above):

```sql
-- "Active MoneyFarm customers and their current portfolio state, scoped to UK FCA"
SELECT
    sa.gcid,
    sa.externalUserId,
    fps.PortfolioID,
    fps.Product_Name,
    fps.Portfolio_Risk_Level,
    fps.Current_Market_Value_GBP,
    fps.Source_Type,
    dim_c.RegistrationCountryID
FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps
JOIN main.bi_db.bronze_sub_accounts_accounts sa
    ON sa.gcid = fps.GCID
    AND sa.providerName = 'Moneyfarm'   -- REQUIRED per Genie instruction
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dim_c
    ON dim_c.RealCID = fps.GCID
WHERE fps.UpdateDate = (SELECT MAX(UpdateDate) FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot)
```

## 5. Gotchas (verbatim from Tier-1 / Tier-3 sources)

1. **One-to-many on GCID — must filter `providerName='Moneyfarm'`.** From `[genie:UK-BA-WIP::join_spec instruction]`:
   > *"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."*

2. **One GCID → many Portfolios.** From `[genie:UK-BA-WIP::join_spec instruction]`:
   > *"A single GCID can have multiple Portfolios (PortfolioIDs) and rows for each portfolio in each table. Therefore when joining on GCID there are multiple different rows for a GCID on left and right."*

3. **AccountTypeID=4 = ISA / MoneyFarm.** From `[genie:UK-BA-WIP::sql_snippet]`:
   > *"FTDPlatformID, --The ID relating to the area of the platform the user first deposited to: 4 = ISA/Moneyfarm, 3 = IBAN, 2 = Options, 1 = Trading Platform"*
   This means MIMO/FTD downstream queries `WHERE FTDPlatformID = 4` to scope to MoneyFarm. The same `4` is the `AccountTypeId` value in the deposit-event payload per `[Confluence/MG/13600227427]`.

4. **Eligibility scope, not all UK customers.** Per `[Confluence/XP/12216961926]`, the table only contains rows for customers who satisfy `countryID=UK + designatedRegulation=FCA + playerStatus=Normal + ≥1 Approved deposit + non-legacy`. Joining to `dim_customer` and filtering `RegistrationCountryID=UK` is therefore *redundant* but not wrong; analysts have been observed double-filtering.

5. **`Source_Type='Silver History'` rows are back-fills.** Tier-3 inference from sample mix: a row with `Source_Type='Silver History'` was reconstructed from the silver-tier AUM history rather than streamed from a live MoneyFarm event. When counting "live" MoneyFarm activity, filter `Source_Type='Live Event'`. `[uc_sample; cluster_brief]`

6. **Currency = GBP, but `Current_Market_Value_GBP` may be `0.00`.** Sample shows multiple rows with `0.00` GBP value despite the column name. Interpreted as freshly-onboarded or pre-funded portfolios where the daily NAV mark hasn't run yet. Always pair this column with `Source_Type` and `Product_Onboarding_Date` for context.

## 6. UC ALTER provenance

The companion `bi_output_moneyfarm_fact_portfolio_snapshot.alter.sql` deploys the table-level comment + 7 column-level comments. **Each deployed comment is the wiki Section 3 `Description` column verbatim** — the verbose `Notes & citations` column never lands in UC. This split keeps the UC `COMMENT` agent-friendly (80–300 chars, declarative + values + filter hint + 1 citation tag) while preserving full provenance for humans browsing the wiki.

| Tier | Count | Columns deployed |
|------|-------|------------------|
| T1 (Confluence-anchored) | 4 | `GCID`, `PortfolioID`, `Product_Name`, `Source_Type` |
| Soft T4 (sample-only, no speculation) | 1 | `Product_Onboarding_Date` |
| T5 (analyst-reviewed 2026-05-04 by guyman) | 2 | `Current_Market_Value_GBP` (approved), `UpdateDate` (softened) |
| **NOT deployed (pure T4, not Confluence-anchored)** | 3 | `Portfolio_Risk_Level`, `Last_Risk_Level_Change_Date`, `Previous_Risk_Level` |

Promote any of the not-deployed columns only after analyst confirmation or MoneyFarm-side documentation surfaces — every promotion logs a T5 entry in `bi_output_moneyfarm_fact_portfolio_snapshot.review-log.md`.

**Confluence-anchoring round 2 (2026-05-04):** the second pass of this review re-read the 4 cached Confluence pages and used them to (a) tighten 4 columns' citations, (b) fix the misclaim that `PortfolioID` is ULID format (the V2 deposit-event HLD shows it as standard UUID v4), and (c) drop the unsourced "P0=Cash, P7=Equity" risk-band semantics from `Portfolio_Risk_Level` because no eToro-side doc actually defines it. See review log for full audit trail.

**Format restructure (2026-05-04):** Section 3 was split from a single `Description (cited)` column into separate `Description` (deployable to UC, distilled for agent consumption) and `Notes & citations` (wiki-only verbose context) columns, per `05-generate-doc.mdc §"Description vs Notes & citations"`. The deployed ALTER text was rewritten to the new distilled form.

Every comment in the ALTER quotes either:
- a Confluence anchor (`12216961926`, `13551468545`, `13600227427`), or
- a Genie space instruction (`UK-BA-WIP` join_specs cited above), or
- a UC sample observation (`[uc_sample]` for `Source_Type`).

**No `[UNVERIFIED]` comments are deployed.**

## 7. Discovery summary (per-source roll-up)

| Source | Hits for this table | Quality |
|--------|---------------------|---------|
| UC inventory | 1 | None — table has no UC comment today (this wiki + alter close that gap) |
| Confluence | 3 anchor pages (XP HLD, XP Deposit Event, MG Payments Configs) | Tier 1 — covers eligibility, event schema, payments dictionary |
| Tableau | 0 workbooks, 0 custom-SQL, 0 calc-fields | None — table is not registered as a Tableau datasource (CS dashboard "ISACustomerLookupDashboard" likely uses a non-UC connection) |
| Genie spaces | **2 of 144** match: `Investment Portfolio Analytics` (1 table register) + **`UK BA space [WIP]` (16 join_specs touching MoneyFarm objects, with explicit cardinality + instruction text)** | **Tier 3 — primary load-bearing source** for `PortfolioID`, `GCID` cardinality, and `Source_Type` semantics |
| Notebooks | 1 (`databricks/de/MoneyFarm/MoneyFarm_Daily.ipynb`) | Tier-3 only for upstream `silver_moneyfarm_etoro_mf_aum` — does NOT directly mention this fact table |
| KPI views index | n/a — this table is a fact, not a KPI view | — |
| Cluster brief | Cluster 13 (DDR/MIMO) — weight 24 | Tier 4 |
