---
description: "Map of Paloma Cui's Tableau workbooks under USA / Paloma's Repository / 1-US Management
  to the Unity Catalog views and bronze tables they read. The 11 workbooks (3 Options-explicit,
  8 cross-functional that include Options): US Options Performance Monitoring (workbook 5820,
  3 views, 12 data sources, view US Options Weekly Mgmt Update has 1455 all-time hits — the
  canonical Options dashboard with New Signups vs Legacy Accounts segmentation), US Options 3.0
  Monitoring (Including UK) (workbook 7008, 6 UC data sources including 'apex last reports
  dates' freshness checker, 'UK daily 3-step funnel cid details', 'unique deposits trades'),
  US Options 3.0 Monitoring NYDFS+FINRA (NY Crypto launch tracking RegID=14), plus US KPI
  Daily Highlights, US KPI Daily Highlights RegulationID-14, US Acquisition Funnel (3.0 States
  vs Others), US BOD Operational Insight, US End-End Funnel, US End-to-End Funnel (Georgios
  Kyriakou), US KPI Monthly Highlights, and US Trading Monitoring. All Databricks data sources
  point to UC adb-6358342630366312.12.azuredatabricks.net; one Synapse fallback at
  prod-synapse-dataplatform-we for 'historical trades, options'. The 9 verbatim sample queries
  from Brian Sullivan / Paloma Cui's BI Knowledge Transfer Doc cover Population, All Apex
  Options Accounts, Funded, Traded, MIMO, Trading, Balance, Revenue — these are the
  pre-prep-view queries that informed the v_options_aum / v_mimo_options_platform /
  v_revenue_optionsplatform shapes. Use for any 'which Tableau workbook drives Options KPIs' /
  'where do I get the Options Funnel sample query' / 'what data source is Options Revenue
  built from' / 'who consumes US Options Weekly Mgmt Update' question."
triggers:
  - tableau options dashboards
  - paloma cui workbooks
  - paloma's repository
  - 1-US Management
  - US Options Weekly Mgmt Update
  - US Options Performance Monitoring
  - US Options 3.0 Monitoring
  - US Options Performance
  - US KPI Daily Highlights
  - US Acquisition Funnel
  - US BOD Operational Insight
  - US End-End Funnel
  - US Trading Monitoring
  - workbook 5820
  - workbook 7008
  - 12 data sources options
  - apex last reports dates
  - UK daily 3-step funnel
  - gatsby legacy user trading data source
  - options KYC profile
  - options revenue data source
  - options accounts FTD data source
  - options accounts first open pos
  - sample query options population
  - sample query options funded
  - sample query options traded
  - sample query options MIMO
  - sample query options balance
  - sample query options revenue
  - 9 sample queries options
sample_questions:
  - Which Tableau workbook is the canonical Options KPI dashboard
  - What data sources does US Options Performance Monitoring read from
  - Where does the New Signups vs Legacy Accounts segmentation come from
  - Which Tableau dashboard tracks the NY crypto launch (NYDFS+FINRA)
  - What's the freshness-checker query for Apex SOD files
  - Where can I find the 9 Brian Sullivan sample queries
required_tables:
  - main.etoro_kpi_prep.v_options_aum
  - main.etoro_kpi_prep.v_mimo_options_platform
  - main.etoro_kpi_prep.v_revenue_optionsplatform
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
name: domain-options
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-04"
---

# Tableau dashboard map + sample queries

## When to Use
Load when the user asks about Paloma Cui's `1-US Management` Tableau workbooks — "which workbook drives Options KPIs", "what data source is Options Revenue built from", "who consumes US Options Weekly Mgmt Update", "where's the apex last reports dates freshness query", or "where can I find the 9 Brian Sullivan / Paloma Cui sample queries from the BI knowledge-transfer Doc".

## Scope
In scope: The 11 `1-US Management` Tableau workbooks (3 Options-explicit + 8 cross-functional that include Options); per-workbook data-source map; the 9 verbatim sample queries from the BI knowledge-transfer Doc (Population / All Apex Options Accounts / Funded / Traded / MIMO / Trading / Balance / Revenue).

Out of scope: Bronze schemas → `options-source-tables.md`. KPI formulas → `options-metric-definitions.md`. Prep-view DDLs → `options-views-architecture.md`. Reusable SQL filter contracts → `options-data-patterns.md`.
Last verified: 2026-06-04

## Repository structure

**Tableau base URL**: `https://reports.etorocorp.com/`

```
USA (project)
└── Paloma's Repository (project 234, owned by palomacui@)
    ├── 1-US Management (Updated Oct 15, 2025)  ← project 430, 11 workbooks ← Options-related lives here
    ├── 2-US Operations
    ├── 3-US Marketing & PR
    ├── 4-US Compliance
    ├── 5-US Finance
    ├── 6-To be Decommissioned
    └── CA Types (workbook)
```

The **`1-US Management`** sub-project is where all Options-related dashboards live. As of 2026-05-31, it contains 11 workbooks; 3 are explicitly Options.

## `1-US Management` workbook inventory (11 workbooks)

| # | Workbook | Owner | Last modified | Options relevance |
|---|---|---|---|---|
| 1 | US Acquisition Funnel (3.0 States vs. Others) | Paloma Cui | 2026-05-21 | ✅ 3.0 cohort funnel |
| 2 | US BOD - Operational Insight | Paloma Cui | 2026-05-14 | partial |
| 3 | US End-End Funnel | Paloma Cui | 2026-05-21 | partial |
| 4 | US End-to-End Funnel | Georgios Kyriakou | 2026-05-31 | partial (most recent) |
| 5 | US KPI Daily Highlights | Paloma Cui | 2026-05-30 | partial — daily Options KPIs roll up |
| 6 | US KPI Daily Highlights RegulationID - 14 (NYDFS+FINRA) | Paloma Cui | 2026-05-21 | ✅ NY Crypto launch |
| 7 | US KPI Monthly Highlights | Georgios Kyriakou | 2026-05-04 | partial |
| 8 | **US Options 3.0 Monitoring (Including UK)** | Paloma Cui | 2026-05-30 | ⭐ Options-explicit (workbook 7008) |
| 9 | **US Options 3.0 Monitoring NYDFS+FINRA** | Paloma Cui | 2026-05-18 | ⭐ Options-explicit (NY-specific) |
| 10 | **US Options Performance Monitoring** | Paloma Cui | 2026-05-13 | ⭐ Options-explicit, canonical (workbook 5820) |
| 11 | US Trading Monitoring | Paloma Cui | 2026-05-31 | partial (most recent) |

## Workbook deep-dive — `US Options Performance Monitoring` (5820)

**The canonical Options dashboard.** Has 3 views, 12 data sources, 10 active subscribers, 1 scheduled extract refresh.

### Views

| View | All-time hits | Sheet # |
|---|---|---|
| **US Options Weekly Mgmt Update** | **1,455** | 1 |
| US Options Legacy Users | 9 | 2 |
| Options Traders KYC Profile | 78 | 3 |

### Visual content of `US Options Weekly Mgmt Update`

Title: "**US Options KPI Monitoring (Incl. UK Beta)**"

| Section | Charts |
|---|---|
| **1. Monthly Conversion: Key Activation Steps** | Monthly Options First Funded Accounts (ICT-Internal Cash Transfer, plus Direct Funding); Monthly First Options Trade |
| **2. Weekly Cumulative since Unity Day** | Funded Accounts (incl. Churn) — latest ~12,621; Total Contracts Traded (Buy and Sell) — latest ~22,127 |
| **3. Monthly Options Trading Data** | Monthly Active Open Options Traders (Buy) — segmented New Signups vs Legacy Accounts with % overlay; Monthly Active Options Traders (Buy or Sell); Monthly Contracts Traded (Buy and Sell) |

A screenshot of this view is saved at `knowledge/_inbox/gatsby-options/us-options-kpi-monitoring-dashboard.png`.

### Data Sources (12) — extract refreshed 2026-05-12, 9:05 AM

| # | Type | Name | Backing |
|---|---|---|---|
| 1 | Live (txt) | Clipboard_20251119T125710 | Manual paste — likely a hand-curated list (test accounts? specific cohort?) |
| 2 | Extract | **Databricks, Gatsby legacy user trading, + etoro** ⭐ | UC `adb-6358342630366312.12.azuredatabricks.net` — explicit Gatsby-era cut |
| 3 | Extract | Databricks, Options - Trading data (monthly, B only) | UC — monthly trading volumes Buy-only |
| 4 | Extract | Databricks, Options - Trading data (monthly, B+S) | UC — monthly trading volumes Buy+Sell |
| 5 | Extract | Databricks, Options - Trading data (weekly, B Only) | UC — weekly trading volumes Buy-only |
| 6 | Extract | Databricks, Options - Trading data (weekly) | UC — weekly trading volumes |
| 7 | Extract | Databricks, Options Accounts - first open pos | UC — first-trade-per-account derivative |
| 8 | Extract | Databricks, Options Accounts - FTD | UC — FTD events per account |
| 9 | Extract | Databricks, Options Accounts - Regs & Pre-approved | UC — regulatory cohort + pre-approval flags |
| 10 | Extract | Databricks, Options Revenue | UC — PFOF revenue |
| 11 | Extract | historical trades, options | **Synapse** `prod-synapse-dataplatform-we.sql.azuresynapse.net` — historical fallback for trades pre-dating UC migration |
| 12 | Extract | Options KYC Profile | UC — KYC segmentation |

→ Each "Databricks, Options ..." data source is a custom SQL query inside the workbook (`.twbx` XML). The names align directly with the prep views: `Options Revenue` → `v_revenue_optionsplatform`; `Options Accounts - FTD` → `v_mimo_options_platform.IsFTD`; etc.

→ The "Gatsby legacy user trading" source is the **physical confirmation** of the bifurcation that drives the New Signups vs Legacy segmentation.

## Workbook deep-dive — `US Options 3.0 Monitoring (Including UK)` (7008)

2 views, 6 data sources (all UC), 18 active subscribers, 1 scheduled refresh.

### Data Sources (6) — extract refreshed 2026-05-30, 3:10 PM

| # | Name | Purpose |
|---|---|---|
| 1 | 3.0 cohort funnel, daily | Cohort-by-registration-date funnel (3.0 states cohort) |
| 2 | 3.0 event funnel, daily | Event-by-event-date funnel |
| 3 | apex last reports dates | **Apex SOD file freshness tracker** — `MAX(ProcessDate)` per file |
| 4 | funnel, events | Generic event funnel |
| 5 | UK daily, 3-step funnel, cid details | UK launch funnel with CID drilldown |
| 6 | unique deposits, trades | Dedup'd MIMO + Trading aggregation |

The **`apex last reports dates`** data source is the canonical freshness-checker query Paloma uses operationally. It surfaces the latest ProcessDate per Apex file — important because Apex skips weekends and sometimes Mon/Tue. Likely SQL shape:

```sql
SELECT 'EXT765_AccountMaster' AS file_name, MAX(ProcessDate) AS last_processdate
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
UNION ALL
SELECT 'EXT869_CashActivity', MAX(ProcessDate)
FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
UNION ALL
SELECT 'EXT872_TradeActivity', MAX(ProcessDate)
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
UNION ALL
SELECT 'EXT981_BuyPowerSummary', MAX(ProcessDate)
FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
UNION ALL
SELECT 'EXT1047_RevenueReports', MAX(TradeDate)
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports;
```

Run this before answering "is the Options dashboard up-to-date today?" — if any date is more than 3 business days behind, suspect a delivery issue.

## Other workbook references

- **US Options 3.0 Monitoring NYDFS+FINRA** — NY-specific RegID=14 cohort tracker. Likely shares data sources with `7008` plus a RegID=14 filter.
- **US KPI Daily Highlights** — composite daily summary; likely pulls from same Databricks Options account/MIMO/revenue queries.
- **US KPI Daily Highlights RegulationID - 14 (NYDFS+FINRA)** — daily summary scoped to NY-only RegID=14 cohort.
- **US Acquisition Funnel (3.0 States vs. Others)** — splits the registration→FTD→trade funnel by 3.0-state cohort vs majority-state cohort. References RepCode `FO1` (3.0) and `GAT` (majority) as the segmentation dimension.

## The 9 sample queries from the BI Knowledge Transfer Doc

Brian Sullivan + Paloma Cui's BI Doc tab 2 contains 9 verbatim Synapse SQL queries that informed the UC prep views. They are the ground-truth pre-prep-view query patterns. The full SQL is preserved at `knowledge/_inbox/gatsby-options/options-data-kt.md` under "Reference: Sample Queries (verbatim from Doc tab 2)".

| # | Query name | Purpose | Equivalent UC view / pattern |
|---|---|---|---|
| 1 | Population | All Apex options accounts (any rep) | `EXT765` filtered to `OfficeCode IN ('4GS','5GU')` + house exclusion |
| 2 | All Apex options accounts | + FINRAONLY with options approval | (1) plus `(RepCode != 'FO1') OR (RepCode='FO1' AND OptionLevel IS NOT NULL)` |
| 3 | Funded | Accounts that have ever made a direct deposit | `v_mimo_options_platform` filter `MIMOAction='Deposit' AND IsInternalTransfer=0` |
| 4 | Traded | Accounts with at least one filled options trade | `EXT872` filter `MarketCode='5'` |
| 5 | MIMO | Daily fund movements | `v_mimo_options_platform` (full passthrough) |
| 6 | Trading | Trade-level data with full join to AccountMaster | `EXT872 + EXT765` join with options filter |
| 7 | Balance | Daily AUM per account | `v_options_aum` (full passthrough) |
| 8 | Revenue | PFOF estimate | `v_revenue_optionsplatform.Amount` |

→ These are the "what people actually run" queries. When a question is "how would Brian / Paloma compute X?", these are the canonical patterns.

→ The KT Doc note: **"This document outlines the current status of Options data and reporting including US, UK beta launch."** It was authored by Brian Sullivan, contributed to by Alain Tennekoon / Jeremy Moye / Jeffrey Myers / Peter Quinn (US OPS / business), and curated by the BI / DE owners Victor Shatokhin, Yulia Kramer, Eyal Boas, Pini Krisher.

## Subscriptions (who consumes this data)

The `US Options Performance Monitoring` workbook has **10 active subscriptions** — emailed snapshots delivered to subscribers on a schedule. The `US Options 3.0 Monitoring (Including UK)` workbook has **18 subscriptions** (broader audience because it covers both US and UK launches).

To enumerate subscribers programmatically: navigate to `https://reports.etorocorp.com/#/workbooks/{ID}/subscriptions` and list. Did NOT enumerate during this skill authoring (privacy and not-needed-for-skill-content).

## Cross-platform cross-references

- `domain-payments/mimo-panel-and-ddr.md` — the cross-platform DDR (`BI_DB_DDR_Fact_MIMO_AllPlatforms` 24c) consumes the Options MIMO rows produced by `v_mimo_options_platform`.
- `domain-revenue-and-fees` — `Fact_Revenue_Generating_Actions` consumes the `v_revenue_optionsplatform` Options PFOF rows under `Metric='Options_PFOF'`.

## Tableau access

If the Tableau MCP tools are available in a future session, prefer them for systematic enumeration. For one-off exploration, `cursor-ide-browser` MCP works (signed in via Microsoft SSO; MFA required on first session).

For the underlying SQL of any data source: open the workbook → Data Sources tab → click data source → "Edit Connection" → SQL panel. (Did NOT extract per-data-source SQL during this skill authoring; the data source NAMES + the prep view DDLs in `views-architecture.md` are sufficient.)

## Identifiers captured

- **Tableau project IDs**: 234 (Paloma's Repository), 430 (1-US Management)
- **Tableau workbook IDs**: 5820 (US Options Performance Monitoring), 7008 (US Options 3.0 Monitoring Including UK)
- **Tableau view ID**: 36879 (US Options Weekly Mgmt Update)
- **Databricks UC workspace**: `adb-6358342630366312.12.azuredatabricks.net`
- **Synapse fallback**: `prod-synapse-dataplatform-we.sql.azuresynapse.net`
