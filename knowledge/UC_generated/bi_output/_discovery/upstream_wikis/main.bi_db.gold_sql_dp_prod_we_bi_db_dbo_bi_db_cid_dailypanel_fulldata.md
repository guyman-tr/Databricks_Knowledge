# BI_DB_dbo.BI_DB_CID_DailyPanel_FullData

> Daily per-depositor customer panel — the broadest customer panel in BI_DB_dbo, covering all eToro depositors with 183 columns of daily activity, revenue, PnL, equity, copy trading, running accumulators, and demographic attributes. One row per depositor per day. 64.5M rows per daily date as of April 2026; data from 2018-01-01 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL (see Section 4) |
| **Refresh** | Daily — DELETE WHERE DateID = @startDateINT + INSERT (SP_CID_DailyPanel_FullData, SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Partition** | RANGE LEFT on DateID, daily partitions 20180101–20260531 |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_DailyPanel_FullData is the primary daily CRM analytics panel for **all eToro depositors** — the broadest customer-level table in BI_DB_dbo. For each customer who has ever made a deposit (IsDepositor=1 in Fact_SnapshotCustomer), it provides a daily snapshot of their activity, financial metrics, trading behavior, acquisition attributes, and accumulated lifetime totals.

The table serves as the foundation for:
- **CRM reporting**: Customer segmentation, Club tier distribution, regulation analysis, activity funnels
- **Revenue analytics**: Daily and lifetime revenue by instrument type, with Islamic/ticket/conversion fee breakdown since 2025
- **PnL tracking**: Customer-side daily and lifetime P&L by instrument
- **Activity measurement**: Active, ActiveOpen, ActiveUser flags; Copy trading flows; new trades by type
- **Cashflow analysis**: Daily deposits, cashouts, and their lifetime accumulators

**Population boundary**: Only **depositors** are included — customers with `IsDepositor=1` at the snapshot date. Non-depositing registered customers are absent. ~5.9M distinct depositor rows per day as of April 2026.

**Instrument taxonomy**: Columns are systematically repeated across 6 asset class families:
- **Copy** — mirror-copy positions (MirrorID > 0)
- **Real Stocks** — settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6)
- **CFD Stocks** — leveraged stock/ETF CFDs (IsSettled=0)
- **Real Crypto** — settled crypto (InstrumentTypeID=10, IsSettled=1)
- **CFD Crypto** — leveraged crypto CFDs
- **FX/Comm/Ind** — forex, commodities, indices (InstrumentTypeID IN 1,2,4)

A secondary **Lev1/LevCFD split** duplicates Active, ActiveOpen, NewTrades, AmountIn, Revenue, PnL, and EOD_Equity columns: Lev1 = leverage=1 AND IsBuy=1 (long unlevered position); LevCFD = leveraged or short position. These mirror the IsSettled split for stocks and crypto, using a leverage-based test instead of the settled flag.

**ACC_ prefix**: 14 cumulative columns accumulate lifetime totals from first deposit date by reading the previous day's row and adding today's increment. On a customer's first day in the table, ACC_ initialises from the day's values.

**Column evolution**: The SP has been extended 8 times since 2020. Columns 168–183 (FirstNewFundedDate, ACC_ChurnDays, EOD_LSD, ActiveOpen_AirDrop/Mirror/Manual/IncludeCopy, Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, CashoutsAdjusted, Transactional_Revenue_Total, ACC_Transactional_Revenue_Total, Revenue_TicketFeeByPercent) were added 2021–2025. Historical rows pre-dating the column additions will show NULL for these columns.

**Daily_Classification** (EOD_Segment): This column is assigned by a separate SP (`SP_CID_DailyPanel_UpdateCluster`) that runs after the main insert. As of April 2026 all rows contain an empty string — the cluster assignment appears to be no longer operational post-Synapse migration. Historical 2018–2020 rows contain values like "Traders", "Crypto", etc.

---

## 2. Business Logic

### 2.1 EOD_Club — Loyalty Tier

**What**: Customer's eToro Club loyalty tier at end of day, based on `Dim_PlayerLevel` with a custom LowBronze/HighBronze split.

**Columns Involved**: `EOD_Club`

**Rules**:
```
EOD_Club =
  WHEN EOD_Equity < 1000 AND Dim_PlayerLevel.PlayerLevelID = 1  → 'LowBronze'
  WHEN Dim_PlayerLevel.PlayerLevelID = 1                         → 'HighBronze'
  ELSE Dim_PlayerLevel.Name                                      → 'Silver'/'Gold'/'Platinum'/'Platinum Plus'/'Diamond'
```
Bronze (PlayerLevelID=1) is split into two ranges at the $1,000 equity mark. Silver through Diamond use the Dim_PlayerLevel.Name directly. Observed distribution (April 2026): LowBronze 79.8%, HighBronze 7.2%, Silver 4.9%, Gold 4.4%, Platinum 2.1%, Platinum Plus 1.5%, Diamond 0.2%.

### 2.2 EOD_Regulation

**What**: Customer's regulatory jurisdiction at end of day.

**Columns Involved**: `EOD_Regulation`

**Rules**: Read from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID`. Observed distribution (April 2026): CySEC 56.5%, FCA 24.2%, FinCEN+FINRA 5.6%, ASIC & GAML 5.3%, FSA Seychelles 4.2%, others < 2%.

### 2.3 ActiveOpen — Position Opened Today

**What**: Flag: customer opened at least one trading position on this date (manual, mirror, or mirror-add; excludes AirDrop positions).

**Columns Involved**: `ActiveOpen`, `ActiveOpen_Manual`, `ActiveOpen_Mirror`

**Rules**:
```
ActiveOpen = 1 IF (ActiveOpen_Manual=1) OR (ActiveOpen_NewMirror=1) OR (ActiveOpen_AddMirror=1)
ActiveOpen_Manual  = has a position opened today with MirrorID=0 AND IsAirDrop=0
ActiveOpen_Mirror  = opened a new DWH_dbo.Dim_Mirror row today (MirrorTypeID IN 1,4)
                     OR added mirror allocation today (Fact_CustomerAction ActionTypeID=15)
ActiveOpen_AirDrop = has a position opened today where IsAirDrop=1
ActiveOpen_IncludeCopy = manual + copy combined, excludes only AirDrop
```

### 2.4 Active vs ActiveOpen vs ActiveUser

| Column | Meaning | Source |
|---|---|---|
| `Active` | Any position held or closed on this date (any instrument) | Dim_Position, any row in date range |
| `ActiveOpen` | Opened a new position today (manual/mirror) | Dim_Position WHERE OpenDateID = today |
| `ActiveUser` | Logged in today | Fact_CustomerAction ActionTypeID=14 |

### 2.5 ACC_ Running Totals

**What**: Columns prefixed `ACC_` are lifetime running totals, accumulating from first deposit date.

**Columns Involved**: `ACC_Revenue_*`, `ACC_PnL_*`, `ACC_TotalDeposits`, `ACC_CountDeposits`, `ACC_TotalCashouts`, `ACC_TotalCoFee`, `ACC_NetDeposits`, `ACC_WithdrawalToWallet`, `ACC_Transactional_Revenue_Total`

**Rules**:
```
ACC_Revenue_X (today) = Revenue_X (today) + ACC_Revenue_X (yesterday)
ACC_TotalDeposits     = TotalDeposits + ACC_TotalDeposits (yesterday)
ACC_ChurnDays         = IF @date <= FirstNewFundedDate OR IsFunded_New=1 THEN 0
                        ELSE 1 + ACC_ChurnDays (yesterday)
```
Yesterday's row is read from `BI_DB_CID_DailyPanel_FullData WHERE DateID = @EndPreviousDINT`. First-day customers start with the day's values (no prior row → NULL from #History, treated as 0 via ISNULL).

### 2.6 Revenue_Total vs Transactional_Revenue_Total

**What**: Two revenue aggregate columns with different scope.

**Columns Involved**: `Revenue_Total`, `Transactional_Revenue_Total`, `Revenue_IslamicFees`, `Revenue_TicketFees`, `Revenue_ConversionFees`, `Revenue_TicketFeeByPercent`

**Rules**:
```
Revenue_Total = Trading commissions (FullCommissions + RollOverFee, all instruments)
              + Revenue_TicketFees (stock ticket fee, flat)
              + Revenue_TicketFeeByPercent components (crypto/stock/FX/copy by %)
              + Revenue_ConversionFees (FX conversion on deposits/cashouts)
              + Revenue_IslamicFees (AdminFee + SpotAdjustFee — swap-free accounts only)

Transactional_Revenue_Total = Revenue_Total MINUS Revenue_IslamicFees
                             (i.e., the pure transaction-driven portion, excludes Islamic swap fees)
```
`Revenue_IslamicFees` = AdminFee + SpotAdjustFee from Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee. Only non-zero for accounts with WeekendFeePrecentage=0 (Islamic/swap-free).

### 2.7 Seniority and Seniority_Seg

**What**: Customer's age as a depositor, measured from first deposit date.

**Columns Involved**: `Seniority`, `Seniority_Seg`

**Rules**:
```
Seniority     = DATEDIFF(MONTH, FTDdate, start-of-month of @date)  [integer months]
Seniority_Seg = '<1month' | '1-2month' | '<2-3month' | ... | '12+month'
```
Segmentation uses day-difference thresholds (30/60/90...360 days), not month subtraction.

### 2.8 IsOTD — One Trade Done

**What**: Flag indicating the customer has made exactly 1 prior deposit (ActionTypeID=7) before today.

**Columns Involved**: `IsOTD`

**Rules**: `COUNT(Fact_CustomerAction WHERE ActionTypeID=7 AND DateID < @endDateINT) = 1`. Used to identify customers in their "first repeat transaction" window.

### 2.9 IsFunded_New

**What**: Flag: customer has equity > 0 AND is at VerificationLevel 3 AND has a first action date before tomorrow.

**Columns Involved**: `IsFunded_New`, `EOD_IsFunded`

**Rules**:
```
EOD_IsFunded = 1 IF EOD_Equity >= 25 (i.e., in #FundedAccounts)
IsFunded_New = 1 IF EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < @nextD
```
`EOD_IsFunded` uses the $25 threshold (original funded definition); `IsFunded_New` uses the stricter definition requiring full KYC (VL3).

### 2.10 CashoutsAdjusted

**What**: Adjusted cashout metric that subtracts cashout-adjustment credits and coin transfers from gross cashouts.

**Columns Involved**: `CashoutsAdjusted`

**Rules**: `SUM(TPCashoutsOldDef - CashoutAdjustment - TransferCoins)` from `BI_DB_V_DDR_Daily_Panel`. Used by DDR/finance reporting to normalise cashout figures.

### 2.11 IsIslamic

**What**: Flag: customer has an Islamic (swap-free) account.

**Columns Involved**: `IsIslamic`

**Rules**: `Dim_Customer.WeekendFeePrecentage = 0 → IsIslamic = 1`. Islamic accounts pay AdminFee and SpotAdjustFee instead of rollover/swap fees.

### 2.12 Copy Trading Columns

**What**: Copy and CopyPortfolio are two distinct copy-trading modes tracked separately.

**Columns Involved**: `IsOpen_Copy`, `Count_Opened_Copy`, `Count_Closed_Copy`, `MoneyIn_Copy`, `MoneyOut_Copy`, `IsOpen_CopyPortfolio`, `Count_Opened_CopyPortfolio`, `Count_Closed_CopyPortfolio`, `MoneyIn_CopyPortfolio`, `MoneyOut_CopyPortfolio`

**Rules**:
- **Copy** (dm.CID IS NULL): ActionTypeID=17 (open), 18 (close), 15 (add), 16 (remove). Standard copy trading where customer copies a trader.
- **CopyPortfolio** (dm.CID IS NOT NULL — ParentCID in social-manager accounts): Managed copy portfolio product. Distinguished by whether the Dim_Mirror's ParentCID is a social-manager account (`AccountTypeID=9`).

---

## 3. Data Elements

> 183 columns. Grouped by functional area. Key columns shown per group; Lev1/LevCFD and FX/Comm/Ind sub-splits follow the same pattern as the representative column in each group.

### 3A. Identity & Date

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `CID` | BIGINT | eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID | T1 | DWH_dbo.Dim_Customer |
| `DateID` | INT | Partition key: date in YYYYMMDD format. One row per CID per day | T2 | SP_CID_DailyPanel_FullData @date param |

### 3B. Activity Period & Acquisition

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Active_Month` | INT | YYYYMM of this row's date | T2 | SP computed: YEAR*100+MONTH |
| `ActiveDate` | DATE | Calendar date of this row | T2 | SP @date param |
| `Seniority` | INT | Months since customer's first deposit (FTDdate) as of start of the current month | T2 | SP: DATEDIFF(MONTH, FTDdate, start-of-month) |
| `Seniority_Seg` | NVARCHAR | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '<11-12month', '12+month' | T2 | SP CASE on DATEDIFF(DAY, FTDdate, date) |
| `Reg_Month` | INT | YYYYMM of customer registration | T2 | Dim_Customer.RegisteredReal |
| `RegDate` | DATE | Customer registration date | T2 | Dim_Customer.RegisteredReal |
| `IsReg_ThisD` | INT | 1 if customer registered on this specific date | T2 | SP: RegDate = @date |
| `FTD_Month` | INT | YYYYMM of customer's first-time deposit (FTD) | T2 | Dim_Customer.FirstDepositDate |
| `FTDdate` | DATE | Customer's first-time deposit date | T2 | Dim_Customer.FirstDepositDate |
| `IsFTD_ThisD` | INT | 1 if customer made their first deposit on this specific date | T2 | SP: FTDdate = @date |
| `FTDA` | FLOAT | First-time deposit amount (USD) | T2 | Dim_Customer.FirstDepositAmount |
| `Region` | NVARCHAR | Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe') | T1 | DWH_dbo.Dim_Country.Region via Fact_SnapshotCustomer.CountryID |
| `NewMarketingRegion` | NVARCHAR | Marketing team region classification (e.g., 'Arabic', 'French', 'Norway', 'ROW') | T2 | Dim_Country.MarketingRegionManualName |
| `Country` | NVARCHAR | Customer's country name at snapshot date | T1 | DWH_dbo.Dim_Country.Name via Fact_SnapshotCustomer.CountryID |
| `Channel` | NVARCHAR | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Mobile Acquisition') | T2 | BI_DB_CIDFirstDates.Channel |
| `SubChannel` | NVARCHAR | Acquisition sub-channel detail | T2 | BI_DB_CIDFirstDates.SubChannel |
| `AffiliateID` | INT | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic | T2 | BI_DB_CIDFirstDates.SerialID |

### 3C. Customer Profile & KYC

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `FirstAction` | NVARCHAR | Deprecated — always NULL. Originally planned first action type | T4 | SP: NULL AS FirstAction |
| `FirstInstrument` | NVARCHAR | Deprecated — always NULL. Originally planned first instrument traded | T4 | SP: NULL AS FirstInstrument |
| `V2_Complete` | INT | 1 if customer has completed verification level 2 as of this date | T2 | Dim_Customer.VerificationLevel2Date <= @date |
| `V3_Complete` | INT | 1 if customer has completed full KYC (verification level 3) as of this date | T2 | Dim_Customer.VerificationLevel3Date <= @date |
| `V3_CompleteDate` | DATE | Date customer completed verification level 3 | T2 | Dim_Customer.VerificationLevel3Date |
| `LastPosOpenDate` | DATE | Most recent date customer opened a position (ActionTypeID IN 1,2), max of today vs. yesterday's carry-forward | T2 | Fact_CustomerAction AT=1,2 ISNULL(today, yesterday) |
| `LastLoggedIn` | DATE | Most recent login date (ActionTypeID=14), max of today vs. yesterday's carry-forward | T2 | Fact_CustomerAction AT=14 ISNULL(today, yesterday) |
| `IsPro` | INT | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3 in Fact_SnapshotCustomer) | T2 | Fact_SnapshotCustomer.MifidCategorizationID |
| `IsOTD` | INT | 1 if customer has made exactly one prior deposit (One Trade Done) | T2 | Fact_CustomerAction AT=7, count before today = 1 |
| `Daily_Classification` | NVARCHAR | Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration | T4 | SP_CID_DailyPanel_UpdateCluster (separate run) |
| `EOD_Club` | NVARCHAR | Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond' | T2 | Dim_PlayerLevel.Name with LowBronze/HighBronze split at $1K equity |
| `EOD_Regulation` | NVARCHAR | Regulatory jurisdiction name at EOD (e.g., 'CySEC', 'FCA', 'ASIC & GAML', 'FinCEN+FINRA') | T2 | DWH_dbo.Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID |
| `LastApplicationProAccountDate` | DATE | Date of most recent professional account application; '1900-01-01' sentinel if never applied | T2 | External_BI_OUTPUT_Customer_ProfessionalCustomers.ApplicationDate |

### 3D. EOD Financials

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Equity` | FLOAT | Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value | T2 | DWH_dbo.V_Liabilities.ActualNWA + Liabilities |
| `RealizedEquity` | FLOAT | Realized equity component (cash + closed positions only), excluding open unrealized positions | T2 | DWH_dbo.V_Liabilities.RealizedEquity |
| `AUM` | FLOAT | Assets Under Management: value of assets the customer holds in copy-trading and portfolio products | T2 | DWH_dbo.V_Liabilities.AUM |
| `Credit` | FLOAT | Credit/margin balance: funds provided as credit (e.g., bonus credits). V_Liabilities.EOD_Balance | T2 | DWH_dbo.V_Liabilities.EOD_Balance |
| `EOD_Equity_Copy` | FLOAT | EOD equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Stocks` | FLOAT | EOD equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Stocks` | FLOAT | EOD equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Crypto` | FLOAT | EOD equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Crypto` | FLOAT | EOD equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_FX/Comm/Ind` | FLOAT | EOD equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Crypto_Lev1` | FLOAT | EOD equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_Real_Stocks_LevCFD` | FLOAT | EOD equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short) | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Crypto_Lev1` | FLOAT | EOD equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1 | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_Equity_CFD_Stocks_LevCFD` | FLOAT | EOD equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0 | T2 | BI_DB_PositionPnL + Dim_Instrument |
| `EOD_IsFunded` | INT | 1 if EOD_Equity >= $25 (original funded customer threshold) | T2 | SP: EOD_Equity >= 25 |
| `IsFunded_New` | INT | 1 if EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < tomorrow (stricter funded definition) | T2 | SP: #NewFundedAcccounts |
| `EOD_LSD` | NVARCHAR | Life Stage Definition segment label at EOD (e.g., lifecycle stage name). Source: BI_DB_CID_LifeStageDefinition | T2 | BI_DB_CID_LifeStageDefinition.LSD |

### 3E. Activity Flags

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `ActiveUser` | INT | 1 if customer logged in (ActionTypeID=14) on this date | T2 | Fact_CustomerAction AT=14 |
| `Active` | INT | 1 if customer had any position open or closed on this date (any instrument, including partial close children excluded) | T2 | Dim_Position OpenDateID<=today AND (CloseDateID=0 OR CloseDateID>=today) |
| `ActiveOpen` | INT | 1 if customer opened a new position today — manual trade OR started/added a mirror (AirDrop excluded). See §2.3 | T2 | SP: ActiveOpen_Manual OR ActiveOpen_NewMirror OR ActiveOpen_AddMirror |
| `Active_Copy` | INT | 1 if customer has an open copy position on this date (MirrorID>0) | T2 | Dim_Position MirrorID>0, in date range |
| `Active_Real_Stocks` | INT | 1 if customer has an open settled stock position (IsSettled=1, InstrumentTypeID IN 5,6, non-AirDrop) | T2 | Dim_Position |
| `Active_CFD_Stocks` | INT | 1 if customer has an open CFD stock position (IsSettled=0, InstrumentTypeID IN 5,6) | T2 | Dim_Position |
| `Active_Real_Crypto` | INT | 1 if customer has an open settled crypto position (IsSettled=1, InstrumentTypeID=10, non-AirDrop) | T2 | Dim_Position |
| `Active_CFD_Crypto` | INT | 1 if customer has an open CFD crypto position (IsSettled=0, InstrumentTypeID=10) | T2 | Dim_Position |
| `Active_FX/Comm/Ind` | INT | 1 if customer has an open FX/commodities/indices position (InstrumentTypeID IN 1,2,4) | T2 | Dim_Position |
| `Active_FX` | INT | 1 if customer has an open FX (Currencies, InstrumentTypeID=1) position | T2 | Dim_Position |
| `Active_Comm` | INT | 1 if customer has an open Commodities (InstrumentTypeID=2) position | T2 | Dim_Position |
| `Active_Ind` | INT | 1 if customer has an open Indices (InstrumentTypeID=4) position | T2 | Dim_Position |
| `Active_Real_Stocks_Lev1` | INT | 1 if customer has an open stock position with Leverage=1 AND IsBuy=1 | T2 | Dim_Position leverage-based split |
| `Active_CFD_Stocks_LevCFD` | INT | 1 if customer has an open stock position with Leverage>1 OR IsBuy=0 | T2 | Dim_Position leverage-based split |
| `Active_Real_Crypto_Lev1` | INT | 1 if customer has an open crypto position with Leverage=1 AND IsBuy=1 | T2 | Dim_Position leverage-based split |
| `Active_CFD_Crypto_LevCFD` | INT | 1 if customer has an open crypto position with Leverage>1 OR IsBuy=0 | T2 | Dim_Position leverage-based split |

### 3F. ActiveOpen by Instrument

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `ActiveOpen_Manual` | INT | 1 if opened a non-AirDrop, non-copy position today (MirrorID=0, IsAirDrop=0) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Mirror` | INT | 1 if started a new copy relationship OR added mirror allocation today | T2 | Dim_Mirror + Fact_CustomerAction AT=15 |
| `ActiveOpen_AirDrop` | INT | 1 if received an AirDrop position today (IsAirDrop=1) | T2 | Dim_Position OpenDateID=today, IsAirDrop=1 |
| `ActiveOpen_IncludeCopy` | INT | 1 if opened any position today including copy but excluding AirDrop | T2 | Dim_Position |
| `ActiveOpen_Copy` | INT | 1 if opened a copy position today (MirrorID>0, non-portfolio, OpenDateID=today) | T2 | Dim_Position |
| `ActiveOpen_Real_Stocks` | INT | 1 if opened a settled stock position today (non-AirDrop) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_CFD_Stocks` | INT | 1 if opened a CFD stock position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Real_Crypto` | INT | 1 if opened a settled crypto position today (non-AirDrop) | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_CFD_Crypto` | INT | 1 if opened a CFD crypto position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_FX/Comm/Ind` | INT | 1 if opened a FX/Comm/Ind position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_FX` | INT | 1 if opened a FX position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Comm` | INT | 1 if opened a Commodities position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Ind` | INT | 1 if opened an Indices position today | T2 | Dim_Position OpenDateID=today |
| `ActiveOpen_Real_Stocks_Lev1` | INT | 1 if opened a stock position (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `ActiveOpen_CFD_Stocks_LevCFD` | INT | 1 if opened a leveraged/short stock position today | T2 | Dim_Position |
| `ActiveOpen_Real_Crypto_Lev1` | INT | 1 if opened a crypto position (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `ActiveOpen_CFD_Crypto_LevCFD` | INT | 1 if opened a leveraged/short crypto position today | T2 | Dim_Position |

### 3G. Copy Trading Activity

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `IsOpen_Copy` | INT | 1 if customer opened a new copy relationship (started copying a trader) today | T2 | Fact_CustomerAction AT=17 |
| `Count_Opened_Copy` | INT | Number of distinct copy relationships opened today | T2 | Fact_CustomerAction AT=17 DISTINCT MirrorID |
| `Count_Closed_Copy` | INT | Number of distinct copy relationships closed today | T2 | Fact_CustomerAction AT=18 DISTINCT MirrorID |
| `MoneyIn_Copy` | FLOAT | Total funds allocated into copy positions today (negative Amount from AT=17,15) | T2 | Fact_CustomerAction AT=17,15 |
| `MoneyOut_Copy` | FLOAT | Total funds returned from closed copy positions today (Amount from AT=18,16) | T2 | Fact_CustomerAction AT=18,16 |
| `IsOpen_CopyPortfolio` | INT | 1 if customer opened a CopyPortfolio (managed portfolio product) today | T2 | Fact_CustomerAction AT=17 where ParentCID is social-manager account |
| `Count_Opened_CopyPortfolio` | INT | Number of CopyPortfolio relationships opened today | T2 | Fact_CustomerAction, portfolio mode |
| `Count_Closed_CopyPortfolio` | INT | Number of CopyPortfolio relationships closed today | T2 | Fact_CustomerAction, portfolio mode |
| `MoneyIn_CopyPortfolio` | FLOAT | Total funds into CopyPortfolio positions today | T2 | Fact_CustomerAction, portfolio mode |
| `MoneyOut_CopyPortfolio` | FLOAT | Total funds returned from CopyPortfolio positions today | T2 | Fact_CustomerAction, portfolio mode |

### 3H. New Trades & Amount In

> `NewTrades_*` = count of positions opened today (IsPartialCloseChild=0). `AmountIn_NewTrades_*` = USD invested in those positions. Repeated for Copy, Real_Stocks, CFD_Stocks, Real_Crypto, CFD_Crypto, FX/Comm/Ind, plus Lev1/LevCFD variants and a _Total.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `NewTrades_Copy` | INT | Count of new copy positions opened today | T2 | Dim_Position OpenDateID=today, MirrorID>0 |
| `NewTrades_Real_Stocks` | INT | Count of new settled stock positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_CFD_Stocks` | INT | Count of new CFD stock positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_Real_Crypto` | INT | Count of new settled crypto positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_CFD_Crypto` | INT | Count of new CFD crypto positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_FX/Comm/Ind` | INT | Count of new FX/Comm/Ind positions opened today | T2 | Dim_Position OpenDateID=today |
| `NewTrades_Total` | INT | Total count of all new positions opened today across all instrument types | T2 | SP: SUM of all NewTrades_* |
| `AmountIn_NewTrades_Copy` | FLOAT | Total USD invested in new copy positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Real_Stocks` | FLOAT | Total USD in new settled stock positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_CFD_Stocks` | FLOAT | Total USD in new CFD stock positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Real_Crypto` | FLOAT | Total USD in new settled crypto positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_CFD_Crypto` | FLOAT | Total USD in new CFD crypto positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_FX/Comm/Ind` | FLOAT | Total USD in new FX/Comm/Ind positions today | T2 | Dim_Position Amount |
| `AmountIn_NewTrades_Total` | FLOAT | Total USD invested in all new positions today | T2 | SP: SUM of all AmountIn_NewTrades_* |
| `NewTrades_Real_Stocks_Lev1` | INT | Count of new Lev1 stock positions (Leverage=1, IsBuy=1) today | T2 | Dim_Position |
| `NewTrades_CFD_Stocks_LevCFD` | INT | Count of new leveraged/short stock positions today | T2 | Dim_Position |
| `NewTrades_Real_Crypto_Lev1` | INT | Count of new Lev1 crypto positions today | T2 | Dim_Position |
| `NewTrades_CFD_Crypto_LevCFD` | INT | Count of new leveraged/short crypto positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_Real_Stocks_Lev1` | FLOAT | USD in new Lev1 stock positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_CFD_Stocks_LevCFD` | FLOAT | USD in new leveraged/short stock positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_Real_Crypto_Lev1` | FLOAT | USD in new Lev1 crypto positions today | T2 | Dim_Position |
| `AmountIn_NewTrades_CFD_Crypto_LevCFD` | FLOAT | USD in new leveraged/short crypto positions today | T2 | Dim_Position |

### 3I. Daily Revenue

> Revenue = trading commissions (FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport plus ticket fees, conversion fees, Islamic fees from revenue functions.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `Revenue_Copy` | FLOAT | Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Real_Stocks` | FLOAT | Revenue from settled stock positions + flat ticket fees | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFee |
| `Revenue_CFD_Stocks` | FLOAT | Revenue from CFD stock positions + ticket fee by percent (Stocks CFD) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Real_Crypto` | FLOAT | Revenue from settled crypto positions + ticket fee by percent (Crypto Real) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_CFD_Crypto` | FLOAT | Revenue from CFD crypto positions + ticket fee by percent (Crypto CFD) | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_FX/Comm/Ind` | FLOAT | Revenue from FX/Commodities/Indices positions + ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_FX` | FLOAT | Revenue from FX (Currencies) positions + Currencies CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Comm` | FLOAT | Revenue from Commodities positions + Commodities CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Ind` | FLOAT | Revenue from Indices positions + Indices CFD ticket fee by percent | T2 | BI_DB_DailyCommisionReport + Function_Revenue_TicketFeeByPercent |
| `Revenue_Total` | FLOAT | Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See §2.6 | T2 | SP: SUM of all revenue components |
| `Revenue_IslamicFees` | FLOAT | Islamic account fees only: AdminFee + SpotAdjustFee (swap-free surcharge). 0 for non-Islamic accounts | T2 | Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee |
| `Revenue_TicketFees` | FLOAT | Flat per-trade ticket fees on stock trades (Function_Revenue_TicketFee) | T2 | Function_Revenue_TicketFee |
| `Revenue_ConversionFees` | FLOAT | Currency conversion fees on deposits/cashouts (Function_Revenue_ConversionFee) | T2 | Function_Revenue_ConversionFee |
| `Revenue_TicketFeeByPercent` | FLOAT | Total percentage-based ticket fees across all instrument types and copy | T2 | Function_Revenue_TicketFeeByPercent SUM(TicketFeeByPercent) |
| `Transactional_Revenue_Total` | FLOAT | Revenue_Total minus Islamic fees — the pure transaction-driven revenue portion. See §2.6 | T2 | SP: Revenue_Total minus Revenue_IslamicFees components |
| `Revenue_Real_Stocks_Lev1` | FLOAT | Revenue from Lev1 stock positions + flat ticket fees | T2 | BI_DB_DailyCommisionReport leverage split |
| `Revenue_CFD_Stocks_LevCFD` | FLOAT | Revenue from leveraged/short stock positions | T2 | BI_DB_DailyCommisionReport leverage split |
| `Revenue_Real_Crypto_Lev1` | FLOAT | Revenue from Lev1 crypto positions | T2 | BI_DB_DailyCommisionReport leverage split |
| `Revenue_CFD_Crypto_LevCFD` | FLOAT | Revenue from leveraged/short crypto positions | T2 | BI_DB_DailyCommisionReport leverage split |

### 3J. Daily PnL (Customer-Side)

> Customer profit & loss on positions opened, closed, or carried through the date. Four cases: (1) opened+closed today, (2) opened prior+closed today, (3) opened today+still open, (4) opened prior+still open.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `PnL_Copy` | FLOAT | Customer-side PnL on copy positions on this date | T2 | BI_DB_PositionPnL PnL calculation |
| `PnL_Real_Stocks` | FLOAT | Customer-side PnL on settled stock positions | T2 | BI_DB_PositionPnL |
| `PnL_CFD_Stocks` | FLOAT | Customer-side PnL on CFD stock positions | T2 | BI_DB_PositionPnL |
| `PnL_Real_Crypto` | FLOAT | Customer-side PnL on settled crypto positions | T2 | BI_DB_PositionPnL |
| `PnL_CFD_Crypto` | FLOAT | Customer-side PnL on CFD crypto positions | T2 | BI_DB_PositionPnL |
| `PnL_FX/Comm/Ind` | FLOAT | Customer-side PnL on FX/Comm/Ind positions | T2 | BI_DB_PositionPnL |
| `PnL_FX` | FLOAT | Customer-side PnL on FX (Currencies) positions | T2 | BI_DB_PositionPnL |
| `PnL_Comm` | FLOAT | Customer-side PnL on Commodities positions | T2 | BI_DB_PositionPnL |
| `PnL_Ind` | FLOAT | Customer-side PnL on Indices positions | T2 | BI_DB_PositionPnL |
| `PnL_Total` | FLOAT | Total customer-side PnL across all instruments (sum of Copy + Real_Stocks + CFD_Stocks + Real_Crypto + CFD_Crypto + FX/Comm/Ind) | T2 | SP: SUM of all PnL_* |
| `PnL_Real_Stocks_Lev1` | FLOAT | PnL on Lev1 stock positions | T2 | BI_DB_PositionPnL leverage split |
| `PnL_CFD_Stocks_LevCFD` | FLOAT | PnL on leveraged/short stock positions | T2 | BI_DB_PositionPnL |
| `PnL_Real_Crypto_Lev1` | FLOAT | PnL on Lev1 crypto positions | T2 | BI_DB_PositionPnL |
| `PnL_CFD_Crypto_LevCFD` | FLOAT | PnL on leveraged/short crypto positions | T2 | BI_DB_PositionPnL |

### 3K. Daily Cash Flow

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `TotalDeposits` | FLOAT | Total deposit amount (USD) on this date (Fact_CustomerAction ActionTypeID=7) | T2 | Fact_CustomerAction AT=7 |
| `CountDeposits` | INT | Number of deposits on this date | T2 | Fact_CustomerAction AT=7 COUNT |
| `TotalCashouts` | FLOAT | Total cashout amount (USD) on this date (ActionTypeID=8) | T2 | Fact_CustomerAction AT=8 |
| `TotalCoFee` | FLOAT | Copy-out fee charged on copy position closure (ActionTypeID=30, Commission field) | T2 | Fact_CustomerAction AT=30 |
| `NetDeposits` | FLOAT | TotalDeposits minus TotalCashouts for this date | T2 | SP: TotalDeposits - TotalCashouts |
| `WithdrawalToWallet` | FLOAT | Cashout amount directed to eToro Money wallet (FundingTypeID=27) | T2 | Fact_CustomerAction AT=8, FundingTypeID=27 |
| `CashoutsAdjusted` | FLOAT | Adjusted cashout: TPCashoutsOldDef - CashoutAdjustment - TransferCoins. Used for DDR/finance normalisation | T2 | BI_DB_V_DDR_Daily_Panel |

### 3L. Accumulated (Lifetime) Columns

> All ACC_ columns are running totals: today's incremental + yesterday's ACC_ value. See §2.5.

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `ACC_Revenue_Copy` | FLOAT | Lifetime accumulated revenue from copy positions | T2 | Prior row + Revenue_Copy |
| `ACC_Revenue_Real_Stocks` | FLOAT | Lifetime accumulated revenue from settled stocks | T2 | Prior row + Revenue_Real_Stocks |
| `ACC_Revenue_CFD_Stocks` | FLOAT | Lifetime accumulated revenue from CFD stocks | T2 | Prior row + Revenue_CFD_Stocks |
| `ACC_Revenue_Real_Crypto` | FLOAT | Lifetime accumulated revenue from settled crypto | T2 | Prior row + Revenue_Real_Crypto |
| `ACC_Revenue_CFD_Crypto` | FLOAT | Lifetime accumulated revenue from CFD crypto | T2 | Prior row + Revenue_CFD_Crypto |
| `ACC_Revenue_FX/Comm/Ind` | FLOAT | Lifetime accumulated revenue from FX/Comm/Ind | T2 | Prior row + Revenue_FX/Comm/Ind |
| `ACC_Revenue_Total` | FLOAT | Lifetime accumulated total revenue (all instruments + all fee types) | T2 | Prior row + Revenue_Total |
| `ACC_Transactional_Revenue_Total` | FLOAT | Lifetime accumulated transactional-only revenue (excludes Islamic fees) | T2 | Prior row + Transactional_Revenue_Total |
| `ACC_PnL_Copy` | FLOAT | Lifetime accumulated customer PnL on copy positions | T2 | Prior row + PnL_Copy |
| `ACC_PnL_Real_Stocks` | FLOAT | Lifetime accumulated customer PnL on settled stocks | T2 | Prior row + PnL_Real_Stocks |
| `ACC_PnL_CFD_Stocks` | FLOAT | Lifetime accumulated customer PnL on CFD stocks | T2 | Prior row + PnL_CFD_Stocks |
| `ACC_PnL_Real_Crypto` | FLOAT | Lifetime accumulated customer PnL on settled crypto | T2 | Prior row + PnL_Real_Crypto |
| `ACC_PnL_CFD_Crypto` | FLOAT | Lifetime accumulated customer PnL on CFD crypto | T2 | Prior row + PnL_CFD_Crypto |
| `ACC_PnL_FX/Comm/Ind` | FLOAT | Lifetime accumulated customer PnL on FX/Comm/Ind | T2 | Prior row + PnL_FX/Comm/Ind |
| `ACC_PnL_Total` | FLOAT | Lifetime accumulated total customer PnL | T2 | Prior row + PnL_Total |
| `ACC_TotalDeposits` | FLOAT | Lifetime total deposits (USD) | T2 | Prior row + TotalDeposits |
| `ACC_CountDeposits` | INT | Lifetime total deposit count | T2 | Prior row + CountDeposits |
| `ACC_TotalCashouts` | FLOAT | Lifetime total cashouts (USD) | T2 | Prior row + TotalCashouts |
| `ACC_TotalCoFee` | FLOAT | Lifetime total copy-out fees paid | T2 | Prior row + TotalCoFee |
| `ACC_NetDeposits` | FLOAT | Lifetime net deposits (TotalDeposits - TotalCashouts cumulative) | T2 | Prior row + NetDeposits |
| `ACC_WithdrawalToWallet` | FLOAT | Lifetime total withdrawals to eToro Money wallet | T2 | Prior row + WithdrawalToWallet |
| `ACC_ChurnDays` | INT | Consecutive days since first funded date where customer was not in IsFunded_New state. Resets to 0 when IsFunded_New=1. See §2.5 | T2 | SP CASE logic on IsFunded_New + prior row |

### 3M. CRM & ETL Metadata

| Column | Type | Description | Tier | Source |
|--------|------|-------------|------|--------|
| `AccountManager` | NVARCHAR | Account manager full name (FirstName + ' ' + LastName) from Dim_Manager | T2 | DWH_dbo.Dim_Manager.FirstName + LastName |
| `IsIslamic` | INT | 1 if customer has a swap-free/Islamic account (WeekendFeePrecentage=0). See §2.11 | T2 | DWH_dbo.Dim_Customer.WeekendFeePrecentage |
| `IsContacted` | INT | 1 if customer was contacted through bonus/CRM channel on this date | T2 | BI_DB_NewBonusReport.IsContacted |
| `IsContactedAmount` | FLOAT | Total deposit amount from contacted periods on this date | T2 | BI_DB_NewBonusReport.IsContactedAmount |
| `UpdateDate` | DATETIME | ETL timestamp: GETDATE() at time of SP execution. Reflects the most recent daily ETL run for this partition | T2 | SP: GETDATE() |
| `FirstNewFundedDate` | DATE | Date when customer first satisfied the IsFunded_New criteria (first VL3-verified funded day). NULL if never funded under new definition | T2 | BI_DB_CIDFirstDates.FirstNewFundedDate |

---

## 4. ETL Pipeline

```
[DWH_dbo production tables]
  Fact_SnapshotCustomer (IsDepositor=1) ──────────────────────── Population
  V_Liabilities ─────────────────────────────────────────────── EOD equity/AUM/credit
  Dim_Position + BI_DB_PositionPnL ─────────────────────────── Position-level PnL & EOD equity
  Fact_CustomerAction (AT=7,8,14,15,17,18,30) ──────────────── Cash flows + Copy + Login
  Dim_Mirror + Fact_CustomerAction(AT=15) ──────────────────── Mirror open/add
  Dim_Customer, Dim_Country, Dim_PlayerLevel ───────────────── Customer demographics & tier

[BI_DB_dbo source tables]
  BI_DB_DailyCommisionReport ────────────────────────────────── Revenue base
  BI_DB_CIDFirstDates ──────────────────────────────────────── Channel + FirstNewFundedDate
  BI_DB_CID_LifeStageDefinition ────────────────────────────── EOD_LSD
  BI_DB_NewBonusReport ─────────────────────────────────────── IsContacted
  BI_DB_PositionPnL ───────────────────────────────────────── EOD equity by type
  BI_DB_V_DDR_Daily_Panel ─────────────────────────────────── CashoutsAdjusted
  External_BI_OUTPUT_Customer_ProfessionalCustomers ─────────── Pro account dates

[Revenue functions]
  Function_Revenue_AdminFee, SpotAdjustFee ──────────────────── Islamic fees
  Function_Revenue_TicketFee ───────────────────────────────── Stock ticket fees
  Function_Revenue_TicketFeeByPercent ─────────────────────── % ticket fees (crypto/FX/copy)
  Function_Revenue_ConversionFee ──────────────────────────── Conversion fees

        │
        ▼
  SP_CID_DailyPanel_FullData (@date)
  [Priority 0, SB_Daily process]
        │  DELETE WHERE DateID = @startDateINT
        │  INSERT INTO BI_DB_CID_DailyPanel_FullData
        │  (reads yesterday's row for ACC_ running totals)
        │
        ▼
  BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(DateID), partitioned daily 2018–2026]

  Companion SPs (historical partition switching only):
    SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE — creates staging table for a date
    SP_BI_DB_CID_DailyPanel_FullData_SWITCH — switches staging partition into main table

  Post-insert (separate run, currently non-operational):
    SP_CID_DailyPanel_UpdateCluster — updates Daily_Classification (EOD_Segment) column
```

---

## 5. Data Quality

| Check | Observation |
|---|---|
| **UpdateDate pattern** | 1,460 distinct dates (2021-04-05 → 2026-04-12): daily ETL confirmed. Historical partitions updated in bulk in April 2021 (all 2018–2020 rows have April 2021 UpdateDate). |
| **Date coverage** | DateID 20180101 → 20260411 (active). ~64.5M rows per monthly date in April 2026. ~5.9M distinct CIDs per daily date. |
| **NULL Equity** | 12,478 NULL Equity rows on 2026-04-11 (0.21%): customers where V_Liabilities join found no equity record (off-platform balance) |
| **NULL FirstNewFundedDate** | 736,041 NULLs on 2026-04-11 (12.5%): customers who never reached VL3+positive-equity state |
| **Daily_Classification** | All rows empty string as of 2025–2026. Column is non-null but effectively unused. Historical (pre-Synapse migration) rows contain segment labels |
| **Revenue NULLs** | Zero NULLs for Revenue_Total, Revenue_IslamicFees, Revenue_TicketFeeByPercent — all ISNULL-defaulted to 0 in SP |
| **FirstAction / FirstInstrument** | Always NULL — deprecated columns present in DDL but SP writes NULL explicitly |
| **AirDrop positions** | IsAirDrop=1 positions are explicitly EXCLUDED from Active_Real_Stocks, Active_Real_Crypto, ActiveOpen (but captured in ActiveOpen_AirDrop) |
| **ACC_ initialisation** | First-day customers: no prior row → #History reads NULL for all ACC_ cols → ISNULL treats as 0 → ACC_ = today's value |

---

## 6. Usage Notes

- **Filter to depositors only**: This table already contains only depositors (IsDepositor=1). Do NOT join back to Fact_SnapshotCustomer expecting to find non-depositors here.
- **Daily_Classification is empty**: Do not use this column for segmentation in current analytics. Use EOD_Club or a separate segmentation table instead.
- **Revenue_Total vs Transactional_Revenue_Total**: For Islamic-account-inclusive total revenue use `Revenue_Total`; for transaction-only revenue comparison (where Islamic fee treatment differs) use `Transactional_Revenue_Total`.
- **ACC_ columns reset logic**: `ACC_ChurnDays` resets to 0 on any day where `IsFunded_New=1`. All other ACC_ columns only grow; they do not reset on cashout.
- **Lev1 vs IsSettled split**: The two split methods (IsSettled and Lev1/LevCFD) capture slightly different populations for stocks/crypto. IsSettled is the primary classification used in most revenue, PnL, and EOD_Equity columns. Lev1/LevCFD is a secondary split available for leverage-based analysis.
- **Equity NULL rows**: 0.21% of rows have NULL Equity. These customers have a position in the depositor population but no V_Liabilities record for the date. Treat as 0 equity in aggregations.
- **Performance**: Table is HASH distributed on CID. Join to CID-keyed tables will be data-local. Avoid full scans across all DateIDs; always filter on DateID to use partition elimination.
- **CopyPortfolio vs Copy**: Use `Count_Opened_Copy` / `IsOpen_Copy` for standard copy trading; `Count_Opened_CopyPortfolio` / `IsOpen_CopyPortfolio` for the managed portfolio product. They are mutually exclusive in the SP logic.

---

## 7. Related Objects

| Object | Schema | Relationship |
|---|---|---|
| `SP_CID_DailyPanel_FullData` | BI_DB_dbo | Writer SP — generates all rows for a given date |
| `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` | BI_DB_dbo | Creates staging switch table for historical load |
| `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` | BI_DB_dbo | Partition switches staging into main table |
| `SP_CID_DailyPanel_UpdateCluster` | BI_DB_dbo | Post-insert cluster update SP (Daily_Classification) — currently non-operational |
| `BI_DB_CID_DailyPanel_Club` | BI_DB_dbo | Sibling: Club-eligible customers only, different scope, similar schema |
| `BI_DB_CID_MonthlyPanel_FullData` | BI_DB_dbo | Monthly rollup of same population |
| `BI_DB_CID_WeeklyPanel_FullData` | BI_DB_dbo | Weekly rollup of same population |
| `BI_DB_DailyCommisionReport` | BI_DB_dbo | Revenue source (Priority 20 upstream) |
| `BI_DB_CIDFirstDates` | BI_DB_dbo | Channel/dates source (Priority 90 upstream) |
| `BI_DB_CID_LifeStageDefinition` | BI_DB_dbo | EOD_LSD source (Priority 0 upstream) |
| `BI_DB_PositionPnL` | BI_DB_dbo | EOD equity by instrument source |
| `BI_DB_NewBonusReport` | BI_DB_dbo | IsContacted source |
| `V_Liabilities` | DWH_dbo | EOD equity/AUM/credit source |
| `Fact_SnapshotCustomer` | DWH_dbo | Population + customer state source |
| `Dim_Position` | DWH_dbo | Position-level data for Active/NewTrades/PnL |

---

## 8. Change History

| Date | Author | Change |
|---|---|---|
| 2020-02-02 | Dan Iliescu | Original SP based on Monthly Panel; start and end date set to same date |
| 2020-02-17 | Dan | Remove IsOTD Update stmt → CASE on ACC_CountDeposits; remove LastLoggedIn & LastPosOpenDate |
| 2020-02-10 | Eti | Add NewMarketingRegion column |
| 2021-03-17 | Adi Ferber | Add partition mechanism |
| 2021-04-07 | Dan | Change activity source from BI_DB_ActivitySegment_Snapshot to BI_DB_CID_DailyCluster |
| 2021-04-07 | Maor | Cut loop — insert NULL for segment, update via separate SP_CID_DailyPanel_UpdateCluster |
| 2021-08-22 | Dan | Add ACC_ChurnDays and FirstNewFundedDate |
| 2022-01-25 | Amir | Fix New Funded Definition — require VerificationLevel=3 |
| 2023-10-22 | Tom B | Migrate to Synapse |
| 2024-03-20 | Or Filizer | Add EOD_LSD (LifeStage) column |
| 2025-01-06 | Or Filizer | Add ActiveOpen_IncludeCopy, ActiveOpen_Manual, ActiveOpen_Mirror, ActiveOpen_AirDrop; edit ActiveOpen/ActiveOpen_Real_Stocks/Real_Crypto; add Revenue_IslamicFees, Revenue_TicketFees, Revenue_ConversionFees, CashoutsAdjusted; revise Revenue_Total + ACC_Revenue_Total |
| 2025-04-28 | Or Filizer | Split Revenue_Total into Transactional_Revenue_Total + total; add ACC_Transactional_Revenue_Total |
| 2025-07-29 | Or Filizer | Add Revenue_TicketFeeByPercent across all revenue, total, transactional, and instruments |
