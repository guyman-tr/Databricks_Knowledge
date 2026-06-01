---
name: domain-moneyfarm
description: "KPI definitions for the MoneyFarm domain — AUM (per-GCID daily GBP +
  USD via fact_currencypricewithsplit InstrumentID=2; SUM Market_Value across
  portfolios), MIMO (gross deposits + withdrawals + net flow; live event-stream
  source PORTFOLIO_DEPOSIT/PORTFOLIO_WITHDRAW Oct 2025+), FTD
  (first-deposit-date per GCID; is_ftd TRUE only on the date with total_deposits
  > 0), Funded (total_balance_gbp > 0; aligned with eToro DDR IsFunded), Funded
  cohort splits via bi_output_moneyfarm_customers.Date_Source_Type 3-rung ladder
  (Live Event New / Bronze Table Recent / Silver AUM Snapshot Legacy), Cohort
  segmentation by Source_Type / Product_Name / V2-eligibility scope, and the
  documented MoneyFarm fee schedule from Confluence page 11942330382 — Stocks
  & Shares ISA points to MoneyFarm public pricing externally; Managed ISA has
  the explicit tiered AUM fee (0.75% / 0.70% / 0.65% / 0.60% under £100K;
  0.45% / 0.40% / 0.35% over £100K); Cash ISA Standard Variable Rate + 12-month
  boost (0.80% Oct 22 2025–Mar 24 2026; 1.00% Mar 25–Apr 30 2026; reverts to SVR
  after 12 months). The ISA cashback offer (2% / 2.5% / 3% banded by Club tier;
  capped at £10K cashback; min holding period 24 months) is also a marketing
  cost not fee revenue. CRITICAL: the fee schedule is documentation only —
  there is NO UC table holding fee data; v_moneyfarm_fees is a placeholder
  WHERE 1=0; querying fee revenue requires Finance ledger access (off-UC).
  Annual ISA allowance for 2025-04-06 to 2026-04-05 is GBP 20,000 per HMRC."
triggers:
  - moneyfarm aum
  - moneyfarm mimo
  - moneyfarm ftd
  - moneyfarm funded
  - moneyfarm fee schedule
  - moneyfarm managed isa fee
  - moneyfarm tiered aum fee
  - moneyfarm cash isa rate
  - moneyfarm svr
  - moneyfarm boosted rate
  - moneyfarm cashback
  - isa allowance
  - hmrc isa allowance
  - moneyfarm cohort
  - moneyfarm provenance
  - Date_Source_Type
  - Source_Type
  - Live Event
  - Silver History
  - Bronze Table Recent
  - Silver AUM Snapshot Legacy
  - portfolio_count
  - is_ftd
  - is_funded
sample_questions:
  - "How is MoneyFarm AUM calculated?"
  - "What is the MoneyFarm FTD definition?"
  - "Where is the Managed ISA fee schedule documented?"
  - "Do MoneyFarm fees flow into UC?"
  - "What's the Cash ISA boost rate for 2025/26?"
  - "How do I split MoneyFarm customers by provenance?"
  - "What's a 'legacy user' in the V2 HLD?"
required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# MoneyFarm — KPI Definitions

Anchors every KPI to a deployed UC view + the cached source documents (Confluence + Genie space + Tableau lineage). When a metric is documented but **not data-backed** (currently true for fees), it's flagged loudly so consumers know to route to Finance directly.

## CRITICAL — Fees are NOT data-backed in UC

> **Read this before any "MoneyFarm fee revenue" query.**
>
> The view `main.etoro_kpi_prep.v_moneyfarm_fees` exists as a **placeholder** — its DDL is `SELECT NULL CASTS WHERE 1=0`. **Querying it always returns 0 rows.**
>
> The customer-facing fee schedule (below) is documented in Confluence as marketing / customer-disclosure content. **No UC table holds per-portfolio or per-customer fee deductions.** Fees are netted from NAV at the MoneyFarm-side platform; what eToro sees in `Current_Market_Value_GBP` and `silver_moneyfarm_etoro_mf_aum.Market_Value` is **already net of fees**.
>
> For booked fee revenue → ask **Finance** directly. The data is in Finance's ledger, not in eToro UC.
>
> See `views-architecture.md` §3 for the full DDL and the rationale for declining the synthetic-fee-from-AUM approach.

## 1. AUM (Assets Under Management)

**Source view**: `main.etoro_kpi_prep.v_moneyfarm_aum`.
**Granularity**: per `(date, gcid)`.
**Definition**: `SUM(Market_Value)` across all of a customer's MoneyFarm portfolios on that date, in GBP. USD is `GBP * COALESCE(GBP/USD mid-rate, 0)`.
**Source bronze**: `main.money_farm.silver_moneyfarm_etoro_mf_aum` (the SFTP-fed silver back-fill ladder).
**Where it surfaces**: `BI_DB_DDR_Fact_AUM` (rolled up cross-platform); Ben's `ISA Market Value (SFTP data)` Tableau workbook (likely directly).

| Metric | Column | Type | Notes |
|---|---|---|---|
| Daily AUM (GBP) | `total_balance_gbp` | DOUBLE | SUM over portfolios for the (date, gcid) |
| Daily AUM (USD) | `total_balance_usd` | DOUBLE | GBP × `COALESCE(rate, 0)` — **0 means missing rate, not zero balance** |
| Funded flag | `is_funded` | BOOLEAN | TRUE when GBP > 0 |
| Portfolio count | `portfolio_count` | LONG | DISTINCT PortfolioID — picks up multi-ISA-wrapper customers |

**Caveat**: cadence is **silver SFTP**, not live event stream. Trails real-time MIMO by the silver pipeline cadence (typically T-1).

## 2. MIMO (Money In / Money Out)

**Source view**: `main.etoro_kpi_prep.v_moneyfarm_mimo`.
**Granularity**: per `(date, gcid)`.
**Definition**: gross deposits + gross withdrawals + net flow per GCID per day, computed from the live `compliance.bronze_event_hub_*` MoneyFarm event stream.
**Source bronze**: `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` filtered `ProviderName='Moneyfarm'` and `EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')`.
**Coverage**: Oct 2025 onwards only. Pre-Oct-2025 deposits live on the silver `historical_events` table or in `bi_output_moneyfarm_fact_transactions` with `Source_Type='Silver History'`.
**Where it surfaces**: `BI_DB_DDR_Fact_MIMO_AllPlatforms` filtered `AccountTypeID=4`; Ben's `ISA MIMO (Events API data)` Tableau workbook.

| Metric | Column | Type | Notes |
|---|---|---|---|
| Total deposits (GBP) | `total_deposits_gbp` | DOUBLE | SUM of `PORTFOLIO_DEPOSIT` amounts where `amount > 0` |
| Total withdrawals (GBP) | `total_withdrawals_gbp` | DOUBLE | SUM of `ABS(PORTFOLIO_WITHDRAW)` amounts where `amount < 0` |
| Net flow (GBP) | `net_flow_gbp` | DOUBLE | deposits − withdrawals; negative when net outflow |
| Total deposits (USD) | `total_deposits_usd` | DOUBLE | GBP × `COALESCE(rate, 0)` |
| Total withdrawals (USD) | `total_withdrawals_usd` | DOUBLE | same FX leg |
| Net flow (USD) | `net_flow_usd` | DOUBLE | sign-preserving |
| Deposit event count | `count_deposits` | LONG | per `(date, gcid)` |
| Withdrawal event count | `count_withdrawals` | LONG | per `(date, gcid)` |
| First-time deposit flag | `is_ftd` | BOOLEAN | TRUE only on FTD-date — see §3 |

**Caveat**: `Full Withdrawal` (the third value in `bi_output_moneyfarm_fact_transactions.TransactionType`) is NOT distinguished here — the upstream EH stream has only `PORTFOLIO_WITHDRAW`. For full-vs-partial withdrawal splits, drill down to `bi_output_moneyfarm_fact_transactions`.

## 3. FTD (First-Time Deposit)

**Definition**: the first calendar date on which a given `gcid` had `total_deposits_gbp > 0`. Computed via the `first_deposit_dates` CTE in `v_moneyfarm_mimo`:

```sql
SELECT GCID, MIN(date) AS first_deposit_date
FROM mimo_daily
WHERE total_deposits > 0
GROUP BY GCID
```

`is_ftd = TRUE` is stamped on the row where `m.date = f.first_deposit_date AND m.total_deposits > 0`.

**Critical difference from Spaceship**: there is **no orphan-FTD synthesis**. `is_ftd = TRUE` always coincides with `total_deposits_gbp > 0` on the same row. (Spaceship's MIMO synthesises an FTD row even when no live event ledger row exists, by reading `Dim_Customer.FirstDepositDate`. MoneyFarm doesn't do this.)

**Critical implication**: customers who FTD'd before Oct 2025 will NOT appear with `is_ftd = TRUE` in `v_moneyfarm_mimo` — because the live event stream didn't fire for those deposits. To get the historical FTD universe, use `bi_output_moneyfarm_fact_transactions` filtered `TransactionType = 'Deposit'` and take `MIN(Transaction_Date)` per GCID.

**FTDPlatformID = 4 = MoneyFarm** is the join filter on `Dim_Customer` for cross-platform "first deposit happened on MoneyFarm" cohorts. Per the UK BA Genie sql_snippet: *"FTDPlatformID — The ID relating to the area of the platform the user first deposited to: 4 = ISA/Moneyfarm, 3 = IBAN, 2 = Options, 1 = Trading Platform"*.

## 4. Funded customer

**Definition**: a customer is "funded on MoneyFarm" on date `d` if `total_balance_gbp > 0` on that date (per `v_moneyfarm_aum.is_funded`).

**Cumulative funded universe** (all-time): customers in `v_moneyfarm_aum` who have ever had `total_balance_gbp > 0`. Equivalent: `EXISTS` over `bi_output_moneyfarm_fact_transactions` with `TransactionType IN ('Deposit', 'Full Withdrawal', 'Withdrawal')`.

**Daily snapshot funded count**:

```sql
SELECT COUNT(DISTINCT gcid) AS funded_customers
FROM main.etoro_kpi_prep.v_moneyfarm_aum
WHERE dateid = 20260101 AND is_funded = TRUE
```

**Cohort splits** via `bi_output.bi_output_moneyfarm_customers.Date_Source_Type` (3-rung provenance ladder):
- `Live Event (New)` (49,189 rows) — newly-acquired customers from the live event stream (Oct 2025+).
- `Bronze Table (Recent)` (45,270 rows) — back-fill from `general.bronze_moneyfarm_users`.
- `Silver AUM Snapshot (Legacy)` (1,797 rows) — back-fill from the silver AUM ladder.

**For "newly acquired" cohort counts** filter `Date_Source_Type = 'Live Event (New)'` only. **Do not double-count** when SUMing across all three rungs — the populations overlap (a single GCID can appear in only one rung, but the rungs are mutually exclusive partitions of the same universe).

## 5. Cohort segmentation

### By V2 onboarding eligibility (Tier-1 anchored)

Per Confluence XP/12216961926 ("Moneyfarm V2 - HLD"):

> *"The criteria for [V2 redirect] users are: countryID=UK, designatedRegulation=FCA, playerStatus is Normal, User has at least one Approved deposit, the user isn't a 'Legacy user'."*

Every row in `bi_output_moneyfarm_fact_portfolio_snapshot` corresponds to a UK + FCA + funded eToro customer. There is **no global / non-UK MoneyFarm population** in scope. Joining to `Dim_Customer` and filtering `RegistrationCountryID=UK` is therefore *redundant* but not wrong; analysts have been observed double-filtering.

**Legacy users** are eToro customers who registered to MoneyFarm directly via the pre-acquisition eToro→Moneyfarm funnel. They're routed to `https://app.moneyfarm.com/gb/sign-in` (NOT the V2 SSO flow). They appear in the bizops facts but are tagged differently — verify with Ben if a query needs to exclude them.

### By Product_Name

`bi_output_moneyfarm_fact_portfolio_snapshot.Product_Name` takes one of three values:

| Value | Launch | Description |
|---|---|---|
| `DIY ISA` | Phase 3, Feb 2025 | Self-directed Stocks & Shares ISA — customer picks UK-eligible UK stocks, ETFs, bonds, mutual funds (NO CFDs, NO crypto) |
| `Managed ISA` | Oct 21, 2025 | Robo-advised — risk-banded portfolios, monthly contribution flow |
| `Cash ISA` | Oct 21, 2025 | Tax-free cash savings — interest accrues, no investment risk |

(The `Stocks & Shares ISA` product line, launched Mar 7 2023, was renamed `DIY ISA` when the `Managed-by-us` flavour added the `Managed ISA` line in Phase 3.)

### By portfolio risk level

`bi_output_moneyfarm_fact_portfolio_snapshot.Portfolio_Risk_Level` takes values like `P0`, `P7`, NULL. **Band semantics are NOT Confluence-anchored** — the public MoneyFarm site implies P0 = Cash and P7 = Equity-heavy, but this mapping is NOT confirmed by any cached eToro doc. Treat as opaque code unless analyst confirms.

### By provenance (3-rung ladder, recap)

See §4 above.

## 6. Annual ISA allowance (HMRC)

For tax year **2025-04-06 → 2026-04-05**: **£20,000 per customer** total across ALL ISA wrappers.

Customers can split across Cash ISA / S&S ISA / Managed ISA / other ISA providers. The £20K is a *combined* limit. eToro CS dashboard (`ISACustomerLookupDashboard`) tracks per-customer YTD utilisation.

The boundary is fixed by HMRC, not by eToro — refresh the boundary on April 6 each tax year. (Future tax years may revise the £20K cap; verify with CS or Finance before reporting on it.)

## 7. Documented fee schedule (informational only — NOT data-backed)

> **Reminder**: this section is **documentation** of customer-facing fee structure as published by eToro / MoneyFarm in marketing and CS-team material. **No UC table or view holds these fees as transactional data.** Querying `v_moneyfarm_fees` returns 0 rows.

Source: Confluence page `11942330382` ("Individual Savings Account (ISA) - MoneyFarm", last updated 2026-04-24, owner: Karina Streger).

### 7.1 Stocks & Shares ISA / DIY ISA

> *"Same fees as standard MoneyFarm pricing"* — per the Confluence page; points externally to `https://moneyfarm.com/uk/pricing/`.

The Confluence page does NOT replicate the S&S ISA fee schedule — it leaves it to the MoneyFarm public pricing page. Because Moneyfarm's pricing site can change, and the S&S ISA fee structure is set on the MoneyFarm side, there is **no eToro-side record** of historical S&S ISA fees in any cached doc.

### 7.2 Managed ISA

**Tiered AUM fee, charged on the time-weighted average portfolio balance.** Documented verbatim in Confluence:

**Under £100,000 invested**:
- 0.75% on investments up to £10,000
- 0.70% on investments between £10,000 and £20,000
- 0.65% on investments between £20,000 and £50,000
- 0.60% on investments between £50,000 and £100,000

**Over £100,000 invested**:
- 0.45% on investments between £100,000 and £250,000
- 0.40% on investments between £250,000 and £500,000
- 0.35% on investments over £500,000

**The schedule is BAND-WISE**, not a single rate determined by total AUM. Worked example for a £150,000 Managed ISA (assumed time-weighted average):

```
On the first £10K   :  £10,000 × 0.75% =  £75.00
On £10K-£20K       :  £10,000 × 0.70% =  £70.00
On £20K-£50K       :  £30,000 × 0.65% = £195.00
On £50K-£100K      :  £50,000 × 0.60% = £300.00
On £100K-£150K     :  £50,000 × 0.45% = £225.00
                                       ----------
Total annual fee                       =  £865.00
Effective rate                         = 0.577%
```

### 7.3 eToro Cash ISA

**Standard Variable Rate (SVR) + 12-month boost, then reverts to SVR.**

| Period | Boost rate (over SVR) | Notes |
|---|---|---|
| Oct 22, 2025 – Mar 24, 2026 | **+0.80%** | Initial 5-month boost |
| Mar 25, 2026 – Apr 30, 2026 | **+1.00%** | Increased boost |
| After Apr 30, 2026 | reverts to SVR | Boost expires; SVR applies |

**Boosted-rate eligibility**: customer must keep ≥ £500 in the Cash ISA AND make ≤ 3 withdrawals over the 12-month boost period. Withdraw more than 3 times or drop below £500 and the boost is forfeited.

**Important**: Cash ISA "fees" are interest *paid to* the customer, not fees from the customer. The boost rate is a **marketing cost on eToro's side**, not fee revenue. Don't include it in any "fee revenue" aggregation.

### 7.4 ISA cashback offers (FTD / first-transfer)

Per the same Confluence page, eToro offers cashback to customers who deposit / transfer in to MoneyFarm ISAs. **These are marketing costs, not fee revenue.**

**New cashback (Oct 22, 2025 – Apr 30, 2026)** — banded by Club tier:

| Club tier | Cashback rate | Max cashback |
|---|---|---|
| Bronze / Silver / Gold | 2% | £10K |
| Platinum / Platinum-Plus | 2.5% | £10K |
| Diamond | 3% | £10K |

**Conditions**:
- Min holding period 24 months — withdrawing principal pre-24-months claws the cashback back.
- Cashback paid into ISA cash balance by Feb 28, 2026.
- Stack with the Managed ISA fee — the cashback is granted gross of fees.

**Old cashback (Feb 4 – Apr 30, 2025)**:
- 2% on min £1,000 invested
- Capped at £5K cashback
- £250K investment cap
- Same 24-month claw-back rule

The **historical cashback paid** by Club tier and tax year is **not in UC** — Finance / Marketing maintain the cashback ledger. Query Finance for the actuals.

## 8. KPI cross-reference summary

| KPI | View / Table | Column / Filter | Doc anchor |
|---|---|---|---|
| Daily AUM (GBP / USD) | `v_moneyfarm_aum` | `total_balance_gbp` / `total_balance_usd` | view DDL — see `views-architecture.md` §1 |
| Daily MIMO (GBP / USD) | `v_moneyfarm_mimo` | `total_deposits_gbp` / `total_withdrawals_gbp` / `net_flow_gbp` | view DDL — see `views-architecture.md` §2 |
| FTD (live-stream era) | `v_moneyfarm_mimo` | `is_ftd = TRUE` | view DDL — see `views-architecture.md` §2 |
| FTD (historical) | `bi_output_moneyfarm_fact_transactions` | `MIN(Transaction_Date) WHERE TransactionType = 'Deposit'` per GCID | wiki — `bi_output_moneyfarm_fact_transactions.md` |
| Funded customer | `v_moneyfarm_aum` | `is_funded = TRUE` | view DDL — `views-architecture.md` §1 |
| Cumulative funded | `bi_output_moneyfarm_fact_transactions` | `EXISTS` per GCID | wiki — fact_transactions |
| FTDPlatformID = 4 (cross-platform) | `Dim_Customer` | `FTDPlatformID = 4` | UK BA Genie sql_snippet |
| Provenance cohort | `bi_output_moneyfarm_customers` | `Date_Source_Type` 3-rung | Confluence XP/13551468545 |
| Live-only activity | `bi_output_moneyfarm_fact_portfolio_snapshot` | `Source_Type = 'Live Event'` | Confluence XP/13551468545 |
| Product cohort | `bi_output_moneyfarm_fact_portfolio_snapshot` | `Product_Name IN ('Managed ISA','DIY ISA','Cash ISA')` | Confluence XP/12216961926 |
| Risk band | `bi_output_moneyfarm_fact_portfolio_snapshot` | `Portfolio_Risk_Level` (opaque code) | UC sample only |
| Managed ISA fee (BAND, %) | **NO UC TABLE** — Confluence only | n/a | Confluence CS/11942330382 §"Managed ISA fee schedule" |
| Cash ISA boost rate | **NO UC TABLE** — Confluence only | n/a | Confluence CS/11942330382 §"Cash ISA" |
| ISA cashback paid | **NO UC TABLE** — Finance ledger | n/a | Confluence CS/11942330382 §"Cashback" |

This cross-reference is the canonical "what column / which view" lookup. Update it together with the view DDLs when a metric is added or renamed.
