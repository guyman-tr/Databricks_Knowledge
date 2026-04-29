# Lineage — BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD

## Source Objects

| Source Object | Kind | Role | Wiki Available |
|---|---|---|---|
| `DWH_dbo.Fact_SnapshotCustomer` | Synapse table | Population base — ASIC-regulated customers as of @Date | Yes (bundle) |
| `DWH_dbo.Dim_Range` | Synapse table | Date-range filter for snapshot join | Yes (bundle) |
| `DWH_dbo.Dim_Customer` | Synapse table | RegisteredReal passthrough | Yes (bundle) |
| `DWH_dbo.Dim_Country` | Synapse table | Country name decode | Yes (bundle) |
| `DWH_dbo.Dim_PlayerLevel` | Synapse table | Club/tier name decode | Yes (bundle) |
| `DWH_dbo.Dim_Manager` | Synapse table | AccountManager name (FirstName + LastName) | Yes (bundle) |
| `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market` | Synapse table | Population filter — CFD_Allowed customers only | Yes (bundle) |
| `BI_DB_dbo.BI_DB_PositionPnL` | Synapse table | 7-day daily equity snapshot for A1 alert | Yes (bundle) |
| `DWH_dbo.Dim_Position` | Synapse table | Closed manual CFD positions (6-month window) for A2/A4/A6 alerts | Yes (bundle) |
| `DWH_dbo.Dim_ClosePositionReason` | Synapse table | BSL reason filter (ClosePositionReasonID=16) for A4 alert | Yes (bundle) |
| `DWH_dbo.Dim_Instrument` | Synapse table | Instrument type for max-leverage thresholds (A6 alert) | Yes (bundle) |
| `DWH_dbo.Fact_CustomerAction` | Synapse table | Negative balance compensation events (CompensationReasonID=11) for A5 alert | Yes (bundle) |

**Writer SP**: `BI_DB_dbo.SP_BI_DB_ASIC_Monitoring_CFD(@Date DATE)`
**ETL Pattern**: DELETE WHERE Date = @Date + INSERT from #FinalTable (daily incremental by date)

---

## Column Lineage

| # | Column | Source Object | Source Column / Expression | Tier | Notes |
|---|--------|---------------|---------------------------|------|-------|
| 1 | Date | ETL-computed | `@Date` (parameter) | Tier 2 | Reporting date injected by SP |
| 2 | RealCID | DWH_dbo.Fact_SnapshotCustomer | `fsc.RealCID` | Tier 1 | Passthrough from FSC population |
| 3 | RegisteredReal | DWH_dbo.Dim_Customer | `dc.RegisteredReal` | Tier 1 | Passthrough via GCID join |
| 4 | Country | DWH_dbo.Dim_Country | `dc1.Name` | Tier 1 | Join-enriched via `fsc.CountryID = dc1.CountryID` |
| 5 | Club | DWH_dbo.Dim_PlayerLevel | `dpl.Name` | Tier 1 | Join-enriched via `fsc.PlayerLevelID = dpl.PlayerLevelID` |
| 6 | AccountManager | DWH_dbo.Dim_Manager | `dm.FirstName + ' ' + dm.LastName` | Tier 2 | Computed concatenation via `fsc.AccountManagerID = dm.ManagerID` |
| 7 | A1_ConcentrationRisk_Ind | ETL-computed | `CASE WHEN FinalAvgEquity > 0.5 THEN 1 ELSE 0 END` | Tier 2 | Derived from #AVG7DaysPnL; FinalAvgEquity = AVG(EquityManualCFD) / AVG(TotalEquity) over 7 days |
| 8 | A1_FinalAvgEquity | BI_DB_dbo.BI_DB_PositionPnL | `AVG(Amount+PositionPnL) for IsSettled=0,MirrorID=0 / AVG(Amount+PositionPnL) total` | Tier 2 | 7-day average ratio; 0 when TotalEquity=0 |
| 9 | A2_LossInvestmentRatio_Ind | DWH_dbo.Dim_Position | `MAX(CASE WHEN ABS(NetProfit)/Amount > 0.5 AND NetProfit<0 THEN 1 ELSE 0 END)` | Tier 2 | 1 if any closed manual CFD position in last 6 months had loss > 50% of investment |
| 10 | A2_LossInvestmentRatio_CountPos | DWH_dbo.Dim_Position | `SUM(CASE WHEN ABS(NetProfit)/Amount > 0.5 AND NetProfit<0 THEN 1 ELSE 0 END)` | Tier 2 | Count of qualifying positions |
| 11 | A4_Last_BSL_Date_Ind | DWH_dbo.Dim_Position | `MAX(CASE WHEN ClosePositionReasonID=16 THEN 1 ELSE 0 END)` | Tier 2 | 1 if any position closed by BSL (below stop-loss / margin call) in last 6 months |
| 12 | A4_Last_BSL_Date_MaxDate | DWH_dbo.Dim_Position | `MAX(CASE WHEN ClosePositionReasonID=16 THEN CloseOccurred ELSE '1999-01-01' END)` | Tier 2 | Most recent BSL close date; '1999-01-01' sentinel when none |
| 13 | A5_NegativeBalance_Ind | DWH_dbo.Fact_CustomerAction | `MAX(CASE WHEN CompensationReasonID=11 THEN 1 ELSE 0 END)` | Tier 2 | 1 if customer received a negative-balance compensation event in last 6 months |
| 14 | A5_Last_NegativeBalance_Date_MaxDate | DWH_dbo.Fact_CustomerAction | `MAX(CASE WHEN CompensationReasonID=11 THEN DateID ELSE 19990101 END)` cast to date | Tier 2 | Date of most recent negative balance event; '1999-01-01' sentinel when none |
| 15 | A6_HighLeverageTrading_Ind | DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument | `CASE WHEN TotalPosMaxLeverage/TotalPosManualCFD > 0 THEN 1 ELSE 0 END` | Tier 2 | IsMaxLeverage per instrument type: Crypto>=2x, Forex>=30x, Commodity/Index>=20x, Stock/ETF>=5x |
| 16 | TotalNetProfit | DWH_dbo.Dim_Position | `SUM(dp.NetProfit) WHERE CloseDateID < @DateID` | Tier 2 | Sum of NetProfit for all closed positions to date (all types) |
| 17 | TotalManualCFD_NetProfit | DWH_dbo.Dim_Position | `SUM(dp.NetProfit) WHERE IsSettled=0 AND MirrorID=0 AND CloseDateID < @DateID` | Tier 2 | Sum of NetProfit for manual CFD closed positions only |
| 18 | LastUpdateDate | ETL-computed | `GETDATE()` | Tier 2 | ETL execution timestamp |

---

## Max-Leverage Thresholds (A6 Alert — from SP code)

| InstrumentTypeID | Asset Class | Max Leverage Threshold (IsMaxLeverage=1 if >=) |
|---|---|---|
| 10 | Crypto | 2× |
| 1 | Currencies (Forex) | 30× |
| 2 | Commodities | 20× |
| 4 | Indices | 20× |
| 5, 6 | Stocks / ETF | 5× |

---

*Lineage derived from SP_BI_DB_ASIC_Monitoring_CFD source code (bundle) + live data sampling.*
