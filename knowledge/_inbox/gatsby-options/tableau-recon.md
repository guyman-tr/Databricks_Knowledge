# Tableau / Paloma's Repository — recon notes (2026-05-31)

**Source**: `https://reports.etorocorp.com/#/projects/234` (Paloma's Repository under USA → project 234), and `#/projects/430` (1-US Management — the headline Options sub-project)
**Owner**: Paloma Cui (with co-contribution from Georgios Kyriakou on End-to-End Funnel + KPI Monthly)
**Captured**: 2026-05-31 via cursor-ide-browser MCP, signed in as guyman@etoro.com

## Repository structure

`Paloma's Repository` (project 234) → 6 sub-projects + 1 workbook:

1. **1-US Management** (Updated Oct 15, 2025) — 11 workbooks ← Options-related lives here
2. 2-US Operations
3. 3-US Marketing & PR
4. 4-US Compliance
5. 5-US Finance
6. 6-To be Decommissioned
7. CA Types (workbook, May 18 2026)

## `1-US Management` workbook inventory (11 workbooks)

| # | Workbook | Owner | Last modified | Options-relevance |
|---|---|---|---|---|
| 1 | US Acquisition Funnel (3.0 States vs. Others) | Paloma Cui | May 21, 2026 | ✅ Options 3.0 funnel |
| 2 | US BOD - Operational Insight | Paloma Cui | May 14, 2026 | partial (US-wide ops, includes Options) |
| 3 | US End-End Funnel | Paloma Cui | May 21, 2026 | partial |
| 4 | US End-to-End Funnel | Georgios Kyriakou | **May 31, 2026** (yesterday) | partial |
| 5 | US KPI Daily Highlights | Paloma Cui | May 30, 2026 | partial (includes Options KPIs) |
| 6 | US KPI Daily Highlights RegulationID - 14 (NYDFS+FINRA) | Paloma Cui | May 21, 2026 | ✅ NY Crypto launch tracking |
| 7 | US KPI Monthly Highlights | Georgios Kyriakou | May 4, 2026 | partial |
| 8 | **US Options 3.0 Monitoring (Including UK)** | Paloma Cui | May 30, 2026 | ⭐ Options-explicit |
| 9 | **US Options 3.0 Monitoring NYDFS+FINRA** | Paloma Cui | May 18, 2026 | ⭐ Options-explicit |
| 10 | **US Options Performance Monitoring** | Paloma Cui | May 13, 2026 | ⭐ Options-explicit (canonical) |
| 11 | US Trading Monitoring | Paloma Cui | **May 31, 2026** (yesterday) | partial |

## Workbook deep-dive — `US Options Performance Monitoring`

**URL**: `https://reports.etorocorp.com/#/workbooks/5820/`

### Views (3)

| View | All-time views | Notes |
|---|---|---|
| **US Options Weekly Mgmt Update** | **1,455** | Canonical Options dashboard — most-consumed view in the repo |
| US Options Legacy Users | 9 | "Legacy" = Gatsby-era pre-acquisition users |
| Options Traders KYC Profile | 78 | Compliance segmentation of options traders |

### Visual content of `US Options Weekly Mgmt Update` (rendered + screenshotted)

Title: **"US Options KPI Monitoring (Incl. UK Beta)"**

**Section 1 — Monthly Conversion: Key Activation Steps**
- Monthly Options First Funded Accounts *(ICT-Internal Cash Transfer, plus Direct Funding)* — bar chart Dec 2022 → May 2026
- Monthly First Options Trade — bar chart Dec 2022 → May 2026

**Section 2 — Weekly Cumulative since Unity Day**
- Funded Accounts (incl. Churn) — line chart, latest ≈ 12,621
- Total Contracts Traded (Buy and Sell) — line chart, latest ≈ 22,127

**Section 3 — Monthly Options Trading Data**
- Monthly Active Open Options Traders (Buy) — bars by month, **segmented New Signups vs Legacy Accounts** with % New Signups overlay line
- Monthly Active Options Traders (Buy or Sell)
- Monthly Contracts Traded (Buy and Sell)

→ Implied KPI surface: First-Funded, First-Trade, Funded (cum), Contracts Traded (cum), Active Open Traders (Buy), Active Traders (Buy+Sell), Contract Volume — all sliced by **New Signups vs Legacy** (post-Unity vs Gatsby-era).

### Data Sources (12) — May 12, 2026 extract refresh

| Type | Name | Backing |
|---|---|---|
| Live (txt) | Clipboard_20251119T125710 | Manual paste |
| Extract | **Databricks, Gatsby legacy user trading, + etoro** ⭐ | UC `adb-6358342630366312.12.azuredatabricks.net` |
| Extract | Databricks, Options - Trading data (monthly, B only) | UC |
| Extract | Databricks, Options - Trading data (monthly, B+S) | UC |
| Extract | Databricks, Options - Trading data (weekly, B Only) | UC |
| Extract | Databricks, Options - Trading data (weekly) | UC |
| Extract | Databricks, Options Accounts - first open pos | UC |
| Extract | Databricks, Options Accounts - FTD | UC |
| Extract | Databricks, Options Accounts - Regs & Pre-approved | UC |
| Extract | Databricks, Options Revenue | UC |
| Extract | historical trades, options | Synapse `prod-synapse-dataplatform-we.sql.azuresynapse.net` (historical fallback) |
| Extract | Options KYC Profile | UC |

→ The "Gatsby legacy user trading" data source is the **physical confirmation** of the Gatsby/Options bifurcation that drives the `New Signups vs Legacy` segmentation in the viz.

### Subscriptions: 10 (people receive emailed snapshots)

## Workbook deep-dive — `US Options 3.0 Monitoring (Including UK)`

**URL**: `https://reports.etorocorp.com/#/workbooks/7008/`

- 2 Views, **6 Data Sources**, 1 Extract Refresh, 18 Subscriptions

### Data Sources (6) — May 30, 2026 extract refresh, all Databricks UC

1. **3.0 cohort funnel, daily** — cohort-by-registration-date funnel
2. **3.0 event funnel, daily** — event-by-event-date funnel
3. **apex last reports dates** — Apex SOD freshness tracker (which `ProcessDate` was last loaded per file)
4. **funnel, events** — generic event funnel
5. **UK daily, 3-step funnel, cid details** — UK launch-specific 3-step funnel with CID drilldown
6. **unique deposits, trades** — dedup'd MIMO + Trading aggregation

→ The "apex last reports dates" source confirms the Apex SOD freshness gating Paloma uses operationally; this should map to a `MAX(ProcessDate)` query against each `bronze_sodreconciliation_apex_*` table.

## Other relevant workbooks (not deep-scraped)

- **US Options 3.0 Monitoring NYDFS+FINRA** (workbook ID likely close to 7008) — NY-specific 3.0 monitoring tracking RegulationID=14
- **US KPI Daily Highlights** — composite daily summary; likely pulls from same Databricks Options account/MIMO/revenue queries

## What this tells us about the KPI surface

1. **Account funnel** (Apex Account Open → FTD → First Position → First Trade)
2. **Funded** (cumulative, incl. churn) since Unity Day (Nov 1, 2022)
3. **MIMO** (deposits, withdrawals) split by funding-channel — ACH/Wire (direct) vs OMJNL (ICT internal)
4. **Trading volume** (contracts) — Buy-only and Buy+Sell variants, weekly + monthly
5. **PFOF revenue** (Options-specific via ClearingAccount = AccountNumber match)
6. **Regulatory cohorts**: All states / Majority states / 3.0 states (NY, NV, HI, PR, US VI, RegID=12) / NYDFS+FINRA (NY post-Mar 2026, RegID=14) / UK
7. **User segmentation**: New Signups (post-Unity) vs Legacy Accounts (pre-Unity Gatsby era)
8. **KYC profile**: appropriateness/eligibility/options-status snapshots
9. **Operational freshness**: per-Apex-file last `ProcessDate` (because Apex skips weekends + sometimes Mon/Tue)

## Identifiers captured

- Project: 234 (Paloma's Repository) → 430 (1-US Management)
- Workbook IDs: 5820 (US Options Performance Monitoring), 7008 (US Options 3.0 Monitoring Including UK)
- View ID: 36879 (US Options Weekly Mgmt Update)
- Databricks workspace: `adb-6358342630366312.12.azuredatabricks.net`
- Synapse fallback: `prod-synapse-dataplatform-we.sql.azuresynapse.net`

## Open follow-ups (NOT done in this pass)

- Did NOT extract the actual SQL inside each Tableau data source (would require opening each data source detail page → Edit → SQL panel; 18 round-trips). The data source names are sufficient for the skill.
- Did NOT screenshot the other 2 Options-explicit workbooks' rendered views (US Options 3.0 Monitoring + NYDFS+FINRA). Names + data source list are captured.
- Did NOT scrape the dashboards in `2-US Operations`, `4-US Compliance`, `5-US Finance` (likely contain Options-adjacent content but out of scope for this skill iteration).

## Screenshot saved

`knowledge/_inbox/gatsby-options/us-options-kpi-monitoring-dashboard.png` — full-page render of the canonical Options KPI Monitoring view.
