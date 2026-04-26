# BI_DB_dbo.BI_DB_CopyMilestone — Lineage

**Generated**: 2026-04-23  
**Writer SP**: SP_CopyMilestone  
**Load Pattern**: DELETE WHERE Date=@date + INSERT (append-only historical table)  

---

## Source Objects

| Object | Schema | Type | Role |
|---|---|---|---|
| BI_DB_CopyDailyData | BI_DB_dbo | Table | Base population: all active PIs and Portfolio accounts for @date; also used for 7-day-ago copier count lookup and historical-max copier count milestone detection |
| DWH_GainDaily | BI_DB_dbo | Table | Monthly (Gain_m) and yearly (Gain_y) gain metrics for up to 12 months and 5 calendar years of history; drives all streak flags and MTD up/down indicators |

---

## Writer

| SP | Load Pattern | Parameters |
|---|---|---|
| SP_CopyMilestone | DELETE WHERE @date=Date + INSERT | @date date |

---

## Downstream Consumers

None identified in the SSDT repository. Used as a milestone event feed for PI performance reporting and account manager alerts.

---

## ETL Data Flow

```
[Base Population]
BI_DB_CopyDailyData WHERE Date = @date
  → #CopiedPop (all active PIs/Portfolio managers on @date: CID, UserName, CopyType, NumOfCopiers)
  CREATE CLUSTERED INDEX ON #CopiedPop (CID)

[7-Day Copier Change]
#CopiedPop (today) JOIN BI_DB_CopyDailyData WHERE DateID = @date_int7daysAgo
  today.NumOfCopiers - 7daysAgo.NumOfCopiers → CopiersGained
  CASE WHEN CopiersGained > 100 THEN 1 ELSE 0 → GainMoreThen100Copiers
  → #CopiersGained

[Milestone Copier Threshold Crossing]
BI_DB_CopyDailyData (all dates < @date-1) → MAX(NumOfCopiers) per CID (historical high-water mark)
JOIN BI_DB_CopyDailyData (DateID = @date_int) on same CID
  PI thresholds (exclusive range bands — fires exactly once per band crossing):
    current > 1000 AND current < 1500 AND hist_max <= 1000 → PI_Passing_1000_Copiers=1
    current > 1500 AND current < 2000 AND hist_max <= 1500 → PI_Passing_1500_Copiers=1
    current > 2000 AND current < 2500 AND hist_max <= 2000 → PI_Passing_2000_Copiers=1
    current > 2500 AND current < 3000 AND hist_max <= 2500 → PI_Passing_2500_Copiers=1
    current > 3000 AND current < 3500 AND hist_max <= 3000 → PI_Passing_3000_Copiers=1
    current > 3500 AND current < 4000 AND hist_max <= 3500 → PI_Passing_3500_Copiers=1
    current > 4000 AND hist_max <= 4000 → PI_Passing_4000_Copiers=1
  Portfolio threshold:
    current > 1000 AND hist_max <= 1000 → CopyPortfolio_Passing_1000_Investors=1
  → #CopiersPassed

[Monthly / Yearly Profit Streaks]
#CopiedPop JOIN DWH_GainDaily ON gd.CID = cp.CID
  Month-end profit flags (N=1..12):
    MAX(CASE WHEN gd.Date = DATEADD(DAY,1,EOMONTH(@date,-N)) AND gd.Gain_m > 0 THEN 1 ELSE 0)
    → MonthAgoInProfit … Month12AgoInProfit
  Year-start profit flags (N=0..4):
    MAX(CASE WHEN gd.Date = DATEADD(yy,DATEDIFF(yy,0,@date)-N,0) AND gd.Gain_y > 0 THEN 1 ELSE 0)
    → LastYearInProfit … Year5InProfit
  MTD gain flags (as of @date):
    MAX(CASE WHEN gd.Date = @date AND gd.Gain_m > 0.05 THEN 1 ELSE 0) → Up5Percent30Days
    MAX(CASE WHEN gd.Date = @date AND gd.Gain_m < -0.05 THEN 1 ELSE 0) → Down5Percent30Days
  Streak aggregation:
    SUM(MonthAgo..Month6Ago) = 6 → Months6InRow=1
    SUM(MonthAgo..Month12Ago) = 12 → Month12InRow=1
    SUM(LastYear..Year3) = 3 → Year3InRow=1
    SUM(LastYear..Year4) = 4 → Year4InRow=1
    SUM(LastYear..Year5) = 5 → Year5inRow=1
  → #Profit

[Assembly]
#CopiedPop
LEFT JOIN #Profit ON cp.CID = pr.CID
LEFT JOIN #CopiersGained ON cp.CID = cg.CID
LEFT JOIN #CopiersPassed ON cp.CID = cpo.CID

DELETE FROM BI_DB_CopyMilestone WHERE @date = Date   -- idempotent re-run safety
INSERT INTO BI_DB_CopyMilestone (..., UpdateDate = GETDATE())
```
