SELECT 
coalesce(z.Date,b.Date,c.Date) Date,
coalesce(z.HedgeServerID, c.HedgeServerID) HedgeServerID,
coalesce(z.InstrumentType,b.InstrumentType, c.InstrumentType)  InstrumentType,
coalesce(z.InstrumentName,b.InstrumentName,c.Instrument)  InstrumentName,
coalesce(z.InstrumentID,b.InstrumentID,c.InstrumentID) InstrumentID,
avg(isnull(z.TotalZero,0)) ClientsZero,
avg(isnull(z.FullCommission,0)) FullCommissions,
avg(isnull(z.RollOverFee,0)) RollOverFee,
avg(isnull(Dividend,0)) Dividend,
avg(ISNULL(RollOverFeeAndDividend,0)) RollOverFeePlusDividend,
avg(isnull(b.DailyAvg_EtoroSpread,0)) DailyAvg_EtoroSpread,
avg(isnull(b.DailyAvg_PPSpread,0)) DailyAvg_PPSpread,
sum(isnull(VolumeLP,0)) VolumeLP,
sum(isnull(z.TotalVolume,0)) VolumeClients
from 
 (
SELECT 
Date
, dv.InstrumentName
, dv.InstrumentType
, dv.HedgeServerID
, dv.InstrumentID
,SUM(ISNULL(dv.TotalZero,0)) TotalZero
,SUM(ISNULL(dv.FullCommission,0)) FullCommission
, SUM(ISNULL(dv.Dividend,0)) as Dividend
, SUM(ISNULL(dv.OverNightFee,0) + ISNULL(dv.Dividend,0))  as RollOverFeeAndDividend
, SUM(ISNULL(dv.OverNightFee,0)) AS RollOverFee
,SUM(ISNULL(dv.TotalVolume,0)) AS TotalVolume
FROM Dealing_dbo.Dealing_DealingDashboard_Clients dv
where dv.Date>= DATEADD(mm, -2, GETDATE())
and dv.InstrumentType IN ('Commodities','Indices','Currencies')
group by Date, InstrumentID, HedgeServerID, InstrumentName,InstrumentType) z 
full outer join  
(select 
Date, 
InstrumentID, 
InstrumentName,
InstrumentType,
avg(DailyAvg_EtoroSpread) DailyAvg_EtoroSpread,
avg(DailyAvg_PPSpread) DailyAvg_PPSpread
FROM Dealing_dbo.Dealing_DailyAvgSpread 
where Date>= DATEADD(mm, -2, GETDATE())
and InstrumentType IN ('Commodities','Indices','Currencies')
group by Date, InstrumentID, InstrumentName,InstrumentType) b
on z.InstrumentID=b.InstrumentID and z.Date=b.Date 
full outer join 
(select Date,
HedgeServerID, 
em.InstrumentID,
Instrument, 
InstrumentType,
sum(Volume) VolumeLP
FROM Dealing_dbo.Dealing_CEP_ExecutionMonitoring em
JOIN DWH_dbo.Dim_Instrument di 
ON em.InstrumentID=di.InstrumentID
where Date>= DATEADD(mm, -2, GETDATE())
and TranType = 'LP'
and InstrumentType in ('Commodities','Indices','Currencies')
group by Date,HedgeServerID, em.InstrumentID, Instrument, InstrumentType, TranType) c
on z.InstrumentID=c.InstrumentID 
and z.HedgeServerID=c.HedgeServerID 
and z.Date=c.Date
group by
coalesce(z.Date,b.Date,c.Date),
coalesce(z.HedgeServerID,c.HedgeServerID),
coalesce(z.InstrumentType,b.InstrumentType, c.InstrumentType),
coalesce(z.InstrumentName,b.InstrumentName,c.Instrument),
coalesce(z.InstrumentID,b.InstrumentID,c.InstrumentID)