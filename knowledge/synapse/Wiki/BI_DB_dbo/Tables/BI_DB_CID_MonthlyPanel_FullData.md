# BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData

> Monthly per-depositor customer panel — the broadest monthly CRM fact table in BI_DB_dbo. 189 columns covering registration, trading activity, revenue, PnL, equity, copy trading, lifetime accumulators, life-stage classification, and LTV predictions. One row per depositor (IsFunded) per calendar month. 353.8M rows total; 5.87M distinct CIDs; date range 2007-08 to present (oldest data in BI_DB_dbo).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL (see Section 4) |
| **Refresh** | Daily — DELETE WHERE ActiveDate = @BeginOfMonth + INSERT, then 4× POST-INSERT UPDATEs (SP_CID_MonthlyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (ActiveDate ASC, CID ASC) |
| **Row Count** | ~353.8M total; ~5.87M per month-slice (April 2026) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_MonthlyPanel_FullData` is the primary **monthly CRM analytics panel** for all eToro depositors — the widest monthly customer table in BI_DB_dbo. For each customer who is classified as "funded" (IsFunded), it provides a full monthly snapshot of their trading activity, financial position, revenue contribution, lifecycle stage, and accumulated lifetime totals.

The table serves as the central input for:
- **CRM and retention analytics**: Club tier distribution, life-stage transitions (EOM_LSD), churn (IsChurn_ThisM) and win-back (IsWB_ThisM) detection
- **Revenue reporting**: Monthly and lifetime revenue by instrument type and fee category; two revenue total formulas (legacy Revenue_Total and current Revenue_Total_New since 2025)
- **LTV modeling**: Six LTV columns written by a separate SP (`SP_LTV_BI_Actual`) representing 1Y, 3Y, and 8Y lifetime value predictions
- **PnL and equity tracking**: End-of-month equity by asset class and leverage tier
- **Acquisition analytics**: Channel, affiliate, first action, and seniority data from the customer's registration
- **Compliance**: AML last ticket date, IsChurn flag, professional client status

**Population boundary**: Only **funded/depositing customers** are included. Non-depositing registered users are absent. ~5.87M distinct CIDs as of April 2026; earliest CID dates from 2007-08 (oldest data in BI_DB_dbo).

**Instrument taxonomy**: Activity, revenue, PnL, and equity columns are systematically repeated across 6 asset-class families:
- **Copy** — copy-mirror positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** sub-divides four asset classes (Real Stocks, CFD Stocks, Real Crypto, CFD Crypto):
- **Lev1** — 1:1 leverage, IsBuy=1 (long un-leveraged position)
- **LevCFD** — leveraged or short position (CFD-style)

**ACC_ prefix**: Accumulator columns carry a running lifetime total from the customer's first month. Each month's value = current month's metric + prior month's ACC_ value (self-reference pattern). For a customer's first ever month, ACC_ initialises from the current month values only.

**Column evolution**: The SP has been extended many times since 2019. Columns 176–189 (ActiveOpenManual, ActiveOpenWOAirdrop, ActiveOpenWOAirdropManual, EOM_LSD, ActiveOpen_AirDrop, ActiveOpen_Mirror, ActiveOpen_Manual, ActiveOpen_IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, Revenue_Total_New, ACC_Revenue_Total_New, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, Revenue_TicketFeeByPercent) were added 2021–2025. Historical rows pre-dating those additions will show NULL.

---

## 2. Business Logic

### 2.1 EOM_Club — Monthly Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of the calendar month, based on `Dim_PlayerLevel` with a LowBronze/HighBronze split applied within BI_DB_dbo.

**Columns Involved**: `EOM_Club`

**Rules**:
```
EOM_Club =
  WHEN EOM_Equity < 1000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                         → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                      → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split at the $1,000 equity mark. Observed distribution (April 2026): LowBronze 79.6%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOM_Regulation — Regulatory Jurisdiction

**What**: Customer's regulatory entity at end of month, from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`.

**Columns Involved**: `EOM_Regulation`

**Observed values (April 2026)**: CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, FinCEN 1.7%, FSRA 1.5%, ASIC 0.9%, MAS, FINRAONLY, NFA, BVI, NYDFS+FINRA, eToroUS (<1% each).

### 2.3 Active / ActiveOpen / NewTrades Definitions

**Columns Involved**: `Active`, `ActiveOpen`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`, `ActiveOpen_AirDrop`, `NewTrades_*`, `Active_*`, `ActiveOpen_*`

**Rules**:
```
Active = 1       → customer closed ≥1 position this calendar month (any asset class)
ActiveOpen = 1   → CASE WHEN ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1 THEN 1 ELSE 0 END
                   (Or Filizer update 2025-01-06)
ActiveUser = 1   → EOM_Equity > 0 (customer has any equity at month end)
NewTrades_Total  → count of all newly opened positions (across all asset classes) this month
```
Note: `ActiveOpen` is a composite flag. A customer counts as ActiveOpen if they have any open manual, new-mirror, or add-mirror position. Copy-portfolio positions count separately (`ActiveOpen_Copy`, `IsOpen_CopyPortfolio`).

### 2.4 Revenue Taxonomy (Post-2025 Update)

**What**: Two parallel revenue totals exist due to the 2025 fee component expansion by Or Filizer.

**Columns Involved**: `Revenue_Total`, `Revenue_Total_New`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Formulas**:
```
FullCommissions = Revenue_Copy + Revenue_Real_Crypto + Revenue_CFD_Crypto
                + Revenue_Real_Stocks + Revenue_CFD_Stocks + Revenue_FX/Comm/Ind + Revenue_Other
                [sourced from BI_DB_DailyCommisionReport]

Revenue_Total     = FullCommissions only (LEGACY formula — excludes function fees)

Revenue_Total_New = FullCommissions
                  + Revenue_AdminFee (Islamic account admin fee)
                  + Revenue_TicketFees (Function_Revenue_TicketFee)
                  + Revenue_ConversionFees (Function_Revenue_ConversionFee)
                  + Revenue_SpotAdjustFee (Islamic spot adjustment fee)
                  + Revenue_TicketFeeByPercent (Function_Revenue_TicketFeeByPercent)

Revenue_IslamicFees = Revenue_AdminFee + Revenue_SpotAdjustFee
                   [fee components specific to Islamic/swap-free accounts]

Transactional_Revenue_Total = Revenue_Total_New − Revenue_ConversionFees
                             [excludes currency conversion fees; pure transactional/trading revenue]
```
**Guidance**: Use `Revenue_Total_New` for all current reporting. `Revenue_Total` is retained for historical comparability only. `Transactional_Revenue_Total` is used when conversion fee effects should be excluded (e.g., revenue from trading activity only).

### 2.5 ACC_ Column Accumulation Pattern

**What**: Running lifetime totals built by reading the prior month's row from the same table.

**Columns Involved**: All `ACC_*` columns (22 columns)

**Pattern**:
```sql
-- Pseudo-code for each ACC_ column:
ACC_Revenue_Total_New(this_month) =
    Revenue_Total_New(this_month)
  + ISNULL(ACC_Revenue_Total_New FROM same_table WHERE ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth), 0)
```
The prior month's ACC_ value is fetched into temp table `#History` via a SELECT on the same Synapse table. For a customer's first month in the table (no prior row exists), `ACC_` initialises to the current month's value only.

**Important**: Because the current month's row is deleted and re-inserted daily (while the month is open), the `#History` lookup always reads the prior *closed* month. The current month's running total accumulates correctly only when the prior month is locked.

### 2.6 IsChurn_ThisM / IsWB_ThisM — Churn and Win-Back Flags

**What**: Monthly churn and win-back event detection based on IsFunded_New transitions.

**Columns Involved**: `IsChurn_ThisM`, `IsWB_ThisM`, `IsFunded_New`

**Rules** (POST-INSERT UPDATE from #ChurnWB):
```
IsChurn_ThisM = 1   when prior_month.IsFunded_New > 0  AND  this_month.IsFunded_New = 0
IsWB_ThisM    = 1   when prior_month.IsFunded_New = 0  AND  this_month.IsFunded_New > 0
```
The prior month's `IsFunded_New` is read from the already-inserted row for `ActiveDate = DATEADD(MONTH,-1,@BeginOfMonth)`.

### 2.7 Seniority_FundedNew — Adjusted Seniority Since First Funding

**What**: Months since the customer's "new funded" date — a composite date that takes the latest of FTD, first action, and KYC level-3 completion dates, rounded to month start.

**Columns Involved**: `Seniority_FundedNew`, `Seniority`

**Rules** (POST-INSERT UPDATE from #Seniority_FundedNew):
```
NewFunded_Date0 = MAX(
    DATEFROMPARTS(YEAR(FTDDate), MONTH(FTDDate), 1),
    DATEFROMPARTS(YEAR(FirstActionDate), MONTH(FirstActionDate), 1),
    DATEFROMPARTS(YEAR(V3_Date), MONTH(V3_Date), 1)
)
Seniority_FundedNew = DATEDIFF(MONTH, NewFunded_Date0, ActiveDate)
                      (NULL for unfunded customers or if dates unavailable)

Seniority (original) = DATEDIFF(MONTH, FTDdate, @BeginOfMonth)
```

### 2.8 LTV Columns — Populated by Separate SP

**What**: Six LTV model predictions. NOT set by `SP_CID_MonthlyPanel_FullData` — they are hardcoded `0` in the initial INSERT to avoid an SP→table circular dependency.

**Columns Involved**: `LTV_1Y`, `LTV_3Y`, `LTV_8Y`, `LTV_8Y_NoExtreme`, `LTV_Expected_bySeniority`, `NoExtremeLTV_Expected_bySeniority`

**Rules**:
```
SP_CID_MonthlyPanel_FullData: LTV_* = 0 (hardcoded, prevents loop)
SP_LTV_BI_Actual:             LTV_* = model predictions (runs separately, UPDATEs these columns)
```
Circular dependency note: `SP_LTV_BI_Actual` reads from `BI_DB_CID_MonthlyPanel_FullData` (for revenue/activity input features), so if `SP_CID_MonthlyPanel_FullData` tried to read LTV from itself, it would create a loop. The solution is to initialise LTV to 0 and let `SP_LTV_BI_Actual` fill them in on a separate pass.

### 2.9 EOM_LSD — Life Stage Description

**What**: 17-value customer lifecycle classification at end of month, set from `BI_DB_CID_LifeStageDefinition`.

**Columns Involved**: `EOM_LSD`

**Observed values (April 2026)**:
| Life Stage | Count | % |
|---|---|---|
| Dump Churn | 2,184,880 | 37.2% |
| Holder | 1,139,396 | 19.4% |
| No Activity - Not Funded | 712,990 | 12.2% |
| Active Open Club | 311,045 | 5.3% |
| Active Open | 296,517 | 5.0% |
| Churn over 60 days | 286,978 | 4.9% |
| Active Open 30-90 days | 257,397 | 4.4% |
| Holder Club | 193,957 | 3.3% |
| No Activity - Funded | 169,824 | 2.9% |
| Active Open 30-90 days Club | 115,709 | 2.0% |
| Win Back Active Open | 72,325 | 1.2% |
| Active LogIn | 40,768 | 0.7% |
| Churn 31-60 days | 38,262 | 0.7% |
| Churn 14-30 days | 22,393 | 0.4% |
| New Funded | 9,458 | 0.2% |
| New Depositor Only | 6,003 | 0.1% |
| Win Back Deposit | 267 | 0.004% |

---

## 3. Query Advisory

### 3.1 Grain and Filtering
- **One row per CID per calendar month**. Always filter `WHERE ActiveDate = '20XX-MM-01'` (first day of month) for a single-month slice. Do NOT filter on Active_Month (char type has trailing spaces, comparisons can fail).
- **ActiveDate is DATE type** (not INT). Use `ActiveDate = '2026-04-01'` not `ActiveDate = 20260401`.
- **Bracket-escape "/" column names**: `[Active_FX/Comm/Ind]`, `[Revenue_FX/Comm/Ind]`, `[PnL_FX/Comm/Ind]`, `[ACC_Revenue_FX/Comm/Ind]`, `[ACC_PnL_FX/Comm/Ind]`, `[AmountIn_NewTrades_FX/Comm/Ind]`, `[NewTrades_FX/Comm/Ind]`, `[EOM_Equity_FX/Comm/Ind]`.

### 3.2 Revenue Columns — Which to Use
- Use **`Revenue_Total_New`** for all current revenue analysis (includes all fee components since 2025).
- Use **`Revenue_Total`** only for pre-2025 historical comparability — it excludes function-based fees.
- Use **`Transactional_Revenue_Total`** when you want to exclude currency conversion fees (e.g., pure trading activity measurement).
- Use **`ACC_Revenue_Total_New`** for lifetime revenue totals. Do NOT use `ACC_Revenue_Total` for new analysis — it accumulates the legacy formula.

### 3.3 LTV Columns
- **LTV columns are always 0 unless SP_LTV_BI_Actual has run for that month**. If you see all-zero LTV values, check whether the LTV SP has been executed. LTV is typically available for historical months only.
- LTV applies to funded/active customers only; check for 0 vs NULL before aggregating.

### 3.4 ACC_ Column Behaviour for Current Month
- The current open month's ACC_ values accumulate correctly only after the prior month is locked. For the **live/current month**, ACC_ reflects: prior month's ACC_ + current run's values. It is refreshed daily on DELETE+INSERT.
- Do NOT compare ACC_ totals across different months for the same CID — the prior month's value is included, making comparisons misleading.

### 3.5 Lev1/LevCFD Sub-Tier Columns
- The **plain** `Active_Real_Stocks`, `Active_CFD_Stocks`, etc. columns include **both Lev1 and LevCFD** combined.
- `Active_Real_Stocks_Lev1` and `Active_CFD_Stocks_LevCFD` are **sub-breakdowns** of the plain columns.
- Note: the Lev1/LevCFD flag columns (Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL) are stored as `[money]` type in the DDL, though semantically binary (0 or 1 for Active/ActiveOpen). This is a known DDL quirk.
- These columns contain NULL for pre-2023 periods when the Lev split was not yet tracked.

### 3.6 EOM_Segment Always NULL
- The `EOM_Segment` column is always NULL in practice — it was reserved but never populated by the ETL.

### 3.7 Large Table Query Guidance
- With 353.8M rows, **always filter on `ActiveDate`** before adding other predicates. `ActiveDate` is the leading index key.
- The table is HASH(CID)-distributed. Joins to other HASH(CID) tables (e.g., BI_DB_CID_DailyPanel_FullData) are co-located — no data movement.
- Avoid `COUNT(*)` without a date filter. Use `sys.dm_pdw_nodes_db_partition_stats` for rowcount estimates.
- For `GROUP BY` analytics on a single month, add `WHERE ActiveDate = '20XX-MM-01'` and include `ActiveDate` in the GROUP BY if reporting multiple months.

### 3.8 CountryID vs Country / Region
- `CountryID` (int, FK → Dim_Country) is the canonical geographic key. JOIN to `DWH_dbo.Dim_Country` for country attributes.
- `Country` (varchar) and `Region` (varchar) are denormalized strings copied from Dim_Customer at ETL time. They may lag Dim_Country changes by up to one day.
- `NewMarketingRegion` is a more recent marketing region label that may differ from `Region` for some countries.

---

## 4. Data Elements

### 4.1 Identity / Grain

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | bigint | NO | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | Active_Month | char(7) | NO | Calendar month this row represents, in YYYY-MM format with trailing space pad to 7 chars (e.g., '202604 '). Grain identifier alongside ActiveDate. Always use ActiveDate (DATE) for filtering; char comparisons on Active_Month can fail due to trailing space. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 3 | ActiveDate | date | NO | First day of the calendar month (e.g., 2026-04-01). Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for month slices. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 109 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_CID_MonthlyPanel_FullData. Refreshed daily during the current open month. (Tier 2 — ETL metadata) |

### 4.2 Registration & Acquisition

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | Seniority | int | YES | Months since first deposit: DATEDIFF(MONTH, FTDdate, ActiveDate). 0 = FTD month. NULL for customers without a deposit. Observed range: 0–225 months (2007–2026). (Tier 2 — SP_CID_MonthlyPanel_FullData, BI_DB_CIDFirstDates) |
| 5 | RegMonth | char(7) | YES | Month of customer registration in YYYY-MM format. (Tier 2 — Dim_Customer via #CIDs) |
| 6 | RegDate | date | YES | Exact date of customer registration. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 7 | IsReg_ThisM | tinyint | YES | 1 if the customer registered during this calendar month; 0 otherwise. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 8 | FTD_Month | char(7) | YES | Month of first time deposit (FTD) in YYYY-MM format. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 9 | FTDdate | date | YES | Exact date of first deposit. NULL before FTD. (Tier 2 — BI_DB_CIDFirstDates) |
| 10 | IsFTD_ThisM | tinyint | YES | 1 if the customer made their first deposit this calendar month; 0 otherwise. (Tier 2 — BI_DB_CIDFirstDates) |
| 11 | FTDA | money | YES | First time deposit amount (USD). Amount of the initial deposit event. (Tier 2 — BI_DB_CIDFirstDates) |
| 12 | Region | varchar(50) | YES | Marketing region name as of ETL run (e.g., 'ROW', 'UK', 'CEE', 'Latam'). Denormalized from Dim_Customer. May differ from NewMarketingRegion for some countries. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 13 | Country | varchar(50) | YES | Customer's country name (e.g., 'United Kingdom', 'Israel'). Denormalized from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 14 | Channel | varchar(50) | YES | Acquisition channel (e.g., 'Affiliate', 'SEM', 'Media Performance'). (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 15 | SubChannel | varchar(250) | YES | Acquisition sub-channel. More granular than Channel. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 16 | AffiliateID | bigint | YES | Affiliate partner identifier. FK → DWH_dbo.Dim_Affiliate. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 17 | FirstAction | varchar(50) | YES | Instrument type of the customer's first-ever trade (e.g., 'FX/Commodities/Indices', 'Crypto'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 18 | FirstInstrument | varchar(250) | YES | Name of the specific instrument in the customer's first trade (e.g., 'EUR/USD', 'BTC'). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions) |
| 19 | V2_Complete | tinyint | YES | 1 if KYC level 2 (identity verification) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 20 | V3_Complete | tinyint | YES | 1 if KYC level 3 (enhanced due diligence / proof of address) was completed before this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |

### 4.3 Engagement & State

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 21 | LastPosOpenDate | date | YES | Date of the customer's last position open event (any instrument) up to and including this month. (Tier 2 — Fact_CustomerAction) |
| 22 | LastLoggedIn | date | YES | Date of the customer's last login before end of this month. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 23 | IsPro | tinyint | YES | 1 if the customer has professional client status (from External_BI_OUTPUT_Customer_ProfessionalCustomers). (Tier 2 — External table) |
| 24 | IsOTD | tinyint | YES | 1 if the customer is classified as OTD (Over-the-Desk / client service tier). (Tier 2 — Fact_SnapshotCustomer) |
| 110 | AccountManager | varchar(250) | YES | Name of the assigned account manager at ETL run time. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 111 | IsIslamic | tinyint | YES | 1 if the customer's account is Islamic (swap-free). Islamic accounts incur AdminFee and SpotAdjustFee instead of overnight swaps. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 112 | IsContacted | tinyint | YES | 1 if the customer was contacted by sales/CRM this month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 113 | IsContactedAmount | money | YES | Amount associated with the CRM contact event this month (if applicable). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 117 | LastApplicationProAccountDate | date | YES | Date of the customer's most recent professional account application. 1900-01-01 if no application. (Tier 2 — Fact_SnapshotCustomer) |
| 173 | LastAMLTicketDate | date | YES | Most recent AML-related Salesforce case date for this customer (POST-INSERT UPDATE from BI_DB_SF_Cases_Panel). NULL if no AML case history. (Tier 2 — BI_DB_SF_Cases_Panel) |

### 4.4 EOM Classification & Segmentation

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | EOM_Club | varchar(50) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000–Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 26 | EOM_Regulation | varchar(50) | YES | Regulatory jurisdiction at end of month (e.g., CySEC, FCA, FinCEN+FINRA, ASIC & GAML). Sourced from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 15 distinct values observed. (Tier 2 — Fact_SnapshotCustomer / Dim_Regulation) |
| 27 | EOM_Equity | money | YES | Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. (Tier 2 — DWH_dbo.V_Liabilities) |
| 28 | EOM_Balance | money | YES | Cash balance (USD) at end of month — equity minus unrealised PnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| 29 | EOM_Segment | varchar(50) | YES | Reserved classification field. Always NULL in practice — never populated by current ETL. (Tier 2 — Reserved) |
| 32 | ActiveUser | tinyint | YES | 1 if EOM_Equity > 0 (customer has any portfolio value at month end). Broader than Active or ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 114 | EOM_IsFunded | tinyint | YES | Legacy funded flag at end of month from Fact_SnapshotCustomer snapshot. Differs from IsEOM_Funded_NEW / IsFunded_New in calculation. Use IsFunded_New or IsEOM_Funded_NEW for current analysis. (Tier 2 — Fact_SnapshotCustomer) |
| 158 | IsFunded_New | tinyint | YES | Current funding flag (new definition). Used as the base for IsChurn_ThisM and IsWB_ThisM churn detection. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 159 | Seniority_FundedNew | int | YES | Months since customer's "new funded" date: DATEDIFF(MONTH, MAX(FTDMonth, FirstActionMonth, V3Month), ActiveDate). NULL for unfunded customers. (Tier 2 — BI_DB_CIDFirstDates + BI_DB_First5Actions, POST-INSERT UPDATE) |
| 168 | NewMarketingRegion | varchar(50) | YES | Marketing region label (newer vintage than Region). Values: ROW, UK, CEE, Nordics, Latam, SEA, Australia, etc. (Tier 2 — Fact_SnapshotCustomer / Dim_Customer) |
| 169 | ClusterDetail | varchar(50) | YES | Customer behaviour cluster name from BI_DB_CID_DailyCluster (e.g., 'Equities Crypto'). NULL for unclustered customers. (Tier 2 — BI_DB_CID_DailyCluster) |
| 170 | IsEOM_Funded_NEW | tinyint | YES | End-of-month funded flag under the new funded definition. Closely related to IsFunded_New; reflects EOM state. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 172 | CountryID | int | YES | FK → DWH_dbo.Dim_Country.CountryID. Use for country attribute lookups (regulation, AML risk, EU membership). CountryID=0 = Not available. (Tier 1 — DWH_dbo.Dim_Country wiki) |
| 174 | IsChurn_ThisM | int | YES | 1 if customer was funded last month (IsFunded_New=1) but not this month (IsFunded_New=0). Churn event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 175 | IsWB_ThisM | int | YES | 1 if customer was not funded last month but is funded this month. Win-back event indicator. POST-INSERT UPDATE. (Tier 2 — SP_CID_MonthlyPanel_FullData self-reference) |
| 179 | EOM_LSD | nvarchar(50) | YES | Life Stage Description at end of month from BI_DB_CID_LifeStageDefinition. 17 possible values: e.g., 'Dump Churn', 'Holder', 'Active Open Club', 'New Funded', 'Win Back Active Open'. (Tier 2 — BI_DB_CID_LifeStageDefinition) |

### 4.5 Activity Flags — Top Level

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | Active | tinyint | YES | 1 if customer closed ≥1 position this month (any asset class). (Tier 2 — Fact_CustomerAction) |
| 34 | ActiveOpen | tinyint | YES | 1 if customer has open positions at month end. Composite: 1 when ActiveOpen_Manual=1 OR ActiveOpen_NewMirror=1 OR ActiveOpen_AddMirror=1. (Tier 2 — SP_CID_MonthlyPanel_FullData, Or Filizer 2025-01-06) |
| 176 | ActiveOpenManual | int | YES | Count of open manual (non-copy) positions at month end. Stored as count, not a binary flag. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 177 | ActiveOpenWOAirdrop | int | YES | Count of open positions at month end, excluding airdrop-type positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 178 | ActiveOpenWOAirdropManual | int | YES | Count of open manual positions at month end excluding airdrop positions. (Tier 2 — SP_CID_MonthlyPanel_FullData) |

### 4.6 Activity Flags — Asset Class

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 45 | Active_Copy | tinyint | YES | 1 if customer had active copy trades closed this month. (Tier 2 — Fact_CustomerAction) |
| 46 | Active_Real_Stocks | tinyint | YES | 1 if customer closed ≥1 real (settled) stock/ETF position this month. (Tier 2 — Fact_CustomerAction) |
| 47 | Active_CFD_Stocks | tinyint | YES | 1 if customer closed ≥1 CFD (leveraged) stock position this month. (Tier 2 — Fact_CustomerAction) |
| 48 | Active_Real_Crypto | tinyint | YES | 1 if customer closed ≥1 settled crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 49 | Active_CFD_Crypto | tinyint | YES | 1 if customer closed ≥1 CFD crypto position this month. (Tier 2 — Fact_CustomerAction) |
| 50 | [Active_FX/Comm/Ind] | tinyint | YES | 1 if customer closed ≥1 FX/commodity/index position this month. Column name contains "/" — must use bracket quoting. (Tier 2 — Fact_CustomerAction) |
| 51 | ActiveOpen_Copy | tinyint | YES | 1 if customer has open copy trades at month end. (Tier 2 — Fact_CustomerAction) |
| 52 | ActiveOpen_Real_Stocks | tinyint | YES | 1 if customer has open real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 53 | ActiveOpen_CFD_Stocks | tinyint | YES | 1 if customer has open CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 54 | ActiveOpen_Real_Crypto | tinyint | YES | 1 if customer has open settled crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 55 | ActiveOpen_CFD_Crypto | tinyint | YES | 1 if customer has open CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 56 | [ActiveOpen_FX/Comm/Ind] | tinyint | YES | 1 if customer has open FX/commodity/index positions at month end. Bracket-quote required. (Tier 2 — Fact_CustomerAction) |
| 180 | ActiveOpen_AirDrop | int | YES | 1 if customer has open airdrop-type positions at month end. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 181 | ActiveOpen_Mirror | int | YES | 1 if customer has open mirror/add-mirror copy positions at month end. CASE WHEN NewMirror=1 OR AddMirror=1. (Tier 2 — Dim_Mirror via #mrr/#addmrr) |
| 182 | ActiveOpen_Manual | int | YES | 1 if customer has open manually-executed positions at month end (non-copy). (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 183 | ActiveOpen_IncludeCopy | int | YES | 1 if customer has open positions including copy trades at month end. Superset of ActiveOpen. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 128 | Active_Real_Stocks_Lev1 | money | YES | Flag (stored as money: 0.0 or 1.0) — customer traded real stocks with 1:1 leverage (un-leveraged long) this month. (Tier 2 — Fact_CustomerAction Lev sub-split) |
| 129 | Active_CFD_Stocks_LevCFD | money | YES | Flag — customer traded leveraged/short CFD stock positions this month. (Tier 2 — Fact_CustomerAction) |
| 130 | Active_Real_Crypto_Lev1 | money | YES | Flag — customer traded un-leveraged real crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 131 | Active_CFD_Crypto_LevCFD | money | YES | Flag — customer traded leveraged/short CFD crypto positions this month. (Tier 2 — Fact_CustomerAction) |
| 132 | ActiveOpen_Real_Stocks_Lev1 | money | YES | Flag — customer has open un-leveraged real stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 133 | ActiveOpen_CFD_Stocks_LevCFD | money | YES | Flag — customer has open leveraged CFD stock positions at month end. (Tier 2 — Fact_CustomerAction) |
| 134 | ActiveOpen_Real_Crypto_Lev1 | money | YES | Flag — customer has open un-leveraged real crypto positions at month end. (Tier 2 — Fact_CustomerAction) |
| 135 | ActiveOpen_CFD_Crypto_LevCFD | money | YES | Flag — customer has open leveraged CFD crypto positions at month end. (Tier 2 — Fact_CustomerAction) |

### 4.7 Copy / Portfolio Copy Activity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 35 | IsOpen_Copy | tinyint | YES | 1 if customer has an open copy trade relationship at month end. (Tier 2 — Fact_CustomerAction) |
| 36 | Count_Opened_Copy | int | YES | Number of new copy trade relationships opened this month. (Tier 2 — Fact_CustomerAction) |
| 37 | Count_Closed_Copy | int | YES | Number of copy trade relationships closed this month. (Tier 2 — Fact_CustomerAction) |
| 38 | MoneyIn_Copy | money | YES | USD amount allocated to new copy trades this month. (Tier 2 — Fact_CustomerAction) |
| 39 | MoneyOut_Copy | money | YES | USD amount withdrawn from copy trades this month (stop-copy events). (Tier 2 — Fact_CustomerAction) |
| 40 | IsOpen_CopyPortfolio | tinyint | YES | 1 if customer has an open copy-portfolio (SmartPortfolio) position at month end. (Tier 2 — Fact_CustomerAction) |
| 41 | Count_Opened_CopyPortfolio | int | YES | Number of new copy-portfolio positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 42 | Count_Closed_CopyPortfolio | int | YES | Number of copy-portfolio positions closed this month. (Tier 2 — Fact_CustomerAction) |
| 43 | MoneyIn_CopyPortfolio | money | YES | USD amount allocated to new copy-portfolio positions this month. (Tier 2 — Fact_CustomerAction) |
| 44 | MoneyOut_CopyPortfolio | money | YES | USD amount withdrawn from copy-portfolio positions this month. (Tier 2 — Fact_CustomerAction) |

### 4.8 Trade Counts & Volumes (NewTrades / AmountIn)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 57 | NewTrades_Copy | int | YES | Count of new copy positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 58 | NewTrades_Real_Stocks | int | YES | Count of new settled stock/ETF positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 59 | NewTrades_CFD_Stocks | int | YES | Count of new CFD stock positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 60 | NewTrades_Real_Crypto | int | YES | Count of new settled crypto positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 61 | NewTrades_CFD_Crypto | int | YES | Count of new CFD crypto positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 62 | [NewTrades_FX/Comm/Ind] | int | YES | Count of new FX/commodity/index positions opened this month. Bracket-quote required. (Tier 2 — Fact_CustomerAction) |
| 63 | NewTrades_Total | int | YES | Total count of new positions opened this month (all asset classes combined). (Tier 2 — Fact_CustomerAction) |
| 64 | AmountIn_NewTrades_Copy | money | YES | USD amount allocated to new copy positions opened this month. (Tier 2 — Fact_CustomerAction) |
| 65 | AmountIn_NewTrades_Real_Stocks | money | YES | USD amount allocated to new real stock positions. (Tier 2 — Fact_CustomerAction) |
| 66 | AmountIn_NewTrades_CFD_Stocks | money | YES | USD amount allocated to new CFD stock positions. (Tier 2 — Fact_CustomerAction) |
| 67 | AmountIn_NewTrades_Real_Crypto | money | YES | USD amount allocated to new settled crypto positions. (Tier 2 — Fact_CustomerAction) |
| 68 | AmountIn_NewTrades_CFD_Crypto | money | YES | USD amount allocated to new CFD crypto positions. (Tier 2 — Fact_CustomerAction) |
| 69 | [AmountIn_NewTrades_FX/Comm/Ind] | money | YES | USD amount allocated to new FX/commodity/index positions. Bracket-quote required. (Tier 2 — Fact_CustomerAction) |
| 70 | AmountIn_NewTrades_Total | money | YES | Total USD amount allocated to all new positions this month. (Tier 2 — Fact_CustomerAction) |
| 136 | NewTrades_Real_Stocks_Lev1 | money | YES | Count of new un-leveraged real stock positions (Lev1) opened this month. Stored as money type. (Tier 2 — Fact_CustomerAction Lev sub-split) |
| 137 | NewTrades_CFD_Stocks_LevCFD | money | YES | Count of new leveraged/short CFD stock positions opened this month. Stored as money type. (Tier 2 — Fact_CustomerAction) |
| 138 | NewTrades_Real_Crypto_Lev1 | money | YES | Count of new un-leveraged real crypto positions opened this month. Stored as money type. (Tier 2 — Fact_CustomerAction) |
| 139 | NewTrades_CFD_Crypto_LevCFD | money | YES | Count of new leveraged/short CFD crypto positions opened this month. Stored as money type. (Tier 2 — Fact_CustomerAction) |
| 140 | AmountIn_NewTrades_Real_Stocks_Lev1 | money | YES | USD amount allocated to new Lev1 real stock positions. (Tier 2 — Fact_CustomerAction) |
| 141 | AmountIn_NewTrades_CFD_Stocks_LevCFD | money | YES | USD amount allocated to new LevCFD CFD stock positions. (Tier 2 — Fact_CustomerAction) |
| 142 | AmountIn_NewTrades_Real_Crypto_Lev1 | money | YES | USD amount allocated to new Lev1 real crypto positions. (Tier 2 — Fact_CustomerAction) |
| 143 | AmountIn_NewTrades_CFD_Crypto_LevCFD | money | YES | USD amount allocated to new LevCFD CFD crypto positions. (Tier 2 — Fact_CustomerAction) |

### 4.9 Revenue

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 71 | Revenue_Copy | money | YES | Monthly commission from copy trading (FullCommissions). (Tier 2 — BI_DB_DailyCommisionReport) |
| 72 | Revenue_Real_Stocks | money | YES | Monthly commission from settled stock/ETF trading. (Tier 2 — BI_DB_DailyCommisionReport) |
| 73 | Revenue_CFD_Stocks | money | YES | Monthly commission from CFD stock trading. (Tier 2 — BI_DB_DailyCommisionReport) |
| 74 | Revenue_Real_Crypto | money | YES | Monthly commission from settled crypto trading. (Tier 2 — BI_DB_DailyCommisionReport) |
| 75 | Revenue_CFD_Crypto | money | YES | Monthly commission from CFD crypto trading. (Tier 2 — BI_DB_DailyCommisionReport) |
| 76 | [Revenue_FX/Comm/Ind] | money | YES | Monthly commission from FX/commodity/index trading. Bracket-quote required. (Tier 2 — BI_DB_DailyCommisionReport) |
| 77 | Revenue_Total | money | YES | LEGACY total revenue: sum of FullCommissions only (Revenue_Copy + Real_Stocks + CFD_Stocks + Real_Crypto + CFD_Crypto + FX_Comm_Ind + Other). Excludes function fees (AdminFee, TicketFees, ConversionFees, etc.). Use Revenue_Total_New for current analysis. (Tier 2 — BI_DB_DailyCommisionReport) |
| 144 | Revenue_Real_Stocks_Lev1 | money | YES | Revenue from un-leveraged real stock positions + Revenue_TicketFees component. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFee) |
| 145 | Revenue_CFD_Stocks_LevCFD | money | YES | Revenue from leveraged CFD stock positions + TicketFeeByPercent_Stocks_CFD_Lev. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent) |
| 146 | Revenue_Real_Crypto_Lev1 | money | YES | Revenue from un-leveraged real crypto positions + TicketFeeByPercent_Crypto_Real. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent) |
| 147 | Revenue_CFD_Crypto_LevCFD | money | YES | Revenue from leveraged CFD crypto positions + TicketFeeByPercent_Crypto_CFD_Lev. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent) |
| 160 | A_Revenue_Currencies | money | YES | Revenue from currency CFD instruments (Currencies sub-class of FX). (Tier 2 — BI_DB_DailyCommisionReport) |
| 161 | A_Revenue_Commodities | money | YES | Revenue from commodity CFD instruments. (Tier 2 — BI_DB_DailyCommisionReport) |
| 162 | A_Revenue_Crypto | money | YES | Revenue from all crypto subtypes combined (CFD Crypto + Real Crypto, all leverage tiers). (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent) |
| 163 | A_Revenue_Equities | money | YES | Revenue from equity instruments (stocks, ETFs). (Tier 2 — BI_DB_DailyCommisionReport) |
| 184 | Revenue_IslamicFees | decimal(38,2) | YES | Islamic account fee revenue this month: AdminFee + SpotAdjustFee (swap replacement fees for Islamic/swap-free accounts). (Tier 2 — Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee) |
| 185 | Revenue_TicketFees | decimal(38,2) | YES | Ticket fee revenue this month from Function_Revenue_TicketFee. Per-position fees. (Tier 2 — Function_Revenue_TicketFee) |
| 186 | Revenue_ConversionFees | decimal(38,2) | YES | Currency conversion fee revenue this month from Function_Revenue_ConversionFee. Charged when trading instruments denominated in non-USD currencies. (Tier 2 — Function_Revenue_ConversionFee) |
| 187 | Revenue_Total_New | decimal(38,2) | YES | CURRENT total revenue formula (Or Filizer 2025): FullCommissions + AdminFee + TicketFees + ConversionFees + SpotAdjustFee + TicketFeeByPercent. Use this column for all current revenue analysis. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 189 | Transactional_Revenue_Total | decimal(38,2) | YES | Revenue_Total_New minus Revenue_ConversionFees. Measures pure trading/transactional revenue, excluding currency conversion costs. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 191 | Revenue_TicketFeeByPercent | decimal(38,2) | YES | Percent-based ticket fee revenue from Function_Revenue_TicketFeeByPercent. Applies to crypto and leveraged stock CFD positions. (Tier 2 — Function_Revenue_TicketFeeByPercent) |

### 4.10 PnL (Customer Perspective)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | PnL_Copy | money | YES | Customer-side realised PnL from copy trades closed this month (USD). Negative = customer lost money. (Tier 2 — BI_DB_PositionPnL) |
| 79 | PnL_Real_Stocks | money | YES | Realised PnL from settled stock/ETF positions closed this month. (Tier 2 — BI_DB_PositionPnL) |
| 80 | PnL_CFD_Stocks | money | YES | Realised PnL from CFD stock positions closed this month. (Tier 2 — BI_DB_PositionPnL) |
| 81 | PnL_Real_Crypto | money | YES | Realised PnL from settled crypto positions closed this month. (Tier 2 — BI_DB_PositionPnL) |
| 82 | PnL_CFD_Crypto | money | YES | Realised PnL from CFD crypto positions closed this month. (Tier 2 — BI_DB_PositionPnL) |
| 83 | [PnL_FX/Comm/Ind] | money | YES | Realised PnL from FX/commodity/index positions closed this month. Bracket-quote required. (Tier 2 — BI_DB_PositionPnL) |
| 84 | PnL_Total | money | YES | Total realised PnL across all asset classes this month. (Tier 2 — BI_DB_PositionPnL) |
| 148 | PnL_Real_Stocks_Lev1 | money | YES | Realised PnL from Lev1 (un-leveraged) real stock positions. (Tier 2 — BI_DB_PositionPnL) |
| 149 | PnL_CFD_Stocks_LevCFD | money | YES | Realised PnL from LevCFD (leveraged) CFD stock positions. (Tier 2 — BI_DB_PositionPnL) |
| 150 | PnL_Real_Crypto_Lev1 | money | YES | Realised PnL from Lev1 real crypto positions. (Tier 2 — BI_DB_PositionPnL) |
| 151 | PnL_CFD_Crypto_LevCFD | money | YES | Realised PnL from LevCFD CFD crypto positions. (Tier 2 — BI_DB_PositionPnL) |

### 4.11 Cashflow

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 85 | TotalDeposits | money | YES | Total USD deposited by the customer this calendar month. (Tier 2 — #Cashier from billing tables) |
| 86 | CountDeposits | int | YES | Number of deposit transactions this month. (Tier 2 — #Cashier) |
| 87 | TotalCashouts | money | YES | Total USD withdrawn by the customer this month. (Tier 2 — #Cashier) |
| 88 | TotalCoFee | money | YES | Total copy-out fees charged this month (fees incurred when exiting a copy relationship). (Tier 2 — #Cashier) |
| 89 | NetDeposits | money | YES | TotalDeposits − TotalCashouts for this month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 115 | WithdrawalToWallet | money | YES | USD amount withdrawn to the eToro Wallet (crypto wallet) this month. (Tier 2 — SP_CID_MonthlyPanel_FullData) |
| 171 | CashoutsAdjusted | decimal(38,2) | YES | Cashout amount adjusted per DDR methodology (from BI_DB_V_DDR_Daily_Panel). May differ from TotalCashouts due to DDR cashout adjustment rules. (Tier 2 — BI_DB_V_DDR_Daily_Panel) |

### 4.12 EOM Equity Breakdown

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 118 | EOM_Equity_Copy | money | YES | End-of-month equity in copy trades (USD). (Tier 2 — Fact_SnapshotCustomer / V_Liabilities breakdown) |
| 119 | EOM_Equity_Real_Crypto | money | YES | End-of-month equity in settled crypto positions. (Tier 2 — Fact_SnapshotCustomer breakdown) |
| 120 | EOM_Equity_Real_Stocks | money | YES | End-of-month equity in settled stock/ETF positions. (Tier 2 — Fact_SnapshotCustomer breakdown) |
| 121 | EOM_Equity_CFD_Crypto | money | YES | End-of-month equity in CFD crypto positions (unrealised value). (Tier 2 — Fact_SnapshotCustomer breakdown) |
| 122 | EOM_Equity_CFD_Stocks | money | YES | End-of-month equity in CFD stock positions. (Tier 2 — Fact_SnapshotCustomer breakdown) |
| 123 | [EOM_Equity_FX/Comm/Ind] | money | YES | End-of-month equity in FX/commodity/index positions. Bracket-quote required. (Tier 2 — Fact_SnapshotCustomer breakdown) |
| 124 | EOM_Equity_Real_Crypto_Lev1 | money | YES | EOM equity in un-leveraged (Lev1) real crypto positions. (Tier 2 — Fact_SnapshotCustomer Lev sub-split) |
| 125 | EOM_Equity_Real_Stocks_LevCFD | money | YES | EOM equity in leveraged-equivalent (LevCFD) real stock positions. (Tier 2 — Fact_SnapshotCustomer) |
| 126 | EOM_Equity_CFD_Crypto_Lev1 | money | YES | EOM equity in Lev1 CFD crypto positions. (Tier 2 — Fact_SnapshotCustomer) |
| 127 | EOM_Equity_CFD_Stocks_LevCFD | money | YES | EOM equity in LevCFD CFD stock positions. (Tier 2 — Fact_SnapshotCustomer) |

### 4.13 Accumulators (ACC_)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 90 | ACC_Revenue_Copy | money | YES | Lifetime accumulated copy trading commission. Current month Revenue_Copy + prior month ACC_Revenue_Copy. (Tier 2 — Self-reference) |
| 91 | ACC_Revenue_Real_Stocks | money | YES | Lifetime accumulated real stock commission. (Tier 2 — Self-reference) |
| 92 | ACC_Revenue_CFD_Stocks | money | YES | Lifetime accumulated CFD stock commission. (Tier 2 — Self-reference) |
| 93 | ACC_Revenue_Real_Crypto | money | YES | Lifetime accumulated settled crypto commission. (Tier 2 — Self-reference) |
| 94 | ACC_Revenue_CFD_Crypto | money | YES | Lifetime accumulated CFD crypto commission. (Tier 2 — Self-reference) |
| 95 | [ACC_Revenue_FX/Comm/Ind] | money | YES | Lifetime accumulated FX/commodity/index commission. Bracket-quote required. (Tier 2 — Self-reference) |
| 96 | ACC_Revenue_Total | money | YES | Lifetime accumulated total commission — accumulates LEGACY Revenue_Total. For lifetime analysis use ACC_Revenue_Total_New. (Tier 2 — Self-reference) |
| 97 | ACC_PnL_Copy | money | YES | Lifetime accumulated copy trading PnL. (Tier 2 — Self-reference) |
| 98 | ACC_PnL_Real_Stocks | money | YES | Lifetime accumulated real stock PnL. (Tier 2 — Self-reference) |
| 99 | ACC_PnL_CFD_Stocks | money | YES | Lifetime accumulated CFD stock PnL. (Tier 2 — Self-reference) |
| 100 | ACC_PnL_Real_Crypto | money | YES | Lifetime accumulated settled crypto PnL. (Tier 2 — Self-reference) |
| 101 | ACC_PnL_CFD_Crypto | money | YES | Lifetime accumulated CFD crypto PnL. (Tier 2 — Self-reference) |
| 102 | [ACC_PnL_FX/Comm/Ind] | money | YES | Lifetime accumulated FX/commodity/index PnL. Bracket-quote required. (Tier 2 — Self-reference) |
| 103 | ACC_PnL_Total | money | YES | Lifetime accumulated total PnL across all asset classes. (Tier 2 — Self-reference) |
| 104 | ACC_TotalDeposits | money | YES | Lifetime accumulated total deposits. (Tier 2 — Self-reference) |
| 105 | ACC_CountDeposits | int | YES | Lifetime accumulated deposit transaction count. (Tier 2 — Self-reference) |
| 106 | ACC_TotalCashouts | money | YES | Lifetime accumulated total cashouts. (Tier 2 — Self-reference) |
| 107 | ACC_TotalCoFee | money | YES | Lifetime accumulated copy-out fees. (Tier 2 — Self-reference) |
| 108 | ACC_NetDeposits | money | YES | Lifetime accumulated net deposits (deposits minus cashouts). (Tier 2 — Self-reference) |
| 116 | ACC_WithdrawalToWallet | money | YES | Lifetime accumulated withdrawals to eToro Wallet. (Tier 2 — Self-reference) |
| 164 | A_ACC_Revenue_Currencies | money | YES | Lifetime accumulated revenue from currency CFD instruments. (Tier 2 — Self-reference) |
| 165 | A_ACC_Revenue_Commodities | money | YES | Lifetime accumulated revenue from commodity CFD instruments. (Tier 2 — Self-reference) |
| 166 | A_ACC_Revenue_Crypto | money | YES | Lifetime accumulated revenue from all crypto subtypes. (Tier 2 — Self-reference) |
| 167 | A_ACC_Revenue_Equities | money | YES | Lifetime accumulated revenue from equity instruments. (Tier 2 — Self-reference) |
| 188 | ACC_Revenue_Total_New | decimal(38,2) | YES | Lifetime accumulated Revenue_Total_New (current formula including all fee components). Use this for lifetime revenue analysis from 2025 onward. (Tier 2 — Self-reference) |
| 190 | ACC_Transactional_Revenue_Total | decimal(38,2) | YES | Lifetime accumulated Transactional_Revenue_Total. (Tier 2 — Self-reference) |

### 4.14 LTV (Lifetime Value)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 152 | LTV_1Y | numeric(38,2) | YES | 1-year lifetime value prediction (USD). Inserted as 0 by SP_CID_MonthlyPanel_FullData; updated by SP_LTV_BI_Actual. Will be 0 if LTV SP has not run for this month. (Tier 2 — SP_LTV_BI_Actual) |
| 153 | LTV_3Y | numeric(38,2) | YES | 3-year lifetime value prediction. Same caveats as LTV_1Y. (Tier 2 — SP_LTV_BI_Actual) |
| 154 | LTV_8Y_NoExtreme | numeric(38,2) | YES | 8-year LTV prediction excluding extreme outlier customers. (Tier 2 — SP_LTV_BI_Actual) |
| 155 | LTV_Expected_bySeniority | numeric(38,2) | YES | Expected LTV based on the customer's seniority cohort model. (Tier 2 — SP_LTV_BI_Actual) |
| 156 | NoExtremeLTV_Expected_bySeniority | numeric(38,2) | YES | No-extreme LTV by seniority cohort. Removes outlier customers from the seniority-based expectation. (Tier 2 — SP_LTV_BI_Actual) |
| 157 | LTV_8Y | numeric(38,2) | YES | 8-year lifetime value prediction (full, including extremes). (Tier 2 — SP_LTV_BI_Actual) |

---

## 5. Lineage

See `BI_DB_CID_MonthlyPanel_FullData.lineage.md` for full column-level lineage and source table reference.

```
etoro.Customer / Dictionary    →  DWH_dbo.Dim_* / Fact_*
                               →  BI_DB_DailyCommisionReport
                               →  BI_DB_PositionPnL
                               →  BI_DB_CIDFirstDates
                               →  BI_DB_First5Actions
                               →  BI_DB_CID_DailyCluster
                               →  BI_DB_CID_LifeStageDefinition
                               →  BI_DB_V_DDR_Daily_Panel (CashoutsAdjusted)
    Self-reference (prior M)   →  #History (ACC_ seeds)
    BI_DB_SF_Cases_Panel       →  LastAMLTicketDate [POST-UPDATE]
                               ↓
                  BI_DB_CID_MonthlyPanel_FullData
                               ↓
    SP_LTV_BI_Actual           →  LTV_1Y/3Y/8Y [UPDATE pass]
                               ↓
    SP_CID_DailyPanel_FullData, SP_Cross_Selling_*, SP_UsersEngagement,
    SP_ClubUsersDataRemarketingGoogle, SP_AffiliatePaymentsReport,
    SP_CorpDevDashboard, SP_LTV_Multiplier_Model, Compliance SPs
```

---

## 6. Relationships

### 6.1 Upstream (Direct JOINs in SP_CID_MonthlyPanel_FullData)

| Table | Join Condition | Data Contribution |
|---|---|---|
| DWH_dbo.Fact_SnapshotCustomer | CID = RealCID | EOM equity, club, regulation, funded flags |
| DWH_dbo.Dim_Customer | CID = RealCID | Demographics, channel, affiliate, manager |
| DWH_dbo.Dim_Range (SCD2) | CID, end_date = '9999-01-01' | EOM club/regulation from SCD2 current record |
| DWH_dbo.V_Liabilities | CID | EOM equity/balance breakdown |
| DWH_dbo.Fact_CustomerAction | CID, InstrumentType, month | Monthly activity, trade counts, amounts |
| DWH_dbo.Dim_Mirror | MirrorID | Mirror/add-mirror detection for ActiveOpen_Mirror |
| DWH_dbo.Dim_Country | CountryID | Country attributes (via CountryID FK) |
| BI_DB_dbo.BI_DB_DailyCommisionReport | CID, month | FullCommissions by asset class |
| BI_DB_dbo.BI_DB_PositionPnL | CID, month | PnL by asset class |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID | FTD/reg dates, first deposit amount |
| BI_DB_dbo.BI_DB_First5Actions | CID | First action/instrument |
| BI_DB_dbo.BI_DB_CID_DailyCluster | CID | ClusterDetail |
| BI_DB_dbo.BI_DB_CID_LifeStageDefinition | CID, month | EOM_LSD |
| BI_DB_dbo.BI_DB_V_DDR_Daily_Panel | CID, month | CashoutsAdjusted |
| BI_DB_dbo.BI_DB_SF_Cases_Panel | CID_Last | LastAMLTicketDate |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | CID, prior month | ACC_ accumulation seeds, IsChurn/IsWB base |

### 6.2 Downstream Consumers (Partial List)

| Consumer | Purpose |
|---|---|
| SP_LTV_BI_Actual | Reads revenue/activity features → writes LTV_* back via UPDATE |
| SP_Cross_Selling_Monthly / Daily | Cross-sell analytics by segment |
| SP_UsersEngagement | User engagement KPIs |
| SP_CorpDevDashboard | Corporate development metrics |
| SP_ClubUsersDataRemarketingGoogle | Google Ads Club remarketing audiences |
| SP_AffiliatePaymentsReport | Affiliate commission calculation |
| SP_D_Compliance_Surveillance_KYC_PnL_Monitoring | KYC/PnL compliance monitoring |
| SP_W_Compliance_Vulnerability_Detection | AML vulnerability detection |

---

## 7. Sample Queries

### 7.1 Monthly Active Customer Summary by Club Tier

```sql
SELECT
    EOM_Club,
    COUNT(*)                        AS total_customers,
    SUM(Active)                     AS active_traders,
    SUM(ActiveOpen)                 AS active_open,
    SUM(Revenue_Total_New)          AS total_revenue_new,
    AVG(EOM_Equity)                 AS avg_equity
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData]
WHERE ActiveDate = '2026-04-01'
GROUP BY EOM_Club
ORDER BY AVG(EOM_Equity) DESC;
```

### 7.2 Revenue Breakdown by Component for a Month

```sql
SELECT
    SUM([Revenue_FX/Comm/Ind])      AS fx_commissions,
    SUM(Revenue_Real_Stocks)        AS real_stocks_commissions,
    SUM(Revenue_CFD_Stocks)         AS cfd_stocks_commissions,
    SUM(Revenue_Real_Crypto)        AS real_crypto_commissions,
    SUM(Revenue_CFD_Crypto)         AS cfd_crypto_commissions,
    SUM(Revenue_Copy)               AS copy_commissions,
    SUM(Revenue_IslamicFees)        AS islamic_fees,
    SUM(Revenue_TicketFees)         AS ticket_fees,
    SUM(Revenue_ConversionFees)     AS conversion_fees,
    SUM(Revenue_TicketFeeByPercent) AS ticket_fee_pct,
    SUM(Revenue_Total_New)          AS total_revenue_new,
    SUM(Transactional_Revenue_Total) AS transactional_revenue
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData]
WHERE ActiveDate = '2026-04-01';
```

### 7.3 Churn and Win-Back Analysis

```sql
SELECT
    ActiveDate,
    SUM(IsChurn_ThisM)  AS churned_customers,
    SUM(IsWB_ThisM)     AS winback_customers,
    SUM(IsFunded_New)   AS funded_customers
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData]
WHERE ActiveDate >= '2025-01-01'
GROUP BY ActiveDate
ORDER BY ActiveDate;
```

### 7.4 Customer Monthly Panel with Country Attributes

```sql
SELECT
    m.CID,
    m.ActiveDate,
    m.EOM_Club,
    m.EOM_Regulation,
    m.Revenue_Total_New,
    m.EOM_Equity,
    m.EOM_LSD,
    d.Name      AS CountryName,
    d.Region    AS CountryRegion,
    d.IsHighRiskCountry
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] m
JOIN [DWH_dbo].[Dim_Country] d ON m.CountryID = d.CountryID
WHERE m.ActiveDate = '2026-04-01'
  AND m.Active = 1
  AND m.CountryID > 0;  -- exclude CountryID=0 placeholder
```

### 7.5 Lifetime Revenue for Cohort

```sql
-- Lifetime revenue for customers who first deposited in Jan 2024
SELECT
    m.CID,
    m.FTDdate,
    m.ACC_Revenue_Total_New AS lifetime_revenue,
    m.ACC_PnL_Total         AS lifetime_pnl,
    m.Seniority             AS months_active,
    m.EOM_Club
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] m
WHERE m.ActiveDate = '2026-04-01'  -- latest snapshot
  AND m.FTD_Month = '2024-01'
ORDER BY m.ACC_Revenue_Total_New DESC;
```

---

## 8. Atlassian

| Source | Relevance |
|---|---|
| Confluence DATA space | BI_DB_dbo schema documentation and ETL process descriptions. Search for "CID_MonthlyPanel" or "Monthly Panel". |
| Confluence DATA space | "Business & Regulatory Undertakings Monitoring Platform" — references customer CRM tables including monthly panel for country and regulation filtering. |
| Confluence DATA space | Revenue methodology updates (2025 fee components): AdminFee, TicketFees, ConversionFees, SpotAdjustFee added to Revenue_Total_New by Or Filizer. |
| Jira DATA | Tickets related to Revenue_Total_New formula change (2025), Lev1/LevCFD split introduction, EOM_LSD life-stage definitions, ActiveOpen composite flag update (Or Filizer 2025-01-06). |
