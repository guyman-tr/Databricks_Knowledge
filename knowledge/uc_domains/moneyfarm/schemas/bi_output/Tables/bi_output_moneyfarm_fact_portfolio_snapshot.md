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
  tier1_columns: 3
  tier2_columns: 0
  tier3_columns: 3
  tier4_columns: 4
  unverified_columns: 0
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

| # | Column | Type | Tier | Description (cited) | Sample values |
|---|--------|------|------|---------------------|---------------|
| 0 | `GCID` | LONG | T1 | eToro Global Customer ID. Always populated (no nulls in 5-row sample). The MoneyFarm flow maps to eToro's existing GCID via the `bronze_sub_accounts_accounts` bridge filtered by `providerName='Moneyfarm'`. `[Confluence/XP/13551468545 §"GCID Source"; genie:UK-BA-WIP::join_spec(dim_customer↔fact)]` | `23352640`, `45527620`, `16843865` |
| 1 | `PortfolioID` | STRING | T3 | UUID identifying a single MoneyFarm portfolio belonging to a `GCID`. **A single GCID can hold multiple PortfolioIDs** (per Genie instruction). Used as the FK to `bi_output_moneyfarm_fact_transactions.PortfolioID` and to `silver_moneyfarm_etoro_mf_aum.Portfolio_Id`. `[genie:UK-BA-WIP::join_spec instruction "A single GCID can have multiple Portfolios (PortfolioIDs)..."]` | `18471683-a0e0-4bee-9ae1-8a43a117d24b` (UUID v4) |
| 2 | `Product_Onboarding_Date` | DATE | T4 | The date the customer onboarded onto this MoneyFarm product (NOT the date eToro acquired MoneyFarm or when the row was inserted — see `UpdateDate` for that). Sample values cluster in 2025-2026 consistent with the MoneyFarm V2 rollout window. `[uc_sample]` | `2026-04-15`, `2025-11-11`, `2025-08-28`, `2025-12-27`, `2025-05-30` |
| 3 | `Product_Name` | STRING | T1 | The MoneyFarm product type. Per UC samples, the active values are `Managed ISA`, `DIY ISA`, `Cash ISA` — all **Individual Savings Account** variants, consistent with the MoneyFarm V2 HLD scope ("ISA-Account_UK" Figma + `IsaAccountService_moneyfarm` Splunk category). The HLD eligibility (UK+FCA) is the reason this column is exclusively ISA-flavoured. `[Confluence/XP/12216961926 §HLD; uc_sample]` | `Managed ISA`, `DIY ISA`, `Cash ISA` |
| 4 | `Current_Market_Value_GBP` | DECIMAL | T4 | The current GBP market value of the portfolio at the snapshot time (`UpdateDate`). Note that **a large fraction of rows show `0.00`** in the 5-row sample — interpreted as either freshly-created portfolios with no funds yet, or NAV-zero states pending the daily mark-to-market in the `silver_moneyfarm_etoro_mf_aum` enrichment. Currency is GBP (matches the FundingType DefaultCurrency=5 that the Confluence config page assigns to MoneyFarm — though note we have not confirmed the currency-id-to-ISO mapping). `[uc_sample; Confluence/MG/13600227427 §Etoro DB FundingType]` | `0.00`, `70806.19` |
| 5 | `Portfolio_Risk_Level` | STRING | T4 | MoneyFarm internal risk-level code. Sample values `P0`-`P7` follow MoneyFarm's documented [seven-band risk system](https://app.moneyfarm.com/) (P0 = lowest risk / Cash, P7 = highest risk / Equity-heavy). Not all rows have a level — `Cash ISA` rows seem to carry `P0` while raw / pre-onboarded `DIY ISA` rows can be NULL. `[uc_sample]` | `P0`, `P7`, NULL |
| 6 | `Last_Risk_Level_Change_Date` | STRING | T4 | Timestamp / date-string of the last `Portfolio_Risk_Level` change. **All NULL in the 5-row sample** — most portfolios in this small sample have never changed risk level. Type is `STRING` not `DATE`, suggesting upstream sends a free-form string (likely ISO 8601). `[uc_sample]` | (all NULL in sample) |
| 7 | `Previous_Risk_Level` | STRING | T4 | The previous `Portfolio_Risk_Level` before the last change. Pairs with `Last_Risk_Level_Change_Date`. **All NULL in the 5-row sample.** `[uc_sample]` | (all NULL in sample) |
| 8 | `Source_Type` | STRING | T3 | Provenance flag distinguishing the row's origin. UC samples show two values: `Live Event` (current — the row was created from a real-time MoneyFarm sub-accounts event) vs `Silver History` (back-fill — the row was reconstructed from the `silver_moneyfarm_etoro_mf_aum` history). The mix is meaningful: counts of `Silver History` rows indicate how much of the panel is **back-filled** vs streamed. `[uc_sample; cluster_brief]` | `Live Event`, `Silver History` |
| 9 | `UpdateDate` | TIMESTAMP | T4 | Snapshot timestamp. All sample rows share the same `UpdateDate` (`2026-05-04T05:22:26+00:00`), confirming this is a **daily-rebuilt snapshot table** rather than a slowly-changing dimension — every row in a given day shares the same `UpdateDate`. `[uc_sample]` | `2026-05-04T05:22:26.307190+00:00` |

**Tier breakdown:** 3 / 10 columns at Tier 1, 3 / 10 at Tier 3, 4 / 10 at Tier 4. **0 / 10 UNVERIFIED.**

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

The companion `bi_output_moneyfarm_fact_portfolio_snapshot.alter.sql` deploys the table-level comment + 6 column-level comments (the 3 T1 + 3 T3 columns plus `Source_Type` which has both T3 + T4 evidence). The 4 pure Tier-4 columns (`Current_Market_Value_GBP`, `Portfolio_Risk_Level`, `Last_Risk_Level_Change_Date`, `Previous_Risk_Level`) are documented in this wiki but **NOT** emitted into the ALTER (per the `05-generate-doc.mdc` policy: "Tier-4 column comments are optional"). They can be promoted later if MoneyFarm-side documentation surfaces.

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
