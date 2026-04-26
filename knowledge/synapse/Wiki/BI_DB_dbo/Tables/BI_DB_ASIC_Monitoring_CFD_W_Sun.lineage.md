# Lineage: BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD_W_Sun

**Writer SP**: `SP_ASIC_Monitoring_CFD_W_Sun` (Priority 0, Weekly Sunday)
**Pattern**: DELETE WHERE Date=@Date + INSERT (weekly append — full history retained)
**UC Target**: `_Not_Migrated`

## ETL Chain

```
DWH_dbo.Fact_SnapshotCustomer (RegulationID IN(4,10), @DateID in range)
  JOIN DWH_dbo.Dim_Range
  JOIN DWH_dbo.Dim_Customer (RegisteredReal)
  JOIN DWH_dbo.Dim_Country (Country name)
  JOIN DWH_dbo.Dim_PlayerLevel (Club name)
  JOIN DWH_dbo.Dim_Manager (AccountManager = FirstName+LastName)
  LEFT JOIN BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market
    (exclude CFD_Status≠'CFD_Allowed')
    → #pop (FCA+ASIC customers eligible for CFD monitoring, ~375K)

BI_DB_dbo.BI_DB_PositionPnL (DateID in [@DateID7DaysAgo, @DateID))
  JOIN #pop
    → #7DaysDailyPnL → #AVG7DaysPnL (A1 avg equity computation)

DWH_dbo.Dim_Position (CloseDateID in [@DateID6MonthAgo, @DateID), IsSettled=0, MirrorID=0)
  JOIN #pop
  JOIN DWH_dbo.Dim_ClosePositionReason
  JOIN DWH_dbo.Dim_Instrument (InstrumentTypeID for leverage thresholds)
    → #ClosedManualCFD6Months
      → #LossInvestmentRatio (A2)
      → #BSL_CloseReason (A4, ClosePositionReasonID=16)
      → #TotalMaxLeverage → #RatioCalcMaxLeverage (A6)

DWH_dbo.Fact_CustomerAction (DateID in [@DateID6MonthAgo, @DateID), CompensationReasonID=11)
  JOIN #pop
    → #Compensation (A5 negative balance)

DWH_dbo.Dim_Position (CloseDateID < @DateID, all time)
  JOIN #pop
    → #ClosedPosToDate (TotalNetProfit, TotalManualCFD_NetProfit)

BI_DB_dbo.BI_DB_PositionPnL (DateID=@DateID — open positions at date)
  JOIN #pop
    → #PnlEquityAtDate (PnLManualCFD, TotalPnL, EquityManualCFD, TotalEquity)

DWH_dbo.Fact_CustomerAction (ActionTypeID IN(7,8), all time)
  JOIN #pop
    → #TotalDepositsWithdraws (NetDeposits)

DELETE WHERE Date=@Date → INSERT BI_DB_ASIC_Monitoring_CFD_W_Sun
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | SP parameter | @Date | ETL run date | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 2 | RealCID | Fact_SnapshotCustomer | RealCID | Direct | T1 — Customer.CustomerStatic |
| 3 | RegisteredReal | Dim_Customer | RegisteredReal | Direct (via GCID JOIN) | T1 — Customer.CustomerStatic |
| 4 | Country | Dim_Country | Name | Lookup via Fact_SnapshotCustomer.CountryID | T1 — Dictionary.Country |
| 5 | Club | Dim_PlayerLevel | Name | Lookup via Fact_SnapshotCustomer.PlayerLevelID | T1 — Dictionary.PlayerLevel |
| 6 | AccountManager | Dim_Manager | FirstName, LastName | Concat: FirstName+' '+LastName | T1 — BackOffice.Manager |
| 7 | Is_PI | Fact_SnapshotCustomer | GuruStatusID | CASE: GuruStatusID>=2 → 1 else 0 | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 8 | A1_ConcentrationRisk_Ind | #AVG7DaysPnL | FinalAvgEquity | CASE: FinalAvgEquity>0.5 → 1 else 0 | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 9 | A1_FinalAvgEquity | BI_DB_PositionPnL | Amount, PositionPnL | AVG(EquityManualCFD)/AVG(TotalEquity) per CID over 7 days | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 10 | A2_LossInvestmentRatio_Ind | Dim_Position | NetProfit, Amount | MAX(CASE: ABS(NetProfit)/Amount>0.5) for manual CFD in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 11 | A2_LossInvestmentRatio_CountPos | Dim_Position | NetProfit, Amount | COUNT of positions where ABS(NetProfit)/Amount>0.5 in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 12 | A4_Last_BSL_Date_Ind | Dim_Position | ClosePositionReasonID | MAX(CASE: ClosePositionReasonID=16) in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 13 | A4_Last_BSL_Date_MaxDate | Dim_Position | CloseOccurred | MAX(CloseOccurred) where ClosePositionReasonID=16 in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 14 | A5_NegativeBalance_Ind | Fact_CustomerAction | CompensationReasonID | MAX(CASE: CompensationReasonID=11) in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 15 | A5_Last_NegativeBalance_Date_MaxDate | Fact_CustomerAction | DateID | MAX(DateID where CompensationReasonID=11) → CAST to date | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 16 | A6_HighLeverageTrading_Ind | Dim_Position | Leverage, InstrumentTypeID | CASE: MaxLeverage positions/TotalPositions>0.5 in 6m | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 17 | TotalNetProfit | Dim_Position | NetProfit | SUM(NetProfit) for all closed positions to date (all time) | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 18 | TotalManualCFD_NetProfit | Dim_Position | NetProfit | SUM(NetProfit) for closed manual non-settled positions to date | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 19 | PnLManualCFD | BI_DB_PositionPnL | PositionPnL | SUM(PositionPnL) for open manual CFD positions at @DateID | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 20 | TotalPnL | BI_DB_PositionPnL | PositionPnL | SUM(PositionPnL) for all open positions at @DateID | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 21 | EquityManualCFD | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) for open manual CFD positions at @DateID | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 22 | TotalEquity | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) for all open positions at @DateID | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 23 | NetDeposits | Fact_CustomerAction | Amount | SUM(deposits ActionTypeID=7) - SUM(withdrawals ActionTypeID=8) all time | T2 — SP_ASIC_Monitoring_CFD_W_Sun |
| 24 | LastUpdateDate | SP | GETDATE() | ETL timestamp | Propagation |

## Tier Summary

- **Tier 1**: 5 (RealCID, RegisteredReal, Country, Club, AccountManager)
- **Tier 2**: 18 (Date, Is_PI, A1_ConcentrationRisk_Ind, A1_FinalAvgEquity, A2_LossInvestmentRatio_Ind, A2_LossInvestmentRatio_CountPos, A4_Last_BSL_Date_Ind, A4_Last_BSL_Date_MaxDate, A5_NegativeBalance_Ind, A5_Last_NegativeBalance_Date_MaxDate, A6_HighLeverageTrading_Ind, TotalNetProfit, TotalManualCFD_NetProfit, PnLManualCFD, TotalPnL, EquityManualCFD, TotalEquity, NetDeposits)
- **Propagation**: 1 (LastUpdateDate)
