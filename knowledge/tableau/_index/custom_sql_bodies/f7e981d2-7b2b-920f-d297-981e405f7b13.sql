select
	ISNULL(a.Date, b.Date) AS Date
   ,ISNULL(a.InstrumentID, b.InstrumentID) AS InstrumentID
   ,ISNULL(a.Minute_Start, b.Minute_Start) AS Minute_Start
   ,ISNULL(a.Minute_End, b.Minute_End) AS Minute_End
   ,a.Bid
   ,a.Ask
   ,a.TotalVolumeClients
   ,a.NOPClients
   ,ISNULL(a.TotalZeroClients,0) TotalZeroClients
   ,ISNULL(a.UnrealizedZeroClients, 0) AS TotalUnrealizedZeroClients
   ,ISNULL(a.RealizedZeroClients, 0) AS TotalRealizedZeroClients,
isnull(b.TotalVolumeEtoro,0)TotalVolumeEtoro,
isnull(b.NOPEtoro,0) NOPEtoro,
isnull(b.EtoroPnL,0)eToroPNL
from
(select 
Date,
InstrumentID,
Minute_Start,
Minute_End,
Bid,
Ask,
sum(VolumeBuy+VolumeSell) TotalVolumeClients,
sum(OP_Buy-OP_Sell)NOPClients,
Sum(UnrealizedEnd+Realized-UnrealizedStart)TotalZeroClients,
SUM(UnrealizedEnd-UnrealizedStart) UnrealizedZeroClients,
SUM(Realized) RealizedZeroClients
 from 
[Dealing_dbo].[Dealing_CommoditiesIntraHour_Clients]
WHERE CAST(Minute_End AS TIME) <> '00:00:00.000'
AND CAST(Minute_Start AS TIME) <> '00:00:00.000'
AND DATEPART(WEEKDAY, Date) NOT IN (1,7)
group by
Date,
InstrumentID,
Minute_Start,
Minute_End,
Bid,
Ask

UNION ALL

select 
Date,
InstrumentID,
Minute_Start,
Minute_End,
Bid,
Ask,
sum(VolumeBuy+VolumeSell) TotalVolumeClients,
sum(OP_Buy-OP_Sell)NOPClients,
Sum(UnrealizedEnd+Realized-UnrealizedStart)TotalZeroClients,
SUM(UnrealizedEnd-UnrealizedStart) UnrealizedZeroClients,
SUM(Realized) RealizedZeroClients
 from 
[Dealing_dbo].[Dealing_CommoditiesIntraHour_Clients]
WHERE CAST(Minute_End AS TIME) <> '00:00:00.000'
AND CAST(Minute_Start AS TIME) <> '00:00:00.000'
AND DATEPART(WEEKDAY, Date) = 1
AND CAST(Minute_Start AS TIME) >= '21:59:00.000'
group by
Date,
InstrumentID,
Minute_Start,
Minute_End,
Bid,
Ask) a

full join 

(select 
Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267,268, 269, 270, 271,272, 273, 274, 275,276, 280, 281, 284, 285) THEN 17
	 ELSE InstrumentID END InstrumentID,
Minute_Start,
Minute_End,
sum(VolumeBuy+VolumeSell) TotalVolumeEtoro,
sum(NOP) NOPEtoro,
sum(ValueEnd+ValueRealized-ValueStart) EtoroPnL
from 
[Dealing_dbo].[Dealing_CommoditiesIntraHour_Etoro]  
WHERE CAST(Minute_End AS TIME) <> '00:00:00.000'
AND CAST(Minute_Start AS TIME) <> '00:00:00.000'
AND DATEPART(WEEKDAY, Date) NOT IN (1,7)
group by Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267,268, 269, 270, 271,272, 273, 274, 275,276, 280, 281, 284, 285) THEN 17
	 ELSE InstrumentID END,
Minute_Start,
Minute_End

UNION ALL

select 
Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267,268, 269, 270, 271,272, 273, 274, 275, 276, 280, 281,284,285) THEN 17
	 ELSE InstrumentID END InstrumentID,
Minute_Start,
Minute_End,
sum(VolumeBuy+VolumeSell) TotalVolumeEtoro,
sum(NOP) NOPEtoro,
sum(ValueEnd+ValueRealized-ValueStart) EtoroPnL
from 
[Dealing_dbo].[Dealing_CommoditiesIntraHour_Etoro]  
WHERE CAST(Minute_End AS TIME) <> '00:00:00.000'
AND CAST(Minute_Start AS TIME) <> '00:00:00.000'
AND DATEPART(WEEKDAY, Date) = 1
AND CAST(Minute_Start AS TIME) >= '21:59:00.000'
group by Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267,268, 269, 270, 271,272, 273, 274, 275, 276, 280, 281,284,285) THEN 17
	 ELSE InstrumentID END,
Minute_Start,
Minute_End) b
on a.Date=b.Date and a.Minute_Start=b.Minute_Start and a.InstrumentID=b.InstrumentID