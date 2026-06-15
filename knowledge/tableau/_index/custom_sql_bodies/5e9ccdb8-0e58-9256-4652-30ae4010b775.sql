SELECT 
	COALESCE(a.Date,b.Date) AS [Date]
   ,COALESCE(a.InstrumentID, b.InstrumentID, c.InstrumentID) AS InstrumentID
   ,c.InstrumentDisplayName
   ,a.Amount AS [Rollover_plus_Fee]
   ,case when coalesce(a.IsIslamic,b.IsIslamic) = 'Islamic' then 0 else dd.JeniaFigure end JeniaFigure
   ,a.PureROBuy
   ,a.PureEtoroFeeBuy
   ,b.PureROSell
   ,b.PureEtoroFeeSell
    ,coalesce(a.IsIslamic,b.IsIslamic) as IsIslamic
	,COALESCE(a.HedgeServerID, b.HedgeServerID) HedgeServerID
   from
(SELECT
  [a].[Date] AS [Date],
  [a].[InstrumentID] AS [InstrumentID],
  SUM([a].[Amount]) AS [Amount],
  SUM([a].[PureROBuy]) AS [PureROBuy],
  SUM([a].[PureEtoroFeeBuy]) AS [PureEtoroFeeBuy],
    a.IsIslamic,
a.HedgeServerID
FROM Dealing_dbo.Dealing_RolloverCommissionSplit [a] WITH (NOLOCK)
group by Date, InstrumentID, IsIslamic, HedgeServerID
) a


full outer join 

(
SELECT 
  [a].[Date] AS [Date],
  [a].[InstrumentID] AS [InstrumentID],
  SUM([a].[PureROSell]) AS [PureROSell],
  SUM([a].[PureEtoroFeeSell]) AS [PureEtoroFeeSell]
    ,a.IsIslamic
	,a.HedgeServerID
from 
Dealing_dbo.Dealing_RolloverCommissionSplit a with (NOLOCK)
GROUP BY a.Date, a.InstrumentID, a.IsIslamic, a.HedgeServerID
)b
on a.InstrumentID = b.InstrumentID and a.Date = b.Date and a.IsIslamic = b.IsIslamic and a.HedgeServerID = b.HedgeServerID
LEFT JOIN 
(
SELECT
bddcrc.InstrumentID
,bddcrc.Date
,SUM(bddcrc.RollOverFee) AS JeniaFigure
FROM
BI_DB_dbo.BI_DB_DailyCommoditiesReport_Clients bddcrc WITH (NOLOCK)
WHERE bddcrc.InstrumentID IN (17,22)
GROUP BY bddcrc.InstrumentID, bddcrc.Date
)dd ON dd.InstrumentID = COALESCE(a.InstrumentID, b.InstrumentID) AND dd.Date = COALESCE(a.Date, b.Date)
JOIN DWH_dbo.Dim_Instrument c WITH (NOLOCK) ON COALESCE(a.InstrumentID, b.InstrumentID) = c.InstrumentID