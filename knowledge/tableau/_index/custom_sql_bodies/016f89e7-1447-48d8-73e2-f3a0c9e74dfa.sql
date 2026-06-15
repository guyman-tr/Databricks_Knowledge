select revenue.OccurredMonth
	  ,revenue.DormantFee
	  ,revenue.CashoutFee
	  ,CO.CashoutCount
	  ,RollOver_Agg.RolloverFees
	  ,CO.Cashouts
	  ,RollOver_Agg.[AVG_InvestedAmount on Rollover Position (unlev)]
from 
(
SELECT EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID))) OccurredMonth
, SUM(ISNULL(ddr.DormantFee, 0))  DormantFee
, SUM(ISNULL(CashoutFee, 0)) CashoutFee

FROM [BI_DB_dbo].[BI_DB_DDR_TimeRange_Aggregated_Country_Level] ddr

WHERE ddr.Regulation = 'FCA' 
AND ddr.DateID>=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and ddr.DateID<=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND ddr.TimeRange = 'Yesterday' 
AND ddr.IsValidCustomer = 1 
AND ddr.IsCreditReportValidCB = 1
group by EOMONTH(CONVERT(datetime, convert(varchar(10), ddr.DateID)))
) revenue
left join 
(select EOMONTH(CAST(Occurred AS DATE)) OccurredMonth,
Sum(Amount)  Cashouts,
COUNT(1)  CashoutCount
from DWH_dbo.Fact_CustomerAction fca WITH (NOLOCK)
JOIN DWH_dbo.Dim_Customer dc WITH (NOLOCK) ON fca.RealCID = dc.RealCID
JOIN DWH_dbo.Dim_Country cn WITH (NOLOCK) ON cn.CountryID = dc.CountryID
where fca.DateID >=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and fca.DateID <= CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
and ActionTypeID = 8 
and IsRedeem <> 1
AND DesignatedRegulationID = 2 
AND dc.IsValidCustomer = 1
GROUP BY EOMONTH(CAST(Occurred AS DATE))
) CO on CO.OccurredMonth=revenue.OccurredMonth
left join 
(select
EOMONTH(CAST(OccurredDate AS DATE))  OccurredMonth,
SUM(Rollover)  RolloverFees, 
AVG([AVG_InvestedAmount on Rollover Position (unlev)])  [AVG_InvestedAmount on Rollover Position (unlev)]
from
(
SELECT dc.RealCID, fca.PositionID, CAST([fca].[Occurred] AS DATE)  OccurredDate, [fca].[DateID], [di].[InstrumentType], 0  [IsSettled]
,- SUM(fca.Amount)  Rollover,
 AVG(dp.Amount)  'AVG_InvestedAmount on Rollover Position (unlev)'

FROM [DWH_dbo].[Fact_CustomerAction] fca with (nolock)
JOIN [DWH_dbo].[Dim_Position] dp ON fca.PositionID = dp.PositionID
JOIN [DWH_dbo].Dim_Customer dc ON fca.RealCID = dc.RealCID
JOIN [DWH_dbo].Dim_Country dc1 ON dc1.CountryID = dc.CountryID
JOIN [DWH_dbo].Dim_Instrument di ON di.InstrumentID = dp.InstrumentID
WHERE ActionTypeID = 35 
AND IsFeeDividend = 1
AND fca.DateID >=CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)
and fca.DateID <=CAST(FORMAT(CAST(<[Parameters].[Parameter 3]> AS DATE),'yyyyMMdd') as INT)
AND DesignatedRegulationID = 2 
AND dc.IsValidCustomer = 1
AND fca.MirrorID = 0
GROUP BY dc.RealCID, fca.PositionID, CAST([fca].[Occurred] AS DATE), [fca].[DateID], [di].[InstrumentType]
)r
group by EOMONTH(CAST(OccurredDate AS DATE)) 
) RollOver_Agg ON revenue.OccurredMonth = RollOver_Agg.OccurredMonth