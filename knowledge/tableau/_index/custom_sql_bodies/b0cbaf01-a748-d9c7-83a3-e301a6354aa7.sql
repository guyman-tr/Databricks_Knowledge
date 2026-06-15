With InitialZero
as
(
select
aa.Date as Date,
aa.InstrumentID,
sum(aa.TotalZero) as DailyZero
FROM
main.bi_dealing_stg.diffusion_daily_zero aa
join (SELECT DISTINCT InstrumentID from main.bi_dealing_stg.bi_output_dealing_nixar_Delta_BacktestConfiguration) bb on aa.InstrumentID = bb.InstrumentID
WHERE
aa.Date between DATEADD(day, -90, <[Parameters].[Parameter 1]>) and <[Parameters].[Parameter 2]>
group by
aa.Date,
aa.InstrumentID
)
, InitialData
(AccountPnL, ExecutedVolume, InstrumentID, PortfolioName, Date)
as
(
SELECT 
  sum(aa.AccountPnL) PnL
    ,sum(ABS(aa.NextHedgeTarget + aa.AccountPnL - aa.HedgeTarget)) ExecutedVolume
      ,aa.InstrumentID
      ,aa.PortfolioName
    ,cast(aa.PositionsTime as DATE) AS Date
FROM 
(
SELECT 
    IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.HourNopPnl
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.HourNopPnl,
         IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.HourNopPnl,
         power(ABS(aa.DeltaRatio),COALESCE(bb.Power,1)) * aa.HourNopPnl))
    ELSE ABS(aa.DeltaRatio) * aa.HourNopPnl
    end AccountPnL,  
    IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.NOP
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.NOP,
         IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.NOP,
         power(ABS(aa.DeltaRatio),COALESCE(bb.Power,1)) * aa.NOP))
    ELSE ABS(aa.DeltaRatio) * aa.NOP
    end HedgeTarget,  
    LEAD(IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.NOP
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.NOP,
         IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.NOP,
         power(ABS(aa.DeltaRatio),COALESCE(bb.Power,1)) * aa.NOP))
    ELSE ABS(aa.DeltaRatio) * aa.NOP
    end) OVER (Partition By aa.InstrumentID, bb.Label Order by aa.PositionsTime asc) NextHedgeTarget
    ,bb.Label as PortfolioName
    , aa.InstrumentID
    , aa.PositionsTime
FROM 
main.bi_dealing_stg.bi_output_dealing_nixar_Delta_TheoreticalAccountPnLDaily aa
join main.bi_dealing_stg.bi_output_dealing_nixar_Delta_BacktestConfiguration bb on aa.InstrumentID = bb.InstrumentID  
where aa.Date between DATEADD(day, -90, <[Parameters].[Parameter 1]>) and <[Parameters].[Parameter 2]>
) aa
group by 
  aa.PortfolioName
  ,cast(aa.PositionsTime as DATE)
  ,aa.InstrumentID
),
InitialHC (PortfolioName, Date, InstrumentID, HedgeCost, DailyZero, ExecutedVolume)
as
(
select
 aa.PortfolioName
, aa.Date
, aa.InstrumentID
, bb.DailyZero - COALESCE(aa.AccountPnL,0) as HedgeCost
, bb.DailyZero
, COALESCE(aa.ExecutedVolume,0)
from 
InitialData aa
join InitialZero bb using (InstrumentID, Date)
)
select f.*
,i.Name as InstrumentName
,STDDEV(HedgeCost) OVER (PARTITION BY PortfolioName, f.InstrumentID) AS StdDev_HedgeCost
,MIN(HedgeCostCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY Date
						   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm7
,MIN(HedgeCostCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY Date
						   ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm30
,MIN(HedgeCostCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY Date
						   ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm90
,MIN(HedgeCostCumulativePortfolio) OVER (
						   PARTITION BY  PortfolioName
						   ORDER BY Date
						   RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm7Portfolio
,MIN(HedgeCostCumulativePortfolio) OVER (
						   PARTITION BY  PortfolioName
						   ORDER BY Date
						   RANGE BETWEEN 29 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm30Portfolio
,MIN(HedgeCostCumulativePortfolio) OVER (
						   PARTITION BY  PortfolioName
						   ORDER BY Date
						   RANGE BETWEEN 89 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm90Portfolio
,SUM(HedgeCost) OVER (
						   PARTITION BY  PortfolioName
						   ORDER BY Date
						   RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
					     ) AS WeekHedgeCostPortfolio
,SUM(HedgeCost) OVER (
						   PARTITION BY  PortfolioName
						   ORDER BY Date
						   RANGE BETWEEN 29 PRECEDING AND CURRENT ROW
					     ) AS MonthHedgeCostPortfolio
,IFF(f.Date < <[Parameters].[Parameter 1]>, 0, 1) as IncudeID
from
(
select 
 aa.PortfolioName
, aa.InstrumentID
, aa.Date
, aa.HedgeCost
,aa.DailyZero
, aa.ExecutedVolume
, sum(aa.HedgeCost) OVER (Partition By aa.PortfolioName, aa.InstrumentID Order by aa.Date asc) as HedgeCostCumulative
, sum(aa.DailyZero) OVER (Partition By aa.PortfolioName, aa.InstrumentID Order by aa.Date asc) as ZeroCumulative
, sum(aa.HedgeCost) OVER (Partition By aa.PortfolioName Order by aa.Date asc) as HedgeCostCumulativePortfolio
, sum(aa.DailyZero) OVER (Partition By aa.PortfolioName Order by aa.Date asc) as DailyZeroCumulativePortfolio
, sum(aa.ExecutedVolume) OVER (Partition By aa.PortfolioName, aa.InstrumentID Order by aa.Date asc) as ExecutedVolumeCumulative
, row_number() OVER(Partition By aa.PortfolioName, aa.InstrumentID Order by Date desc) rn
, row_number() OVER(Partition By aa.PortfolioName, aa.InstrumentID Order by Date) rn_2
FROM
InitialHC aa
) f 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument i
on f.InstrumentID = i.InstrumentID