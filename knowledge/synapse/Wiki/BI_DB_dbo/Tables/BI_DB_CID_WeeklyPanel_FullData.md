# BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData

> Weekly per-depositor customer panel — the broadest weekly CRM fact table in BI_DB_dbo. 174 columns covering customer classification, trading activity, revenue, PnL, end-of-week equity, copy trading, cash flow, and accumulated totals. One row per depositor per calendar week. ~5.87M distinct CIDs; date range 2021–present; refreshed daily via DELETE/INSERT on the current week's partition.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL via BI_DB_CID_DailyPanel_FullData (see Section 5) |
| **Refresh** | Daily — DELETE WHERE FirstDayOfWeek = @FirstDayOfWeek + INSERT (SP_CID_WeeklyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (FirstDayOfWeek ASC, CID ASC) |
| **Row Count** | ~5.87M distinct CIDs per weekly slice (April 2026); ~14 distinct weeks in 2026 as of April |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CID_WeeklyPanel_FullData` is the primary **weekly CRM analytics panel** for all eToro depositors — the weekly counterpart to `BI_DB_CID_DailyPanel_FullData` (183 cols, daily grain) and `BI_DB_CID_MonthlyPanel_FullData` (189 cols, monthly grain). For each customer who has ever made a deposit, it provides a per-week summary of their trading activity, financial metrics, acquisition attributes, and accumulated totals.

The table serves as the central input for:
- **Weekly CRM reporting**: Week-over-week Club tier distribution, regulation, activity, and lifecycle segmentation
- **Revenue analytics**: Weekly revenue totals by instrument type, with Islamic/ticket/conversion fee breakdown since 2025
- **PnL tracking**: Customer-side weekly P&L by instrument and leverage tier
- **Activity measurement**: Active, ActiveOpen, ActiveUser flags — any-day-in-week semantics (MAX aggregation)
- **Cash flow analysis**: Weekly deposits, cashouts, withdrawal-to-wallet, and their running totals
- **Copy trading**: Weekly copy open/close/fund flows

**Population boundary**: Only **depositors** are included — customers with any deposit history. Non-depositing registered customers are absent. ~5.87M distinct depositor rows per weekly slice as of April 2026.

**Grain**: One row per CID per calendar week. The week is identified by `FirstDayOfWeek` (Sunday of the target week) and `YearWeekNumber` (e.g., '2026-15'). `SSWeekNumberOfYear` is the SQL Server ISO-style week number for the year.

**Two-source JOIN pattern**: The SP aggregates rows from `BI_DB_CID_DailyPanel_FullData` for the week's date range into two temp tables:
- **`#dailysum`** — weekly SUM/MAX aggregates of flow metrics (trades, revenue, PnL, deposits, copy activity)
- **`#lastdayattributes`** — end-of-week (EOW) snapshot from the **last calendar day of the week** only, capturing classification state (Region, Country, EOW_Club, EOW_Regulation, Equity, EOW_LSD, etc.)

**Instrument taxonomy**: Columns are systematically repeated across 6 asset-class families — same as the DailyPanel:
- **Copy** — mirror-copy positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** provides sub-breakdowns for Real Stocks, CFD Stocks, Real Crypto, CFD Crypto across Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL, and EOW_Equity columns. Lev1 = leverage=1 AND IsBuy=1; LevCFD = leveraged or short.

**ACC_ prefix**: 20 accumulator columns (ACC_Revenue_*, ACC_PnL_*, ACC_TotalDeposits, ACC_CountDeposits, ACC_TotalCashouts, ACC_TotalCoFee, ACC_NetDeposits, ACC_WithdrawalToWallet). In the weekly panel, these are the **SUM of daily ACC_ values** across the week's days — see §2.6 for semantics.

**Column evolution**: The SP has been extended 5 times since 2021. Columns added 2025-01-06 (ActiveOpen_AirDrop/Mirror/Manual/IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, CashoutsAdjusted) and 2025-08-13 (Revenue_TicketFeeByPercent). Historical rows pre-dating these additions will show NULL.

---

## 2. Business Logic

### 2.1 EOW_Club — Weekly Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of week, inherited from `EOD_Club` in the DailyPanel's last day of the week.

**Columns Involved**: `EOW_Club`

**Rules**:
```
EOW_Club =
  WHEN EOW_Equity < 1,000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                          → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                       → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split at the $1,000 equity mark. Observed distribution (Week 15 / 2026-04-05): LowBronze 79.8%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOW_Regulation — Weekly Regulatory Jurisdiction

**What**: Customer's regulatory entity at end of week, inherited from `EOD_Regulation` on the week's last day.

**Columns Involved**: `EOW_Regulation`

**Observed values (Week 15 / 2026)**: CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, FinCEN 1.7%, FSRA 1.5%, ASIC 0.9%, plus MAS, FINRAONLY, NFA, BVI, NYDFS+FINRA, eToroUS (<1%).

### 2.3 Active / ActiveOpen / ActiveUser — Weekly Aggregation

**What**: Activity flags use MAX across the week's days — a customer is Active/ActiveOpen for the week if they were active on ANY day within the week.

**Columns Involved**: `Active`, `ActiveOpen`, `ActiveUser`, `Active_*`, `ActiveOpen_*`

**Rules**:
```
Active (week)      = MAX(Active across all days in week)       → 1 if had any position open/closed on any day
ActiveOpen (week)  = MAX(ActiveOpen across all days in week)   → 1 if opened any new position on any day
ActiveUser (week)  = MAX(ActiveUser across all days in week)   → 1 if logged in on any day
Active_Copy        = MAX(Active_Copy) → 1 if had open copy position on any day
Active_*           = MAX(Active_*) for all asset class flags
ActiveOpen_*       = MAX(ActiveOpen_*) for all asset class flags
```
**Note**: ActiveOpen flag semantics differ from the MonthlyPanel where `Active = closed ≥1 position`. In the Weekly panel, `Active = MAX(daily Active)` where daily Active means "any position open or closed on that day."

### 2.4 Weekly_Classification — Always Empty String

**What**: Customer segment label (e.g., 'Traders', 'Crypto'). Inherited from `Daily_Classification` in the DailyPanel — which is set by a separate SP (`SP_CID_DailyPanel_UpdateCluster`) that is non-operational post-Synapse migration.

**Columns Involved**: `Weekly_Classification`

**Observed values**: Always empty string `''` as of 2025–2026. Historical rows (pre-Synapse migration) may contain values like 'Traders', 'Crypto'. Do not use this column for current segmentation — use `EOW_Club` or `EOW_LSD` instead.

### 2.5 Revenue Taxonomy

**What**: Weekly revenue uses the same two-total structure as the DailyPanel (post-2025 update by Or Filizer).

**Columns Involved**: `Revenue_Total`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Rules** (weekly SUM of daily values):
```
Revenue_Total               = SUM(daily trading commissions + TicketFees + TicketFeeByPercent + 
                                   ConversionFees + IslamicFees) for the week
Transactional_Revenue_Total = Revenue_Total - Islamic fee components (week SUM)
Revenue_IslamicFees         = SUM(daily AdminFee + SpotAdjustFee) for the week — 0 for non-Islamic
Revenue_TicketFees          = SUM(flat per-trade stock ticket fees) for the week
Revenue_ConversionFees      = SUM(deposit/cashout currency conversion fees) for the week
Revenue_TicketFeeByPercent  = SUM(% ticket fees across all asset classes) for the week
```

### 2.6 ACC_ Column Weekly Semantics

**What**: ACC_ columns in the Weekly panel are computed as `SUM(daily_ACC_value)` across all days in the week — NOT a self-referencing running total as in the MonthlyPanel.

**Columns Involved**: `ACC_Revenue_*`, `ACC_PnL_*`, `ACC_TotalDeposits`, `ACC_CountDeposits`, `ACC_TotalCashouts`, `ACC_TotalCoFee`, `ACC_NetDeposits`, `ACC_WithdrawalToWallet`

**Rules**:
```
ACC_Revenue_Total (week) = SUM(daily ACC_Revenue_Total for Mon, Tue, ..., Sun)
                         ≠ weekly Revenue_Total
                         ≠ lifetime ACC_ as of week-end
```
Each daily ACC_Revenue_Total is itself a lifetime running total (prior day + today's revenue). Summing 7 daily lifetime totals produces a value larger than the weekly revenue and not directly comparable to the MonthlyPanel's ACC_ columns.

**Practical implication**: Do NOT compare ACC_ across the DailyPanel, WeeklyPanel, and MonthlyPanel as equivalent lifetime totals. For lifetime revenue as of a given week, look at the DailyPanel row for the last day of the week instead. `ACC_ChurnDays` and `ACC_Transactional_Revenue_Total` are absent from the Weekly panel entirely.

### 2.7 EOW vs Daily Snapshot Attributes

**What**: Demographic and classification attributes are point-in-time from the **last calendar day** of the week (`#lastdayattributes WHERE DateID = @dateID`), not averaged or MAX'd across the week.

**Columns Involved**: `Seniority`, `Seniority_Seg`, `Region`, `Country`, `Channel`, `SubChannel`, `AffiliateID`, `V2_Complete`, `V3_Complete`, `IsPro`, `IsOTD`, `Weekly_Classification`, `EOW_Club`, `EOW_Regulation`, `NewMarketingRegion`, `Equity`, `RealizedEquity`, `AUM`, `Credit`, `EOW_Equity_*`, `EOW_LSD`

**Note on IsReg_ThisD / IsFTD_ThisD**: These are also from the last day of the week (end-of-week snapshot) — they answer "was this customer's registration date or FTD date the last day of this week?" Use `IsReg_ThisW` / `IsFTD_ThisW` (MAX aggregates) for "did this happen during the week?"

---

## 3. Query Advisory

### 3.1 Grain and Filtering
- **One row per CID per calendar week**. Always filter `WHERE FirstDayOfWeek = 'YYYY-MM-DD'` (Sunday of target week) for a single-week slice. The leading CLUSTERED INDEX key is FirstDayOfWeek.
- **FirstDayOfWeek is DATE type**. Use `FirstDayOfWeek = '2026-04-05'` (Sunday) not `= 20260405`.
- **YearWeekNumber format** is `'YYYY-W'` (e.g., '2026-15'). Use FirstDayOfWeek for reliable filtering; YearWeekNumber string comparisons are valid but secondary.
- **Bracket-escape "/" column names**: `[Active_FX/Comm/Ind]`, `[ActiveOpen_FX/Comm/Ind]`, `[NewTrades_FX/Comm/Ind]`, `[AmountIn_NewTrades_FX/Comm/Ind]`, `[Revenue_FX/Comm/Ind]`, `[PnL_FX/Comm/Ind]`, `[ACC_Revenue_FX/Comm/Ind]`, `[ACC_PnL_FX/Comm/Ind]`, `[EOW_Equity_FX/Comm/Ind]`.

### 3.2 Revenue — Which Column to Use
- Use **`Revenue_Total`** for current total revenue analysis (includes all fee components).
- Use **`Transactional_Revenue_Total`** when excluding Islamic swap fees (pure trading activity).
- Revenue_Total in the Weekly panel uses the same composition as DailyPanel (post-2025): commissions + rollover + TicketFees + TicketFeeByPercent + ConversionFees + IslamicFees. **Note**: No `Revenue_Total_New` column exists here (unlike MonthlyPanel). The Weekly `Revenue_Total` already includes all 2025+ fee components.

### 3.3 ACC_ Column Caveats
- Do NOT use ACC_ columns as lifetime totals — they are SUM of daily running totals for the week. For true lifetime figures, join to the DailyPanel row for the week's last day.
- Week-over-week comparison of ACC_ values will show inflated deltas because each ACC_ value already contains the lifetime total repeated 7 times.

### 3.4 Lev1/LevCFD Sub-Tier Columns
- The plain `Active_Real_Stocks`, `Revenue_Real_Stocks`, etc. columns include **both Lev1 and LevCFD** combined.
- `Active_Real_Stocks_Lev1` and `Active_CFD_Stocks_LevCFD` are sub-breakdowns. NULL for pre-2023 rows when the Lev split was not yet tracked.

### 3.5 Weekly_Classification Is Empty
- Do not use `Weekly_Classification` for current segmentation. Use `EOW_Club` (7 tiers) or `EOW_LSD` (17 lifecycle values) instead.

### 3.6 Large Table Query Guidance
- With ~5.87M CIDs × multiple years of weekly data, **always filter on `FirstDayOfWeek`** before adding other predicates. FirstDayOfWeek is the leading CLUSTERED INDEX key.
- HASH(CID) distributed — joins to other HASH(CID) tables (DailyPanel, MonthlyPanel) are co-located.
- Avoid unfiltered aggregations across all weeks. Use a date-bounded WHERE clause.

---

## 4. Data Elements

> 174 columns. Grouped by functional area. EOW = end-of-week snapshot from last day of week. MAX = maximum across all week days. SUM = sum across all week days. NOT NULL columns: CID, Credit, UpdateDate.

### 4A. Identity & Week Grain

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | eToro customer ID (Real CID). Only depositors present. HASH distribution key. FK → DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | YearWeekNumber | varchar(7) | YES | ISO-style week identifier: 'YYYY-W' (e.g., '2026-15'). Grain label for the week. Use FirstDayOfWeek (DATE) for reliable filtering. (Tier 2 — SP: CAST(YEAR(@date), '-', SSWeekNumberOfYear)) |
| 3 | SSWeekNumberOfYear | tinyint | YES | SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear. (Tier 2 — DWH_dbo.Dim_Date) |
| 4 | CalendarYear | smallint | YES | Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear. (Tier 2 — DWH_dbo.Dim_Date) |
| 28 | FirstDayOfWeek | date | YES | Sunday date marking the start of the calendar week. Primary grain column and leading CLUSTERED INDEX key. Always filter on this column for week slices. (Tier 2 — SP: DATEADD(dd, -(DATEPART(dw, @date)-1), @date)) |

### 4B. Registration & Acquisition

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 5 | Seniority | int | YES | Months since customer's first deposit (FTDdate), as of start of the last month of the week. EOW snapshot. 0 = FTD month. (Tier 2 — SP: DATEDIFF(MONTH, FTDdate, month-start-of-@date), via DailyPanel) |
| 6 | Seniority_Seg | varchar(11) | YES | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '12+month'. EOW snapshot. (Tier 2 — SP CASE on DATEDIFF(DAY, FTDdate, @date), via DailyPanel) |
| 22 | Reg_Month | int | YES | YYYYMM of customer registration. MAX across week (no change expected). (Tier 2 — Dim_Customer.RegisteredReal, via DailyPanel) |
| 23 | RegDate | date | YES | Customer registration date. MAX across week. (Tier 2 — Dim_Customer.RegisteredReal, via DailyPanel) |
| 7 | IsReg_ThisD | int | YES | 1 if customer's registration date is the last day of this week (EOW snapshot from @dateID). NOT a weekly flag — use IsReg_ThisW for "registered during this week". (Tier 2 — SP: RegDate = last day of week, via DailyPanel) |
| 8 | IsFTD_ThisD | int | YES | 1 if customer's first deposit date is the last day of this week (EOW snapshot). NOT a weekly flag — use IsFTD_ThisW for "FTD occurred during this week". (Tier 2 — SP: FTDdate = last day of week, via DailyPanel) |
| 24 | IsReg_ThisW | int | YES | 1 if customer registered on any day during this calendar week (MAX of daily IsReg_ThisD). (Tier 2 — SP: MAX(IsReg_ThisD)) |
| 25 | IsFTD_ThisW | int | YES | 1 if customer made their first deposit on any day during this calendar week (MAX of daily IsFTD_ThisD). (Tier 2 — SP: MAX(IsFTD_ThisD)) |
| 26 | FTDdate | date | YES | Customer's first-time deposit date. MAX across week (no change expected). (Tier 2 — BI_DB_CIDFirstDates, via DailyPanel) |
| 27 | FTDA | money | YES | First-time deposit amount (USD). MAX across week (no change expected). (Tier 2 — BI_DB_CIDFirstDates, via DailyPanel) |

### 4C. Customer Attributes & Classification (EOW Snapshot)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Region | nvarchar(500) | YES | Geographic region label at end of week (e.g., 'French', 'UK', 'Arabic GCC', 'Australia', 'North Europe'). EOW snapshot from Dim_Country.Region. (Tier 1 — DWH_dbo.Dim_Country wiki, via DailyPanel) |
| 10 | Country | varchar(500) | YES | Customer's country name at end of week (e.g., 'France', 'United Kingdom'). EOW snapshot from Dim_Country.Name. (Tier 1 — DWH_dbo.Dim_Country wiki, via DailyPanel) |
| 11 | Channel | nvarchar(500) | YES | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Media Performance', 'Mobile Acquisition'). EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.Channel, via DailyPanel) |
| 12 | SubChannel | nvarchar(500) | YES | Acquisition sub-channel detail. EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.SubChannel, via DailyPanel) |
| 13 | AffiliateID | int | YES | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic. EOW snapshot. (Tier 2 — BI_DB_CIDFirstDates.SerialID, via DailyPanel) |
| 14 | V2_Complete | int | YES | 1 if customer has completed verification level 2 as of end of week. EOW snapshot. (Tier 1 — DWH_dbo.Dim_Customer wiki, via DailyPanel) |
| 15 | V3_Complete | int | YES | 1 if customer has completed full KYC (verification level 3) as of end of week. EOW snapshot. (Tier 1 — DWH_dbo.Dim_Customer wiki, via DailyPanel) |
| 16 | IsPro | int | YES | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3). EOW snapshot. (Tier 2 — Fact_SnapshotCustomer.MifidCategorizationID, via DailyPanel) |
| 17 | IsOTD | int | YES | 1 if customer has made exactly one prior deposit (One Trade Done). EOW snapshot. (Tier 2 — Fact_CustomerAction AT=7 count, via DailyPanel) |
| 21 | NewMarketingRegion | varchar(50) | YES | Marketing team region classification (e.g., 'Arabic', 'French', 'UK', 'ROW'). EOW snapshot. More recent vintage than Region. (Tier 2 — Dim_Country.MarketingRegionManualName, via DailyPanel) |
| 18 | Weekly_Classification | varchar(50) | YES | Customer segment label. Always empty string in 2025–2026 — inherited from Daily_Classification which is non-operational post-Synapse migration. See §2.4. Do not use for current analysis. (Tier 4 — SP_CID_DailyPanel_UpdateCluster, non-operational) |
| 19 | EOW_Club | varchar(50) | YES | eToro Club loyalty tier at end of week: 'LowBronze' (equity < $1,000), 'HighBronze' (equity ≥ $1,000, Bronze tier), 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'. EOW snapshot. See §2.1. Observed: LowBronze 79.8%, HighBronze 7.3%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki, via DailyPanel) |
| 20 | EOW_Regulation | varchar(50) | YES | Regulatory jurisdiction at end of week (e.g., 'CySEC', 'FCA', 'FinCEN+FINRA', 'ASIC & GAML', 'FSA Seychelles'). EOW snapshot. See §2.2. 15 distinct values. (Tier 2 — Dim_Regulation.Name via Fact_SnapshotCustomer, via DailyPanel) |
| 164 | EOW_LSD | nvarchar(50) | YES | Life Stage Description at end of week from BI_DB_CID_LifeStageDefinition. 17 possible values (e.g., 'Dump Churn' 37.2%, 'Holder' 19.4%, 'No Activity - Not Funded' 12.1%, 'Active Open Club' 5.3%, 'Active Open' 5.1%, 'New Funded' 0.2%). EOW snapshot. (Tier 2 — BI_DB_CID_LifeStageDefinition.LSD, via DailyPanel) |

### 4D. EOW Financials (End-of-Week Snapshot)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | Equity | decimal(23,4) | YES | Total EOW equity (USD): NWA + liabilities from DWH_dbo.V_Liabilities. Includes open position unrealised PnL. NULL for ~0.2% of rows (no V_Liabilities record). EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities, via DailyPanel) |
| 30 | RealizedEquity | money | YES | Realized equity component (cash + closed positions, excluding open unrealised). EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.RealizedEquity, via DailyPanel) |
| 31 | AUM | money | YES | Assets Under Management: value in copy-trading and portfolio products. EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.AUM, via DailyPanel) |
| 32 | Credit | money | NO | Credit/margin balance (bonus credits, loans). NOT NULL — CASE WHEN NULL THEN 0 applied in SP. EOW snapshot. (Tier 2 — DWH_dbo.V_Liabilities.EOD_Balance, via DailyPanel) |
| 116 | EOW_Equity_Copy | money | YES | EOW equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 119 | EOW_Equity_Real_Stocks | money | YES | EOW equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 120 | EOW_Equity_CFD_Stocks | money | YES | EOW equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 117 | EOW_Equity_Real_Crypto | money | YES | EOW equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 121 | EOW_Equity_CFD_Crypto | money | YES | EOW equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10). EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 123 | EOW_Equity_FX/Comm/Ind | money | YES | EOW equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4). Column name requires bracket quoting. EOW snapshot. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 124 | EOW_Equity_Real_Crypto_Lev1 | money | YES | EOW equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long). EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 125 | EOW_Equity_Real_Stocks_LevCFD | money | YES | EOW equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short). EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 126 | EOW_Equity_CFD_Crypto_Lev1 | money | YES | EOW equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1. EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 127 | EOW_Equity_CFD_Stocks_LevCFD | money | YES | EOW equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0. EOW snapshot. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |

### 4E. Activity Flags (MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | ActiveUser | int | YES | 1 if customer logged in on any day during the week (MAX of daily ActiveUser). (Tier 2 — Fact_CustomerAction AT=14, via DailyPanel) |
| 34 | Active | int | YES | 1 if customer had any position open or closed on any day during the week (MAX of daily Active). (Tier 2 — Dim_Position date range, via DailyPanel) |
| 35 | ActiveOpen | int | YES | 1 if customer opened a new position (manual/mirror, excludes AirDrop) on any day during the week (MAX of daily ActiveOpen). (Tier 2 — SP composite flag, via DailyPanel) |
| 112 | EOW_IsFunded | int | YES | 1 if EOW_Equity ≥ $25 on the last day of the week (original funded threshold). MAX across week. (Tier 2 — SP: EOD_IsFunded ≥ $25 threshold, via DailyPanel) |
| 150 | IsFunded_New | int | YES | 1 if customer has EOW_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < next day (stricter funded definition). MAX across week. (Tier 2 — SP: #NewFundedAccounts, via DailyPanel) |
| 46 | Active_Copy | int | YES | 1 if customer had an open copy position on any day during the week. MAX. (Tier 2 — Dim_Position MirrorID>0, via DailyPanel) |
| 47 | Active_Real_Stocks | int | YES | 1 if customer had an open settled stock position on any day (IsSettled=1, InstrTypeID IN 5,6). MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 48 | Active_CFD_Stocks | int | YES | 1 if customer had an open CFD stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 49 | Active_Real_Crypto | int | YES | 1 if customer had an open settled crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 50 | Active_CFD_Crypto | int | YES | 1 if customer had an open CFD crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 51 | Active_FX/Comm/Ind | int | YES | 1 if customer had an open FX/Comm/Ind position on any day (InstrTypeID IN 1,2,4). Column name requires bracket quoting. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 151 | Active_FX | int | YES | 1 if customer had an open FX (Currencies, InstrTypeID=1) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 152 | Active_Comm | int | YES | 1 if customer had an open Commodities (InstrTypeID=2) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 153 | Active_Ind | int | YES | 1 if customer had an open Indices (InstrTypeID=4) position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 128 | Active_Real_Stocks_Lev1 | tinyint | YES | 1 if customer had an open stock position with Leverage=1 AND IsBuy=1 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 129 | Active_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer had an open stock position with Leverage>1 OR IsBuy=0 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 130 | Active_Real_Crypto_Lev1 | tinyint | YES | 1 if customer had an open crypto position with Leverage=1 AND IsBuy=1 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 131 | Active_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer had an open crypto position with Leverage>1 OR IsBuy=0 on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |

### 4F. ActiveOpen by Instrument (MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 52 | ActiveOpen_Copy | int | YES | 1 if customer opened a copy position (MirrorID>0) on any day. MAX. (Tier 2 — Dim_Position OpenDateID, via DailyPanel) |
| 53 | ActiveOpen_Real_Stocks | int | YES | 1 if customer opened a settled stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 54 | ActiveOpen_CFD_Stocks | int | YES | 1 if customer opened a CFD stock position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 55 | ActiveOpen_Real_Crypto | int | YES | 1 if customer opened a settled crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 56 | ActiveOpen_CFD_Crypto | int | YES | 1 if customer opened a CFD crypto position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 57 | ActiveOpen_FX/Comm/Ind | int | YES | 1 if customer opened a FX/Comm/Ind position on any day. Column name requires bracket quoting. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 154 | ActiveOpen_FX | int | YES | 1 if customer opened a FX position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 155 | ActiveOpen_Comm | int | YES | 1 if customer opened a Commodities position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 156 | ActiveOpen_Ind | int | YES | 1 if customer opened an Indices position on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 167 | ActiveOpen_Manual | int | YES | 1 if customer opened a non-AirDrop, non-copy position (MirrorID=0, IsAirDrop=0) on any day. MAX. (Tier 2 — Dim_Position OpenDateID, via DailyPanel) |
| 168 | ActiveOpen_Mirror | int | YES | 1 if customer started a new copy relationship or added mirror allocation on any day. MAX. (Tier 2 — Dim_Mirror + Fact_CustomerAction AT=15, via DailyPanel) |
| 165 | ActiveOpen_AirDrop | int | YES | 1 if customer received an AirDrop position (IsAirDrop=1) on any day. MAX. (Tier 2 — Dim_Position IsAirDrop=1, via DailyPanel) |
| 169 | ActiveOpen_IncludeCopy | int | YES | 1 if customer opened any position (manual + copy) excluding AirDrop on any day. MAX. (Tier 2 — Dim_Position, via DailyPanel) |
| 132 | ActiveOpen_Real_Stocks_Lev1 | tinyint | YES | 1 if customer opened a Lev1 stock position (Leverage=1, IsBuy=1) on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 133 | ActiveOpen_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer opened a leveraged/short stock position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 134 | ActiveOpen_Real_Crypto_Lev1 | tinyint | YES | 1 if customer opened a Lev1 crypto position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 135 | ActiveOpen_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer opened a leveraged/short crypto position on any day. MAX. (Tier 2 — Dim_Position leverage split, via DailyPanel) |

### 4G. Copy Trading (SUM/MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | IsOpen_Copy | int | YES | 1 if customer opened a new copy relationship on any day (MAX of daily flag). (Tier 2 — Fact_CustomerAction AT=17, via DailyPanel) |
| 37 | Count_Opened_Copy | int | YES | Total number of copy relationships opened during the week (SUM). (Tier 2 — Fact_CustomerAction AT=17 DISTINCT MirrorID, via DailyPanel) |
| 38 | Count_Closed_Copy | int | YES | Total number of copy relationships closed during the week (SUM). (Tier 2 — Fact_CustomerAction AT=18 DISTINCT MirrorID, via DailyPanel) |
| 39 | MoneyIn_Copy | decimal(38,2) | YES | Total funds allocated into copy positions during the week (SUM). (Tier 2 — Fact_CustomerAction AT=17,15, via DailyPanel) |
| 40 | MoneyOut_Copy | decimal(38,2) | YES | Total funds returned from closed copy positions during the week (SUM). (Tier 2 — Fact_CustomerAction AT=18,16, via DailyPanel) |
| 41 | IsOpen_CopyPortfolio | int | YES | 1 if customer opened a CopyPortfolio on any day (MAX). (Tier 2 — Fact_CustomerAction AT=17 portfolio mode, via DailyPanel) |
| 42 | Count_Opened_CopyPortfolio | int | YES | Total CopyPortfolio relationships opened during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |
| 43 | Count_Closed_CopyPortfolio | int | YES | Total CopyPortfolio relationships closed during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |
| 44 | MoneyIn_CopyPortfolio | decimal(38,2) | YES | Total funds into CopyPortfolio positions during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |
| 45 | MoneyOut_CopyPortfolio | decimal(38,2) | YES | Total funds returned from CopyPortfolio positions during the week (SUM). (Tier 2 — Fact_CustomerAction portfolio mode, via DailyPanel) |

### 4H. New Trades & Amount In (SUM across week)

> `NewTrades_*` = total count of positions opened during the week (IsPartialCloseChild=0). `AmountIn_NewTrades_*` = total USD invested in those positions. Repeated for Copy, Real_Stocks, CFD_Stocks, Real_Crypto, CFD_Crypto, FX/Comm/Ind, plus Lev1/LevCFD variants and _Total.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 58 | NewTrades_Copy | int | YES | Total copy positions opened during the week. SUM. (Tier 2 — Dim_Position OpenDateID, MirrorID>0, via DailyPanel) |
| 59 | NewTrades_Real_Stocks | int | YES | Total settled stock positions opened during the week. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 60 | NewTrades_CFD_Stocks | int | YES | Total CFD stock positions opened during the week. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 61 | NewTrades_Real_Crypto | int | YES | Total settled crypto positions opened during the week. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 62 | NewTrades_CFD_Crypto | int | YES | Total CFD crypto positions opened during the week. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 63 | NewTrades_FX/Comm/Ind | int | YES | Total FX/Comm/Ind positions opened during the week. Bracket quoting required. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 64 | NewTrades_Total | int | YES | Total positions opened across all instrument types during the week. SUM. (Tier 2 — SP: SUM of all NewTrades_*, via DailyPanel) |
| 65 | AmountIn_NewTrades_Copy | money | YES | Total USD invested in new copy positions during the week. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 66 | AmountIn_NewTrades_Real_Stocks | money | YES | Total USD in new settled stock positions during the week. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 67 | AmountIn_NewTrades_CFD_Stocks | money | YES | Total USD in new CFD stock positions during the week. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 68 | AmountIn_NewTrades_Real_Crypto | money | YES | Total USD in new settled crypto positions during the week. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 69 | AmountIn_NewTrades_CFD_Crypto | money | YES | Total USD in new CFD crypto positions during the week. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 70 | AmountIn_NewTrades_FX/Comm/Ind | money | YES | Total USD in new FX/Comm/Ind positions during the week. Bracket quoting required. SUM. (Tier 2 — Dim_Position Amount, via DailyPanel) |
| 71 | AmountIn_NewTrades_Total | money | YES | Total USD invested in all new positions during the week. SUM. (Tier 2 — SP: SUM of all AmountIn_NewTrades_*, via DailyPanel) |
| 136 | NewTrades_Real_Stocks_Lev1 | int | YES | Total Lev1 stock positions opened (Leverage=1, IsBuy=1). SUM. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 137 | NewTrades_CFD_Stocks_LevCFD | int | YES | Total leveraged/short stock positions opened. SUM. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 138 | NewTrades_Real_Crypto_Lev1 | int | YES | Total Lev1 crypto positions opened. SUM. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 139 | NewTrades_CFD_Crypto_LevCFD | int | YES | Total leveraged/short crypto positions opened. SUM. (Tier 2 — Dim_Position leverage split, via DailyPanel) |
| 140 | AmountIn_NewTrades_Real_Stocks_Lev1 | money | YES | Total USD in new Lev1 stock positions. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 141 | AmountIn_NewTrades_CFD_Stocks_LevCFD | money | YES | Total USD in new leveraged/short stock positions. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 142 | AmountIn_NewTrades_Real_Crypto_Lev1 | money | YES | Total USD in new Lev1 crypto positions. SUM. (Tier 2 — Dim_Position, via DailyPanel) |
| 143 | AmountIn_NewTrades_CFD_Crypto_LevCFD | money | YES | Total USD in new leveraged/short crypto positions. SUM. (Tier 2 — Dim_Position, via DailyPanel) |

### 4I. Weekly Revenue (SUM across week)

> Revenue = trading commissions (FullCommissions + RollOverFee) + fee components. All are weekly sums. Asset-class decomposition mirrors DailyPanel §3I.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 72 | Revenue_Copy | decimal(38,2) | YES | Weekly revenue from copy positions (commissions + RollOverFee + TicketFeeByPercent_Copy). SUM. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent, via DailyPanel) |
| 73 | Revenue_Real_Stocks | decimal(38,2) | YES | Weekly revenue from settled stock positions + flat ticket fees. SUM. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFee, via DailyPanel) |
| 74 | Revenue_CFD_Stocks | decimal(38,2) | YES | Weekly revenue from CFD stock positions + ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent, via DailyPanel) |
| 75 | Revenue_Real_Crypto | decimal(38,2) | YES | Weekly revenue from settled crypto positions + ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent, via DailyPanel) |
| 76 | Revenue_CFD_Crypto | decimal(38,2) | YES | Weekly revenue from CFD crypto positions + ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent, via DailyPanel) |
| 77 | Revenue_FX/Comm/Ind | decimal(38,2) | YES | Weekly revenue from FX/Comm/Ind positions. Bracket quoting required. SUM. (Tier 2 — BI_DB_DailyCommisionReport, via DailyPanel) |
| 78 | Revenue_Total | decimal(38,2) | YES | Total weekly revenue across all instruments and fee types (commissions + rollover + ticket + conversion + Islamic fees). SUM. See §2.5. (Tier 2 — SP: SUM of all revenue components, via DailyPanel) |
| 157 | Revenue_FX | decimal(38,2) | YES | Weekly revenue from FX (Currencies) positions + Currencies CFD ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport, via DailyPanel) |
| 158 | Revenue_Comm | decimal(38,2) | YES | Weekly revenue from Commodities positions + Commodities CFD ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport, via DailyPanel) |
| 159 | Revenue_Ind | decimal(38,2) | YES | Weekly revenue from Indices positions + Indices CFD ticket fee by percent. SUM. (Tier 2 — BI_DB_DailyCommisionReport, via DailyPanel) |
| 170 | Revenue_IslamicFees | decimal(38,2) | YES | Weekly Islamic account fees: AdminFee + SpotAdjustFee. 0 for non-Islamic accounts. Added 2025-01-06. SUM. (Tier 2 — Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee, via DailyPanel) |
| 171 | Revenue_TicketFees | decimal(38,2) | YES | Weekly flat per-trade ticket fees on stock trades. Added 2025-01-06. SUM. (Tier 2 — Function_Revenue_TicketFee, via DailyPanel) |
| 172 | Revenue_ConversionFees | decimal(38,2) | YES | Weekly currency conversion fees on deposits/cashouts. Added 2025-01-06. SUM. (Tier 2 — Function_Revenue_ConversionFee, via DailyPanel) |
| 174 | Revenue_TicketFeeByPercent | decimal(38,2) | YES | Weekly percentage-based ticket fees across all instrument types and copy. Added 2025-08-13. SUM. (Tier 2 — Function_Revenue_TicketFeeByPercent, via DailyPanel) |
| 173 | Transactional_Revenue_Total | decimal(38,2) | YES | Revenue_Total minus Islamic fees — pure transaction-driven revenue. See §2.5. Added 2025-01-06. SUM. (Tier 2 — SP: Revenue_Total minus Islamic components, via DailyPanel) |
| 144 | Revenue_Real_Stocks_Lev1 | money | YES | Weekly revenue from Lev1 stock positions + flat ticket fees. SUM. (Tier 2 — BI_DB_DailyCommisionReport leverage split, via DailyPanel) |
| 145 | Revenue_CFD_Stocks_LevCFD | money | YES | Weekly revenue from leveraged/short stock positions. SUM. (Tier 2 — BI_DB_DailyCommisionReport leverage split, via DailyPanel) |
| 146 | Revenue_Real_Crypto_Lev1 | money | YES | Weekly revenue from Lev1 crypto positions. SUM. (Tier 2 — BI_DB_DailyCommisionReport leverage split, via DailyPanel) |
| 147 | Revenue_CFD_Crypto_LevCFD | money | YES | Weekly revenue from leveraged/short crypto positions. SUM. (Tier 2 — BI_DB_DailyCommisionReport leverage split, via DailyPanel) |

### 4J. Weekly PnL — Customer-Side (SUM across week)

> Customer profit & loss on positions during the week (opened, closed, or carried). Asset-class decomposition mirrors DailyPanel §3J.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 79 | PnL_Copy | decimal(38,4) | YES | Weekly customer-side PnL on copy positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 80 | PnL_Real_Stocks | decimal(38,4) | YES | Weekly customer-side PnL on settled stock positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 81 | PnL_CFD_Stocks | decimal(38,4) | YES | Weekly customer-side PnL on CFD stock positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 82 | PnL_Real_Crypto | decimal(38,4) | YES | Weekly customer-side PnL on settled crypto positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 83 | PnL_CFD_Crypto | decimal(38,4) | YES | Weekly customer-side PnL on CFD crypto positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 84 | PnL_FX/Comm/Ind | decimal(38,4) | YES | Weekly customer-side PnL on FX/Comm/Ind positions. Bracket quoting required. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 85 | PnL_Total | decimal(38,4) | YES | Total weekly customer-side PnL across all instruments. SUM. (Tier 2 — SP: SUM of all PnL_*, via DailyPanel) |
| 160 | PnL_FX | decimal(38,2) | YES | Weekly PnL on FX positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 161 | PnL_Comm | decimal(38,2) | YES | Weekly PnL on Commodities positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 162 | PnL_Ind | decimal(38,2) | YES | Weekly PnL on Indices positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 148 | PnL_Real_Stocks_Lev1 | money | YES | Weekly PnL on Lev1 stock positions. SUM. (Tier 2 — BI_DB_PositionPnL leverage split, via DailyPanel) |
| 149 | PnL_CFD_Stocks_LevCFD | money | YES | Weekly PnL on leveraged/short stock positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 150 | PnL_Real_Crypto_Lev1 | money | YES | Weekly PnL on Lev1 crypto positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |
| 151 | PnL_CFD_Crypto_LevCFD | money | YES | Weekly PnL on leveraged/short crypto positions. SUM. (Tier 2 — BI_DB_PositionPnL, via DailyPanel) |

### 4K. Weekly Cash Flow (SUM across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | TotalDeposits | decimal(38,2) | YES | Total deposit amount (USD) during the week (Fact_CustomerAction ActionTypeID=7). SUM. (Tier 2 — Fact_CustomerAction AT=7, via DailyPanel) |
| 87 | CountDeposits | int | YES | Number of deposits during the week. SUM. (Tier 2 — Fact_CustomerAction AT=7 COUNT, via DailyPanel) |
| 88 | TotalCashouts | decimal(38,2) | YES | Total cashout amount (USD) during the week (ActionTypeID=8). SUM. (Tier 2 — Fact_CustomerAction AT=8, via DailyPanel) |
| 89 | TotalCoFee | money | YES | Copy-out fee charged on copy position closures during the week (ActionTypeID=30). SUM. (Tier 2 — Fact_CustomerAction AT=30 Commission, via DailyPanel) |
| 90 | NetDeposits | decimal(38,2) | YES | TotalDeposits minus TotalCashouts for the week. SUM. (Tier 2 — SP: TotalDeposits - TotalCashouts, via DailyPanel) |
| 111 | WithdrawalToWallet | decimal(38,2) | YES | Cashout amount directed to eToro Money wallet (FundingTypeID=27) during the week. SUM. (Tier 2 — Fact_CustomerAction AT=8 FundingTypeID=27, via DailyPanel) |
| 174 | CashoutsAdjusted | decimal(38,2) | YES | Adjusted cashout: TPCashoutsOldDef - CashoutAdjustment - TransferCoins. DDR/finance normalised cashout. Added 2025-01-06. SUM. (Tier 2 — BI_DB_V_DDR_Daily_Panel, via DailyPanel) |

### 4L. Accumulated Columns (SUM of daily running totals)

> ACC_ columns = SUM of daily ACC_ values across all days in the week. Each daily ACC_ value is itself a lifetime running total. See §2.6 for usage caveats — do NOT interpret as weekly revenue/PnL or as a lifetime total.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 91 | ACC_Revenue_Copy | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (copy) for this week's days. See §2.6. (Tier 2 — SP: SUM(daily ACC_Revenue_Copy), via DailyPanel) |
| 92 | ACC_Revenue_Real_Stocks | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (settled stocks) for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 93 | ACC_Revenue_CFD_Stocks | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (CFD stocks). (Tier 2 — SP: SUM, via DailyPanel) |
| 94 | ACC_Revenue_Real_Crypto | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (settled crypto). (Tier 2 — SP: SUM, via DailyPanel) |
| 95 | ACC_Revenue_CFD_Crypto | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (CFD crypto). (Tier 2 — SP: SUM, via DailyPanel) |
| 96 | ACC_Revenue_FX/Comm/Ind | decimal(38,2) | YES | Sum of daily lifetime revenue accumulators (FX/Comm/Ind). Bracket quoting required. (Tier 2 — SP: SUM, via DailyPanel) |
| 97 | ACC_Revenue_Total | decimal(38,2) | YES | Sum of daily total lifetime revenue accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 98 | ACC_PnL_Copy | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (copy) for this week's days. (Tier 2 — SP: SUM, via DailyPanel) |
| 99 | ACC_PnL_Real_Stocks | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (settled stocks). (Tier 2 — SP: SUM, via DailyPanel) |
| 100 | ACC_PnL_CFD_Stocks | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (CFD stocks). (Tier 2 — SP: SUM, via DailyPanel) |
| 101 | ACC_PnL_Real_Crypto | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (settled crypto). (Tier 2 — SP: SUM, via DailyPanel) |
| 102 | ACC_PnL_CFD_Crypto | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (CFD crypto). (Tier 2 — SP: SUM, via DailyPanel) |
| 103 | ACC_PnL_FX/Comm/Ind | decimal(38,4) | YES | Sum of daily lifetime PnL accumulators (FX/Comm/Ind). Bracket quoting required. (Tier 2 — SP: SUM, via DailyPanel) |
| 104 | ACC_PnL_Total | decimal(38,4) | YES | Sum of daily total lifetime PnL accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 105 | ACC_TotalDeposits | decimal(38,2) | YES | Sum of daily lifetime deposit accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 106 | ACC_CountDeposits | int | YES | Sum of daily lifetime deposit-count accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 107 | ACC_TotalCashouts | decimal(38,2) | YES | Sum of daily lifetime cashout accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 108 | ACC_TotalCoFee | money | YES | Sum of daily lifetime copy-out fee accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 109 | ACC_NetDeposits | decimal(38,2) | YES | Sum of daily lifetime net-deposit accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |
| 112 | ACC_WithdrawalToWallet | decimal(38,2) | YES | Sum of daily lifetime withdrawal-to-wallet accumulators for this week. (Tier 2 — SP: SUM, via DailyPanel) |

### 4M. Date Milestones (MAX across week)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 113 | LastApplicationProAccountDate | date | YES | Most recent professional account application date as of end of week; '1900-01-01' sentinel if never applied. MAX. (Tier 2 — External_BI_OUTPUT_Customer_ProfessionalCustomers.ApplicationDate, via DailyPanel) |
| 114 | LastPosOpenDate | date | YES | Most recent date customer opened a position (any instrument) during or before this week. MAX. (Tier 2 — Fact_CustomerAction AT=1,2, via DailyPanel) |
| 115 | LastLoggedIn | date | YES | Most recent login date during or before this week. MAX. (Tier 2 — Fact_CustomerAction AT=14, via DailyPanel) |

### 4N. ETL Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 163 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at SP execution time. Refreshed daily during the current open week. (Tier 2 — SP: GETDATE()) |

---

## 5. ETL Pipeline

```
[Production Sources — via BI_DB_CID_DailyPanel_FullData]
  DWH_dbo.V_Liabilities ──────────────── EOW equity/AUM/credit
  DWH_dbo.Fact_SnapshotCustomer ──────── Population + Club + Regulation
  DWH_dbo.Dim_Position + BI_DB_PositionPnL ─ Position PnL & equity by type
  DWH_dbo.Fact_CustomerAction ────────── Cash flows + Copy + Login
  DWH_dbo.Dim_Customer, Dim_Country ──── Demographics + acquisition
  DWH_dbo.Dim_PlayerLevel ─────────────── Club tier name
  BI_DB_DailyCommisionReport ──────────── Revenue base
  BI_DB_CIDFirstDates ─────────────────── Channel + FTD dates
  BI_DB_CID_LifeStageDefinition ───────── EOW_LSD
  BI_DB_PositionPnL ───────────────────── EOW equity by instrument
  BI_DB_V_DDR_Daily_Panel ─────────────── CashoutsAdjusted
  External_BI_OUTPUT_Customer_ProfessionalCustomers ── Pro dates
  Revenue functions ────────────────────── Fee components

        │
        ▼
  SP_CID_DailyPanel_FullData (@date)
  [Priority 0, SB_Daily]
        │
        ▼
  BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(DateID)]

  ┌─ DWH_dbo.Dim_Date ─── Week boundaries
  │
  ▼
  SP_CID_WeeklyPanel_FullData (@date)
  [Priority 0, SB_Daily — OpsDB dependency: SP_CID_DailyPanel_FullData]

    ┌── #weeklydays ─── DateKeys for Mon–Sun of target week
    ├── #dailydata ──── DailyPanel rows for week's DateIDs (HASH(CID) temp)
    ├── #dailysum ───── GROUP BY CID: SUM/MAX aggregates for the week
    └── #lastdayattributes — EOW snapshot WHERE DateID = last day of week

    DELETE WHERE FirstDayOfWeek = @FirstDayOfWeek
    INSERT (#dailysum ds LEFT JOIN #lastdayattributes lda ON ds.CID = lda.CID)

        │
        ▼
  BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(FirstDayOfWeek ASC, CID ASC)]
```

---

## 6. Data Quality

| Check | Observation |
|---|---|
| **Row count** | ~5.87M distinct CIDs per weekly slice (Week 15 / 2026-04-05, consistent with DailyPanel) |
| **Date coverage** | 2026-01-04 to 2026-04-05 confirmed in 2026; SP created 2021-06-29, full historical range not live-verified |
| **UpdateDate pattern** | 2026-04-12 for Week 15 (2026-04-05 to 2026-04-11): weekly batch runs with ~7-day lag after week end, or same-week daily refresh during current open week |
| **NULL Equity** | ~0.2% of rows expected (inherited from DailyPanel NULL V_Liabilities pattern) — observable in sample (CIDs 47551421, 47556565 show NULL Equity in Week 15) |
| **Weekly_Classification** | Always empty string — same as DailyPanel Daily_Classification non-operational state post-Synapse migration |
| **ACC_ column semantics** | SUM of daily running totals — NOT weekly incremental revenue/PnL, NOT lifetime-as-of-week-end. Values will be significantly larger than weekly Revenue_Total |
| **Credit NOT NULL** | 3 NOT NULL columns: CID, Credit, UpdateDate. Credit applies CASE WHEN NULL THEN 0 in SP |
| **Revenue NULLs** | ISNULL defaulted to 0 in source DailyPanel — zero NULL expected for Revenue_Total, PnL_Total after SUM |
| **Lev1/LevCFD columns** | NULL for pre-2023 periods (tinyint type for Active/ActiveOpen Lev variants; int for NewTrades/AmountIn/Revenue/PnL) |
| **Revenue_TicketFeeByPercent** | Added 2025-08-13; NULL for rows before that date |
| **IsReg_ThisD / IsFTD_ThisD** | EOW last-day snapshot only (not MAX across week) — use IsReg_ThisW / IsFTD_ThisW for any-day-in-week semantics |

---

## 7. Usage Notes

- **Filter by FirstDayOfWeek**: This is the leading CLUSTERED INDEX key. Always add `WHERE FirstDayOfWeek = 'YYYY-MM-DD'` (Sunday date) for week slices. Do NOT filter on YearWeekNumber alone — string comparisons may have edge cases.
- **Weekly_Classification is empty**: Do not use for segmentation. Use `EOW_Club` (7 tiers with live distribution) or `EOW_LSD` (17 lifecycle labels) instead.
- **ACC_ are not lifetime totals here**: For true lifetime revenue/PnL as of a given week, join the DailyPanel for the last day of the week: `WHERE DateID = CONVERT(CHAR(8), @LastDayOfWeek, 112)`.
- **Revenue_Total scope**: The Weekly panel has only one revenue total column (unlike MonthlyPanel which has both `Revenue_Total` and `Revenue_Total_New`). Weekly `Revenue_Total` includes all 2025+ fee components and is equivalent to the DailyPanel's `Revenue_Total`.
- **IsReg_ThisD / IsFTD_ThisD vs IsReg_ThisW / IsFTD_ThisW**: The `*_ThisD` variants are point-in-time from the last day of the week, not weekly flags. Use `*_ThisW` for "event occurred during the week."
- **Equity NULL rows**: ~0.2% of rows have NULL Equity (no V_Liabilities record). Treat as 0 in aggregations.
- **Performance**: HASH(CID) distributed. Joins to other HASH(CID) tables (DailyPanel, MonthlyPanel) are co-located — no data movement. Avoid cross-week full scans; always filter on FirstDayOfWeek.
- **Missing DailyPanel columns**: AccountManager, IsIslamic, IsContacted, IsContactedAmount, ACC_ChurnDays, FirstNewFundedDate, Active_Month/ActiveDate/FTD_Month, FirstAction/FirstInstrument are not present in the WeeklyPanel.

---

## 8. Related Objects

| Object | Schema | Relationship |
|---|---|---|
| `SP_CID_WeeklyPanel_FullData` | BI_DB_dbo | Writer SP — generates all rows for a given week |
| `BI_DB_CID_DailyPanel_FullData` | BI_DB_dbo | Primary source — all 174 columns derived from daily rows |
| `BI_DB_CID_MonthlyPanel_FullData` | BI_DB_dbo | Monthly rollup sibling (same depositor population) |
| `BI_DB_CID_DailyPanel_Club` | BI_DB_dbo | Club-eligible customers only sibling |
| `DWH_dbo.Dim_Date` | DWH_dbo | Week boundary calculation (SSWeekNumberOfYear, FirstDayOfWeek) |
| `DWH_dbo.V_Liabilities` | DWH_dbo | EOW equity/AUM/credit source (via DailyPanel) |
| `BI_DB_CIDFirstDates` | BI_DB_dbo | Channel, FTD, FTDA source |
| `BI_DB_CID_LifeStageDefinition` | BI_DB_dbo | EOW_LSD source |
| `BI_DB_DailyCommisionReport` | BI_DB_dbo | Revenue base |

---

## 9. Change History

| Date | Author | Change |
|---|---|---|
| 2021-06-29 | Dan Iliescu | Original SP — weekly panel based on DailyPanel FullData |
| 2021-07-12 | Dan | Removed SSWeekNumberOfMonth + CalendarYearMonth columns |
| 2024-03-26 | Or Filizer | Add Lifestage Column (note: applied to DailyPanel; WeeklyPanel DDL/SP does not include EOW_Lifestage — only EOW_LSD via passthrough) |
| 2025-01-06 | Or Filizer | Added ActiveOpen_IncludeCopy, ActiveOpen_Manual, ActiveOpen_Mirror, ActiveOpen_AirDrop; added Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees; added CashoutsAdjusted, Transactional_Revenue_Total |
| 2025-08-13 | Or Filizer | Added Revenue_TicketFeeByPercent |
