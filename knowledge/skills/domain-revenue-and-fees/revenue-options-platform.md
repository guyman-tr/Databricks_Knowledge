---
name: domain-revenue-and-fees
description: |
  Revenue from the eToro Options product — end to end. Owns the
  Options_PFOF DDR metric (RevenueMetricID = 18, added 2025-10-22),
  the canonical `etoro_kpi_prep.v_revenue_optionsplatform` view,
  the Options AUM panel (`v_options_aum`), the Options MIMO flows
  (`v_mimo_options_platform` / `v_mimo_optionsplatform`), and the Apex
  SFTP feed family that delivers the raw data: revenue reports
  (`bronze_sodreconciliation_apex_ext1047_revenuereports`), trade activity
  (`ext872`), cash activity (`ext869`), stock activity (`ext870`),
  dividend report (`ext922`), account master (`ext765`), buying-power
  summary (`ext981`), the SOD file registry (`sodfiles`), and the
  Apex / USABroker reference / dictionary tables.

  CRITICAL disambiguation: **Gatsby is the product brand (acquired);
  Apex (= USABroker) is the broker.** Two ingest paths off the same broker:
  Options product → Apex SFTP → this sub-skill. US-resident customer
  equities cleared by Apex → regular trading tables (Dim_Position,
  Fact_Position) — NOT this sub-skill. Same broker, different downstream.
  Gatsby-side systems were NEVER ingested.
triggers: [Options_PFOF, options product, USA broker, US equity, Apex SFTP, Apex sodfiles, ext1047 revenuereports, ext872 tradeactivity, ext869 cashactivity, ext870 stockactivity, ext922 dividendreport, ext765 accountmaster, ext981 buypowersummary, apexrecon, options reasoning form, PTP, buying power]
load_after: [_router.md, domain-revenue-and-fees/SKILL.md]
intersects_with:
  - domain-revenue-and-fees/trading-revenue-and-fees    # US-equity trades land in regular trading tables, NOT here
  - domain-payments/mimo-panel-and-ddr                  # Options-side MIMO rolls up to BI_DB_DDR_Fact_MIMO_AllPlatforms
  - domain-cross/dealing-broker-identity                # planned — broker / LP master
primary_objects:
  - main.etoro_kpi_prep.v_revenue_optionsplatform     # canonical Options revenue KPI view (Options_PFOF)
  - main.etoro_kpi_prep.v_options_aum                 # canonical Options AUM panel
  - main.etoro_kpi_prep.v_mimo_options_platform       # Options MIMO flows
  - main.etoro_kpi_prep.v_mimo_optionsplatform        # alias / variant
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports  # the headline raw revenue feed
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity    # raw trade activity
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity     # raw cash activity (deposits / withdrawals)
  - main.finance.bronze_sodreconciliation_apex_ext870_stockactivity    # raw stock activity
  - main.finance.bronze_sodreconciliation_apex_ext922_dividendreport   # raw dividend report
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster    # raw account master
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary  # buying-power summary
  - main.finance.bronze_sodreconciliation_apex_sodfiles                # SOD file registry
  - main.general.gold_apex_ext869_3eu                                  # gold cash activity
  - main.general.gold_apex_ext870_3eu                                  # gold stock activity
  - main.general.gold_apex_ext872_3eu_217314                           # gold trade activity
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity
  - main.general.bronze_usabroker_apex_options                         # options-side reference data
  - main.general.bronze_usabroker_history_options                      # historical options data
  - main.finance.bronze_usabroker_apex_apexdata                        # USABroker / Apex account state
out_of_scope:
  - US-resident customer EQUITY trading (regular stocks for US customers cleared by Apex) — goes to the regular trading tables (Dim_Position, Fact_Position, etc.); see trading-revenue-and-fees.md
  - Trading-platform fees (eToro-native FullCommission, Rollover, Ticket, etc.) → trading-revenue-and-fees.md
  - MIMO-side fees → fees-deposit-withdraw-fx.md
  - Customer money VOLUMES via Options MIMO → payments super-domain (the Options MIMO views ALSO roll up to the canonical MIMO panel)

version: 1
owner: "dataplatform"

required_tables:
  - main.etoro_kpi_prep.v_revenue_optionsplatform
  - main.etoro_kpi_prep.v_options_aum
  - main.etoro_kpi_prep.v_mimo_options_platform
  - main.etoro_kpi_prep.v_mimo_optionsplatform
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext870_stockactivity
  - main.finance.bronze_sodreconciliation_apex_ext922_dividendreport
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.finance.bronze_sodreconciliation_apex_sodfiles
  - main.general.gold_apex_ext869_3eu
  - main.general.gold_apex_ext870_3eu
  - main.general.gold_apex_ext872_3eu_217314
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity
  - main.general.bronze_usabroker_apex_options
  - main.general.bronze_usabroker_history_options
  - main.finance.bronze_usabroker_apex_apexdata
last_validated_at: "2026-05-10"

---

# H.5 — Options-platform revenue (Gatsby brand / Apex broker)


## When to Use
Load when the question is about Options platform revenue — PFOF, Apex/Gatsby fees, or Options-specific revenue streams.

## Scope
In scope: Options PFOF (Payment For Order Flow), Apex/Gatsby revenue, Options platform trading revenue, v_options_aum for equity context
Out of scope: TP options (InstrumentTypeID=9 on eToro platform) → trading-revenue-and-fees.md; Options AUM (equity, not revenue) → portfolio-value skill
Last verified: 2026-05-10

This sub-skill owns the eToro Options product, end-to-end on the revenue side. Locked in before the rest: **Gatsby is the PRODUCT brand; Apex (= USABroker) is the BROKER.**

## Gatsby vs Apex — the disambiguation that must be in every answer

| Name | What it is |
|------|------------|
| **Gatsby** | The eToro Options product, acquired. A product brand. Gatsby-side systems (the original Gatsby app stack) were **NEVER ingested** into the lake. |
| **Apex** | The actual broker. Also referred to internally as **USABroker**. Apex feeds the lake daily via SFTP. |

**Two ingest paths off the same broker:**

| Path | Where its revenue lives | Sub-skill |
|------|-------------------------|-----------|
| Gatsby Options product | Apex SFTP → `etoro_kpi_prep.v_revenue_optionsplatform` (and `Metric = 'Options_PFOF'` rows in the DDR fact) | **This sub-skill (H.5)** |
| US-resident customer EQUITY trading (regular stocks for US customers, cleared by Apex) | Regular trading tables — `Dim_Position`, `Fact_Position`, etc. — **just like any other trade**; revenue flows as `FullCommission`, etc. | **H.1 `trading-revenue-and-fees.md`** |

Same broker, two different downstream pipelines. Don't conflate.

## The 1 DDR metric this sub-skill owns

| RevenueMetricID | Metric | Category | What it is | When added |
|-----------------|--------|----------|------------|------------|
| 18 | `Options_PFOF` | Other | Payment For Order Flow from options routing | **2025-10-22** (don't pre-date) |

## Where Options revenue lives (in UC, in order of grain)

| Object | Grain | Purpose |
|--------|-------|---------|
| DDR fact, `Metric = 'Options_PFOF'` | Daily aggregated per CID | Total Options revenue for KPI dashboards |
| `etoro_kpi_prep.v_revenue_optionsplatform` | Per-event Options_PFOF revenue | Canonical Options revenue view |
| `etoro_kpi_prep.v_options_aum` | Per-customer per-day Options AUM | Options AUM panel |
| `etoro_kpi_prep.v_mimo_options_platform` / `v_mimo_optionsplatform` | Options MIMO (deposits/withdrawals INTO Options) | Customer money flow into the Options product. Also rolls up to `BI_DB_DDR_Fact_MIMO_AllPlatforms` (Payments). |
| `finance.bronze_sodreconciliation_apex_ext1047_revenuereports` | Raw daily Apex SFTP revenue report | The raw revenue feed from Apex |
| `finance.bronze_sodreconciliation_apex_ext872_tradeactivity` / `general.gold_apex_ext872_3eu_217314` | Raw / gold daily trade activity | Per-trade execution detail (price, fees, commissions on the Apex side) |
| `finance.bronze_sodreconciliation_apex_ext869_cashactivity` / `general.gold_apex_ext869_3eu` | Raw / gold daily cash activity | Customer deposits / withdrawals on the Options account |
| `finance.bronze_sodreconciliation_apex_ext870_stockactivity` / `general.gold_apex_ext870_3eu` | Raw / gold daily stock activity | Per-stock daily position change |
| `finance.bronze_sodreconciliation_apex_ext922_dividendreport` | Raw daily dividend report | Apex-cleared dividend events |
| `general.bronze_sodreconciliation_apex_ext765_accountmaster` | Apex account master | Account-level reference (customer → Apex account number) |
| `general.bronze_sodreconciliation_apex_ext981_buypowersummary` | Buying-power summary | Per-account daily buying power |
| `finance.bronze_sodreconciliation_apex_sodfiles` | Daily SOD (start-of-day) file registry | Tracks which files have arrived per day — debugging SFTP gaps |
| `dealing.gold_*_dealing_apexrecon_holdings` | Reconciliation snapshot | Apex holdings reconciled against eToro internal records |
| `dealing.gold_*_dealing_apexrecon_tradeactivity` | Reconciliation snapshot | Apex trade activity reconciled |

## Apex SFTP file convention

The `apex_ext<NNN>_*` naming reflects the Apex SFTP file numbering:

| Apex file # | What it is |
|-------------|------------|
| `ext765` | Account master |
| `ext869` | Cash activity (deposits/withdrawals) |
| `ext870` | Stock activity (positions) |
| `ext872` | Trade activity (executions) |
| `ext922` | Dividend report |
| `ext981` | Buying-power summary |
| `ext982` | (additional report) |
| `ext1034` | New account financial information |
| `ext1047` | **Revenue reports — the headline revenue feed** |

All arrive daily via SFTP. The `bronze_sodreconciliation_apex_*` family is the raw landing; `general.gold_apex_ext<NNN>_*` is the cleaned / promoted version where it exists.

## Identity bridge

Apex account number → eToro customer is via `general.bronze_sodreconciliation_apex_ext765_accountmaster.AccountNumber` (the Apex side) cross-referenced with the **Customer & Identity** super-domain's identity model. See `domain-customer-and-identity/SKILL.md` for the Apex `AccountNumber` cross-reference table (currently maintained alongside Spaceship `user_id`, MoneyFarm `moneyfarmUserId`, etc.).

## Query patterns

### Pattern 1 — Total Options_PFOF revenue (Apex SFTP feed didn't start at the beginning)
```sql
SELECT
    FLOOR(DateID / 100) AS yyyymm,
    SUM(Amount) AS options_pfof_revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'Options_PFOF'
  AND DateID BETWEEN 20251022 AND 20260331
GROUP BY yyyymm
ORDER BY yyyymm;
```
**Note:** `Dim_Revenue_Metrics.UpdateDate` for `Options_PFOF` = `2025-10-22`. Don't query DDR rows for this metric BEFORE that date — they won't exist.

### Pattern 2 — Options AUM trend
```sql
SELECT DateID, SUM(AumUSD) AS options_aum_usd, COUNT(DISTINCT GCID) AS n_customers
FROM main.etoro_kpi_prep.v_options_aum
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```

### Pattern 3 — Apex revenue report sanity-check (vs DDR)
```sql
SELECT DateID, SUM(<RevenueAmountColumn>) AS apex_reported_revenue
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
WHERE DateID BETWEEN 20260101 AND 20260131
GROUP BY DateID
ORDER BY DateID;
```
(Column name TBD; inspect the table schema to confirm. Sanity-check against the DDR `Options_PFOF` rollup.)

## Critical Warnings

1. **Gatsby is NOT a broker. Apex is.** Never describe Gatsby as having its own ingest pipeline — it does not. Gatsby-side systems were never ingested. All Options data comes via Apex SFTP.
2. **US-equity revenue for US-resident customers is NOT in this sub-skill.** That goes to H.1 `trading-revenue-and-fees.md` via the regular trading tables. Same broker (Apex), different pipeline.
3. **`Options_PFOF` started 2025-10-22** (per `Dim_Revenue_Metrics.UpdateDate`). Don't claim Options revenue exists in the DDR fact before that date.
4. **The Apex SFTP feed is delivered daily.** If a `DateID` is missing from the bronze tables, check `finance.bronze_sodreconciliation_apex_sodfiles` to confirm the file arrived — gaps happen and are not always backfilled.
5. **`bronze_sodreconciliation_apex_*` vs `bronze_usabroker_apex_*`** — both exist, both relate to Apex. The `sodreconciliation_*` family is the daily SOD file landing; the `usabroker_*` family is broader USABroker reference / state data (options dictionary, validation errors, user data history). Pick the right one based on the question (revenue / activity → `sodreconciliation_*`; reference / status → `usabroker_*`).
6. **Options MIMO ALSO rolls up to the canonical MIMO panel** (`BI_DB_DDR_Fact_MIMO_AllPlatforms`). For Options-product-specific MIMO use the Options views; for cross-product MIMO (Options + eToro + Spaceship + MoneyFarm) use the canonical MIMO panel (Payments super-domain).
7. **Apex options-status enums live in `bronze_usabroker_dictionary_optionsstatus` and `bronze_usabroker_dictionary_optionsstatuscontrol`** — join through if you need to interpret raw status codes.

## Cluster provenance

- `v_revenue_optionsplatform`, `v_options_aum`, `v_mimo_options_platform` — `etoro_kpi_prep`, joined to DDR via CID.
- `finance.bronze_sodreconciliation_apex_*` — Apex SFTP ingest cluster (Finance super-domain raw data).
- `dealing.gold_*_dealing_apexrecon_*` — Dealing-side reconciliation (Trading super-domain when built).

## Source of truth

- DDR `Options_PFOF` rows derive from `v_revenue_optionsplatform` (when this view ships data into the DDR via `SP_DDR_Fact_Revenue_Generating_Actions`).
- The raw revenue feed is `finance.bronze_sodreconciliation_apex_ext1047_revenuereports`.
- The Apex SFTP file numbering scheme is Apex-side convention (file numbers `ext765`, `ext869`, ... are Apex's, not eToro's invention).
