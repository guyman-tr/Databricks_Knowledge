---
name: domain-options
description: "US-equities & options platform via Apex Clearing — the post-Gatsby acquisition stack.
  Anchored on three production prep views in main.etoro_kpi_prep that the DDR is built on:
  v_options_aum (daily Options AUM per GCID — TotalEquity / CashEquity / PositionMarketValue
  with first-funding timestamp), v_mimo_options_platform (Options MIMO with FINRAONLY-aware
  FTD detection — both Local FTD and Global FTD via reconciliation to Dim_Customer
  FirstDepositDate / FTDPlatformID=2), and v_revenue_optionsplatform (per-customer PFOF revenue
  shaped like Function_Revenue_OptionsPlatform with Metric=Options_PFOF). Sources are
  Apex SOD reporting (38 raw tables across main.general / main.finance / main.bi_db /
  main.trading: bronze_sodreconciliation_apex_* + bronze_usabroker_apex* +
  bronze_usabroker_dictionary_*) and the USABroker GCID-to-OptionsApexID bridge with
  appropriateness / eligibility / options-status dictionaries. Covers US regulatory phases
  (eToroUS=6 / FINCEN=7 / FinCEN+FINRA=8 / FINRAONLY=12 / NYDFS+FINRA=14 since Mar 2026
  for NY crypto), UK beta launches (Apr-Jun 2023 + Mar-Jul 2025), the GAT/ETA/UK1/FO1/NY1
  RepCode taxonomy, and the 4GS/5GU/3E% OfficeCode taxonomy. Surfaces Paloma Cui's Tableau
  workbooks under USA/Paloma's Repository/1-US Management — the canonical view US Options
  Weekly Mgmt Update (1455 all-time hits) renders New-Signups vs Legacy Accounts segmentation
  where 'Legacy' is the Gatsby-era pre-acquisition cohort. Synapse TVF wrappers
  Function_MIMO_Options_Platform and Function_Revenue_OptionsPlatform exist in BI_DB_dbo
  (knowledge-only, not migrated)."
triggers:
  - options
  - apex clearing
  - us options
  - options 3.0
  - options account
  - options app
  - eToro options
  - options ftd
  - options trader
  - options aum
  - options mimo
  - options pfof
  - options revenue
  - 4GS
  - 5GU
  - 3ET
  - GAT repcode
  - PFOF
  - payment for order flow
  - FINRAONLY
  - FinCEN+FINRA
  - NYDFS+FINRA
  - regulationid 12
  - regulationid 14
  - ICT
  - instant cash transfer
  - OMJNL
  - OptionsApexID
  - options eligibility
  - reasoning form
  - v_options_aum
  - v_mimo_options_platform
  - v_mimo_optionsplatform
  - v_revenue_optionsplatform
  - bronze_sodreconciliation_apex
  - bronze_usabroker_apex_options
  - apex_EXT765_AccountMaster
  - apex_EXT869_CashActivity
  - apex_EXT872_TradeActivity
  - apex_EXT981_BuyPowerSummary
  - apex_EXT1047_RevenueReports
  - paloma cui repository
  - US Options Weekly Mgmt Update
  - US Options Performance Monitoring
  - US Options 3.0 Monitoring
  - new signups vs legacy
  - gatsby legacy
  - gatsby era
required_tables:
  - main.etoro_kpi_prep.v_options_aum
  - main.etoro_kpi_prep.v_mimo_options_platform
  - main.etoro_kpi_prep.v_revenue_optionsplatform
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
  - main.general.bronze_usabroker_apex_options
sub_skills:
  - options-source-tables.md
  - options-metric-definitions.md
  - options-views-architecture.md
  - options-dashboard-queries.md
  - options-data-patterns.md
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# US Options Skill (Apex / post-Gatsby)

## When to Use
Load this skill when the user asks about:
- US options trading, accounts, or KPIs
- Apex Clearing data (SOD files, EXT765/869/872/981/1047, etc.)
- The USABroker GCID-to-OptionsApexID bridge or its appropriateness/eligibility/reasoning-form dictionaries
- US regulatory phases — eToroUS / FINCEN / FinCEN+FINRA / FINRAONLY / NYDFS+FINRA — and the OfficeCode (4GS/5GU/3E%) and RepCode (GAT/ETA/UK1/FO1/NY1) taxonomy
- UK options beta launches
- The post-Gatsby segmentation (`New Signups` vs `Legacy Accounts`)
- The three prep views: `v_options_aum`, `v_mimo_options_platform`, `v_revenue_optionsplatform`
- Paloma Cui's `1-US Management` Tableau workbooks (Performance Monitoring / 3.0 Monitoring / NYDFS+FINRA / KPI Highlights / Acquisition Funnel)
- DDR rows where the metric source is Options PFOF, Options MIMO, or Options AUM
- PFOF (Payment for Order Flow) revenue accounting
- ICT (Instant Cash Transfer) movement between main eToro account and Options account

## Scope
**In scope:** Apex SOD reporting (38 raw tables in `main.general` / `main.finance` / `main.bi_db` / `main.trading`), USABroker bridge tables, US options regulatory cohorts, UK options beta, the 3 prep views, post-Gatsby vs Legacy segmentation, PFOF revenue, Options MIMO incl. ICT internal transfers, Options AUM (BuyPowerSummary), the 11 Paloma's Repository / `1-US Management` Tableau workbooks.

**Out of scope:**
- eToro main-platform trading → `domain-trading`
- eToro main-platform deposits/withdrawals → `domain-payments` (`mimo-panel-and-ddr`) — but note the Options MIMO joins to main MIMO via ICT (`TerminalID = 'OMJNL'`)
- eToro main-platform revenue → `domain-revenue-and-fees`
- Customer master / GCID semantics → `domain-customer-and-identity`
- Compliance/AML (post-onboarding) → `domain-compliance-and-aml`. Note: the appropriateness/eligibility/options-status status dictionaries used at Apex onboarding ARE in scope here because they're the gates that determine OptionsStatusID, not generic AML.

Last verified: 2026-05-31

## Sub-File Index

| File | Load when | Contents |
|------|-----------|----------|
| `options-source-tables.md` | Exploring raw Apex/USABroker data, "what table holds X", schema/PII lookups | 38-table catalog across `main.general` / `main.finance` / `main.bi_db` / `main.trading` with key fields, PII flags, dev notes, missing-from-Synapse callouts |
| `options-metric-definitions.md` | Computing KPIs, QA, "how is Options FTD calculated", validation | FTD (Local + Global), MIMO (Deposit/Withdraw, ICT vs direct), Funded (cumulative incl. Churn), Trading (Buy-only / Buy+Sell), AUM (TotalEquity / CashEquity / PositionMarketValue), PFOF revenue (estimate vs final) |
| `options-views-architecture.md` | Building or fixing prep-view-backed queries, DDR root-cause | Full DDLs + CTE walkthrough for `v_options_aum`, `v_mimo_options_platform`, `v_revenue_optionsplatform` + the legacy `v_mimo_optionsplatform` (deprecated) + Apex SOD pipeline + USABroker bridge mechanics |
| `options-dashboard-queries.md` | Tableau dashboard work, replicating charts, mapping a KPI back to UC | The 11 `1-US Management` Tableau workbooks + per-workbook data source map (18+ unique Databricks data sources catalogued) + the 9 sample queries from the BI knowledge-transfer Doc |
| `options-data-patterns.md` | Writing any Options SQL query | Reusable CTEs: house-account exclusion, OfficeCode/RepCode filter, MarketCode='5' options-only filter, GCID-to-OptionsApexID join, Reg classification by RepCode, ICT vs direct funding split, RegisteredRepCode-to-region map |

**Routing guidance**: Most questions need `options-data-patterns.md` (CTEs) + one of the others. Load `options-data-patterns.md` first when writing queries; load `options-views-architecture.md` first when reading existing DDR / dashboard logic.

## Product Structure

**Apex Clearing** is eToro's US clearing broker. Internally referenced as **Apex / USABroker / Options broker** — three names, one entity. The **"Gatsby"** brand survives only as:
- `RegisteredRepCode = 'GAT'` (the "Gatsby" RepCode for FinCEN+FINRA options accounts)
- The data source `Databricks, Gatsby legacy user trading, + etoro` in Paloma's Tableau workbook (the explicit segmentation cut)
- The "Legacy Accounts" segment of `Monthly Active Open Options Traders (Buy)` chart on the canonical `US Options Weekly Mgmt Update` dashboard
- The phrase "since the Gatsby era" in the BI knowledge-transfer Doc when referring to the EXT765 AccountMaster contents (which includes pre-Unity-date accounts).

After Nov 1, 2022 ("Unity Date"), eToro merged the Gatsby brand into the main eToro app. Pre-Unity accounts persist with their Gatsby-era OfficeCode + RepCode.

**Two stacked taxonomies** that classify every Apex account:

### OfficeCode / Branch Code (product-line code)
| OfficeCode | Meaning | Where present |
|---|---|---|
| `3E%` (e.g. `3ET`) | Equity account for Reg 6/7/8 (eToroUS, FINCEN, FinCEN+FINRA) | EXT765, EXT1034, EXT869, EXT872 |
| `4GS` | (a) Options account for Reg 6/7/8; (b) equity-options hybrid for Reg 12 (FINRAONLY) | EXT765, EXT1034 (Branch), EXT869, EXT872 |
| `5GU` | Same scope as 4GS — added because 4GS reached its account-number cap | EXT765, EXT869, EXT872 |

### RegisteredRepCode / RepCode (regulatory cohort flag)
| RepCode | Meaning | RegulationID | Notes |
|---|---|---|---|
| `ETA` | USA equity | 6, 7, 8 | |
| `GAT` | USA options — the **"Gatsby" code** | 6, 7, 8 | This is where the brand name lives |
| `UK1` | UK options (selected UK clients during beta) | n/a | UK |
| `FO1` | USA equity-options hybrid for FINRAONLY | 12 | Created for the 5 "options 3.0" states (NY/NV/HI/PR/USVI). If a FO1 client fails options suitability, the account remains equity-only. |
| `NY1` | USA NY all-enabled (NYDFS+FINRA) | 14 | Created Mar 2026 for NY crypto launch. **OfficeCode 4GS was full when NY1 launched, so 4GS doesn't have a 1:1 RepCode match for NY** — NY1 sits on 5GU. |
| `000` | Global test accounts | n/a | EXCLUDE from analytics |

## Critical Warnings

### Tier 1 — Silent wrong numbers

1. **OfficeCode filter is mandatory** — `am.OfficeCode IN ('4GS','5GU')` for options-only; `'3E%'` for equity. Without it you mix products. The 3 prep views already apply this; raw-bronze queries must add it manually.
2. **`MarketCode = '5'` is the ONLY indicator of an options trade** in `EXT872_TradeActivity` (vs `'N'` for equity). Don't infer from Symbol or AccountNumber alone.
3. **House accounts MUST be excluded** — Brian Sullivan (briansu@) owns the canonical list; verify with him for changes. Current list:
   - **Equity (3ET)**: `3ET00001` (avg price), `3ET00100` (deposit), `3ET00101` (error), `3ET00002` (fee), `3ET05007` (MSB/facilitation)
   - **Options (4GS)**: `4GS43999` (facilitation), `4GS00100` (deposit), `4GS00101` (error), `4GS00103` (fee), `4GS00104` (rewards/promos)
4. **Apex skips weekends** — `ProcessDate` follows the NASDAQ trading calendar, not eToro's internal calendar. Some Apex reports also skip Mon/Tue (deemed non-critical refresh). Always check `MAX(ProcessDate)` per file before joining to date dims; the canonical freshness query is the data source `apex last reports dates` in the `US Options 3.0 Monitoring (Including UK)` workbook.
5. **PFOF in `EXT1047_RevenueReports` is an ESTIMATE** — final figures come from Apex Finance and can vary by **20% or more**. Never use `v_revenue_optionsplatform.Amount` as the authoritative finance number. Use it only for trend / day-over-day comparison.
6. **`v_revenue_optionsplatform` is Options-only by design** — the view's join `LEFT JOIN bronze_usabroker_apex_options op ON rev.ClearingAccount = op.OptionsApexID` only matches when ClearingAccount equals an actual options account number. Equity PFOF is aggregated under a single ClearingAccount (`'3ET00001'` for Reg 6/7/8 or `'9820101'` for Reg 12) which won't match any specific OptionsApexID — so equity rows fall through. **This is intentional** — the view is scoped to Options-only PFOF. For Equity PFOF, query `EXT1047` directly (see `data-patterns.md` pattern #11). For cross-instrument PFOF totals, sum the two sources separately.
7. **`v_mimo_options_platform` Global FTD is hardcoded to FirstDepositDate >= 2025-09-01 AND FTDPlatformID = '2'** — anything before Sep 2025 returns `IsGlobalFTD = 0` mechanically (not because there was no global FTD before then). FTDPlatformID=2 is the Options platform ID. Don't use IsGlobalFTD for pre-Sep-2025 cohorts.
8. **`TradeNumber` is NOT unique — use `OrderID`** as the transaction-level key in `EXT872_TradeActivity`.
9. **`ACATSControlNumber` is the unique fund-movement key** in `EXT869_CashActivity`. Pair with `PayTypeCode IN ('C','D')` and EITHER `EnteredBy IN ('ACH','WRD')` (direct funding) OR `TerminalID = 'OMJNL'` (ICT internal transfer between main eToro and Options accounts). Failed/rejected transactions are NOT in this file.
10. **`apex_EXT981_BuyPowerSummary` has no RepCode** — must JOIN `EXT765_AccountMaster` for region/regulation context. The prep view `v_options_aum` skips this join (only carries GCID, no RegisteredRepCode), so for region splits you have to re-join EXT765 yourself or use a different anchor.

### Tier 2 — Aggregate / interpretation

11. **`apex_EXT1034` only stores accounts opened AFTER Unity Date (Nov 1, 2022)** — pre-Gatsby-era accounts and migrated accounts are NOT in this table. Use `EXT765_AccountMaster` for the full historical universe (it's the only table that preserves the Gatsby-era cohort).
12. **`EnteredBy IN ('ACH','WRD')` and `TerminalID = 'OMJNL'`** are the documented filters today, but the Doc warns these can evolve over time. The 3 prep views encode the current rules; if Apex adds a new EnteredBy code (e.g. for a future ICT variant), the views are wrong until updated.
13. **`AccountType` semantics** — `AccountType = 1` is cash, `AccountType = 2` is margin (in `EXT1034`). For `EXT981_BuyPowerSummary`, `CashEquity` and `MarginEquity` are BOTH "cash available" — when `AccountType = cash`: `TotalEquity = CashEquity + PositionMarketValue`; when `AccountType = margin`: `TotalEquity = MarginEquity + PositionMarketValue`. **Confirm with US OPS (Trading) before using either field — semantics may evolve.**
14. **`Margin = 'Y'` vs `OptionLevel IS NOT NULL`** in EXT765 — `Margin` indicates margin vs cash (account type); `OptionLevel` indicates options approval. A 4GS/5GU account with `OptionLevel IS NULL` has been opened on the options rail but is NOT yet approved to trade options (equity-only fallback for FINRAONLY). The "All existing options accounts" sample query filters `RepCode='FO1' AND OptionLevel IS NOT NULL` precisely to handle this case.
15. **`OpenDDate`** is the open-date column in `EXT765` — query as-is (the typo is preserved in the source).
16. **Trade timestamps are minute-granular only** — `ExecutionTime` is HHMM (no seconds). Timezone is **EST** (US Eastern), not UTC. Convert with care if joining to other-platform (UTC) trade tables.

### Tier 3 — Operational

17. **Schema split is intentional but non-obvious** — accounts live in `main.general`, financial activity in `main.finance`, regulatory dictionaries in `main.bi_db`, market events in `main.trading`. The same Apex SOD family (`bronze_sodreconciliation_apex_*`) is split across all four. See `source-tables.md` for the full table-to-schema mapping.
18. **`apex_EXT765_AccountMaster` is now in UC** at `main.general.bronze_sodreconciliation_apex_ext765_accountmaster` — the 2025 BI Doc says "doesn't exist in Synapse, request separately". As of 2026-05-31 it's in UC.
19. **`v_mimo_optionsplatform` (no underscore) is the older / deprecated copy** — it has 15 columns including `FundingTypeID` (mapped 42=OMJNL/29=ACH/2=WRD); the newer `v_mimo_options_platform` (with underscore) has 14 columns and drops FundingTypeID. Use the newer view for new work.

## Three Prep Views (the DDR backbone)

| View | Cols | Purpose | Source bronze tables |
|---|---|---|---|
| `v_options_aum` | 8 | One row per (`DateID`, `GCID`) — Options EOD balance + first-funding date | `bronze_sodreconciliation_apex_ext981_buypowersummary` + `bronze_usabroker_apex_options` |
| `v_mimo_options_platform` | 14 | One row per (`DateID`, `RealCID`, `TransactionID`) — Options MIMO with FTD detection (Local + Global) | `bronze_sodreconciliation_apex_ext869_cashactivity` + `bronze_usabroker_apex_options` + `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |
| `v_revenue_optionsplatform` | 26 | Per-customer Options PFOF revenue (Metric=`Options_PFOF`) | `bronze_sodreconciliation_apex_ext1047_revenuereports` + `bronze_usabroker_apex_options` + `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |

Plus `v_mimo_optionsplatform` (no underscore) — older / deprecated 15-column variant retaining `FundingTypeID`. Full DDLs and CTE walkthroughs in `views-architecture.md`.

## Tableau Dashboard Reference

**Repository**: `https://reports.etorocorp.com/#/projects/234` (Paloma's Repository) → project 430 (`1-US Management`). **11 workbooks**; 3 explicitly Options:

| Workbook | ID | Last modified | Data sources | Notes |
|---|---|---|---|---|
| **US Options Performance Monitoring** | 5820 | 2026-05-13 | 12 (11 UC + 1 Synapse fallback `historical trades, options`) | Canonical — view `US Options Weekly Mgmt Update` has **1,455 all-time hits** (most-consumed). Renders **New Signups vs Legacy Accounts** segmentation explicitly. |
| **US Options 3.0 Monitoring (Including UK)** | 7008 | 2026-05-30 | 6 (all UC) | UK + 3.0 funnel; includes the canonical `apex last reports dates` freshness data source |
| **US Options 3.0 Monitoring NYDFS+FINRA** | TBD | 2026-05-18 | TBD | NY-specific RegID=14 cohort tracker |

Plus 8 more workbooks in `1-US Management` that touch Options as part of broader US KPIs. Full inventory + per-workbook data source map in `dashboard-queries.md`.

## ETL Pipeline (one-paragraph summary)

Apex sends SOD (Start-Of-Day) files to the eToro `Sodreconciliation_PROD` server. Selected files are migrated to UC under `main.{general,finance,bi_db,trading}.bronze_sodreconciliation_apex_*`. Linkage tables (Apex AccountNumber ↔ eToro GCID) come from the `USABroker` server and land at `main.{general,bi_db,finance}.bronze_usabroker_*`. Apex skips weekends (NASDAQ calendar) + sometimes Mon/Tue. Data Engineering owners: Eyal Boas (eyalbo@), Pini Krisher (pinikr@). New table requests go through them; new dictionary additions and item-ID definitions through Victor Shatokhin (victorsh@) and Yulia Kramer (yuliakr@).

## Source of Truth

- **BI knowledge-transfer Doc**: Google Doc `1Vvqafpw-DlzcJhSK1JoLuNqNsXPXFckgbdYUvd0kHBk` ("Options Data Knowledge Transfer (BI)" by Brian Sullivan briansu@; curated by Paloma Cui palomacui@; V1 Oct 22 2025; last edit May 6 2026). Local extract: `knowledge/_inbox/gatsby-options/options-data-kt.md`.
- **Tableau repo**: `https://reports.etorocorp.com/#/projects/234`. Recon notes: `knowledge/_inbox/gatsby-options/tableau-recon.md`.
- **US OPS lead**: Brian Sullivan (briansu@) — owns the canonical house-account exclusion list and most "is this still true" business questions.
- **Existing Synapse wiki**: `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_Options_Platform.md` and `Function_Revenue_OptionsPlatform.md` (knowledge-only, not migrated to UC; kept for cross-reference).
- **Apex's official data dictionary**: `CoreExtracts` (external/Apex-side; ask Brian Sullivan for the latest URL).

## SMEs (people)

- Brian Sullivan (briansu@) — US OPS lead, house-account list, business-logic changes
- Paloma Cui (palomacui@) — BI / Tableau dashboards owner, the KT Doc curator
- Jeremy Moye (jeremymo@) — US OPS / Trading
- Victor Shatokhin (victorsh@) — dictionary IDs (e.g. `AppropriatenessRecalculationReasonID`)
- Yulia Kramer (yuliakr@) — table requests
- Eyal Boas (eyalbo@), Pini Krisher (pinikr@) — DE / Data Engineering for new pipelines

## Cross-references shared with other skills

- Valid-customer filter contract: see `knowledge/skills/cross-cutting/valid-users-filter-contract.md`. The Options prep views surface `IsValidCustomer` and `IsCreditReportValidCB` from `Dim_Customer`.
- DDR / MIMO panel: this skill feeds the DDR rows for the Options platform; the cross-platform aggregation lives in `domain-payments/mimo-panel-and-ddr.md`.
- The Synapse-side Function wrappers (`Function_MIMO_Options_Platform`, `Function_Revenue_OptionsPlatform`) reference the same Apex bronze tables; they're kept as knowledge-only and not deployed to UC. The 3 prep views are the UC-side replacements.

## Skill provenance

Authored 2026-05-31. Source materials:
- BI Options KT Doc (Google Doc) — full 1669-line `/mobilebasic` snapshot saved to `knowledge/_inbox/gatsby-options/options-data-kt.md`.
- Paloma Cui's Tableau repo — recon notes in `knowledge/_inbox/gatsby-options/tableau-recon.md` + canonical dashboard screenshot in same folder.
- UC inventory query (`main.information_schema.tables`) — 38 Apex/USABroker tables across 4 schemas.
- 4 view DDLs (`SHOW CREATE TABLE`) for `v_options_aum`, `v_mimo_options_platform`, `v_mimo_optionsplatform`, `v_revenue_optionsplatform`.
- Existing Synapse wiki entries for `Function_MIMO_Options_Platform` and `Function_Revenue_OptionsPlatform`.

Naming: `domain-options` not `domain-gatsby-options` — "Gatsby" is preserved as a trigger word and as the internal `RepCode='GAT'` / `Legacy Accounts` segmentation reference, but is not the canonical product name (the platform is Options; Apex is the broker; Gatsby is the brand-history footprint).
