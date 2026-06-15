---
description: "Complete inventory of the 38 Apex / USABroker bronze tables in Unity Catalog,
  organised by schema (main.general for accounts, main.finance for financial activity + user
  data + dictionaries, main.bi_db for regulatory/reasoning dictionaries, main.trading for
  corporate actions). The 6 documented Apex SOD tables — EXT765 AccountMaster (general),
  EXT869 CashActivity (finance), EXT872 TradeActivity (finance), EXT981 BuyPowerSummary
  (general), EXT1047 RevenueReports (finance), EXT1034 NewAccountFinancialInformation (bi_db)
  — are the operationally-used core; another 4 SOD tables (EXT538 ClosedAccounts, EXT870
  StockActivity, EXT922 DividendReport, EXT235 MandatoryCorporateActions, plus EXT_sodfiles)
  cover specific edge cases. The USABroker bridge centres on bronze_usabroker_apex_options
  (GCID to OptionsApexID with appropriateness/eligibility/status fields) plus 9 status
  dictionaries (eligibilitystatus / appropriatenessproduct / appropriatenesstestresult /
  optionsstatus / optionsstatuscontrol / reasoningstatus / accounttype / apexstatus /
  customertype) and 5 user-side tables (apexdata / state / tradinguserdata / userdata /
  uservalidationerrors). Critical PII fields (TaxIdNumber, DateOfBirth, EmailAddress,
  AddressLine1) live in EXT765 + EXT1034. apex_EXT765_AccountMaster is the only table that
  preserves the full historical universe — including pre-Unity-Date Gatsby-era accounts —
  EXT1034 only has post-Unity accounts. ProcessDate skips weekends (NASDAQ calendar);
  some files also skip Mon/Tue. Use for any 'which Apex/USABroker table holds X' / 'is X in
  Synapse or only UC' / 'where do PII fields live' / 'which dictionary do I join for
  EligibilityStatusID' question."
triggers:
  - apex_EXT765
  - apex_EXT869
  - apex_EXT872
  - apex_EXT981
  - apex_EXT1047
  - apex_EXT1034
  - apex_EXT538
  - apex_EXT870
  - apex_EXT922
  - apex_EXT235
  - bronze_sodreconciliation_apex
  - bronze_usabroker_apex
  - bronze_usabroker_dictionary
  - main.general apex
  - main.finance apex
  - main.bi_db apex
  - main.trading apex
  - AccountMaster
  - CashActivity
  - TradeActivity
  - BuyPowerSummary
  - RevenueReports
  - NewAccountFinancialInformation
  - ClosedAccounts
  - StockActivity
  - DividendReport
  - MandatoryCorporateActions
  - usabroker apex options
  - apex options reasoning form
  - eligibility status dictionary
  - appropriateness test result
  - options status dictionary
  - reasoning status dictionary
  - 38 apex tables
sample_questions:
  - Which schema holds apex_EXT765_AccountMaster, EXT869_CashActivity, EXT981_BuyPowerSummary
  - What PII fields live in the Apex SOD bronze tables and where
  - Is apex_EXT765 in Synapse or only in Unity Catalog
  - Which USABroker dictionaries exist and what dimension do each resolve
  - What's the difference between EXT1034 and EXT765 (which one has the Gatsby-era cohort)
  - Where are pre-Unity-Date accounts stored
required_tables:
  - main.general.bronze_sodreconciliation_apex_ext765_accountmaster
  - main.general.bronze_sodreconciliation_apex_ext981_buypowersummary
  - main.general.bronze_usabroker_apex_options
  - main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
  - main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity
  - main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
  - main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
  - main.trading.bronze_sodreconciliation_apex_ext235_mandatorycorporateactions
name: domain-options
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-04"
---

# Apex / USABroker source tables

## When to Use
Load when the user asks about raw Apex / USABroker bronze tables in Unity Catalog — "which table holds X", "is X in Synapse or only UC", "where do PII fields live", or "which dictionary do I join for EligibilityStatusID".

## Scope
In scope: 38-table Apex / USABroker bronze catalog across `main.general` / `main.finance` / `main.bi_db` / `main.trading`; key fields per core SOD table (EXT765/869/872/981/1047/1034); PII inventory; dictionary IDs; the USABroker bridge mechanics.

Out of scope: KPI definitions → `options-metric-definitions.md`. Prep-view DDLs → `options-views-architecture.md`. Reusable SQL filter contracts → `options-data-patterns.md`.
Last verified: 2026-06-04

## 38-table inventory across 4 schemas

Validated 2026-05-31 against `main.information_schema.tables`. All tables are EXTERNAL Delta tables (bronze layer). Refresh cadence follows Apex SOD generation — daily on NASDAQ trading days (skips weekends; sometimes skips Mon/Tue for non-critical files).

### `main.general` — accounts & options bridge (7 tables)

| Table | Role |
|---|---|
| `bronze_sodreconciliation_apex_ext765_accountmaster` | **Core**: full Apex account master (equity + options, since Gatsby era) |
| `bronze_sodreconciliation_apex_ext981_buypowersummary` | **Core**: EOD account balance snapshot (TotalEquity / NetBalance / PositionMarketValue / CashEquity / MarginEquity) |
| `bronze_usabroker_apex_options` | **Core bridge**: GCID ↔ OptionsApexID + appropriateness/eligibility/status fields |
| `bronze_usabroker_apex_userprogramenrolment` | UserProgram enrolment events (e.g. paper-trading, beta programs) |
| `bronze_usabroker_dictionary_optionsstatuscontrol` | OptionsStatusControl dim (0=None, 1=Blocked, 2=Allowed) |
| `bronze_usabroker_dictionary_userprogram` | UserProgram dim |
| `bronze_usabroker_dictionary_userprogramenrolmentstatus` | UserProgramEnrolmentStatus dim |

### `main.finance` — financial activity + user data + dictionaries (20 tables)

| Table | Role |
|---|---|
| `bronze_sodreconciliation_apex_ext869_cashactivity` | **Core**: deposits + withdrawals (PayTypeCode C/D, ACATSControlNumber, EnteredBy, TerminalID) |
| `bronze_sodreconciliation_apex_ext872_tradeactivity` | **Core**: filled trades (MarketCode, OrderID, BuySellCode, Cusip, OptionSymbolRoot, StrikePrice, CallPut, ExpirationDeliveryDate, Quantity, NetAmount) |
| `bronze_sodreconciliation_apex_ext1047_revenuereports` | **Core**: PFOF revenue (CustomerPFOFPayback, ClearingAccount, InstrumentType Equity/Option) |
| `bronze_sodreconciliation_apex_ext870_stockactivity` | Stock activity (corporate actions on holdings — splits, transfers, etc.) |
| `bronze_sodreconciliation_apex_ext922_dividendreport` | Dividend distributions per account |
| `bronze_sodreconciliation_apex_sodfiles` | Per-SOD-file metadata (file-level audit trail of Apex deliveries) |
| `bronze_usabroker_apex_apexdata` | Master Apex user data (GCID-anchored) |
| `bronze_usabroker_apex_state` | Per-state data (US state of residence with regulatory implications) |
| `bronze_usabroker_apex_tradinguserdata` | Trading-eligibility user data |
| `bronze_usabroker_apex_userdata` | Generic user-data sync from USABroker server |
| `bronze_usabroker_apex_uservalidationerrors` | Validation errors during Apex onboarding |
| `bronze_usabroker_dictionary_accounttype` | AccountType dim |
| `bronze_usabroker_dictionary_apexstatus` | ApexStatus dim |
| `bronze_usabroker_dictionary_apexvalidationerror` | ApexValidationError dim |
| `bronze_usabroker_dictionary_customertype` | CustomerType dim |
| `bronze_usabroker_dictionary_documenttype` | DocumentType dim |
| `bronze_usabroker_dictionary_modifytype` | ModifyType dim |
| `bronze_usabroker_dictionary_phonetype` | PhoneType dim |
| `bronze_usabroker_dictionary_userdataupdatesmask` | UserData updates mask dim |
| `bronze_usabroker_dictionary_userdocumenttype` | UserDocumentType dim |

### `main.bi_db` — regulatory / reasoning-form dictionaries (10 tables)

| Table | Role |
|---|---|
| `bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation` | **Core**: daily incremental new accounts (post-Unity-Date only) |
| `bronze_sodreconciliation_apex_ext538_closedaccounts` | Closed-account events |
| `bronze_usabroker_apex_optionsreasoningform` | Options reasoning-form submissions (DateCreated, DateSubmitted, PreviousAppropriatenessTestDate) |
| `bronze_usabroker_apex_optionsreasoningformquestionsanswers` | Q&A rows for each reasoning-form (KycQuestionID, ReasoningFormAnswerID, OldKycAnswerID) |
| `bronze_usabroker_apex_sketchinvestigationdonotappealreason` | SketchInvestigation do-not-appeal reasons (rare-path investigation outcomes) |
| `bronze_usabroker_dictionary_appropriatenessproduct` | AppropriatenessProduct dim (0=None, 1=CFD, 2=FPSL, 3=Options) |
| `bronze_usabroker_dictionary_appropriatenesstestresult` | AppropriatenessTestResult dim (0=None, 1=Failed, 2=Passed) |
| `bronze_usabroker_dictionary_eligibilitystatus` | EligibilityStatus dim (0=Disallowed, 1=Allowed) |
| `bronze_usabroker_dictionary_optionsstatus` | OptionsStatus dim (0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected) |
| `bronze_usabroker_dictionary_reasoningstatus` | ReasoningStatus dim (0=None, 1=PendingReasoningScreen, 2=PendingManualReview, 3=Allowed, 4=DisallowedByManualReview) |

### `main.trading` — corporate actions (1 table)

| Table | Role |
|---|---|
| `bronze_sodreconciliation_apex_ext235_mandatorycorporateactions` | Mandatory corporate actions (mergers, spin-offs, mandatory tenders) |

## Core Apex SOD tables — detailed schemas

### `main.general.bronze_sodreconciliation_apex_ext765_accountmaster`

The single most important Apex table — the full historical account universe (equity + options, including pre-Unity-Date Gatsby-era accounts).

**Key fields**:
| Field | Type | Notes |
|---|---|---|
| `OfficeCode` | string | `3E%` equity, `4GS`/`5GU` options. **Mandatory filter for any product-scoped query.** |
| `RegisteredRepCode` | string | `GAT`/`ETA`/`UK1`/`FO1`/`NY1`/`000` (test) |
| `AccountNumber` | string | Apex Customer Account Number — unique identifier |
| `AccountName` | string | PII (legal name) |
| `TaxIdNumber` | string | **PII** |
| `AddressLine1`, `City`, `State`, `ZipCode` | string | PII (residence) |
| `Margin` | string | `'Y'` = margin; NULL = cash account |
| `OptionLevel` | string | NOT NULL = approved for options trading; NULL = equity-only |
| `OpenDDate` | date | Account open date (typo "DDate" preserved in source) |
| `RestrDate`, `RestrictReasonCode` | date / string | Account restriction date + reason |
| `ClosedDate` | date | NULL if currently open |

**Limitation** (from BI Doc): historically marked "doesn't exist in Synapse — request separately"; verified 2026-05-31 to be in UC.

### `main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation`

Daily incremental — new accounts created on the day. **Only stores post-Unity accounts** (Nov 1, 2022 onwards). Less actively used than EXT765.

**Key fields**:
- `Branch`, `RepCode`, `AccountNumber` — note column names differ from EXT765 (`Branch` here, `OfficeCode` in EXT765)
- `TaxIdNumber` (**PII**), `DateOfBirth` (**PII**), `EmailAddress` (**PII**)
- `AccountType` — `1` = cash, `2` = margin
- `OpenDate` (note: NOT `OpenDDate` — different spelling in this table)
- `AccountName1`, `AddressLine1`, `City`, `State`, `ZipCode`

### `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity`

The MIMO source — every successful deposit / withdrawal / internal-transfer record.

**Key fields**:
| Field | Notes |
|---|---|
| `OfficeCode`, `RegisteredRepCode`, `AccountNumber` | Account identifiers |
| `ProcessDate` | Date (NASDAQ-only; skips weekends) |
| `AccountType` | `1` cash, `2` margin |
| `ACATSControlNumber` | Unique fund-movement record ID — use as transaction PK |
| `PayTypeCode` | `'C'` (credit) = deposit; `'D'` (debit) = withdrawal |
| `TerminalID` | `'OMJNL'` = ICT (internal transfer eToro main ↔ Options); else direct funding |
| `EnteredBy` | `'ACH'` = ACH; `'WRD'` = wire deposit; others (rare) |
| `Amount` | Signed (negative for deposits, positive for withdrawals — counterintuitive). The 3 prep views use `ABS(Amount)`. |

**No timestamp** — date-level only.
**No failed/rejected records** — Apex SOD only contains successful payments.
**Required filter for fund-movement queries**: `EnteredBy IN ('ACH','WRD') OR TerminalID = 'OMJNL'` (the rest are administrative entries).

### `main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity`

The trades source — every filled trade (no unfilled).

**Key fields**:
| Field | Notes |
|---|---|
| `OfficeCode`, `RegisteredRepCode`, `AccountNumber` | Account identifiers |
| `ProcessDate`, `ExecutionTime` | Date + HHMM (no seconds; **EST timezone**) |
| `MarketCode` | **`'5'` = options; `'N'` = equity** — the canonical filter |
| `OrderID` | Unique transaction ID — buy/sell get different values. **Don't use TradeNumber (not unique).** |
| `BuySellCode` | `B` Buy / `S` Sell / `C` Cancel Buy / `T` Cancel Sell |
| `Cusip`, `Symbol`, `OptionSymbolRoot` | Instrument identifiers; OptionSymbolRoot is the 3-letter abbrev |
| `StrikePrice`, `CallPut` (`C`/`P`), `ExpirationDeliveryDate` | Options-specific contract terms |
| `Quantity` | Number of contracts (one trade can fill multiple contracts) |
| `NetAmount` | Buy = principal invested; Sell = market value (principal + PnL) |

### `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary`

The balance source — daily EOD account-balance snapshot.

**Key fields**:
| Field | Notes |
|---|---|
| `OfficeCode`, `AccountNumber`, `ProcessDate` | Identifiers + date. **No RepCode** — must JOIN EXT765. |
| `TotalEquity` | EOD total = `PositionMarketValue` + cash available |
| `NetBalance` | Cash available |
| `PositionMarketValue` | Position EOD value (principal + PnL) |
| `CashEquity` | "Cash available" when `AccountType=cash`; `TotalEquity = CashEquity + PositionMarketValue` |
| `MarginEquity` | "Cash available" when `AccountType=margin`; `TotalEquity = MarginEquity + PositionMarketValue` |

**Caveat**: confirm CashEquity / MarginEquity semantics with US OPS (Trading) before using in finance reports — semantics may evolve.

### `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports`

The PFOF revenue source — combines options + equity PFOF in one file.

**Key fields**:
| Field | Notes |
|---|---|
| `ClearingAccount` | NOT exactly an account number for Equity PFOF — see note below |
| `InstrumentType` | `'Equity'` (stocks/ETF) or `'Option'` |
| `TradeMonth`, `BillingPeriod` | YYYYMM — `BillingPeriod` is one month behind `TradeMonth` |
| `TradeDate` | Date |
| `Side` | `B` Buy / `S` Sell |
| `TotalQuantity` | Count of contracts |
| `CustomerPFOFPayback` | Actual PFOF received by eToro (after Apex haircut) |

**ClearingAccount behavior**:
- **Options PFOF** is at AccountNumber level (one row per options account per trade-day-side-instrument)
- **Equity PFOF** is NOT broken down by individual account — it aggregates under a single `ClearingAccount`:
  - `'3ET00001'` for RegulationID 6/7/8
  - numeric `'9820101'` for RegulationID 12 (FINRAONLY)

**This is an estimate, not the final figure.** Final PFOF comes from Apex Finance (handled by US Finance) and can vary by **20% or more**.

## Other SOD tables (less commonly used)

| Table | When to use |
|---|---|
| `EXT538_ClosedAccounts` (`main.bi_db`) | Tracking account closures explicitly (rather than inferring from `EXT765.ClosedDate IS NOT NULL`) |
| `EXT870_StockActivity` (`main.finance`) | Corporate actions affecting stock holdings (splits, transfers in/out, ACATS) |
| `EXT922_DividendReport` (`main.finance`) | Dividend distributions for equity holdings (note: options don't pay dividends, so this is equity-side only despite living adjacent) |
| `EXT235_MandatoryCorporateActions` (`main.trading`) | Mandatory corporate-action events (mergers, mandatory tenders, spin-offs) |
| `EXT_sodfiles` (`main.finance`) | File-level audit (which files were delivered when by Apex) |

## USABroker bridge & dictionaries

### `main.general.bronze_usabroker_apex_options` — the GCID ↔ OptionsApexID bridge

The **single most important USABroker table**. One row per options-onboarded customer. Joins eToro's `GCID` to Apex's `AccountNumber` (here called `OptionsApexID`) and carries the regulatory-onboarding state.

**Key fields**:
- `GCID`, `OptionsApexID` — the bridge (1:1 in practice; primary key is GCID)
- `EligibilityStatusID`, `EligibilityStatusReasonID` — onboarding eligibility
- `AppropriatenessProductID`, `AppropriatenessTestResultID`, `AppropriatenessRecalculationReasonID`, `AppropriatenessTestDate` — suitability test outcomes
- `OptionsStatusID`, `OptionsStatusControlID` — current options-trading approval state
- `ReasoningFormID`, `ReasoningStatusID` — manual-review override path
- `BeginTime` — when the customer first appeared in this table

### Dictionaries (resolve the *ID columns above)

| ID column | Dictionary table | Values |
|---|---|---|
| `EligibilityStatusID` | `main.bi_db.bronze_usabroker_dictionary_eligibilitystatus` | 0=Disallowed, 1=Allowed |
| `AppropriatenessProductID` | `main.bi_db.bronze_usabroker_dictionary_appropriatenessproduct` | 0=None, 1=CFD, 2=FPSL, 3=Options |
| `AppropriatenessTestResultID` | `main.bi_db.bronze_usabroker_dictionary_appropriatenesstestresult` | 0=None, 1=Failed, 2=Passed |
| `OptionsStatusID` | `main.bi_db.bronze_usabroker_dictionary_optionsstatus` | 0=None, 1=Pending, 2=InProcess, 3=Approved, 4=Rejected |
| `OptionsStatusControlID` | `main.general.bronze_usabroker_dictionary_optionsstatuscontrol` | 0=None, 1=Blocked, 2=Allowed |
| `ReasoningStatusID` | `main.bi_db.bronze_usabroker_dictionary_reasoningstatus` | 0=None, 1=PendingReasoningScreen, 2=PendingManualReview, 3=Allowed, 4=DisallowedByManualReview |
| `AppropriatenessRecalculationReasonID` | (no dictionary table — offline note from Victor Shatokhin) | 0=None, 1=BulkRecalculation, 2=RegulationChanged, 3=ReachedVerificationLevel2, 4=AnswerChanged, 5=Manual |

The `AppropriatenessRecalculationReasonID` enum is documented in the BI Doc as offline knowledge — Victor Shatokhin (victorsh@) is the source of truth. If a new dictionary needs to be added, request via Victor.

### Reasoning-form sub-tables (for manual review / appeal flow)

- `main.bi_db.bronze_usabroker_apex_optionsreasoningform` — one row per submitted reasoning form (DateCreated, DateSubmitted, PreviousAppropriatenessTestDate)
- `main.bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers` — Q&A pairs (KycQuestionID, ReasoningFormAnswerID, OldKycAnswerID)
- `main.bi_db.bronze_usabroker_apex_sketchinvestigationdonotappealreason` — outcomes for cases that can't be appealed

### USABroker user-data tables (`main.finance` cluster)

These mirror the broader Apex user-data sync (not just Options-onboarding):
- `bronze_usabroker_apex_apexdata` — master user data
- `bronze_usabroker_apex_state` — state-of-residence data
- `bronze_usabroker_apex_tradinguserdata` — trading-eligibility records
- `bronze_usabroker_apex_userdata` — generic user data
- `bronze_usabroker_apex_uservalidationerrors` — validation errors during onboarding

For most BI/KPI work, `bronze_usabroker_apex_options` is sufficient. Use the user-data cluster only for ops/onboarding deep-dives.

## PII inventory

PII fields are concentrated in these 4 tables — handle carefully:

| Table | PII fields |
|---|---|
| `main.general.bronze_sodreconciliation_apex_ext765_accountmaster` | `AccountName`, `TaxIdNumber`, `AddressLine1`, `City`, `State`, `ZipCode` |
| `main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation` | `AccountName1`, `TaxIdNumber`, `DateOfBirth`, `EmailAddress`, `AddressLine1`, `City`, `State`, `ZipCode` |
| `main.finance.bronze_usabroker_apex_userdata` | full user data (PII) |
| `main.finance.bronze_usabroker_apex_apexdata` | full user data (PII) |

The 3 prep views (`v_options_aum`, `v_mimo_options_platform`, `v_revenue_optionsplatform`) all join via `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (the masked Dim_Customer) — so they don't expose PII downstream. Direct queries against the bronze tables above DO expose PII.

## Cross-references

- For column-level details on the 6 documented Apex SOD tables, the BI Doc extract `knowledge/_inbox/gatsby-options/options-data-kt.md` has verbatim "Key Fields / Developer Note / Comment (Limitations)" sections.
- The Synapse-side TVF wrappers (`Function_MIMO_Options_Platform`, `Function_Revenue_OptionsPlatform`) reference the same bronze tables under their pre-UC names (with `External_` prefix) — see `knowledge/synapse/Wiki/BI_DB_dbo/Functions/`.
- For schema validation: `SELECT * FROM main.information_schema.tables WHERE table_name LIKE '%apex%' OR table_name LIKE '%usabroker%'` (returns 38 rows as of 2026-05-31).
