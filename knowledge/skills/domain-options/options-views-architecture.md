---
description: "The four Options prep views in main.etoro_kpi_prep — what columns they expose,
  which CTEs they're built from, what filters they apply, and where the DDR depends on them.
  v_options_aum (8 cols) takes EXT981 BuyPowerSummary, dedups daily by ROW_NUMBER PARTITION BY
  (Date, AccountNumber) ORDER BY ProcessDate DESC, joins to bronze_usabroker_apex_options for
  GCID resolution, and returns Options TotalEquity / CashEquity / PositionMarketValue plus
  FirstOptionsAUMDate per account. v_mimo_options_platform (14 cols) is the new canonical
  Options MIMO view — a 9-step CTE chain (MIMORecords > DEPOSIT_UNIQUE_FOR_FTDJOIN > GLOBAL_FTD
  > FINRAONLY_ftd_date > FINRAONLY_FTD_records > FTDSingle > FTDMultiple > FinalFTD > Final
  output) implementing both Local FTD (per-account first-deposit-of-PayTypeCode-C) and Global
  FTD (reconciled to Dim_Customer.FirstDepositDate where FTDPlatformID=2 and FirstDepositDate
  >= 2025-09-01). The Local-FTD logic is FINRAONLY-specific (filters RegisteredRepCode='FO1')
  with single-tx accounts handled directly and multi-tx accounts deduplicated by ORDER BY
  TransactionID. v_mimo_optionsplatform (no underscore, 15 cols) is the older deprecated
  variant kept for backwards compat — same logic but retains FundingTypeID (mapped 42=OMJNL /
  29=ACH / 2=WRD). v_revenue_optionsplatform (26 cols) mirrors Function_Revenue_OptionsPlatform
  exactly with Metric=Options_PFOF, InstrumentTypeID 9=Option / 5=Equity, ActionTypeID 1=B / 4=S,
  but the join ClearingAccount=OptionsApexID drops Equity PFOF rows because Equity ClearingAccount
  is the aggregate '3ET00001' / '9820101' which doesn't match any individual options account.
  All views apply the canonical Apex filter contract: OfficeCode IN ('4GS','5GU') + house-account
  exclusion + EnteredBy IN ('ACH','WRD') OR TerminalID = 'OMJNL'. None of the 4 views handle
  weekend fill-forward — Apex skips weekends so there are simply no rows for those dates.
  Use for any 'what does v_options_X return' / 'what's the FTD logic in v_mimo_options_platform'
  / 'why does v_revenue_optionsplatform have no equity rows' / 'how is Apex AUM dedup'd' question."
triggers:
  - v_options_aum
  - v_mimo_options_platform
  - v_mimo_optionsplatform
  - v_revenue_optionsplatform
  - main.etoro_kpi_prep options
  - options aum view
  - options mimo view
  - options revenue view
  - options pfof view
  - Function_MIMO_Options_Platform
  - Function_Revenue_OptionsPlatform
  - Function_AUM_OptionsPlatform
  - 9-step CTE
  - MIMORecords
  - DEPOSIT_UNIQUE_FOR_FTDJOIN
  - GLOBAL_FTD
  - FINRAONLY_ftd_date
  - FINRAONLY_FTD_records
  - FTDSingle
  - FTDMultiple
  - FinalFTD
  - FundingTypeID 42 29 2
  - IsInternalTransfer
  - FTDPlatformID 2
  - FirstDepositDate 2025-09-01
  - first_funding apex
  - latest_daily_buypower
  - buypower_ranked
  - PREP RN FIRSTTRADE
  - ClearingAccount OptionsApexID drop
  - house account exclusion 4GS43999
  - dedup ROW_NUMBER ProcessDate
sample_questions:
  - What columns does v_options_aum return and how is it deduplicated daily
  - What's the 9-step CTE architecture of v_mimo_options_platform
  - How is Local FTD vs Global FTD computed in v_mimo_options_platform
  - Why does v_revenue_optionsplatform appear to have no equity rows
  - What's the difference between v_mimo_options_platform and v_mimo_optionsplatform
  - Where do v_options_aum / v_mimo_options_platform / v_revenue_optionsplatform feed into the DDR
required_tables:
  - main.etoro_kpi_prep.v_options_aum
  - main.etoro_kpi_prep.v_mimo_options_platform
  - main.etoro_kpi_prep.v_mimo_optionsplatform
  - main.etoro_kpi_prep.v_revenue_optionsplatform
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
  - main.general.bronze_usabroker_apex_options
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
name: domain-options
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-04"
---

# Options prep views architecture

## When to Use
Load when the user asks how the Options prep views are built — `v_options_aum`, `v_mimo_options_platform`, `v_mimo_optionsplatform` (deprecated), `v_revenue_optionsplatform`; their CTE chains, filter contracts, deduplication logic, or how they map to the Synapse-side `Function_*_OptionsPlatform` TVFs.

## Scope
In scope: Full DDLs and CTE walkthroughs for the four prep views; the 9-step MIMO CTE chain; Local FTD vs Global FTD logic; the ClearingAccount-drops-Equity-PFOF quirk; the canonical Apex filter contract that all four views apply.

Out of scope: Bronze table schemas → `options-source-tables.md`. KPI business meaning → `options-metric-definitions.md`. Reusable filter CTEs for ad-hoc SQL → `options-data-patterns.md`. Tableau dashboard reverse-mapping → `options-dashboard-queries.md`.
Last verified: 2026-06-04

The four prep views in `main.etoro_kpi_prep` are the Options DDR backbone. They mirror three Synapse-side TVFs (`Function_AUM_OptionsPlatform`, `Function_MIMO_Options_Platform`, `Function_Revenue_OptionsPlatform`) but execute against UC bronze tables.

## View family at a glance

| View | Cols | Purpose | Source bronze tables | Synapse equivalent |
|---|---|---|---|---|
| `v_options_aum` | 8 | Daily Options AUM per (DateID, GCID) | EXT981 + USABroker_Apex_Options | Function_AUM_OptionsPlatform |
| `v_mimo_options_platform` | 14 | Options MIMO with Local + Global FTD | EXT869 + USABroker_Apex_Options + Dim_Customer (masked) | Function_MIMO_Options_Platform |
| `v_mimo_optionsplatform` | 15 | **Deprecated**: older mirror of v_mimo_options_platform with FundingTypeID retained | (same as above) | Function_MIMO_OptionsPlatform (older naming) |
| `v_revenue_optionsplatform` | 26 | Per-customer Options PFOF revenue (Metric=`Options_PFOF`) | EXT1047 + USABroker_Apex_Options + Dim_Customer (masked) | Function_Revenue_OptionsPlatform |

**Common filter contract** (applied inside every view):
- `am.OfficeCode IN ('4GS', '5GU')` — options-only product line
- `am.AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')` — house-account exclusion
- For MIMO: `(ca.EnteredBy IN ('ACH','WRD') OR ca.TerminalID = 'OMJNL')` — direct funding OR ICT internal transfer
- All views join `bronze_usabroker_apex_options` to resolve `AccountNumber → OptionsApexID → GCID` (the eToro identity)

**No weekend fill-forward** — Apex skips weekends (NASDAQ calendar). For continuous date series, the consumer must fill-forward themselves OR consume the DDR which already does.

---

## `v_options_aum` (8 columns)

**Purpose**: One row per (`DateID`, `GCID`) — daily EOD Options AUM with first-funding timestamp.

### Output columns

| # | Column | Type / Source | Notes |
|---|---|---|---|
| 1 | `GCID` | from `bronze_usabroker_apex_options.OptionsApexID → GCID` | Primary key (one Options record per customer). Tier 1. |
| 2 | `DateID` | `CAST(DATE_FORMAT(bp.Date, 'yyyyMMdd') AS INT)` | Tier 2. |
| 3 | `Date` | `CAST(ProcessDate AS DATE)` | Tier 2. |
| 4 | `OptionsTotalEquity` | `CAST(TotalEquity AS DECIMAL(18,2))` | EOD account total = `PositionMarketValue` + cash available |
| 5 | `OptionsCashEquity` | `CAST(CashEquity AS DECIMAL(18,2))` | "Cash available" when AccountType=cash |
| 6 | `OptionsPositionMarketValue` | `CAST(PositionMarketValue AS DECIMAL(18,2))` | EOD position value |
| 7 | `FirstOptionsAUMDateID` | First `ProcessDate` per AccountNumber via `ROW_NUMBER OVER (PARTITION BY AccountNumber ORDER BY ProcessDate)` RN=1 | First Options-funding date as INT YYYYMMDD |
| 8 | `FirstOptionsAUMDate` | Same source as FirstOptionsAUMDateID | First Options-funding date as DATE |

### CTE architecture

Three CTEs:

1. **`buypower_ranked`** — adds two ROW_NUMBER fields to EXT981:
   - `RN = ROW_NUMBER() OVER (PARTITION BY AccountNumber ORDER BY ProcessDate)` — first-funding identification
   - `daily_rn = ROW_NUMBER() OVER (PARTITION BY CAST(ProcessDate AS DATE), AccountNumber ORDER BY ProcessDate DESC)` — daily latest snapshot per account
   - WHERE: `OfficeCode IN ('4GS','5GU')` + house-account exclusion
2. **`first_funding`** — `WHERE RN = 1` per account (the first time the account appears in EXT981)
3. **`latest_daily_buypower`** — `WHERE daily_rn = 1` (the latest snapshot per account-day; defends against multiple SOD entries on the same day)

Final SELECT:
```sql
SELECT DISTINCT op.GCID, ...
FROM latest_daily_buypower bp
INNER JOIN main.general.bronze_usabroker_apex_options op
  ON bp.AccountNumber = op.OptionsApexID
LEFT JOIN first_funding ff
  ON bp.AccountNumber = ff.AccountNumber
```

### Gotchas
- `INNER JOIN` on `op` means accounts that aren't in `bronze_usabroker_apex_options` (rare — typically test or pre-bridge accounts) are dropped silently.
- `LEFT JOIN first_funding` allows for the rare case of an account row in `latest_daily_buypower` that doesn't have a first-funding RN=1 row — in practice this never happens, but defensive.
- **No RegisteredRepCode in output** — for region splits (US vs UK, FinCEN vs FINRAONLY vs NYDFS) you must re-join `EXT765_AccountMaster`.

---

## `v_mimo_options_platform` (14 columns) — canonical

**Purpose**: One row per (`DateID`, `RealCID`, `TransactionID`) — Options MIMO record with FTD detection (Local + Global).

### Output columns

| # | Column | Notes |
|---|---|---|
| 1 | `OfficeCode` | Passthrough from EXT869 |
| 2 | `RegisteredRepCode` | Passthrough from EXT869 |
| 3 | `AccountNumber` | Passthrough from EXT869 |
| 4 | `DateID` | `CAST(DATE_FORMAT(ProcessDate, 'yyyyMMdd') AS INT)` |
| 5 | `Date` | `CAST(ProcessDate AS DATE)` |
| 6 | `RealCID` | From masked Dim_Customer via Options GCID join |
| 7 | `MIMOAction` | `'Deposit'` if PayTypeCode=`'C'`, `'Withdraw'` if `'D'` |
| 8 | `AmountUSD` | `ABS(CAST(Amount AS DECIMAL(19,4)))` (the source `Amount` is signed inversely; ABS gives positive amounts on both sides) |
| 9 | `IsFTD` | 1 if matched in `FinalFTD` CTE, else 0 |
| 10 | `IsInternalTransfer` | 1 if `TerminalID='OMJNL'`, else 0 |
| 11 | `TransactionID` | `ACATSControlNumber` |
| 12 | `IsGlobalFTD` | 1 if Local-FTD row also matches Dim_Customer first-deposit, else 0 |
| 13 | `IsValidCustomer` | From masked Dim_Customer (`PlayerLevelID != 4 AND LabelID NOT IN (26,30) AND CountryID != 250`) |
| 14 | `IsCreditReportValidCB` | From masked Dim_Customer (~= IsValidCustomer + 6 hardcoded eToro-EU subsidiary CIDs; see `cross-cutting/valid-users-filter-contract.md`) |

### 9-step CTE architecture

This is the most complex view in the family. The FTD logic is FINRAONLY-specific because for `RegisteredRepCode='FO1'` accounts, the first deposit anchors a **single** account that handles both equity and options — so the FTD has to be picked carefully.

```
Step 1: MIMORecords
   ├─ Filters: OfficeCode IN ('4GS','5GU') + house exclusion + funding-channel filter
   ├─ Joins: EXT869 → USABroker_Apex_Options (op) → Dim_Customer (dc, masked)
   └─ Computes: AmountUSD, FundingTypeID (42=OMJNL/29=ACH/2=WRD), IsInternalTransfer

Step 2: DEPOSIT_UNIQUE_FOR_FTDJOIN
   ├─ Source: MIMORecords WHERE PayTypeCode='C' AND IsInternalTransfer=0
   └─ ROW_NUMBER PARTITION BY (RealCID, DateID, AmountUSD) ORDER BY DateID, then RN=1
   └─ Purpose: dedup deposits before joining to global Dim_Customer FTD

Step 3: GLOBAL_FTD
   ├─ Source: DEPOSIT_UNIQUE_FOR_FTDJOIN
   ├─ Joins: Dim_Customer (filtered to FirstDepositDate >= '2025-09-01' AND FTDPlatformID = '2')
   └─ ON gd.RealCID = dc_ftd.RealCID
       AND gd.FTDAmount = dc_ftd.DCFTDAmount
       AND gd.FTDDate = dc_ftd.DCFTDDate
   └─ Sets IsGlobalFTD = 1 if matched

Step 4: FINRAONLY_ftd_date
   ├─ Source: MIMORecords WHERE PayTypeCode='C' AND IsInternalTransfer=0 AND RegisteredRepCode='FO1'
   └─ MIN(Date) per AccountNumber — the first non-internal-transfer deposit date per FO1 account

Step 5: FINRAONLY_FTD_records
   └─ All MIMORecords rows that occurred on the FINRAONLY first-deposit date per account
      (could be multiple TransactionIDs same day)

Step 6: FTDSingle
   └─ Accounts with exactly ONE FINRAONLY FTD row (HAVING COUNT(*) = 1) — pass through

Step 7: FTDMultiple
   └─ Accounts with MULTIPLE FINRAONLY FTD rows (HAVING COUNT(*) > 1)
   └─ ROW_NUMBER PARTITION BY AccountNumber ORDER BY TransactionID, then rn=1
   └─ Picks the smallest TransactionID per account — deterministic FTD per account

Step 8: FinalFTD
   ├─ UNION ALL of FTDSingle + FTDMultiple (rn=1)
   └─ LEFT JOIN GLOBAL_FTD on (RealCID, IsGlobalFTD=1) → final IsGlobalFTD per FTD row

Step 9: Final SELECT
   ├─ Source: MIMORecords (mr) joined back to USABroker_Apex_Options (op) and Dim_Customer (dc)
   └─ LEFT JOIN FinalFTD f ON (AccountNumber, Date, TransactionID)
   └─ IsFTD = 1 if FinalFTD row matched, else 0
   └─ IsGlobalFTD = COALESCE(f.IsGlobalFTD, 0)
```

### Important design decisions
- **FTD logic is FO1-specific by design**: the FINRAONLY_ftd_date CTE filters `RegisteredRepCode='FO1'`. For non-FO1 accounts (GAT, UK1, NY1) the first deposit is whatever the first PayTypeCode='C' row is — captured implicitly in `DEPOSIT_UNIQUE_FOR_FTDJOIN`. This is intentional: non-FO1 cohorts (GAT/UK1/NY1) have a single options-only account so the simple "first PayTypeCode='C'" pattern is sufficient; FO1 needed special handling because its accounts are equity-options hybrids where multiple same-day deposits could exist.
- **Global FTD has a hardcoded date floor**: `FirstDepositDate >= '2025-09-01' AND FTDPlatformID = '2'`. Pre-September-2025 cohorts get `IsGlobalFTD = 0` mechanically — not because they had no global FTD.
- **Internal transfers (ICT) are excluded from FTD** — `IsInternalTransfer = 0` is required in steps 2, 4, 5. An ICT from main eToro to Options is NOT counted as an Options FTD. This is correct: the customer's first eToro deposit was already counted upstream.
- **Equality join on amount + date** for global-FTD reconciliation. If the Dim_Customer FTD amount doesn't exactly match the Apex EXT869 amount (e.g. due to FX rounding), the row gets `IsGlobalFTD = 0` even though it really is the same FTD. Worth investigating if `IsGlobalFTD` undercounts.

---

## `v_mimo_optionsplatform` (15 columns) — DEPRECATED

The older variant with **`FundingTypeID`** retained as column 9 (between `AmountUSD` and `IsFTD`). Same 9-step CTE chain, same FTD logic, same filter contract. Comments are slightly less detailed.

`FundingTypeID` mapping (in MIMORecords step 1):
- `42` when `TerminalID = 'OMJNL'` (ICT)
- `29` when `EnteredBy = 'ACH'`
- `2` when `EnteredBy = 'WRD'` (wire deposit)

**Why two views?** Likely an in-place rewrite where the new view dropped FundingTypeID; the old one is kept for backwards compat with any consumer that still reads it. **Use `v_mimo_options_platform` (with underscore) for new work.** If a downstream actually needs FundingTypeID, lift it back into the canonical view rather than depending on the deprecated alias.

---

## `v_revenue_optionsplatform` (26 columns)

**Purpose**: Per-customer Options PFOF revenue, shaped to plug into the same DDR revenue framework as other revenue metrics.

### Output columns (selected — full list mirrors `Function_Revenue_OptionsPlatform`)

| # | Column | Notes |
|---|---|---|
| 1 | `DateID` | `CAST(DATE_FORMAT(rev.TradeDate, 'yyyyMMdd') AS INT)` |
| 2 | `Date` | `CAST(rev.TradeDate AS DATE)` |
| 3 | `RealCID` | From Dim_Customer via OptionsApexID join |
| 4 | `ActionTypeID` | `1` for Buy (Side='B'), `4` for Sell (Side='S') |
| 5 | `ActionType` | `'ManualPositionOpen'` (B) or `'ManualPositionClose'` (S) |
| 6 | `InstrumentTypeID` | `9` for Option, `5` for Equity |
| 7 | `IsSettled` | constant `1` |
| 8 | `IsCopy` | constant `0` |
| 9 | `Metric` | constant `'Options_PFOF'` |
| 10 | `Amount` | `SUM(ABS(rev.CustomerPFOFPayback))` per group |
| 11 | `CountTransactions` | `COUNT(rev.OrderID)` |
| 12 | `IncludedInTotalRevenue` | constant `1` |
| 13 | `CountAsActiveTrade` | `1` for Buy, `0` for Sell |
| 14 | `UpdateDate` | `CURRENT_TIMESTAMP()` |
| 15-22 | `IsBuy=1`, `IsLeveraged=0`, `IsFuture=0`, `IsCopyFund=0`, `IsOpenedFromIBAN=0`, `IsClosedToIBAN=0`, `IsRecurring=0`, `IsAirDrop=0` | Constants matching the cross-platform revenue contract |
| 23 | `IsValidCustomer` | From Dim_Customer (masked) |
| 24 | `IsCreditReportValidCB` | From Dim_Customer (masked) |
| 25 | `FirstTradeDate` | First `TradeDate` per `ClearingAccount` (ROW_NUMBER) |
| 26 | `FirstTradeDateID` | INT YYYYMMDD form of FirstTradeDate |

### CTE architecture (2 CTEs)

```
PREP:
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY ClearingAccount ORDER BY TradeDate) AS RN
  FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports

FIRSTTRADE:
  SELECT * FROM PREP WHERE RN = 1

Final SELECT:
  FROM PREP rev
  LEFT JOIN FIRSTTRADE ft ON rev.ClearingAccount = ft.ClearingAccount
  LEFT JOIN bronze_usabroker_apex_options op ON rev.ClearingAccount = op.OptionsApexID
  JOIN dim_customer_masked dc ON op.GCID = dc.GCID
  WHERE rev.ClearingAccount NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')
  GROUP BY DateID, Date, RealCID, ActionTypeID, ActionType, CountAsActiveTrade,
           InstrumentTypeID, IsValidCustomer, IsCreditReportValidCB,
           FirstTradeDate, FirstTradeDateID
```

### The Equity-PFOF rows-drop problem (IMPORTANT)

The join `LEFT JOIN bronze_usabroker_apex_options op ON rev.ClearingAccount = op.OptionsApexID` only matches when `ClearingAccount` equals an actual options account number (4GS/5GU range). **Equity PFOF aggregates under a synthetic `ClearingAccount`** — `'3ET00001'` for Reg 6/7/8 or `'9820101'` for Reg 12 — which never matches any individual `OptionsApexID`. So:

- Equity-PFOF rows get `op.GCID = NULL`
- The downstream `INNER JOIN dim_customer_masked dc ON op.GCID = dc.GCID` filters them out (NULL won't match any `dc.GCID`)
- **Result: only Options-PFOF rows survive in the view**

This is **intentional and confirmed** — `v_revenue_optionsplatform` is scoped to Options-only PFOF. Apex is also the broker for US equities, but equity coverage is out of scope for this view (and out of scope for the `domain-options` skill in general). For Equity PFOF, query `EXT1047` directly with `InstrumentType='Equity'` and the synthetic ClearingAccount ('3ET00001' for Reg 6/7/8, '9820101' for Reg 12) — see `data-patterns.md` pattern #11. Note that Equity PFOF is **not** broken down per-customer (it's pre-aggregated by Apex), so per-customer Equity PFOF requires a different upstream source (ask US Finance).

### Other gotchas
- `ROW_NUMBER OVER (PARTITION BY ClearingAccount ORDER BY TradeDate)` for first-trade — for accounts with multiple rows on the same TradeDate, the first one in some unspecified order is picked. If you need the absolute earliest, add a tiebreaker.
- `LEFT JOIN FIRSTTRADE ft` is a Cartesian-amplification risk if `ClearingAccount` has many rows in PREP — but FIRSTTRADE is filtered to RN=1, so only one row per ClearingAccount, so it's safe.
- `SUM(ABS(rev.CustomerPFOFPayback))` — uses ABS because PFOF payback is sometimes signed negative for refunds; the view treats both directions as positive revenue. **Watch out** if Apex starts emitting genuine clawbacks — they'd be silently absorbed as revenue.

---

## How the views feed the DDR

The user has confirmed these views are what the DDR is based on. The mapping (inferred — verify with the DDR canonical query in `domain-payments/mimo-panel-and-ddr.md` or `domain-revenue-and-fees`):

| DDR fact | Source view | Key columns |
|---|---|---|
| `Fact_AUM` (Options rows) | `v_options_aum` | `DateID`, `RealCID` (via GCID), `OptionsTotalEquity` |
| `Fact_MIMO_AllPlatforms` (Options rows) | `v_mimo_options_platform` | `DateID`, `RealCID`, `MIMOAction`, `AmountUSD`, `IsFTD`, `IsGlobalFTD`, `IsInternalTransfer` |
| `Fact_Revenue_Generating_Actions` (RevenueMetricID for `Options_PFOF`) | `v_revenue_optionsplatform` | `DateID`, `RealCID`, `Metric`, `Amount`, `CountTransactions`, `CountAsActiveTrade`, `ActionTypeID`, `InstrumentTypeID` |
| `Fact_Customer_Daily_Status` (Options-funded flag, Options-trader flag) | `v_options_aum` + `v_mimo_options_platform` + `v_revenue_optionsplatform` | Daily rollup |

Cross-reference: `domain-payments/mimo-panel-and-ddr.md` for the cross-platform DDR aggregation and how Options rows compose with eToro main / EXW / Spaceship rows.

---

## Synapse-side parity check

The 4 views are UC-side counterparts to BI_DB_dbo Synapse TVFs. The TVFs are knowledge-only (NOT migrated to UC) and exist in the wiki at:

| UC view | Synapse TVF wiki |
|---|---|
| `v_options_aum` | (inferred) Function_AUM_OptionsPlatform — not yet wikied; the column comments reference it |
| `v_mimo_options_platform` | `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_Options_Platform.md` |
| `v_revenue_optionsplatform` | `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_OptionsPlatform.md` |

Filter contract is verified to match (OfficeCode + house exclusion + funding-channel filter). Output column counts:
- v_options_aum (8 cols) — Synapse TVF likely has 8 output cols; not currently in the wiki
- v_mimo_options_platform (14) vs Function_MIMO_Options_Platform (14) — match
- v_revenue_optionsplatform (26) vs Function_Revenue_OptionsPlatform (26) — match

Use the Synapse wiki entries as a sanity check for column-by-column parity. If the UC view diverges from the Synapse logic, treat the UC view as canonical (it's what the DDR actually reads) but flag the divergence to Paloma + DE.

---

## Verification queries

Quick smoke tests to run after any view change:

```sql
-- Account universe matches house-exclusion contract
SELECT DISTINCT OfficeCode FROM main.etoro_kpi_prep.v_mimo_options_platform;
-- Expected: only '4GS' and '5GU'

SELECT DISTINCT AccountNumber FROM main.etoro_kpi_prep.v_mimo_options_platform
WHERE AccountNumber IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104');
-- Expected: 0 rows

-- FTD logic: each account should have at most one IsFTD=1 row per (Date, TransactionID)
SELECT AccountNumber, COUNT(*) as ftd_rows
FROM main.etoro_kpi_prep.v_mimo_options_platform
WHERE IsFTD = 1
GROUP BY AccountNumber
HAVING COUNT(*) > 1;
-- Expected: empty for FO1 cohort; non-empty rows worth investigating

-- Revenue view: should be Options-only
SELECT DISTINCT InstrumentTypeID, Metric FROM main.etoro_kpi_prep.v_revenue_optionsplatform;
-- Expected: (9, 'Options_PFOF') only — no (5, 'Options_PFOF') rows

-- AUM dedup: at most one row per (Date, AccountNumber→GCID)
SELECT GCID, Date, COUNT(*)
FROM main.etoro_kpi_prep.v_options_aum
GROUP BY GCID, Date
HAVING COUNT(*) > 1;
-- Expected: empty (the daily_rn dedup should guarantee 1 row per account-day)
```
