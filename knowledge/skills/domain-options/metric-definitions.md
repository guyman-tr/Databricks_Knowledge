---
name: domain-options
description: "The 8 Options KPIs computed against the Apex stack — the metrics that drive
  Paloma's Tableau dashboards and the DDR Options rows. FTD = First-Time Deposit per Apex
  options account (Local) reconciled to Dim_Customer.FirstDepositDate where FTDPlatformID=2
  (Global); Local FTD logic is FINRAONLY-specific in the prep view (filters
  RegisteredRepCode='FO1') with single-tx accounts passed through and multi-tx accounts
  deduplicated by smallest TransactionID; Global FTD has a hardcoded date floor 2025-09-01.
  MIMO = ABS(EXT869.Amount) split by PayTypeCode (C=Deposit, D=Withdraw) with
  IsInternalTransfer (TerminalID='OMJNL') flag for ICT vs direct funding (EnteredBy IN
  ('ACH','WRD')); house accounts (4GS43999/4GS00100/4GS00101/4GS00103/4GS00104) excluded.
  Funded = customers with positive OptionsTotalEquity (or non-zero CashEquity+PositionMarketValue)
  on Date — cumulative-since-Unity-Day variant adds churn (close events from
  EXT765.ClosedDate). Trader = customers with at least one filled trade in
  EXT872 with MarketCode='5' for the period; Buy-only Trader filters BuySellCode='B';
  Active Open Trader = Buy-only at month grain. Contracts Traded = SUM(EXT872.Quantity)
  with Buy/Sell or Buy-only variants. AUM = OptionsTotalEquity from EXT981 with daily
  dedup; CashEquity / MarginEquity / PositionMarketValue are sub-decompositions.
  PFOF = SUM(ABS(EXT1047.CustomerPFOFPayback)) by trade date and customer with
  ActionType ManualPositionOpen/Close mapped from Side B/S; Options-only because the
  ClearingAccount=OptionsApexID join filters Equity-PFOF aggregate ClearingAccounts;
  estimate vs final variance up to 20%. Cohort segmentation: New Signups vs Legacy Accounts
  (Gatsby-era pre-Unity-Date), regulatory cohort by RepCode (GAT 6/7/8 / FO1 12 / NY1 14 /
  UK1 UK), and platform cohort 3.0 (NY/NV/HI/PR/USVI added Reg 12) vs Majority states.
  Use for any 'how is X computed in the Options stack' / 'what filter defines an Options
  Trader' / 'estimate vs final PFOF' / 'first-time deposit logic' question."
triggers:
  - options ftd
  - options first time deposit
  - local ftd vs global ftd
  - options mimo formula
  - options funded
  - options funded incl churn
  - options trader
  - options active open trader
  - active options trader buy or sell
  - contracts traded
  - options aum formula
  - cash equity margin equity
  - PFOF formula
  - PFOF estimate vs final
  - 20% PFOF variance
  - new signups vs legacy
  - gatsby legacy cohort
  - 3.0 states majority states
  - regulatory cohort options
  - cohort by repcode
  - is_funded options
  - is_ftd options
  - is_global_ftd
  - is_internal_transfer
  - icapex internal transfer
  - house accounts options
  - first options trade
  - first opens position
  - unity date
  - November 1 2022
sample_questions:
  - How is Options FTD computed in v_mimo_options_platform (Local vs Global)
  - What's the difference between Active Open Options Trader (Buy) and Active Options Trader (Buy or Sell)
  - How is PFOF revenue calculated and how does it relate to Apex Finance final
  - What defines an Options Funded account vs cumulative-since-Unity Funded
  - How is the 'Legacy Accounts' segment (Gatsby cohort) defined in the dashboard
  - What's the formula for Monthly Contracts Traded (Buy and Sell)
required_tables:
  - main.etoro_kpi_prep.v_options_aum
  - main.etoro_kpi_prep.v_mimo_options_platform
  - main.etoro_kpi_prep.v_revenue_optionsplatform
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.general.bronze_usabroker_apex_options
version: 1
owner: "dataplatform"
---

# Options KPI metric definitions

Eight KPI families drive the Options Tableau dashboards and the DDR Options-platform rows. Each definition below includes: business meaning, exact computation, filter contract, segmentation cuts, and known caveats.

## 1. FTD (First-Time Deposit)

**Business meaning**: The first deposit a customer makes into an eToro Options (Apex) account. Two variants:
- **Local FTD** — first Options-side deposit per `AccountNumber` (`IsFTD=1`)
- **Global FTD** — Local FTD that is also the customer's first eToro deposit globally per Dim_Customer (`IsGlobalFTD=1`)

**Where it's computed**: `main.etoro_kpi_prep.v_mimo_options_platform.IsFTD` and `IsGlobalFTD` (full CTE walkthrough in `views-architecture.md`).

**Local FTD computation** (FINRAONLY-specific):
1. Filter `MIMORecords` to `PayTypeCode='C'` (deposits) AND `IsInternalTransfer=0` AND `RegisteredRepCode='FO1'`
2. Compute `MIN(Date)` per `AccountNumber` — this is the FINRAONLY first-deposit date
3. For accounts with exactly 1 deposit on that date → that's the FTD row
4. For accounts with multiple deposits on that date → pick smallest `TransactionID` (ACATSControlNumber)

**Global FTD computation**:
1. Take Local FTD rows
2. Reconcile to `dim_customer_masked` where `FTDPlatformID = '2'` AND `FirstDepositDate >= '2025-09-01'` AND `RealCID` matches AND amount and date match
3. If matched → `IsGlobalFTD = 1`, else `0`

**Filter contract**:
- Account: `OfficeCode IN ('4GS','5GU')`
- Account: NOT in house list (`4GS43999`, `4GS00100`, `4GS00101`, `4GS00103`, `4GS00104`)
- Funding channel: `EnteredBy IN ('ACH','WRD')` (direct deposits — ACH and wire) — **internal transfers via ICT (`OMJNL`) are NOT FTDs**

**Caveats**:
- Local FTD logic is **FO1-specific by design** (FINRAONLY). For non-FO1 cohorts (GAT, UK1, NY1) the implicit FTD is the first PayTypeCode='C' row in `DEPOSIT_UNIQUE_FOR_FTDJOIN`. This is intentional: non-FO1 cohorts have single-purpose options accounts where the simple first-deposit rule works; FO1 needed extra handling because its hybrid equity-options accounts can have multiple same-day deposits requiring deterministic tie-breaking.
- Global FTD has a **hardcoded date floor of 2025-09-01**. Pre-September-2025 cohorts always get `IsGlobalFTD=0` (mechanical, not because there was no global FTD).
- Equality join on `(RealCID, FTDAmount, FTDDate)` — if FX rounding causes Apex amount ≠ Dim_Customer amount, IsGlobalFTD undercounts.

**Tableau alignment**: The "Monthly Options First Funded Accounts (ICT-Internal Cash Transfer, plus Direct Funding)" chart on `US Options Weekly Mgmt Update` looks like first-funded — note it INCLUDES ICT (different from FTD which excludes ICT). For first-funded:
```sql
SELECT DateID, COUNT(DISTINCT RealCID) AS first_funded_accounts
FROM (
  SELECT RealCID, MIN(DateID) AS DateID
  FROM main.etoro_kpi_prep.v_mimo_options_platform
  WHERE MIMOAction = 'Deposit'  -- both ICT and direct
  GROUP BY RealCID
)
GROUP BY DateID;
```

---

## 2. MIMO (Money In / Money Out)

**Business meaning**: Net cash flow into/out of Options accounts per day per customer.

**Where it's computed**: `main.etoro_kpi_prep.v_mimo_options_platform`.

**Computation**:
- `MIMOAction = 'Deposit'` if `PayTypeCode='C'`, `'Withdraw'` if `'D'`
- `AmountUSD = ABS(EXT869.Amount)` — sign-stripped
- Internal-transfer flag: `IsInternalTransfer = (TerminalID = 'OMJNL') ? 1 : 0`

**Two funding channels** (via `EnteredBy` / `TerminalID`):
| Channel | Filter | Description |
|---|---|---|
| Direct ACH | `EnteredBy = 'ACH'` | ACH deposit / withdrawal |
| Direct Wire | `EnteredBy = 'WRD'` | Wire deposit |
| ICT (Internal Cash Transfer) | `TerminalID = 'OMJNL'` | Transfer between main eToro account and Options account — only for FinCEN+FINRA users (Reg 8) and (after Phase 1.5, ~Aug 22 2023) appropriate cohorts |

**Daily MIMO per customer**:
```sql
SELECT DateID, RealCID,
  SUM(CASE WHEN MIMOAction='Deposit' THEN AmountUSD ELSE 0 END) AS deposits_usd,
  SUM(CASE WHEN MIMOAction='Withdraw' THEN AmountUSD ELSE 0 END) AS withdraws_usd,
  SUM(CASE WHEN MIMOAction='Deposit' AND IsInternalTransfer=1 THEN AmountUSD ELSE 0 END) AS ict_deposits_usd,
  SUM(CASE WHEN MIMOAction='Deposit' AND IsInternalTransfer=0 THEN AmountUSD ELSE 0 END) AS direct_deposits_usd
FROM main.etoro_kpi_prep.v_mimo_options_platform
WHERE DateID BETWEEN 20260101 AND 20260131
GROUP BY DateID, RealCID;
```

**Caveats**:
- No timestamp — all MIMO is date-level. Same-day deposits and withdrawals net out at the day grain.
- `EXT869` only contains successful payments — failed/rejected attempts are not in MIMO.
- A new `EnteredBy` code (e.g. for a future ICT variant) would silently drop out of the view's filter — the prep view encodes only `('ACH','WRD','OMJNL')`. If Apex adds new channels, the view needs updating.

---

## 3. Funded (account-level state)

**Business meaning**: An options account is "Funded" when it has positive equity. Used for cumulative funded-account counts and churn analysis.

**Where it's computed**: derive from `v_options_aum.OptionsTotalEquity > 0` (typical) or `OptionsCashEquity + OptionsPositionMarketValue > 0`.

**Variants seen on dashboards**:
- **Cumulative Funded since Unity Day** (the "Funded Accounts (incl. Churn)" chart on `US Options Weekly Mgmt Update`): cumulative count of accounts that have ever been funded since 2022-11-01, MINUS accounts that closed (`EXT765.ClosedDate IS NOT NULL`). Latest value ≈ 12,621 as of May 2026.
- **Daily Funded Snapshot**: count of distinct accounts with `OptionsTotalEquity > 0` on a given Date.
- **Monthly Funded Snapshot**: distinct accounts funded at any point in the month.
- **First Funded Date per account**: `v_options_aum.FirstOptionsAUMDate` — when the account first appeared in EXT981 (i.e. first time it had a non-zero buy-power).

**Daily-Funded query template**:
```sql
SELECT DateID, COUNT(DISTINCT GCID) AS funded_accounts
FROM main.etoro_kpi_prep.v_options_aum
WHERE OptionsTotalEquity > 0
GROUP BY DateID;
```

**Caveats**:
- An account can flip Funded → Unfunded → Funded as the customer withdraws and re-deposits. Cumulative "ever funded" needs `MIN(DateID) WHERE OptionsTotalEquity > 0` per account.
- Churn definition is ambiguous — at minimum it includes `EXT765.ClosedDate IS NOT NULL`. Verify Paloma's specific churn formula in the workbook.
- The view does NOT preserve weekend rows — Apex skips weekends. For continuous date series, fill-forward Friday EOD into Sat/Sun manually.

---

## 4. Trader (account-level activity flag)

**Business meaning**: An account is a "Trader" if it has placed at least one filled trade in the period. Multiple variants by side and grain.

**Where it's computed**: `main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity`. No prep view aggregates this directly — typically computed inline.

**Variants seen on dashboards**:
| Variant | Filter |
|---|---|
| Active Options Trader (Buy or Sell) | `MarketCode='5'` AND `BuySellCode IN ('B','S')` |
| Active Open Options Trader (Buy) | `MarketCode='5'` AND `BuySellCode='B'` (the canonical "trader who opened a position") |
| Monthly First Options Trade | per-account `MIN(ProcessDate)` where `MarketCode='5'` |
| New Signups Trader | Active trader AND account `OpenDDate >= 2022-11-01` (Unity Date) |
| Legacy Accounts Trader | Active trader AND account `OpenDDate < 2022-11-01` (Gatsby cohort) |

**Active Open Trader query template**:
```sql
SELECT
  CAST(DATE_FORMAT(ProcessDate, 'yyyyMM') AS INT) AS yyyymm,
  COUNT(DISTINCT t.AccountNumber) AS active_open_traders
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON t.AccountNumber = am.AccountNumber
WHERE t.MarketCode = '5'
  AND t.BuySellCode = 'B'
  AND am.OfficeCode IN ('4GS','5GU')
  AND am.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
GROUP BY CAST(DATE_FORMAT(ProcessDate, 'yyyyMM') AS INT);
```

**Caveats**:
- `EXT872` only has filled trades. Pulled / cancelled orders aren't in this table.
- `OrderID` is the unique trade identifier. **Don't use `TradeNumber`.**
- One trade can have `Quantity > 1` (multiple contracts in a single trade). For "trader counts" use `COUNT(DISTINCT AccountNumber)`; for contract counts see KPI #5.

---

## 5. Contracts Traded (volume)

**Business meaning**: Total options-contract volume.

**Computation**:
- Buy + Sell: `SUM(Quantity)` where `MarketCode='5' AND BuySellCode IN ('B','S')`
- Buy-only: `SUM(Quantity)` where `MarketCode='5' AND BuySellCode='B'`

**Cumulative-since-Unity-Day variant**: running sum from 2022-11-01. The `Total Contracts Traded (Buy and Sell)` chart on `US Options Weekly Mgmt Update` shows ≈ 22,127 latest value (May 2026).

**Caveats**:
- `Quantity` is contract count, not principal. For dollar-volume use `SUM(NetAmount)` (but note: `NetAmount` is buy=principal, sell=market value, so summing both sides without a sign convention conflates inflows and outflows).
- One filled trade can be a single OrderID with `Quantity = 100` contracts; count differs depending on whether you measure orders or contracts.

---

## 6. AUM (Assets Under Management)

**Business meaning**: Total account equity for Options accounts.

**Where it's computed**: `main.etoro_kpi_prep.v_options_aum`.

**Three components**:
- `OptionsTotalEquity` — the headline AUM ($total at EOD)
- `OptionsCashEquity` — cash portion when account is cash; "cash available" semantically
- `OptionsPositionMarketValue` — open-position market value (principal + PnL)

**Identity**:
- For `AccountType = cash`: `TotalEquity = CashEquity + PositionMarketValue`
- For `AccountType = margin`: `TotalEquity = MarginEquity + PositionMarketValue`

But note: `MarginEquity` is NOT in `v_options_aum` — only `CashEquity` is. For margin-account decomposition, query `EXT981_BuyPowerSummary` directly.

**Daily Options AUM**:
```sql
SELECT DateID, SUM(OptionsTotalEquity) AS daily_options_aum_usd
FROM main.etoro_kpi_prep.v_options_aum
GROUP BY DateID;
```

**Caveats**:
- Confirm CashEquity/MarginEquity semantics with US OPS (Trading) before using in finance reports — semantics may evolve (per BI Doc).
- `v_options_aum` already applies daily dedup (`daily_rn=1`). Don't re-dedup in consumer queries.
- No weekend rows. For continuous dailies, fill-forward.

---

## 7. PFOF (Payment for Order Flow) — the main US revenue stream

**Business meaning**: Apex pays eToro for routing customer orders to specific market makers. This is the dominant US revenue source (along with ticket fees in UK).

**Where it's computed**: `main.etoro_kpi_prep.v_revenue_optionsplatform.Amount`.

**Computation**: `SUM(ABS(rev.CustomerPFOFPayback))` per (DateID, RealCID, ActionTypeID, ActionType, InstrumentTypeID, IsValidCustomer, IsCreditReportValidCB, FirstTradeDate, FirstTradeDateID).

**Filter contract**:
- `ClearingAccount NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')`
- (implicit) `ClearingAccount` matches an `OptionsApexID` in `bronze_usabroker_apex_options` — drops Equity PFOF rows (see "view caveat" below)

**Caveats**:
- **THIS IS AN ESTIMATE, NOT THE FINAL FIGURE.** Final PFOF comes from Apex Finance directly (handled by US Finance) and **can vary by 20% or more**. Use this for trend / day-over-day comparison; never as the authoritative finance number.
- **Equity PFOF rows are dropped by the view** because the join `ClearingAccount = OptionsApexID` doesn't match Equity PFOF aggregates (`'3ET00001'` for Reg 6/7/8, `'9820101'` for Reg 12). To get Equity PFOF, query `EXT1047` directly with no GCID resolution and use `InstrumentType='Equity'`.
- `SUM(ABS(...))` — clawbacks would be silently absorbed as revenue. If Apex starts emitting genuine refunds, the view needs a sign-aware split.
- `Side` mapping: `B → ActionTypeID=1, ActionType='ManualPositionOpen'`; `S → ActionTypeID=4, ActionType='ManualPositionClose'`. This is a copy of the cross-platform RevenueMetric contract.

**Trend query**:
```sql
SELECT DateID, SUM(Amount) AS daily_pfof_usd
FROM main.etoro_kpi_prep.v_revenue_optionsplatform
WHERE IsValidCustomer = 1  -- standard reporting filter
GROUP BY DateID;
```

---

## 8. Cohort segmentation (the lens applied to all metrics above)

The Tableau dashboards slice every KPI by these segmentation cuts:

### Customer cohort

- **New Signups** — accounts opened on or after Unity Date (2022-11-01). Filter: `EXT765.OpenDDate >= '2022-11-01'`.
- **Legacy Accounts** — accounts opened before Unity Date. The "Gatsby-era" cohort. Filter: `EXT765.OpenDDate < '2022-11-01'`. Tableau's data source `Databricks, Gatsby legacy user trading, + etoro` is the explicit cut.

### Regulatory cohort (by RegisteredRepCode)

- **GAT** — USA Reg 6/7/8 (eToroUS / FinCEN / FinCEN+FINRA) options. The "main" Options cohort.
- **ETA** — USA equity (Reg 6/7/8). Equity-only — not in Options KPIs, but reported in cross-product equity dashboards.
- **FO1** — USA FINRAONLY (Reg 12). 5 states (NY/NV/HI/PR/USVI) where crypto disabled, equity + options offered. The "Options 3.0" cohort.
- **NY1** — USA NYDFS+FINRA (Reg 14). NY-only, opened from Mar 31 2026 — crypto + equity + options. The "Options 4 / NY crypto" cohort.
- **UK1** — UK options beta cohort (Apr-Jun 2023 ~12K UK Club; Mar-Jul 2025 ~400K UK clients).
- **000** — Global test accounts. **EXCLUDE from analytics.**

### Platform cohort (by states)

- **3.0 States** — NY, NV, HI, PR, US VI (RegulationID=12, Reg=FINRAONLY).
- **Majority States** — All other US states (RegulationID 6/7/8).
- **NY split** — NY post-Mar-2026 is RegID=14 (NYDFS+FINRA); NY pre-Mar-2026 is FINRAONLY. NY1 RepCode lives on `OfficeCode='5GU'` because 4GS was full when NY1 launched.

### Account product

- **Cash** — `AccountType=1` (`EXT1034`) or `Margin IS NULL` (`EXT765`). Cash account.
- **Margin** — `AccountType=2` (`EXT1034`) or `Margin='Y'` (`EXT765`). Margin account.

### Options approval

- **Equity-only** — `OptionLevel IS NULL` (account opened on options rail but not approved for options trading; the FINRAONLY equity-fallback case).
- **Options-approved** — `OptionLevel IS NOT NULL`.

---

## Cross-references

- For raw-table-level filters, see `data-patterns.md` (canonical CTEs).
- For the "is this the right segmentation" question on a dashboard, query the workbook's data source map in `dashboard-queries.md`.
- For valid-customer / valid-CB filter contracts, see `knowledge/skills/cross-cutting/valid-users-filter-contract.md`.
- For the `domain-customer-and-identity` semantics (RealCID vs GCID vs MasterAccountCID), load that domain skill — Apex's `OptionsApexID` is unique in this domain because it's the customer's Apex AccountNumber, NOT a master eToro identity.
