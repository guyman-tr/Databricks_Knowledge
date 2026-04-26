# Lineage: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData

## Writer SP

| SP | Priority | Frequency | Process |
|----|----------|-----------|---------|
| `BI_DB_dbo.SP_CID_DailyPanel_FullData` | 0 | Daily | SB_Daily |

**ETL Pattern**: DELETE WHERE DateID = @startDateINT + INSERT. Not partition-switch (despite the naming of companion SPs). Runs at Priority 0 — base layer, no intra-schema dependencies on other BI_DB computed tables.

**Partition scheme**: RANGE LEFT on DateID with daily partitions from 20180101 to 20260531. Partition switching used only in companion SPs for bulk historical loads.

---

## Source Tables

### Direct Inputs to SP_CID_DailyPanel_FullData

| Source Table | Schema | Role | Columns Fed |
|---|---|---|---|
| `Fact_SnapshotCustomer` | DWH_dbo | Population filter (IsDepositor=1) + regulation, player level, country, pro status | EOD_Regulation, EOD_Club (via Dim_PlayerLevel JOIN), IsPro, V2_Complete, V3_Complete, RegulationID |
| `Dim_Range` | DWH_dbo | Date range lookup for Fact_SnapshotCustomer SCD2 | Used in all Fact_SnapshotCustomer JOINs |
| `Dim_Customer` | DWH_dbo | Customer demographics: registration date, FTD date, islamic flag | Reg_Month, RegDate, FTDdate, FTD_Month, FTDA, IsIslamic |
| `V_Liabilities` | DWH_dbo | EOD equity, AUM, credit balance | Equity, RealizedEquity, AUM, Credit |
| `Dim_PlayerLevel` | DWH_dbo | Club tier lookup (Name) | EOD_Club (LowBronze/HighBronze computed; Silver–Diamond from Name) |
| `Dim_Regulation` | DWH_dbo | Regulation name lookup | EOD_Regulation |
| `Dim_Country` | DWH_dbo | Country and region lookup | Country, Region |
| `Dim_Manager` | DWH_dbo | Account manager name | AccountManager |
| `Dim_Position` | DWH_dbo | All open/closed positions for the date | Active_*, ActiveOpen_*, NewTrades_*, AmountIn_*, PnL_* columns |
| `Dim_Mirror` | DWH_dbo | New mirror-copy relationships opened on the date | ActiveOpen_Mirror, ActiveOpen_NewMirror |
| `Dim_Instrument` | DWH_dbo | Instrument type lookup (InstrumentTypeID) | Used in instrument-type CASE logic throughout |
| `Fact_CustomerAction` | DWH_dbo | Deposits (7), cashouts (8), logins (14), copy start (17), copy end (18), mirror add (15) | TotalDeposits, CountDeposits, TotalCashouts, ActiveUser, IsOpen_Copy, Count_Opened_Copy, Count_Closed_Copy, MoneyIn_Copy, MoneyOut_Copy, IsOpen_CopyPortfolio, WithdrawalToWallet |
| `Fact_FirstCustomerAction` | DWH_dbo | First position open / first login date | FirstActionDate (used for NewFundedAccounts check) |
| `BI_DB_PositionPnL` | BI_DB_dbo | Position-level daily PnL | EOD_Equity_* by instrument, PnL calculation in #All_Positions |
| `BI_DB_DailyCommisionReport` | BI_DB_dbo | Daily revenue (FullCommissions + RollOverFee) by instrument | Revenue_Copy, Revenue_Real_Stocks, Revenue_CFD_Stocks, Revenue_Real_Crypto, Revenue_CFD_Crypto, Revenue_FX/Comm/Ind, Revenue_FX, Revenue_Comm, Revenue_Ind |
| `BI_DB_CIDFirstDates` | BI_DB_dbo | First-event dates per customer: FTD, channel, affiliate | Channel, SubChannel, AffiliateID, FirstNewFundedDate, FTDdate cross-check |
| `BI_DB_NewBonusReport` | BI_DB_dbo | Contact/bonus events for the date | IsContacted, IsContactedAmount |
| `BI_DB_CID_LifeStageDefinition` | BI_DB_dbo | Life stage definitions by date range | EOD_LSD |
| `BI_DB_V_DDR_Daily_Panel` | BI_DB_dbo | DDR-derived cashout adjustment | CashoutsAdjusted |
| `External_BI_OUTPUT_Customer_ProfessionalCustomers` | BI_DB_dbo | Professional client applications | IsPro (cross-check), LastApplicationProAccountDate |
| `BI_DB_CID_DailyPanel_FullData` (self) | BI_DB_dbo | Previous day's row for ACC_ running totals | All ACC_* columns seeded from yesterday's values |

### Revenue Function Inputs

| Function | Schema | Role | Columns Fed |
|---|---|---|---|
| `Function_Revenue_ConversionFee` | BI_DB_dbo | Currency conversion fees on deposits/cashouts | Revenue_ConversionFees |
| `Function_Revenue_AdminFee` | BI_DB_dbo | Islamic admin fee (weekend/swap-free fee component) | Revenue_IslamicFees (part 1) |
| `Function_Revenue_SpotAdjustFee` | BI_DB_dbo | Spot adjust fee for Islamic accounts | Revenue_IslamicFees (part 2) |
| `Function_Revenue_TicketFee` | BI_DB_dbo | Per-trade ticket fee for stock positions | Revenue_TicketFees, Revenue_Real_Stocks (added), Revenue_Real_Stocks_Lev1 (added) |
| `Function_Revenue_TicketFeeByPercent` | BI_DB_dbo | Percentage-based ticket fee by instrument type | Revenue_TicketFeeByPercent, Revenue_Copy (added), Revenue_CFD_Stocks (added), Revenue_CFD_Crypto (added), Revenue_FX/Comm/Ind (added) |

---

## OpsDB Dependencies (SP_CID_DailyPanel_FullData reads from)

| Source SP | Source Table | Source Priority | Note |
|---|---|---|---|
| `SP_CIDFirstDates` | `BI_DB_CIDFirstDates` | 90 | FirstNewFundedDate, channel |
| `SP_DailyCommisionReport` | `BI_DB_DailyCommisionReport` | 20 | Revenue base |
| `SP_CID_LifeStageDefinition` | `BI_DB_CID_LifeStageDefinition` | 0 | EOD_LSD |
| `SP_NewBonusReport` | `BI_DB_NewBonusReport` | 0 | IsContacted |
| `SP_ClubChangeLogProduct` | `BI_DB_ClubChangeLogProduct` | 20 | Club history (not read directly but part of lineage chain) |
| `SP_DDR` | `BI_DB_DDR_CID_Level` | 90 | OpsDB metadata dep; not directly queried in SP code |

---

## Column Lineage Map

```
[Fact_SnapshotCustomer IsDepositor=1]
  └─→ Population base (#Depositors): all depositors on the date

[Fact_SnapshotCustomer + Dim_Range + Dim_Country + Dim_PlayerLevel + Dim_Regulation + Dim_Manager + Dim_Customer]
  └─→ #CIDs (main customer profile temp table)
       ├── CID, Reg_Month, RegDate, IsReg_ThisD
       ├── FTD_Month, FTDdate, IsFTD_ThisD, FTDA
       ├── Region, Country, NewMarketingRegion, Channel, SubChannel, AffiliateID
       ├── V2_Complete, V3_Complete, Seniority_Seg
       ├── LastPosOpenDate (from #LastPosOpen ← Fact_CustomerAction AT=1,2)
       ├── LastLoggedIn   (from #LastLoggin ← Fact_CustomerAction AT=14)
       ├── IsPro          (from Fact_SnapshotCustomer MifidCategorizationID IN 2,3)
       ├── IsOTD          (from #OTD ← Fact_CustomerAction AT=7, count=1)
       ├── EOD_Club       (CASE: Equity<1000&PL=1→LowBronze, PL=1→HighBronze, else Dim_PlayerLevel.Name)
       ├── EOD_Regulation (Dim_Regulation.Name)
       ├── Equity, RealizedEquity, AUM, Credit  (from #vl ← DWH_dbo.V_Liabilities)
       ├── IsIslamic      (Dim_Customer.WeekendFeePrecentage=0 → 1)
       ├── IsContacted    (from #IsContacted ← BI_DB_NewBonusReport)
       ├── AccountManager (Dim_Manager.FirstName+LastName)
       └── LastApplicationProAccountDate (from #ProAccount ← External_BI_OUTPUT_Customer_ProfessionalCustomers)

[Dim_Position + Dim_Instrument + BI_DB_PositionPnL]
  └─→ #All_Positions (per-position detail for the date)
       ├── #Active  → Active_Copy/_Real_Stocks/_CFD_Stocks/_Real_Crypto/_CFD_Crypto/_FX_Comm_Ind (+ Lev1/LevCFD)
       └── #ActiveOpen → ActiveOpen_* + NewTrades_* + AmountIn_NewTrades_*

[Dim_Mirror + Fact_CustomerAction AT=15]
  └─→ ActiveOpen_NewMirror, ActiveOpen_AddMirror → ActiveOpen, ActiveOpen_Mirror

[Fact_CustomerAction AT=7,8,14,30]
  └─→ #Cashier → TotalDeposits, CountDeposits, TotalCashouts, TotalCoFee, ActiveUser, WithdrawalToWallet

[Fact_CustomerAction AT=17,15,16,18 + Dim_Mirror]
  └─→ #Copy → IsOpen_Copy, Count_Opened_Copy, Count_Closed_Copy, MoneyIn_Copy, MoneyOut_Copy
               IsOpen_CopyPortfolio, Count_Opened_CopyPortfolio, Count_Closed_CopyPortfolio, MoneyIn_CopyPortfolio, MoneyOut_CopyPortfolio

[BI_DB_DailyCommisionReport (FullCommissions + RollOverFee) + Function_Revenue_Ticket/TicketFeeByPercent]
  └─→ #rev + #rev_ticketfees + #rev_crypto_ticketfees
       └─→ Revenue_Copy, Revenue_Real_Stocks, Revenue_CFD_Stocks, Revenue_Real_Crypto,
           Revenue_CFD_Crypto, Revenue_FX/Comm/Ind, Revenue_FX, Revenue_Comm, Revenue_Ind,
           Revenue_Total, Revenue_TicketFeeByPercent

[Function_Revenue_AdminFee + Function_Revenue_SpotAdjustFee]
  └─→ Revenue_IslamicFees

[Function_Revenue_ConversionFee]
  └─→ Revenue_ConversionFees

[Function_Revenue_TicketFee]
  └─→ Revenue_TicketFees

[#All_Positions PnL calculation]
  └─→ #pnl → PnL_Copy, PnL_Real_Stocks, PnL_CFD_Stocks, PnL_Real_Crypto,
              PnL_CFD_Crypto, PnL_FX/Comm/Ind, PnL_FX, PnL_Comm, PnL_Ind, PnL_Total

[BI_DB_PositionPnL + Dim_Instrument]
  └─→ #EOD_Equities → EOD_Equity_Copy, EOD_Equity_Real_Stocks, EOD_Equity_CFD_Stocks,
                       EOD_Equity_Real_Crypto, EOD_Equity_CFD_Crypto, EOD_Equity_FX/Comm/Ind,
                       EOD_Equity_Real_Crypto_Lev1, EOD_Equity_Real_Stocks_LevCFD,
                       EOD_Equity_CFD_Crypto_Lev1, EOD_Equity_CFD_Stocks_LevCFD

[BI_DB_CIDFirstDates]
  └─→ Channel, SubChannel, AffiliateID, FirstNewFundedDate (cross-check for IsFunded_New)

[BI_DB_CID_LifeStageDefinition]
  └─→ EOD_LSD

[BI_DB_V_DDR_Daily_Panel]
  └─→ CashoutsAdjusted = TPCashoutsOldDef - CashoutAdjustment - TransferCoins

[BI_DB_CID_DailyPanel_FullData (self, DateID=yesterday)]
  └─→ #History → ACC_Revenue_*, ACC_PnL_*, ACC_TotalDeposits, ACC_CountDeposits,
                  ACC_TotalCashouts, ACC_TotalCoFee, ACC_NetDeposits, ACC_WithdrawalToWallet,
                  ACC_ChurnDays, ACC_Transactional_Revenue_Total
```

---

## Downstream Consumers

| Object | Schema | How Used |
|---|---|---|
| `BI_DB_CID_DailyPanel_Club` | BI_DB_dbo | Sibling Club panel — overlapping population (Club-eligible customers), comparable column schema |
| `BI_DB_CID_MonthlyPanel_FullData` | BI_DB_dbo | Monthly rollup of same customer population |
| `BI_DB_CID_WeeklyPanel_FullData` | BI_DB_dbo | Weekly rollup of same customer population |
| Tableau/BI reports | External | CRM and Account Management dashboards |
| Unity Catalog | main.bi_db | Target pending migration (`_Not_Migrated`) |

---

## Instrument Type Classification Reference

| Condition | Label |
|---|---|
| `MirrorID > 0` | Copy |
| `InstrumentTypeID IN (5,6) AND IsSettled=1` (or `Leverage=1 AND IsBuy=1`) | Real Stocks (Lev1) |
| `InstrumentTypeID IN (5,6) AND IsSettled=0` (or `Leverage>1 OR IsBuy=0`) | CFD Stocks (LevCFD) |
| `InstrumentTypeID=10 AND IsSettled=1` (or `Leverage=1 AND IsBuy=1`) | Real Crypto (Lev1) |
| `InstrumentTypeID=10 AND IsSettled=0` (or `Leverage>1 OR IsBuy=0`) | CFD Crypto (LevCFD) |
| `InstrumentTypeID IN (1,2,4)` | FX/Comm/Ind |
| `InstrumentTypeID=1` | FX (Currencies) |
| `InstrumentTypeID=2` | Comm (Commodities) |
| `InstrumentTypeID=4` | Ind (Indices) |
