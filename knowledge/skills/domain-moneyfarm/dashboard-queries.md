---
name: domain-moneyfarm
description: "Tableau workbook + Genie-space inventory for MoneyFarm — Ben Thompson's
  five UK/ISA Tableau workbooks (project 485): AM-ISA-Performance-V1 (id 7741, AM
  attribution + portfolio funding state, no fees), ISA-Focussed-Acquisition-Funnel
  (eligible→registered→FTF onboarding pipeline; the most-recent of the five),
  ISA-Market-Value-SFTP-data (AUM trend from silver_moneyfarm_etoro_mf_aum, the
  SFTP-fed silver), ISA-MIMO-Events-API-data (live event-stream MIMO from
  v_moneyfarm_mimo), UK-Funded-by-MoneyFarm-and-eToro (cross-product UK funded
  customers MF+eToro). Plus the CS-team ISACustomerLookupDashboard for per-CID
  MoneyFarm External-ID lookup (CS Confluence page 13209534657). Plus the UK BA
  Genie space [WIP] id 01f122020cb3178380de2efa0b990279 with 16 verbatim
  join_specs touching MoneyFarm objects + key sql_snippet for FTDPlatformID=4
  cohort definition. Includes 6 sample queries: Daily AUM trend, Daily MIMO with
  FTD overlay, Provenance-cohort funded customer count, Multi-product-wrapper
  customer profile, Per-portfolio risk-band drill-down, and Cross-platform
  funded universe (MF + Spaceship + eToro). Each sample maps to the deployed
  prep view and the cached wiki anchor."
triggers:
  - moneyfarm tableau
  - moneyfarm dashboards
  - ben thompson tableau
  - ISA tableau
  - ISA workbooks
  - AM ISA Performance
  - ISA Focussed Acquisition Funnel
  - ISA Market Value SFTP data
  - ISA MIMO Events API data
  - UK Funded by MoneyFarm and eToro
  - ISACustomerLookupDashboard
  - ISACustomerDashboard
  - moneyfarm genie
  - UK BA space WIP
  - 01f122020cb3178380de2efa0b990279
  - moneyfarm join_specs
  - moneyfarm sample queries
  - FTDPlatformID 4
sample_questions:
  - "What MoneyFarm Tableau workbooks does Ben Thompson own?"
  - "Where is the AM - ISA Performance V1 workbook? What does it track?"
  - "Show me a daily MoneyFarm AUM trend SQL"
  - "How do I count MoneyFarm-funded customers by provenance cohort?"
  - "Where do analysts join silver_moneyfarm_etoro_mf_aum to bronze_sub_accounts_accounts?"
  - "How do I find a customer's MoneyFarm External-ID for CS handling?"
required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.bi_db.bronze_sub_accounts_accounts
  - main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# MoneyFarm — Dashboard & Genie Reference + Sample Queries

## Tableau workbook inventory

**Repository**: `https://reports.etorocorp.com/#/projects/76` (UK project) → project 485 (`UK/ISA`).
**Owner of all 5 workbooks**: **Ben Thompson** (`benth@etoro.com`, UK analyst).

### Workbook 1 — `AM - ISA Performance V1`

| Attribute | Value |
|---|---|
| ID | 7741 |
| URL | `https://reports.etorocorp.com/#/workbooks/7741/views` |
| Last modified | 2026-02-26 |
| Sheets | 2 — `CID Level`, `AM Aggregated` |
| Field count (lineage) | 27 fields |
| Custom SQL | yes — Silver-first portfolio panel with events |
| Fee fields | **none** |

**What it shows**: Account-Manager attribution + 30-day pre-FTF contact flags + portfolio funding state. **"AM" = Account Manager** (NOT Asset Management). The 27 fields cover AUM, MIMO, funding state, AM contact flags, AM identity, but no fee columns. The Custom SQL preamble (paraphrased from inspection): *"Silver-first portfolio panel with events; adds funding/defunding flags + manager/club at FTD; dedupes silver double-sends by max SourceFile per (etr_ymd, Portfolio_Id)."*

### Workbook 2 — `ISA Focussed Acquisition Funnel`

| Attribute | Value |
|---|---|
| Last modified | 2026-04-30 (the most recently updated of the 5) |
| What it shows | Eligible → Registered → FTF onboarding funnel for the V2 eligibility cohort |
| Likely UC sources | `dim_customer` (filter UK + FCA + non-legacy) → `bi_output_moneyfarm_customers` (Date_Source_Type) → `v_moneyfarm_mimo` (is_ftd) |

The funnel logic mirrors the V2 HLD eligibility criteria — `countryID=UK + designatedRegulation=FCA + playerStatus=Normal + ≥1 Approved deposit + non-legacy`. Conversion rates between funnel stages are the canonical UK-ISA acquisition KPI.

### Workbook 3 — `ISA Market Value (SFTP data)`

| Attribute | Value |
|---|---|
| Last modified | 2026-02-26 |
| What it shows | AUM trend from the SFTP-fed silver |
| Primary UC source | `money_farm.silver_moneyfarm_etoro_mf_aum` (the SFTP-fed silver) |
| Likely prep view | `v_moneyfarm_aum` (which wraps the same silver) |

The "(SFTP data)" qualifier in the workbook name is deliberate — Ben uses it to distinguish from the live-event-stream-fed `ISA MIMO (Events API data)` workbook. The SFTP path is the canonical AUM source; the EventHub path is the canonical MIMO source.

### Workbook 4 — `ISA MIMO (Events API data)`

| Attribute | Value |
|---|---|
| Last modified | 2026-03-25 |
| What it shows | Daily deposits + withdrawals from the EventHub stream |
| Primary UC source | `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` (filtered `Moneyfarm`) — i.e. the source of `v_moneyfarm_mimo` |
| Likely prep view | `v_moneyfarm_mimo` |

The "(Events API data)" qualifier signals that this workbook bypasses the silver back-fill path and reads directly from the live event stream — so it's the freshest view of MIMO but only covers Oct 2025+ activity.

### Workbook 5 — `UK Funded - by MoneyFarm & eToro`

| Attribute | Value |
|---|---|
| Last modified | 2026-04-08 |
| What it shows | Cross-product UK funded customers (MoneyFarm + eToro main) |
| Likely UC sources | `Dim_Customer` filtered country=UK + `bi_output_moneyfarm_customers` for MF-funded universe |

The cross-product cut likely uses the `FTDPlatformID` taxonomy: `FTDPlatformID = 1` (Trading Platform) vs `FTDPlatformID = 4` (ISA/MoneyFarm) per the UK BA Genie sql_snippet — to split UK-funded customers by where they first deposited.

### CS-side dashboard — `ISACustomerLookupDashboard` / `ISACustomerDashboard`

| Attribute | Value |
|---|---|
| Owner | CS team (referenced from Confluence CS/13209534657) |
| What it shows | Per-CID MoneyFarm External-ID lookup; ISA customer history |
| Used by | CS TLs handling MoneyFarm-related Tmail tickets |

Not directly authored by Ben Thompson; it's the operational lookup tool for CS. CS Confluence page `13209534657` ("Individual Savings Account (ISA) - MoneyFarm For CS TLs") routes TLs to this dashboard for the External-ID lookup.

## UK BA Genie space [WIP] — the Tier-3 goldmine

**Space ID**: `01f122020cb3178380de2efa0b990279`
**Title**: "UK BA space [WIP]"
**Cached at**: `knowledge/uc_domains/moneyfarm/_discovery/genie_spaces/01f122020cb3178380de2efa0b990279__uk-ba-space-wip.json` (256KB).

**Total registered tables**: 30. **Total `join_specs`**: 52. **MoneyFarm-touching join_specs**: 16.

### MoneyFarm-touching join_specs (verbatim, from the cached JSON)

| # | Join | SQL | Cardinality | Instruction |
|---|------|-----|-------------|-------------|
| 1 | `dim_customer.GCID = silver_moneyfarm_etoro_mf_aum.GCID` | `gold_sql_dp_prod_we_dwh_dbo_dim_customer.GCID = silver_moneyfarm_etoro_mf_aum.GCID` | (rt unspecified) | (no instruction) |
| 2 | `dim_customer.GCID = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | `gold_sql_dp_prod_we_dwh_dbo_dim_customer.GCID = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | (rt unspecified) | (no instruction) |
| 3 | `dim_customer.GCID = bi_output_moneyfarm_fact_transactions.GCID` | `gold_sql_dp_prod_we_dwh_dbo_dim_customer.GCID = bi_output_moneyfarm_fact_transactions.GCID` | (rt unspecified) | (no instruction) |
| 4 | `bronze_sub_accounts_accounts.gcid = bronze_event_hub_prod_event_streaming_we_sub_accounts.EventPayloadRowData_EventMetadata_Gcid` | (combined) | n/a | **"ensure to filter/join also on bronze_sub_accounts_accounts by providerName = 'Moneyfarm' and filter/join also on EventPayloadRowData_ProviderName = 'Moneyfarm' when joining these two tables. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."** |
| 5 | `bronze_sub_accounts_accounts.gcid = silver_moneyfarm_etoro_mf_aum.GCID` | (verbatim) | n/a | **"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."** |
| 6 | `bronze_sub_accounts_accounts.gcid = bi_output_moneyfarm_fact_portfolio_snapshot.GCID` | (verbatim) | n/a | **"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."** |
| 7 | `bronze_sub_accounts_accounts.gcid = bi_output_moneyfarm_fact_transactions.GCID` | (verbatim) | n/a | **"Make sure to filter/join also on bronze_sub_accounts_accounts where providerName = 'Moneyfarm'. This ensures bronze_sub_accounts_accounts is 'one' in the 'one to many' relationship."** |
| 8 | `fact_portfolio_snapshot.GCID = silver_moneyfarm_etoro_mf_aum.GCID` | (verbatim) | n/a | (no instruction — this is the within-MoneyFarm cross-grain join; can give multi-row blow-up if not used carefully) |
| 9 | `fact_portfolio_snapshot.GCID = fact_transactions.GCID` | (verbatim) | n/a | (no instruction) |
| 10 | `silver_moneyfarm_etoro_mf_aum.GCID = fact_transactions.GCID` | (verbatim) | n/a | (no instruction) |
| 11 | `fact_portfolio_snapshot.PortfolioID = fact_transactions.PortfolioID` | (verbatim, ONE_TO_MANY) | ONE_TO_MANY | (no instruction) |
| 12 | `fact_portfolio_snapshot.PortfolioID = silver_moneyfarm_etoro_mf_aum.Portfolio_Id` | (verbatim, ONE_TO_MANY — note case difference Portfolio_Id vs PortfolioID) | ONE_TO_MANY | (no instruction) |
| 13 | `silver_moneyfarm_etoro_mf_aum.Portfolio_Id = fact_transactions.PortfolioID` | (verbatim) | n/a | (no instruction) |
| 14 | `silver_moneyfarm_etoro_mf_aum.Identifier_Value = bronze_sub_accounts_accounts.externalUserId` | (verbatim) | n/a | (no instruction — this is the alternative join when you don't have a resolved GCID) |
| 15 | `bronze_event_hub.EventPayloadRowData_EventMetadata_Gcid = fact_portfolio_snapshot.GCID` | (verbatim) | MANY_TO_MANY | **"A single GCID can have multiple Portfolios (PortfolioIDs) and rows for each portfolio in each table. Therefore when joining on GCID there are multiple different rows for a GCID on left and right."** |
| 16 | `bronze_event_hub.EventPayloadRowData_EventMetadata_Gcid = fact_transactions.GCID` | (verbatim) | n/a | (no instruction) |

### Key UK BA Genie sql_snippet — main user filters

This snippet sits in the UK BA space `sql_snippets[]` array (id `01f12868d28d1782b0f3e1f7fd26e5d1`) under question *"Main user details/filters/identifiers/classifications"*. The MoneyFarm-relevant fragment:

```sql
SELECT
    dc.RealCID AS CID,
    dc.GCID,
    dc.FTDPlatformID,
        --The ID relating to the area of the platform the user first deposited to:
        --   4 = ISA/Moneyfarm,
        --   3 = IBAN,
        --   2 = Options,
        --   1 = Trading Platform
    at.Name AS FTDPlatformName,
    -- ... other dim_customer columns ...
FROM   main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc
JOIN   main.bi_db.bronze_moneybusdb_dictionary_accounttypes at
       ON at.ID = dc.FTDPlatformID
WHERE  IsValidCustomer = 1
```

The `at.Name` lookup resolves `FTDPlatformID = 4` → `'ISA/Moneyfarm'` (via `bi_db.bronze_moneybusdb_dictionary_accounttypes`).

## Sample queries

### Sample 1 — Daily AUM trend (Q1 2026)

Maps to: Ben's `ISA Market Value (SFTP data)` workbook.

```sql
SELECT
    a.dateid,
    a.date,
    SUM(a.total_balance_gbp)        AS aum_gbp,
    SUM(a.total_balance_usd)        AS aum_usd,
    COUNT(DISTINCT a.gcid)          AS funded_customers,
    AVG(a.portfolio_count)          AS avg_portfolios_per_customer
FROM main.etoro_kpi_prep.v_moneyfarm_aum a
WHERE a.dateid BETWEEN 20260101 AND 20260331
  AND a.is_funded = TRUE
GROUP BY a.dateid, a.date
ORDER BY a.dateid
```

### Sample 2 — Daily MIMO with FTD overlay

Maps to: Ben's `ISA MIMO (Events API data)` workbook.

```sql
SELECT
    m.dateid,
    m.date,
    SUM(m.total_deposits_gbp)               AS deposits_gbp,
    SUM(m.total_withdrawals_gbp)            AS withdrawals_gbp,
    SUM(m.net_flow_gbp)                     AS net_flow_gbp,
    SUM(m.count_deposits)                   AS deposit_events,
    SUM(m.count_withdrawals)                AS withdrawal_events,
    COUNT(DISTINCT CASE WHEN m.is_ftd THEN m.gcid END) AS ftd_customers
FROM main.etoro_kpi_prep.v_moneyfarm_mimo m
WHERE m.dateid BETWEEN 20251001 AND 20260331  -- live-stream coverage starts Oct 2025
GROUP BY m.dateid, m.date
ORDER BY m.dateid
```

### Sample 3 — Provenance-cohort funded count

Maps to: a slicer on the funnel workbook.

```sql
WITH funded_today AS (
    SELECT a.gcid
    FROM main.etoro_kpi_prep.v_moneyfarm_aum a
    WHERE a.dateid = 20260331
      AND a.is_funded = TRUE
)
SELECT
    c.Date_Source_Type,
    COUNT(DISTINCT c.GCID)              AS customers_in_cohort,
    COUNT(DISTINCT f.gcid)              AS funded_today_in_cohort,
    ROUND(100.0 * COUNT(DISTINCT f.gcid) / COUNT(DISTINCT c.GCID), 1) AS pct_funded
FROM main.bi_output.bi_output_moneyfarm_customers c
LEFT JOIN funded_today f ON f.gcid = c.GCID
GROUP BY c.Date_Source_Type
ORDER BY customers_in_cohort DESC
```

### Sample 4 — Multi-product-wrapper customer profile

Maps to: cross-tab in `AM - ISA Performance V1`.

```sql
SELECT
    fps.GCID,
    COUNT(DISTINCT fps.PortfolioID)       AS portfolio_count,
    COUNT(DISTINCT fps.Product_Name)      AS product_count,
    COLLECT_SET(fps.Product_Name)         AS products,
    SUM(fps.Current_Market_Value_GBP)     AS aum_gbp_today
FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps
WHERE fps.UpdateDate = (SELECT MAX(UpdateDate) FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot)
  AND fps.Source_Type = 'Live Event'
GROUP BY fps.GCID
HAVING COUNT(DISTINCT fps.Product_Name) >= 2  -- multi-wrapper customers only
ORDER BY aum_gbp_today DESC
LIMIT 50
```

### Sample 5 — Per-portfolio risk-band drill-down

Maps to: an ad-hoc slicer used during onboarding QA.

```sql
SELECT
    fps.Product_Name,
    fps.Portfolio_Risk_Level,
    COUNT(*)                              AS portfolio_count,
    COUNT(DISTINCT fps.GCID)              AS customer_count,
    SUM(fps.Current_Market_Value_GBP)     AS aum_gbp_total,
    AVG(fps.Current_Market_Value_GBP)     AS aum_gbp_avg
FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot fps
WHERE fps.UpdateDate = (SELECT MAX(UpdateDate) FROM main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot)
GROUP BY ROLLUP (fps.Product_Name, fps.Portfolio_Risk_Level)
ORDER BY fps.Product_Name, fps.Portfolio_Risk_Level
```

**Caveat**: `Portfolio_Risk_Level` band semantics (`P0..P7`) are NOT Confluence-anchored — see `metric-definitions.md` §5.

### Sample 6 — Cross-platform funded universe (MF + Spaceship + eToro)

Maps to: Ben's `UK Funded - by MoneyFarm & eToro` workbook.

```sql
WITH mf_funded AS (
    SELECT DISTINCT gcid AS GCID
    FROM main.etoro_kpi_prep.v_moneyfarm_aum
    WHERE dateid = 20260331 AND is_funded = TRUE
),
spaceship_funded AS (
    SELECT DISTINCT gcid AS GCID
    FROM main.etoro_kpi.v_spaceship_aum    -- Spaceship's parallel — see domain-spaceship
    WHERE date_id = 20260331 AND is_funded = TRUE
),
etoro_funded AS (
    SELECT RealCID AS GCID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer
    WHERE FirstDepositAmount > 0
      AND IsValidCustomer = 1
      AND CountryID = (SELECT CountryID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country WHERE Name = 'United Kingdom')
)
SELECT
    CASE
        WHEN mf.GCID IS NOT NULL AND etoro.GCID IS NOT NULL THEN 'MoneyFarm + eToro'
        WHEN mf.GCID IS NOT NULL                              THEN 'MoneyFarm only'
        WHEN sp.GCID IS NOT NULL AND etoro.GCID IS NOT NULL  THEN 'Spaceship + eToro'
        WHEN sp.GCID IS NOT NULL                              THEN 'Spaceship only'
        ELSE                                                       'eToro only'
    END                                  AS cohort,
    COUNT(DISTINCT COALESCE(mf.GCID, sp.GCID, etoro.GCID)) AS uk_funded_customers
FROM etoro_funded etoro
FULL OUTER JOIN mf_funded         mf  ON etoro.GCID = mf.GCID
FULL OUTER JOIN spaceship_funded  sp  ON etoro.GCID = sp.GCID
GROUP BY cohort
ORDER BY uk_funded_customers DESC
```

**Caveats**:
- This sample assumes Spaceship's view name is `v_spaceship_aum` and column is `date_id` (with underscore). Confirm against `domain-spaceship/views-architecture.md` before running.
- The eToro-funded UK universe uses `Dim_Customer.FirstDepositAmount > 0` + UK country filter, which is approximate — for the precise "funded customer" definition see `domain-customer-and-identity/customer-populations`.
- `IsValidCustomer = 1` filter from the UK BA Genie sql_snippet — keep it on.

## Where to find more dashboards

- `https://reports.etorocorp.com/#/projects` → search by owner Ben Thompson (`benth@etoro.com`).
- `https://reports.etorocorp.com/#/projects/76` (UK project) → other UK-related workbooks beyond ISA.
- `https://reports.etorocorp.com/#/projects/485` (UK/ISA sub-project) — the canonical home of the 5 ISA workbooks.
- `https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13600260206/MoneyFarm` — the Investment Portfolio Analytics Genie space's Confluence landing page (lighter-weight than the UK BA WIP space).

## Genie spaces summary

| Space ID | Title | Tables registered | MoneyFarm join_specs | Notes |
|---|---|---|---|---|
| `01f122020cb3178380de2efa0b990279` | UK BA space [WIP] | 30 | **16** | The Tier-3 goldmine — analyst-authored joins with explicit `instruction` text |
| `01f14394002815a288421fd85f36d595` | Investment Portfolio Analytics | 1 | n/a | Just registers `bi_output_moneyfarm_fact_portfolio_snapshot` |
| `01f092d3b7d3120f889da5ebede3b4c2` | New space (template) | unknown | unknown | Template / unfinished — likely safe to ignore |

When in doubt about how to join two MoneyFarm tables, **consult the UK BA WIP Genie space first**.
