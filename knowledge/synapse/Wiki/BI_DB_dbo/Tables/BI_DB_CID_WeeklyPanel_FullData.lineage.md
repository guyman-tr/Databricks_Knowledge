# Lineage: BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData

## Source Chain

```
[Production Sources — INDIRECT via BI_DB_CID_DailyPanel_FullData]
  DWH_dbo.V_Liabilities ─────────────────────── EOW equity (Equity, RealizedEquity, AUM, Credit)
  DWH_dbo.Fact_SnapshotCustomer ─────────────── Depositor population, Club, Regulation, IsFunded
  DWH_dbo.Dim_Position + BI_DB_PositionPnL ──── Position-level PnL & EOW equity by asset class
  DWH_dbo.Fact_CustomerAction (AT=7,8,14,15+) ─ Deposits, cashouts, copy actions, logins
  DWH_dbo.Dim_Mirror + Fact_CustomerAction(15) ─ Copy mirror open/add
  DWH_dbo.Dim_Customer, Dim_Country ─────────── Customer demographics
  DWH_dbo.Dim_PlayerLevel ───────────────────── Club tier name (LowBronze/HighBronze split)
  BI_DB_DailyCommisionReport ────────────────── Revenue (commissions + rollover)
  BI_DB_CIDFirstDates ───────────────────────── Channel, SubChannel, AffiliateID, FTDdate, FTDA
  BI_DB_CID_LifeStageDefinition ─────────────── EOW_LSD (life stage segment label)
  BI_DB_PositionPnL ─────────────────────────── EOD equity by instrument type
  BI_DB_V_DDR_Daily_Panel ───────────────────── CashoutsAdjusted
  External_BI_OUTPUT_Customer_ProfessionalCustomers ── LastApplicationProAccountDate
  Revenue functions (Function_Revenue_*) ────── Fee components (Islamic, Ticket, Conversion)

        │
        ▼
  SP_CID_DailyPanel_FullData (@date)
  [Priority 0, SB_Daily]
        │
        ▼
  BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(DateID), partitioned daily 2018–2026]

  ┌─ DWH_dbo.Dim_Date ───────────────── Week boundary calculation (SSWeekNumberOfYear, FirstDayOfWeek)
  │
  ▼
  SP_CID_WeeklyPanel_FullData (@date)   ← OpsDB: Priority 0, SB_Daily
  │
  │  Step 1: Build #weeklydays — DateKeys in target week window (Dim_Date SSWeekNumberOfYear filter)
  │  Step 2: Build #dailydata  — DailyPanel rows for week's DateIDs (HASH(CID) temp table)
  │  Step 3: Build #dailysum   — Weekly SUM/MAX aggregates from #dailydata (GROUP BY CID, SSWeekNum, CalYear)
  │  Step 4: Build #lastdayattributes — EOW snapshot from #dailydata WHERE DateID = @dateID
  │  Step 5: DELETE WHERE FirstDayOfWeek = @FirstDayOfWeek
  │  Step 6: INSERT (#dailysum ds LEFT JOIN #lastdayattributes lda ON ds.CID = lda.CID)
  │
  ▼
  BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(FirstDayOfWeek ASC, CID ASC)]
```

## Column-Level Source Attribution

### End-of-Week Snapshot Columns (from #lastdayattributes — last day of the week only)

Sourced from `BI_DB_CID_DailyPanel_FullData WHERE DateID = @dateID` (last calendar day of the week).

| Weekly Column | Daily Source Column | Source |
|---|---|---|
| Seniority | Seniority | SP: DATEDIFF(MONTH, FTDdate, month-start) |
| Seniority_Seg | Seniority_Seg | SP: CASE on day-diff from FTDdate |
| IsReg_ThisD | IsReg_ThisD | SP: RegDate = last day of week |
| IsFTD_ThisD | IsFTD_ThisD | SP: FTDdate = last day of week |
| Region | Region | DWH_dbo.Dim_Country.Region |
| Country | Country | DWH_dbo.Dim_Country.Name |
| Channel | Channel | BI_DB_CIDFirstDates.Channel |
| SubChannel | SubChannel | BI_DB_CIDFirstDates.SubChannel |
| AffiliateID | AffiliateID | BI_DB_CIDFirstDates.SerialID |
| NewMarketingRegion | NewMarketingRegion | Dim_Country.MarketingRegionManualName |
| V2_Complete | V2_Complete | Dim_Customer.VerificationLevel2Date |
| V3_Complete | V3_Complete | Dim_Customer.VerificationLevel3Date |
| IsPro | IsPro | Fact_SnapshotCustomer.MifidCategorizationID |
| IsOTD | IsOTD | Fact_CustomerAction AT=7, count < today = 1 |
| Weekly_Classification | Daily_Classification | SP_CID_DailyPanel_UpdateCluster (non-operational) |
| EOW_Club | EOD_Club | Dim_PlayerLevel + LowBronze/HighBronze split |
| EOW_Regulation | EOD_Regulation | Dim_Regulation.Name via Fact_SnapshotCustomer |
| EOW_LSD | EOD_LSD | BI_DB_CID_LifeStageDefinition.LSD |
| Equity | Equity | DWH_dbo.V_Liabilities.ActualNWA + Liabilities |
| RealizedEquity | RealizedEquity | DWH_dbo.V_Liabilities.RealizedEquity |
| AUM | AUM | DWH_dbo.V_Liabilities.AUM |
| Credit | Credit | DWH_dbo.V_Liabilities.EOD_Balance (CASE WHEN NULL THEN 0) |
| EOW_Equity_Copy | EOD_Equity_Copy | BI_DB_PositionPnL (MirrorID>0) |
| EOW_Equity_Real_Stocks | EOD_Equity_Real_Stocks | BI_DB_PositionPnL (IsSettled=1, InstrTypeID IN 5,6) |
| EOW_Equity_CFD_Stocks | EOD_Equity_CFD_Stocks | BI_DB_PositionPnL (IsSettled=0, InstrTypeID IN 5,6) |
| EOW_Equity_Real_Crypto | EOD_Equity_Real_Crypto | BI_DB_PositionPnL (IsSettled=1, InstrTypeID=10) |
| EOW_Equity_CFD_Crypto | EOD_Equity_CFD_Crypto | BI_DB_PositionPnL (IsSettled=0, InstrTypeID=10) |
| EOW_Equity_FX/Comm/Ind | EOD_Equity_FX/Comm/Ind | BI_DB_PositionPnL (InstrTypeID IN 1,2,4) |
| EOW_Equity_Real_Crypto_Lev1 | EOD_Equity_Real_Crypto_Lev1 | BI_DB_PositionPnL leverage split |
| EOW_Equity_Real_Stocks_LevCFD | EOD_Equity_Real_Stocks_LevCFD | BI_DB_PositionPnL leverage split |
| EOW_Equity_CFD_Crypto_Lev1 | EOD_Equity_CFD_Crypto_Lev1 | BI_DB_PositionPnL leverage split |
| EOW_Equity_CFD_Stocks_LevCFD | EOD_Equity_CFD_Stocks_LevCFD | BI_DB_PositionPnL leverage split |

### Week-Derived Scalar Columns (SP @date parameter + Dim_Date)

| Column | Derivation |
|---|---|
| YearWeekNumber | CAST(YEAR(@date), '-', SSWeekNumberOfYear) — e.g., '2026-15' |
| SSWeekNumberOfYear | DWH_dbo.Dim_Date.SSWeekNumberOfYear WHERE DateKey = @dateID |
| CalendarYear | DWH_dbo.Dim_Date.CalendarYear |
| FirstDayOfWeek | DATEADD(dd, -(DATEPART(dw, @date)-1), @date) |

### Weekly Aggregated Columns (from #dailysum — MAX or SUM across the week's days)

**MAX aggregates** (flag/snapshot semantics — highest value seen across the week):
ActiveUser, Active, ActiveOpen, IsOpen_Copy, IsOpen_CopyPortfolio, Active_Copy, Active_Real_Stocks, Active_CFD_Stocks, Active_Real_Crypto, Active_CFD_Crypto, Active_FX/Comm/Ind, Active_FX, Active_Comm, Active_Ind, Active_Real_Stocks_Lev1, Active_CFD_Stocks_LevCFD, Active_Real_Crypto_Lev1, Active_CFD_Crypto_LevCFD, ActiveOpen_Copy, ActiveOpen_Real_Stocks, ActiveOpen_CFD_Stocks, ActiveOpen_Real_Crypto, ActiveOpen_CFD_Crypto, ActiveOpen_FX/Comm/Ind, ActiveOpen_FX, ActiveOpen_Comm, ActiveOpen_Ind, ActiveOpen_AirDrop, ActiveOpen_Mirror, ActiveOpen_Manual, ActiveOpen_IncludeCopy, ActiveOpen_Real_Stocks_Lev1, ActiveOpen_CFD_Stocks_LevCFD, ActiveOpen_Real_Crypto_Lev1, ActiveOpen_CFD_Crypto_LevCFD, EOW_IsFunded, IsFunded_New, Reg_Month, RegDate, IsReg_ThisW, IsFTD_ThisW, FTDdate, FTDA, LastApplicationProAccountDate, LastPosOpenDate, LastLoggedIn

**SUM aggregates** (flow metric — cumulative over the week's days):
Count_Opened_Copy, Count_Closed_Copy, MoneyIn_Copy, MoneyOut_Copy, Count_Opened_CopyPortfolio, Count_Closed_CopyPortfolio, MoneyIn_CopyPortfolio, MoneyOut_CopyPortfolio, NewTrades_Copy, NewTrades_Real_Stocks, NewTrades_CFD_Stocks, NewTrades_Real_Crypto, NewTrades_CFD_Crypto, NewTrades_FX/Comm/Ind, NewTrades_Total, NewTrades_Real_Stocks_Lev1, NewTrades_CFD_Stocks_LevCFD, NewTrades_Real_Crypto_Lev1, NewTrades_CFD_Crypto_LevCFD, AmountIn_NewTrades_* (all variants), Revenue_* (all variants), Transactional_Revenue_Total, Revenue_TicketFeeByPercent, PnL_* (all variants), TotalDeposits, CountDeposits, TotalCashouts, TotalCoFee, NetDeposits, WithdrawalToWallet, CashoutsAdjusted, ACC_Revenue_* (all variants), ACC_PnL_* (all variants), ACC_TotalDeposits, ACC_CountDeposits, ACC_TotalCashouts, ACC_TotalCoFee, ACC_NetDeposits, ACC_WithdrawalToWallet

**Note on ACC_ columns**: In the weekly panel, ACC_ columns are `SUM(daily_ACC_value)` across the week's days — i.e., sum of daily lifetime running totals, NOT a weekly self-referencing accumulator (unlike the MonthlyPanel pattern). This is an unusual aggregation choice; see usage notes in main wiki.

### ETL Metadata

| Column | Source |
|---|---|
| UpdateDate | GETDATE() at SP execution time |

## OpsDB Orchestration

| Property | Value |
|---|---|
| SP | BI_DB_dbo.SP_CID_WeeklyPanel_FullData |
| Target Table | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData |
| Priority | 0 (base layer — no intra-schema dependencies) |
| Process | SB_Daily |
| ProcessType | SQL (1) |
| Frequency | Daily |
| OpsDB Dependency | SP_CID_DailyPanel_FullData → BI_DB_CID_DailyPanel_FullData |

## Columns Excluded vs DailyPanel

The following DailyPanel columns are **not included** in the WeeklyPanel:

| Column | Reason |
|---|---|
| Active_Month, ActiveDate | Replaced by weekly grain identifiers (YearWeekNumber, FirstDayOfWeek) |
| FTD_Month | Not carried to weekly aggregation (FTDdate/FTDA available) |
| FirstAction, FirstInstrument | Always NULL in DailyPanel SP; excluded from weekly |
| AccountManager | Not aggregated into weekly |
| IsIslamic | Not aggregated into weekly |
| IsContacted, IsContactedAmount | Not aggregated into weekly |
| ACC_ChurnDays | In #dailydata SELECT but not aggregated into #dailysum or INSERT |
| FirstNewFundedDate | Not aggregated into weekly |
| ACC_Transactional_Revenue_Total | Not accumulated in weekly SP |
| Daily_Classification (renamed) | Renamed to Weekly_Classification; always empty string |
