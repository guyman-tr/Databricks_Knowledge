with InitialData
(AccountPnL, ExecutedVolume, InstrumentID, PortfolioName, LowerBoundary, UpperBoundary, Date)
as
(
SELECT 
  sum(aa.AccountPnL) PnL
    ,sum(ABS(aa.NextHedgeTarget + aa.AccountPnL - aa.HedgeTarget)) ExecutedVolume
      ,aa.InstrumentID
      ,aa.PortfolioName
    , aa.LowerBoundary
    , aa.UpperBoundary
    ,cast(aa.PositionsTime as DATE) AS Date
FROM 
(
SELECT 
    IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.HourNopPnl
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.HourNopPnl, IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.HourNopPnl, power(ABS(aa.DeltaRatio), <[Parameters].[Parameter 3]>) * aa.HourNopPnl))
    ELSE ABS(aa.DeltaRatio) * aa.HourNopPnl
    end AccountPnL,  
    IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.NOP
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.NOP, IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.NOP, power(ABS(aa.DeltaRatio), <[Parameters].[Parameter 3]>) * aa.NOP))
    ELSE ABS(aa.DeltaRatio) * aa.NOP
    end HedgeTarget,  
    LEAD(IFNULL(bb.Multiplier, 1) *
    CASE
    WHEN bb.Strategy = 'NOP' THEN aa.NOP
    WHEN bb.UpperBoundary IS NOT NULL AND bb.LowerBoundary IS NOT NULL 
    THEN IFF(ABS(aa.DeltaRatio) > bb.UpperBoundary, bb.UpperBoundary * ABS(aa.DeltaRatio) * aa.NOP, IFF(ABS(aa.DeltaRatio) < bb.LowerBoundary, bb.LowerBoundary * ABS(aa.DeltaRatio) * aa.NOP, power(ABS(aa.DeltaRatio), <[Parameters].[Parameter 3]>) * aa.NOP))
    ELSE ABS(aa.DeltaRatio) * aa.NOP
    end) OVER (Partition By aa.InstrumentID Order by aa.PositionsTime asc) NextHedgeTarget
    ,bb.Label as PortfolioName
    , bb.LowerBoundary
    , bb.UpperBoundary
    , aa.InstrumentID
    , aa.PositionsTime
FROM 
main.bi_dealing_stg.bi_output_dealing_nixar_Delta_TheoreticalAccountPnLDaily aa
join main.bi_dealing_stg.bi_output_dealing_nixar_Delta_BacktestConfiguration bb on aa.InstrumentID = bb.InstrumentID  
where aa.Date between DATEADD(day, -90, <[Parameters].[Parameter 1]>) and <[Parameters].[Parameter 2]>
) aa
group by 
  aa.PortfolioName
  , aa.LowerBoundary
  , aa.UpperBoundary
  ,cast(aa.PositionsTime as DATE)
  ,aa.InstrumentID
),
InitialHC (PortfolioName, LowerBoundary, UpperBoundary, Date, InstrumentID, AccountPnL, ExecutedVolume)
as
(
select
 aa.PortfolioName
,aa.LowerBoundary
,aa.UpperBoundary
, aa.Date
, aa.InstrumentID
, COALESCE(aa.AccountPnL,0)
, COALESCE(aa.ExecutedVolume,0)
from 
InitialData aa
)
select f.*
, ddz.DailyZero
, ddz.DailyZero - f.AccountPnL as Hedgecost
, ddz.ZeroCumulative
, ddz.ZeroCumulative - f.AccountPnLCumulative as HedgecostCumulative
,i.Name as InstrumentName
,STDDEV(ddz.DailyZero - f.AccountPnL) OVER (PARTITION BY PortfolioName, f.InstrumentID) AS StdDev_Hedgecost
,MAX(ddz.ZeroCumulative - f.AccountPnLCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY f.Date
						   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm7
,MAX(ddz.ZeroCumulative - f.AccountPnLCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY f.Date
						   ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm30
,MAX(ddz.ZeroCumulative - f.AccountPnLCumulative) OVER (
						   PARTITION BY  PortfolioName, f.InstrumentID
						   ORDER BY f.Date
						   ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
					     ) AS MaxCumm90
from
(
select 
 aa.PortfolioName
,aa.LowerBoundary
,aa.UpperBoundary
, aa.InstrumentID
, aa.Date
, aa.AccountPnL
, aa.ExecutedVolume
, sum(aa.AccountPnL) OVER (Partition By aa.PortfolioName, aa.InstrumentID Order by aa.Date asc) as AccountPnLCumulative
, sum(aa.ExecutedVolume) OVER (Partition By aa.PortfolioName, aa.InstrumentID Order by aa.Date asc) as ExecutedVolumeCumulative
, row_number() OVER(Partition By aa.PortfolioName, aa.InstrumentID Order by Date desc) rn
, row_number() OVER(Partition By aa.PortfolioName, aa.InstrumentID Order by Date) rn_2
FROM
InitialHC aa
) f 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument i
on f.InstrumentID = i.InstrumentID
join 
(
select
InstrumentID,
Date,
TotalZero DailyZero,
sum(TotalZero) over (Partition By InstrumentID ORder by Date asc) ZeroCumulative
from
main.bi_dealing_stg.diffusion_daily_zero z 
)
ddz on 
f.InstrumentID = ddz.InstrumentID and f.Date = ddz.Date
where 
ddz.Date between DATEADD(day, -90, <[Parameters].[Parameter 1]>) and <[Parameters].[Parameter 2]>