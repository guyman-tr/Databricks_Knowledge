# Options Data Knowledge Transfer (BI) — raw extract

**Source**: Google Doc owned by Paloma Cui (briansu@etoro.com primary author/SME), V1 Oct 22 2025, last edit May 6 2026
**URL**: https://docs.google.com/document/d/1Vvqafpw-DlzcJhSK1JoLuNqNsXPXFckgbdYUvd0kHBk/
**Captured via**: cursor-ide-browser MCP (`/mobilebasic` accessibility snapshot) on 2026-05-31 by guyman@etoro.com
**Raw a11y snapshot**: `C:\Users\guyman\.cursor\browser-logs\snapshot-2026-05-31T09-21-06-265Z-qsyx72.log`

This file is the curated/structured extract from the raw a11y snapshot — the raw snapshot has the full ground-truth verbatim text (1669 lines).

---

## OVERVIEW

> "This document outlines the current status of Options data and reporting including US, UK beta launch (as of documentation date). It's intended for knowledge transfer within the BI team and serves any [...]"

**Contributors**: Alain Tennekoon, Brian Sullivan, Jeremy Moye, Jeffrey Myers, Peter Quinn (US OPS / business)
**BI / DE owners**: Victor Shatokhin, Yulia Kramer, Eyal Boas, Pini Krisher

---

## Product Launch & Data Impact

### USA

#### Phase 1: "2 apps" — eToro App + eToro Options App
- **Launched**: November 1, 2022 ("Unity date")
- Coverage: all US states & territories EXCEPT NY, NV, HI, PR, US VI
- Two physically separate iOS/Android apps; user funded options account directly via ACH/wire from the Options App

#### Phase 1.5: ICT enabled
- **Launched**: ~August 22, 2023
- ICT (Instant Cash Transfer) lets users move funds between main trading account and options account — only for FinCEN+FINRA users

#### Phase 3.0: 5 states ("options 3.0")
- **Coverage added**: NY, NV, HI, PR, US VI
- New regulation **`FINRAONLY` (RegulationID = 12)** for residents of these states
- For FINRAONLY: only equity (stocks/ETF) + options offered; **crypto disabled**

#### (Phase 4) Crypto coming to New York
- **Launched**: March 31, 2026
- New regulation **`NYDFS+FINRA` (RegulationID = 14)** for new NY clients
  - Modeled after FinCEN+FINRA (RegulationID=8)
  - No new NY accounts opened under FINRAOnly post-launch
  - New `3ET` account created for NYDFS+FINRA users — main account for stock + manual CopyTrading; **crypto held separately via M[…]** (truncated in source)

### ROW — UK
- **1st beta**: April–June 2023 (~12K UK club members whitelisted)
- **2nd beta**: March–July 2025 (~400K UK clients)
- More launches planned

---

## Data and Storage

### 1. New data sources
- **Apex SOD files** added to the `Sodreconciliation_PROD` server
- **Linkage tables (Apex Account Number ↔ eToro GCID)** added to the `USABroker` server
- All available tables in Synapse + Data Lake catalogued in: **"Options Data at eToro"** (linked doc)
- Selected tables migrated to Synapse + Data Lake based on business need — **NOT all tables** are in both.

### 2. Key concepts in Apex reporting

| Concept | Description | Values | Where |
|---|---|---|---|
| **OfficeCode / Branch Code** | Differentiator of equity vs options accounts (with launch nuances) | `3E%` = equity for Reg 6/7/8 (eToroUS, FINCEN, FinCEN+FINRA); `4GS` = options for Reg 6/7/8, OR equity-options hybrid for Reg 12 (FINRAONLY); `5GU` = same scope as 4GS, added because 4GS hit cap | `apex_EXT765_AccountMaster` (OfficeCode), `apex_EXT1034_NewAccountFinancialInformation` (Branch), `apex_EXT869_CashActivity` (OfficeCode), `apex_EXT872_TradeActivity` (OfficeCode) |
| **RegisteredRepCode / RepCode** | Group code, flag for major launches (regions, regs, special batches) | `ETA` = USA equity Reg 6/7/8; **`GAT` = USA options Reg 6/7/8 ← "Gatsby"**; `UK1` = UK options beta; `FO1` = USA equity-options hybrid for FINRAONLY (#12); `NY1` = USA NY all-enabled NYDFS+FINRA (#14) — note 4GS was full when NY1 launched, so 4GS doesn't have a 1:1 RepCode match; `000` = global test accounts | Same 4 tables as OfficeCode |
| **AccountNumber** | Unique Apex Customer Account Number | N/A | All Apex SOD files |
| **PFOF** | "Payment for Order Flow" — main US revenue stream (besides ticket fees for UK) | N/A | `apex_EXT1047_RevenueReports.CustomerPFOFPayback` |
| **ProcessDate** | Apex skips weekends, follows NASDAQ trading calendar; some reports also skip Mon/Tue (non-critical refresh). Always check data last updated. | N/A | All SOD files |
| **USA internal / house accounts** | List of Apex Account Numbers that are NOT real customers; must exclude from OPS/management reporting. Brian Sullivan owns the up-to-date list. | See below | All SOD files |

#### House accounts to exclude

**Equity (3ET):**
- `3ET00001` — average price account
- `3ET00100` — deposit
- `3ET00101` — error
- `3ET00002` — fee
- `3ET05007` — MSB / facilitation

**Options (4GS):**
- `4GS43999` — facilitation
- `4GS00100` — deposit
- `4GS00101` — error
- `4GS00103` — fee
- `4GS00104` — rewards & promos

> Brian Sullivan (US OPS lead) keeps the canonical list — query him for changes.

---

## 3. Most Used Tables & Key Notes

### Apex SOD files (canonical Apex data dictionary: **CoreExtracts**)

#### `apex_EXT765_AccountMaster`
**Key fields**: OfficeCode, RegisteredRepCode, AccountNumber, AccountName, **TaxIdNumber (PII)**, AddressLine1, City, State, ZipCode, Margin, OptionLevel, OpenDDate, RestrDate, RestrictReasonCode, ClosedDate

- Account master file — contains **all** Apex accounts (equity + options) opened **since the Gatsby era** (USA + ROW)
- Options-specific:
  - `Margin`: 'Y' = margin account; NULL = cash
  - `OptionLevel`: NOT NULL = approved for options trading; NULL = equity-only (stocks + ETF)
  - `OpenDDate` — query as-is (typo preserved)
- **⚠ This table doesn't exist in Synapse — request separately if needed.** *(2026-05-31 UC validation: now lives in `main.general.bronze_sodreconciliation_apex_ext765_accountmaster`)*

#### `apex_EXT1034_NewAccountFinancialInformation`
**Key fields**: Branch, RepCode, AccountNumber, **TaxIdNumber (PII)**, AccountType, OpenDate, **DateOfBirth (PII)**, AccountName1, AddressLine1, City, State, ZipCode, **EmailAddress (PII)**

- Daily incremental — new accounts created on the day (by `OpenDate`)
- `AccountType`: 1 = cash, 2 = margin
- Only stores accounts opened **after Unity date** (Nov 1 2022)
- **Limitation**: not actively used; EXT765 covers most account info needs
- UC: `main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation`

#### `apex_EXT869_CashActivity`
**Key fields**: OfficeCode, RegisteredRepCode, AccountNumber, ProcessDate, AccountType, ACATSControlNumber, PayTypeCode, TerminalID, EnteredBy, Amount

- `ACATSControlNumber` — unique fund-movement record ID (deposit OR withdrawal)
- `PayTypeCode`: `'C'` (credit) = deposit; `'D'` (debit) = withdrawal
- **Filters needed** for actual fund movement (not all rows are client-initiated):
  - Direct funding: `EnteredBy IN ('ACH', 'WRD')`
  - Internal transfer (ICT): `TerminalID = 'OMJNL'`
- Only successful payments — no failed/rejected
- **No timestamp** (date-level only)
- UC: `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`

#### `apex_EXT872_TradeActivity`
**Key fields**: OfficeCode, RegisteredRepCode, AccountNumber, ProcessDate, ExecutionTime (HHMM), AccountType, MarketCode, OrderID, BuySellCode (B/S), Cusip, Symbol, OptionSymbolRoot, StrikePrice, CallPut (C/P), ExpirationDeliveryDate / OptionContractDate, Quantity (#contracts), NetAmount

- **`MarketCode`**: `'5'` = options; `'N'` = equity ← **critical filter for Options-only queries**
- `OrderID` — unique transaction record (buy/sell different values); **don't use TradeNumber, it's not unique**
- `ExecutionTime` — HHMM, timezone EST
- `OptionSymbolRoot` — 3-letter symbol abbreviation
- `Quantity` — count of contracts (one trade can include multiple contracts)
- `NetAmount` — at buy = principal invested; at sell = market value (principal + PnL)
- Only **filled** trades (no unfilled)
- Granularity: minute (no second/ms)
- UC: `main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity`

#### `apex_EXT981_BuyPowerSummary`
**Key fields**: OfficeCode, AccountNumber, ProcessDate, TotalEquity, NetBalance, PositionMarketValue, CashEquity, MarginEquity

- `TotalEquity` = `PositionMarketValue` + cash available — EOD snapshot of total account balance
- `NetBalance` = cash available
- `PositionMarketValue` = position EOD value (principal + PnL)
- `CashEquity` & `MarginEquity` are **both** "cash available":
  - When `AccountType = cash`: `TotalEquity = CashEquity + PositionMarketValue`
  - When `AccountType = margin`: `TotalEquity = MarginEquity + PositionMarketValue`
- **No RepCode** — must JOIN EXT765 for region/regulation context
- **⚠ Confirm with US OPS (Trading) before using CashEquity/MarginEquity** — semantics may evolve
- UC: `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`

#### `apex_EXT1047_RevenueReports`
**Key fields**: ClearingAccount, InstrumentType, TradeMonth (YYYYMM), BillingPeriod (YYYYMM), TradeDate, Side, TotalQuantity, CustomerPFOFPayback

- Combines PFOF for both options + equity — split via `InstrumentType`: `'Equity'` (stocks/ETF) or `'Option'`
- **`ClearingAccount`** behavior:
  - **Equity PFOF** is NOT broken down by individual account
  - **Options PFOF** IS at AccountNumber level
  - For Equity PFOF daily-sum, ClearingAccount = `'3ET00001'` (Reg 6/7/8) OR numeric `'9820101'` (Reg 12)
- `TotalQuantity` — count of contracts
- `CustomerPFOFPayback` — actual PFOF received by eToro (after Apex haircut)
- **⚠ This table only gives an estimate of PFOF** — final figures come from Apex Finance directly (handled by US Finance). Estimate vs final can vary up to **20%** (sometimes more).
- UC: `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

---

## Related onboarding dictionaries

> New tables can be requested from Victor Shatokhin / Yulia Kramer; new table creation requests go to DE (Eyal Boas, Pini Krisher); if any item ID lacks a dictionary in the Data Lake, ask Victor for definition and request the dictionary be added.

### `USABroker_Apex_Options` — main GCID↔OptionsApexID bridge
**Key fields**: GCID, OptionsApexID, EligibilityStatusID, EligibilityStatusReasonID, AppropriatenessProductID, AppropriatenessTestResultID, AppropriatenessRecalculationReasonID, AppropriatenessTestDate, OptionsStatusID, OptionsStatusControlID, ReasoningFormID, ReasoningStatusID, BeginTime

**`AppropriatenessRecalculationReasonID`** dictionary (offline note from Victor Shatokhin):
- 0 — None
- 1 — BulkRecalculation
- 2 — RegulationChanged
- 3 — ReachedVerificationLevel2
- 4 — AnswerChanged
- 5 — Manual

UC: `main.general.bronze_usabroker_apex_options`

### `USABroker_Dictionary_EligibilityStatus`
- 0 — Disallowed; 1 — Allowed
- UC: `main.bi_db.bronze_usabroker_dictionary_eligibilitystatus`

### `USABroker_Dictionary_AppropriatenessProduct`
- 0 — None; 1 — CFD; 2 — FPSL; 3 — Options
- UC: `main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct`

### `USABroker_Dictionary_AppropriatenessTestResult`
- 0 — None; 1 — Failed; 2 — Passed
- UC: `main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult`

### `USABroker_Dictionary_OptionsStatus`
- 0 — None; 1 — Pending; 2 — InProcess; 3 — Approved; 4 — Rejected
- UC: `main.bi_db.bronze_usabroker_dictionary_optionsstatus`

### `USABroker_Apex_OptionsReasoningForm` (with ReasoningStatusID dict)
- 0 — None; 1 — PendingReasoningScreen; 2 — PendingManualReview; 3 — Allowed; 4 — DisallowedByManualReview
- UC: `main.bi_db.bronze_usabroker_apex_optionsreasoningform` + `main.bi_db.bronze_usabroker_dictionary_reasoningstatus`

### `USABroker_Dictionary_OptionsStatusControl`
- 0 — None; 1 — Blocked; 2 — Allowed
- UC: `main.general.bronze_usabroker_dictionary_optionsstatuscontrol`

### `USABroker_Apex_OptionsReasoningForm` (form fields)
**Key fields**: ReasoningFormID, GCID, DateCreated, DateSubmitted, PreviousAppropriatenessTestDate

### `USABroker_Apex_OptionsReasoningFormQuestionsAnswers`
**Key fields**: ReasoningFormID, KycQuestionID, ReasoningFormAnswerID, OldKycAnswerID

---

## Reference: Sample Queries (verbatim from Doc tab 2)

### Population — eToro users without an options account
```sql
SELECT dc.RealCID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
LEFT JOIN main.general.bronze_usabroker_apex_options op
  ON dc.GCID = op.OptionsApexID
WHERE op.OptionsApexID IS NULL
GROUP BY 1;
```

### All existing options accounts (US & UK)
```sql
WITH apex_base AS (
  SELECT DISTINCT
    OfficeCode, RegisteredRepCode, AccountNumber,
    OptionLevel, OpenDDate AS AccountOpenDate
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  JOIN main.general.bronze_usabroker_apex_options op
    ON am.AccountNumber = op.OptionsApexID
  -- options account linkage filters for clients onboarded through options rails;
  -- equity accounts (3E*) are excluded here
  WHERE OfficeCode IN ('4GS', '5GU')   -- options vs. equity (3E)
)
-- US accounts:
SELECT 'USA' AS RegionByRepCode, *
FROM apex_base
WHERE RegisteredRepCode = 'GAT'                         -- Reg = FinCEN+FINRA
   OR (RegisteredRepCode = 'FO1' AND OptionLevel IS NOT NULL)  -- Reg = FINRAONLY
  -- FO1 = unified equity-options Apex account for Reg=12 (FINRAONLY).
  -- If client fails options suitability, his 4GS/5GU account [...]
  AND ca.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')  -- exclude house
UNION
-- UK accounts:
SELECT 'UK' AS RegionByRepCode, *
FROM apex_base
WHERE RegisteredRepCode = 'UK1';
```

### Options accounts that were ever funded
```sql
SELECT DISTINCT ca.AccountNumber, base.GCID, base.RegisteredRepCode
FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
JOIN (
  SELECT op.GCID, am.AccountNumber, am.RegisteredRepCode
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  JOIN main.general.bronze_usabroker_apex_options op
    ON am.AccountNumber = op.OptionsApexID
  WHERE am.OfficeCode IN ('4GS','5GU')
) base ON ca.AccountNumber = base.AccountNumber
WHERE ca.PayTypeCode = 'C'                              -- C(credit)=deposit, D(debit)=withdrawal
  AND (ca.EnteredBy IN ('ACH','WRD') OR ca.TerminalID = 'OMJNL')   -- direct funding OR internal transfer
  AND ca.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104');
```

### Options accounts currently funded (latest balance > 0)
```sql
SELECT bps.AccountNumber, base.GCID,
       CAST(bps.ProcessDate AS DATE) AS BalanceAsOfDate,
       bps.TotalEquity AS OptionsTotalEquity,
       CAST(bps.PositionMarketValue AS DECIMAL(18,2)) AS OptionsPositionMarketValue,
       CAST(bps.NetBalance AS DECIMAL(18,2)) AS OptionsCashBalance
FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
JOIN (
  SELECT DISTINCT op.GCID, am.AccountNumber, am.RegisteredRepCode
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  JOIN main.general.bronze_usabroker_apex_options op
    ON am.AccountNumber = op.OptionsApexID
  WHERE am.OfficeCode IN ('4GS','5GU')
    AND ca.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
) base ON base.AccountNumber = bps.AccountNumber
WHERE bps.AccountNumber = '4GS75912'
  AND bps.ProcessDate IN (
    SELECT MAX(ProcessDate)
    FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  )
  AND bps.TotalEquity <> 0;
```

### Options accounts that ever traded
```sql
SELECT DISTINCT tr.AccountNumber, base.GCID, base.RegisteredRepCode
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr
JOIN (
  SELECT op.GCID, am.AccountNumber, am.RegisteredRepCode
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  JOIN main.general.bronze_usabroker_apex_options op
    ON am.AccountNumber = op.OptionsApexID
  WHERE am.OfficeCode IN ('4GS','5GU')
    AND am.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
) base ON tr.AccountNumber = base.AccountNumber
WHERE tr.MarketCode = '5';   -- ONLY indicator for options trades (vs equity '5'/'N')
```

### MIMO (deposits/withdrawals for an options account)
```sql
SELECT DISTINCT ca.AccountNumber, op.GCID, am.RegisteredRepCode,
       ca.ProcessDate, ca.ACATSControlNumber,    -- unique transaction id
       ca.PayTypeCode,                            -- C=deposit, D=withdrawal
       ca.TerminalID, ca.EnteredBy,
       ca.Amount                                  -- negative=deposits, positive=withdrawals
FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON ca.AccountNumber = am.AccountNumber
LEFT JOIN main.general.bronze_usabroker_apex_options op
  ON am.AccountNumber = op.OptionsApexID
WHERE am.OfficeCode IN ('4GS','5GU')
  AND (ca.EnteredBy IN ('ACH','WRD') OR ca.TerminalID = 'OMJNL')
  AND ca.AccountNumber = '4GS67362'
  AND ca.ProcessDate = '2024-10-29'
  AND PayTypeCode IN ('C','D')
  AND ca.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104');
```

### Trading
```sql
SELECT DISTINCT
  op.GCID, ta.AccountNumber, am.RegisteredRepCode,
  ta.OrderId, ta.BuySellCode,                -- B=Buy; S=Sell; C=Cancel Buy; T=Cancel Sell
  ta.ProcessDate, ta.ExecutionTime,
  ta.NetAmount,                              -- positive=Buy, negative=Sell
  ta.Quantity AS Contracts_Count,            -- positive=Buy, negative=Sell
  ta.CallPut,                                -- C=call, P=put
  ta.ExpirationDeliveryDate,
  ta.DisplaySymbol, ta.Symbol, ta.OptionSymbolRoot, ta.Description1
FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ta
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON ta.AccountNumber = am.AccountNumber
JOIN main.general.bronze_usabroker_apex_options op
  ON am.AccountNumber = op.OptionsApexID
WHERE ta.OfficeCode IN ('4GS','5GU')
  AND ta.ProcessDate = '2025-10-20'
  AND ta.MarketCode = '5'
  AND ta.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
  AND AccountNumber = '4GS63306';
```

### Balance
```sql
SELECT bps.AccountNumber, op.GCID, am.RegisteredRepCode,
       CAST(bps.ProcessDate AS DATE) AS BalanceAsOfDate,
       bps.TotalEquity AS OptionsTotalEquity,
       CAST(bps.PositionMarketValue AS DECIMAL(18,2)) AS OptionsPositionMarketValue,
       CAST(bps.NetBalance AS DECIMAL(18,2)) AS OptionsCashBalance,
       CAST(bps.CashEquity AS DECIMAL(18,2)) AS CashAvailable_AccountTypeCash,
       CAST(bps.MarginEquity AS DECIMAL(18,2)) AS CashAvailable_AccountTypeMargin
FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bps
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON bps.AccountNumber = am.AccountNumber
JOIN main.general.bronze_usabroker_apex_options op
  ON am.AccountNumber = op.OptionsApexID
WHERE am.OfficeCode IN ('4GS','5GU')
  AND bps.ProcessDate = '2025-10-28'
  AND am.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
  AND bps.AccountNumber = '4GS75912';
```

### Revenue (PFOF)
```sql
SELECT BillingPeriod,                        -- YYYYMM, one month behind TradeMonth
       TradeMonth,                           -- YYYYMM
       CAST(TradeDate AS DATE) AS TradeDate,
       Side,                                 -- B=buy, S=sell
       SUM(TotalQuantity)         AS TotalContractTraded,
       SUM(CustomerPFOFPayback)   AS TotalPFOF
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports r
JOIN main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  ON r.ClearingAccount = am.AccountNumber
 AND am.OfficeCode IN ('4GS','5GU')
WHERE InstrumentType = 'Option'
  AND am.AccountNumber NOT IN ('4GS43999','4GS00100','4GS00101','4GS00103','4GS00104')
GROUP BY BillingPeriod, TradeMonth, CAST(TradeDate AS DATE), Side;
```

---

## Tableau dashboards (verbatim from Doc tab 3)

> Options-related dashboards live in the "US Management" tab of the **US Tableau Dashboard Repository (Updated Oct 15, 2025)** (Google Sheet `12YN_dDC...`).

| # | Launched | Dashboard | Objective | Primary KPI | Cadence | Limitations |
|---|----------|-----------|-----------|-------------|---------|-------------|
| 1 | Mar 2025 | **Options UK Funnel & Insights** | UK 2025 launch — assess acquisition funnel + monitor deposit/trading | Funnel: Apex acct open → FTD → First Action; MIMO (deposit count/$/uniques); Trading (contracts count/$/uniques) | M | Low volume → only monthly aggregates (no daily) |
| 2 | Jan 2025 | **Options 3.0 vs Majority States Funnel Comparison** | Compare funnel efficiency for 3.0 states vs majority; touchpoints vs cohort side-by-side | All states: Reg, V1–V3. 3.0 states: Apex Acct Open / FTD / FA. Majority: Equity AcctOpen, Options AcctOpen, FTD, Apex FTD, FA(no options), FA(options), FA(all) | M, W | Weekly cohort = 30-day cutoff; monthly cohort = cumulative-to-yesterday |
| 3 | Nov 2024 | **US Options 3.0 Funnel, Events vs Cohort** | Launch tracking for 3.0 states (NY, NV, HI, PR, US VI) | Reg, V1–V3, Apex AcctOpen, Apex FTD, FA | M, W, D | Cohort view has no built-in cutoff; cohort by reg-date counts events cumulative-to-yesterday (30-day cutoff for weekly views planned) |
| 4 | Nov 2022 | **US Options Weekly Mgmt Update** | Original Options 1.0 launch tracker | Active traders, order count, $ invested, avg trade size, total contracts, avg contracts/trader, Revenue, ARPU | M, W | Retired options-app charts deleted (looks "missing"); PFOF from SOD inconsistent vs Apex Finance |

---

## Comments / open notes

- **[a]** @briansu @jeremymo — keep BI posted on any business logic / code / process changes (assigned to briansu)
- **[b]** Added May 5, 2026 (NY1 row)
- **[c]** @briansu — keep posted if house codes ever change (assigned to briansu)
- **[d]** @briansu — CashEquity / MarginEquity semantics may evolve (assigned to briansu)

## Cross-references in eToro internal links (broken inside the Doc, recovered context)

- **"Options Data at eToro"** — likely a Confluence/Drive page cataloging all UC + Synapse Options tables. Need to fetch separately.
- **"CoreExtracts (Apex data dictionary)"** — Apex's official data dictionary (external/Apex-side).
- **"US Tableau Dashboard Repository (Updated Oct 15, 2025)"** — the Sheet at `12YN_dDC...`.
