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
Dealing.[dbo].[Dealing_DailyIndicesReport_Clients]
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
InstrumentID,
Hour_Start,
Hour_End,
sum(VolumeBuy+VolumeSell) TotalVolumeEtoro,
sum(NOP) NOPEtoro,
sum(ValueEnd+ValueRealized-ValueStart) EtoroPnL
from 
Dealing.[dbo].[Dealing_DailyIndicesReport_Etoro]
group by Date,
InstrumentID,
Hour_Start,
Hour_End) b
on a.Date=b.Date and a.Hour_Start=b.Hour_Start and a.InstrumentID=b.InstrumentID