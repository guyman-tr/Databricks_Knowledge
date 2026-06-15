select
a.*,
isnull(b.TotalVolumeEtoro,0)TotalVolumeEtoro,
isnull(b.NOPEtoro,0) NOPEtoro,
isnull(b.EtoroPnL,0)EtoroPnL
from
(select 
Date,
InstrumentID,
Hour_Start,
Hour_End,
Bid,
Ask,
sum(VolumeBuy+VolumeSell) TotalVolumeClients,
sum(OP_Buy-OP_Sell)NOPClients,
Sum(UnrealizedEnd+Realized-UnrealizedStart)TotalZeroClients
 from 
[dbo].[BI_DB_DailyCommoditiesReport_Clients]
group by
Date,
InstrumentID,
Hour_Start,
Hour_End,
Bid,
Ask) a

left join 

(select 
Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267, 268, 269, 270, 271, 272) THEN 17
	 ELSE InstrumentID END InstrumentID,
Hour_Start,
Hour_End,
sum(VolumeBuy+VolumeSell) TotalVolumeEtoro,
sum(NOP) NOPEtoro,
sum(ValueEnd+ValueRealized-ValueStart) EtoroPnL
from 
[dbo].[BI_DB_DailyCommoditiesReport_Etoro]
group by Date,
CASE WHEN InstrumentID IN (150, 151) THEN 22
	 WHEN InstrumentID IN (266, 267,268, 269, 270, 271, 272) THEN 17
	 ELSE InstrumentID END,
Hour_Start,
Hour_End) b
on a.Date=b.Date and a.Hour_Start=b.Hour_Start and a.InstrumentID=b.InstrumentID