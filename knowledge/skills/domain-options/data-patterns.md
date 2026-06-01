---
description: "Reusable SQL building blocks for any Options-domain query against the Apex stack:
  the canonical house-account exclusion (5 equity 3ET + 5 options 4GS), the OfficeCode
  filter contract (4GS/5GU options vs 3E% equity), the MarketCode='5' options-only filter on
  EXT872 TradeActivity, the GCID-to-OptionsApexID bridge join (via bronze_usabroker_apex_options.OptionsApexID
  to AccountNumber), the Reg classification by RegisteredRepCode (GAT=Reg6/7/8 / FO1=Reg12 /
  NY1=Reg14 / UK1=UK / ETA=equity / 000=test), the ICT-vs-direct funding split (TerminalID='OMJNL'
  for ICT vs EnteredBy IN ('ACH','WRD') for direct), the daily AUM dedup pattern (ROW_NUMBER
  PARTITION BY (Date, AccountNumber) ORDER BY ProcessDate DESC), the first-funding-per-account
  RN=1 pattern, the FINRAONLY-only-options-approved filter (RepCode='FO1' AND OptionLevel IS NOT
  NULL), the Apex SOD freshness check (MAX ProcessDate per file), and the canonical
  Dim_Customer masked join. Also covers the cross-platform RealCID resolution flow (GCID via
  bronze_usabroker_apex_options to RealCID via gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked)
  and how to handle the Equity-PFOF-rows-drop quirk in v_revenue_optionsplatform if you need
  cross-instrument totals. Use whenever writing any new Options SQL — these CTEs replace
  copy-paste of the filter logic from the prep view DDLs and prevent the most common
  mistakes (mixing 4GS+3ET, forgetting to exclude house accounts, using TradeNumber instead
  of OrderID, joining on TradeMonth instead of TradeDate)."
triggers:
  - options sql patterns
  - options reusable CTE
  - house accounts exclusion CTE
  - 4GS 5GU OfficeCode filter
  - MarketCode 5 options filter
  - GCID OptionsApexID join
  - Reg classification by RepCode
  - ICT direct funding split
  - apex sod freshness query
  - daily AUM dedup
  - first funding RN 1 pattern
  - FO1 OptionLevel IS NOT NULL
  - dim_customer_masked options
  - RealCID via GCID options
  - cross-instrument PFOF
  - Equity PFOF aggregate ClearingAccount 3ET00001
  - house list 4GS43999 4GS00100
sample_questions:
  - What's the canonical house-account exclusion list for Options
  - How do I join Apex AccountNumber to GCID/RealCID
  - How do I classify Apex accounts by regulatory cohort
  - How do I check Apex SOD freshness
  - How do I split MIMO into ICT vs direct funding
  - What's the canonical pattern for daily Options AUM dedup
required_tables:
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.general.bronze_usabroker_apex_options
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
---

# Reusable SQL patterns for the Options domain

Copy/paste these CTEs into new queries. They encode the filter contract that the 3 prep views apply, so you can write raw-bronze queries without re-deriving the rules.

---

## 1. The house-account exclusion list (canonical)

**Brian Sullivan (briansu@) owns this list — verify with him for changes.**

```sql
-- Equity (3ET) house accounts
-- 3ET00001 — average price account
-- 3ET00100 — deposit
-- 3ET00101 — error
-- 3ET00002 — fee
-- 3ET05007 — MSB / facilitation

-- Options (4GS) house accounts
-- 4GS43999 — facilitation
-- 4GS00100 — deposit
-- 4GS00101 — error
-- 4GS00103 — fee
-- 4GS00104 — rewards & promos

-- For Options-only queries (the 5 4GS accounts):
WHERE AccountNumber NOT IN ('4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104')

-- For Equity-only queries (the 5 3ET accounts):
WHERE AccountNumber NOT IN ('3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007')

-- For combined Equity + Options:
WHERE AccountNumber NOT IN (
  '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007',
  '4GS43999', '4GS00100', '4GS00101', '4GS00103', '4GS00104'
)
```

The 3 prep views all use the Options-only list. If a query reads from `EXT869` / `EXT872` / `EXT981` / `EXT1047` directly, **you must add this filter manually**.

---

## 2. The OfficeCode filter contract

```sql
-- Options-only (the 4GS / 5GU OfficeCode universe)
WHERE OfficeCode IN ('4GS', '5GU')

-- Equity-only (the 3E% range — 3ET is the main one)
WHERE OfficeCode LIKE '3E%'

-- All Apex (equity + options)
WHERE OfficeCode IN ('4GS', '5GU') OR OfficeCode LIKE '3E%'
```

`5GU` was added because `4GS` reached its account-number cap. Functionally equivalent to `4GS` for Reg 6/7/8 + Reg 12 (FINRAONLY). Note: `NY1` RepCode (Reg 14, NY post-March-2026) sits on `5GU` because `4GS` was full when `NY1` launched.

`EXT981_BuyPowerSummary` has `OfficeCode` but **no `RegisteredRepCode`** — for Reg-aware splits, JOIN `EXT765`.

`EXT1034_NewAccountFinancialInformation` calls the column `Branch` instead of `OfficeCode`. Same values.

---

## 3. The `MarketCode='5'` filter for options-only trades

```sql
-- Options trades only on EXT872
WHERE t.MarketCode = '5'

-- Equity trades only on EXT872
WHERE t.MarketCode = 'N'
```

This is the **only reliable way** to distinguish options trades from equity trades in `EXT872_TradeActivity`. Don't infer from Symbol or AccountNumber.

For the canonical "Options Trader" definition:

```sql
-- All accounts that have ever placed an options trade
SELECT DISTINCT t.AccountNumber
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON t.AccountNumber = am.AccountNumber
WHERE t.MarketCode = '5'
  AND am.OfficeCode IN ('4GS', '5GU')
  AND am.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104');
```

`OrderID` is the unique transaction identifier — never use `TradeNumber` (not unique across buy/sell).

---

## 4. The GCID-to-OptionsApexID bridge join

```sql
-- bronze_usabroker_apex_options.OptionsApexID == AccountNumber in EXT*_*
JOIN main.general.bronze_usabroker_apex_options op
  ON apex.AccountNumber = op.OptionsApexID
-- now op.GCID is the eToro identity; carry it forward
```

To then resolve to `RealCID` (the eToro DWH primary key):

```sql
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON op.GCID = dc.GCID
-- dc.RealCID is the eToro customer primary key (dc is the masked Dim_Customer view)
```

The 3 prep views all do this. If you bypass the views, replicate this join exactly.

**Warning**: `bronze_usabroker_apex_options` has 1:1 GCID-OptionsApexID for normal accounts. Test accounts and pre-bridge legacy accounts may not have a row → INNER JOIN drops them.

---

## 5. Reg classification by `RegisteredRepCode`

```sql
-- The canonical RepCode-to-Reg mapping (per BI Doc + verified Mar 2026)
SELECT
  RegisteredRepCode,
  CASE RegisteredRepCode
    WHEN 'GAT' THEN 'USA Options Reg 6/7/8 (eToroUS / FinCEN / FinCEN+FINRA) — main Options cohort'
    WHEN 'ETA' THEN 'USA Equity Reg 6/7/8'
    WHEN 'FO1' THEN 'USA FINRAONLY Reg 12 — 3.0 states (NY pre-2026, NV, HI, PR, USVI)'
    WHEN 'NY1' THEN 'USA NYDFS+FINRA Reg 14 — NY post-March-2026'
    WHEN 'UK1' THEN 'UK Options beta'
    WHEN '000' THEN 'Test / Internal — EXCLUDE FROM ANALYTICS'
    ELSE 'Unknown — investigate'
  END AS reg_label
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
GROUP BY RegisteredRepCode;
```

For the canonical RegulationID join (when you have `Dim_Customer.RegulationID`):

| RegulationID | Region/Reg | Maps to RepCode |
|---|---|---|
| 6 | eToroUS (legacy US) | GAT or ETA |
| 7 | FinCEN | GAT or ETA |
| 8 | FinCEN + FINRA | GAT or ETA |
| 12 | FINRAONLY (3.0 states) | FO1 |
| 14 | NYDFS + FINRA (NY post-Mar-2026) | NY1 |

(UK clients have their own regulatory IDs in the eToro reg table — not directly Apex-side.)

---

## 6. ICT vs Direct Funding split

```sql
-- The canonical funding-channel filter (from EXT869 cash activity)
WHERE (
  ca.EnteredBy IN ('ACH', 'WRD')   -- Direct deposits / withdrawals via ACH or wire
  OR ca.TerminalID = 'OMJNL'       -- ICT (Internal Cash Transfer between main eToro and Options)
)

-- Channel breakdown
SELECT
  CASE
    WHEN TerminalID = 'OMJNL' THEN 'ICT'
    WHEN EnteredBy = 'ACH' THEN 'Direct ACH'
    WHEN EnteredBy = 'WRD' THEN 'Direct Wire'
    ELSE 'Other'
  END AS funding_channel,
  PayTypeCode,  -- 'C' deposit, 'D' withdrawal
  SUM(ABS(Amount)) AS volume_usd,
  COUNT(*) AS tx_count
FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
WHERE OfficeCode IN ('4GS', '5GU')
  AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
  AND (EnteredBy IN ('ACH','WRD') OR TerminalID = 'OMJNL')
GROUP BY 1, 2;
```

ICT was launched ~Aug 22, 2023 (Phase 1.5) and is **only available for FinCEN+FINRA users** (Reg 8). Pre-Aug 2023 there are no `OMJNL` rows.

The 3 prep views encode `('ACH','WRD','OMJNL')` literally. If Apex adds a new EnteredBy code (e.g. for a future ICT variant or a new banking partner), the views silently drop those rows until updated.

---

## 7. Apex SOD freshness check

Run before any Options analytics query — Apex skips weekends + sometimes Mon/Tue.

```sql
SELECT 'EXT765 AccountMaster' AS file_name, MAX(ProcessDate) AS last_processdate,
       DATEDIFF(CURRENT_DATE, MAX(ProcessDate)) AS days_behind
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
UNION ALL
SELECT 'EXT869 CashActivity (MIMO)', MAX(ProcessDate),
       DATEDIFF(CURRENT_DATE, MAX(ProcessDate))
FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
UNION ALL
SELECT 'EXT872 TradeActivity', MAX(ProcessDate),
       DATEDIFF(CURRENT_DATE, MAX(ProcessDate))
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
UNION ALL
SELECT 'EXT981 BuyPowerSummary (AUM)', MAX(ProcessDate),
       DATEDIFF(CURRENT_DATE, MAX(ProcessDate))
FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
UNION ALL
SELECT 'EXT1047 RevenueReports (PFOF)', MAX(TradeDate),
       DATEDIFF(CURRENT_DATE, MAX(TradeDate))
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
ORDER BY days_behind DESC;
```

Expectations on a normal Wednesday at 10am UTC: each file should be ≤ 2 business days behind. If any is > 3 business days behind, suspect a delivery issue and ping `#data-engineering` (DE owners: Eyal Boas eyalbo@, Pini Krisher pinikr@).

---

## 8. Daily AUM dedup pattern (already inside `v_options_aum`)

If you query `EXT981` directly (not via the view), apply this dedup:

```sql
WITH buypower_dedup AS (
  SELECT
    AccountNumber,
    CAST(ProcessDate AS DATE) AS Date,
    TotalEquity, CashEquity, MarginEquity, PositionMarketValue,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(ProcessDate AS DATE), AccountNumber
      ORDER BY ProcessDate DESC
    ) AS daily_rn
  FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  WHERE OfficeCode IN ('4GS', '5GU')
    AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
)
SELECT * FROM buypower_dedup WHERE daily_rn = 1;
```

This defends against multiple SOD entries on the same calendar date (rare but happens during reprocessing).

---

## 9. First-funding-per-account pattern

```sql
WITH buypower_ranked AS (
  SELECT
    AccountNumber,
    ProcessDate,
    ROW_NUMBER() OVER (PARTITION BY AccountNumber ORDER BY ProcessDate) AS RN
  FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  WHERE OfficeCode IN ('4GS', '5GU')
    AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
)
SELECT AccountNumber, ProcessDate AS first_funding_date
FROM buypower_ranked
WHERE RN = 1;
```

`v_options_aum.FirstOptionsAUMDate` exposes this directly. Use it instead of re-deriving.

---

## 10. FINRAONLY filter pattern (Reg 12 cohort)

For "options accounts in FINRAONLY states that ARE approved for options trading":

```sql
SELECT *
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
WHERE OfficeCode IN ('4GS', '5GU')
  AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
  AND RegisteredRepCode = 'FO1'
  AND OptionLevel IS NOT NULL;  -- key: NULL means equity-only fallback
```

For the FINRAONLY cohort regardless of approval (i.e. all options accounts in 3.0 states):

```sql
WHERE RegisteredRepCode = 'FO1'
-- (drop the OptionLevel IS NOT NULL filter)
```

This pattern matches sample query #2 ("All Apex options accounts") in the BI Doc.

---

## 11. The Equity-PFOF rows-drop workaround

`v_revenue_optionsplatform` is Options-only because the `ClearingAccount = OptionsApexID` join filters out Equity PFOF rows (Equity uses aggregate ClearingAccount `'3ET00001'` for Reg 6/7/8 or `'9820101'` for Reg 12). To get Equity PFOF, query `EXT1047` directly:

```sql
SELECT
  CAST(rev.TradeDate AS DATE) AS Date,
  rev.ClearingAccount,
  rev.InstrumentType,           -- 'Equity' here
  COUNT(rev.OrderID) AS tx_count,
  SUM(ABS(rev.CustomerPFOFPayback)) AS pfof_estimate_usd
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports rev
WHERE rev.InstrumentType = 'Equity'
  AND rev.ClearingAccount IN ('3ET00001', '9820101')
  AND rev.ClearingAccount NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
  AND rev.TradeDate BETWEEN '2026-05-01' AND '2026-05-31'
GROUP BY 1, 2, 3;
```

Note: Equity PFOF is **not** broken down per-customer (it's aggregated under the `'3ET00001'` synthetic ClearingAccount), so you cannot get per-customer Equity PFOF from EXT1047.

For per-customer equity PFOF, ask Brian Sullivan or US Finance — they can either provide the un-aggregated source or a different calculation method.

---

## 12. Cross-platform RealCID resolution flow

```sql
-- The canonical 3-step join for any per-customer Options analytics
SELECT
  apex.AccountNumber AS apex_account,
  op.GCID,
  dc.RealCID,
  dc.IsValidCustomer,
  dc.IsCreditReportValidCB,
  dc.RegulationID,
  dc.CountryID,
  dc.PlayerLevelID
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster apex
JOIN main.general.bronze_usabroker_apex_options op
  ON apex.AccountNumber = op.OptionsApexID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON op.GCID = dc.GCID
WHERE apex.OfficeCode IN ('4GS','5GU')
  AND apex.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104');
```

After this join you have the eToro identity for every Options account — use `RealCID` to join to `Fact_*`, `Dim_*`, MIMO, AUM, Trading, etc. The masked Dim_Customer view automatically applies PII masking; safe to join in any analytics context.

---

## 13. RegisteredRepCode-to-region quick map

```sql
SELECT
  CASE RegisteredRepCode
    WHEN 'GAT' THEN 'USA-Reg678'      -- main USA options cohort
    WHEN 'ETA' THEN 'USA-Equity'
    WHEN 'FO1' THEN 'USA-3.0states'   -- FINRAONLY (NY pre-2026, NV, HI, PR, USVI)
    WHEN 'NY1' THEN 'USA-NY-Reg14'    -- NYDFS+FINRA (NY post-March-2026)
    WHEN 'UK1' THEN 'UK'
    WHEN '000' THEN 'TEST'             -- exclude
    ELSE 'OTHER'
  END AS region_cohort,
  COUNT(*) AS account_count
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
WHERE OfficeCode IN ('4GS','5GU')
  AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
GROUP BY 1
ORDER BY account_count DESC;
```

---

## 14. Cohort segmentation: New Signups vs Legacy Accounts

```sql
SELECT
  CASE
    WHEN OpenDDate < '2022-11-01' THEN 'Legacy (Gatsby era)'
    WHEN OpenDDate >= '2022-11-01' THEN 'New Signups (post-Unity)'
    ELSE 'Unknown'
  END AS signup_cohort,
  RegisteredRepCode,
  COUNT(*) AS account_count
FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster
WHERE OfficeCode IN ('4GS','5GU')
  AND AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
GROUP BY 1, 2
ORDER BY 1, 2;
```

Tableau's `Databricks, Gatsby legacy user trading, + etoro` data source uses this cut on a derived account-level table (likely with the trading data joined in). The chart `Monthly Active Open Options Traders (Buy)` colors by this segment.

---

## Anti-patterns (DO NOT DO)

| Anti-pattern | Why wrong | Correct |
|---|---|---|
| `WHERE AccountNumber LIKE '4GS%'` | Misses 5GU accounts | `WHERE OfficeCode IN ('4GS','5GU')` |
| `WHERE Symbol LIKE '%CALL%'` | Doesn't reliably identify options | `WHERE MarketCode = '5'` |
| `JOIN ON apex.AccountNumber = dc.RealCID` | Wrong type — RealCID is eToro int, AccountNumber is Apex string | Bridge via `bronze_usabroker_apex_options.OptionsApexID = apex.AccountNumber` then `op.GCID = dc.GCID` |
| `SUM(NetAmount)` to compute revenue | NetAmount is principal+PnL on sell side — combining buy and sell sides without sign convention is meaningless | Use EXT1047 `CustomerPFOFPayback` for revenue |
| `COUNT(DISTINCT TradeNumber)` | TradeNumber is NOT unique | Use `COUNT(DISTINCT OrderID)` |
| Forgetting to exclude house accounts | Inflates counts by ~10 accounts but those have anomalous balances/trade volumes | Always apply the exclusion filter |
| Treating PFOF in EXT1047 as final | It's an estimate; final differs by up to 20% | Use for trend only; ask US Finance for final |
| Querying EXT1034 for historical accounts | Only post-Unity (Nov 1 2022) | Use EXT765 for full history |
