SELECT bddcr.FullDate
,bddcr.InstrumentID
,bddcr.Instrument
,bddcr.[InstrumentTypeID]
,bddcr.[InstrumentType]
,di.InstrumentDisplayName
,di.ReceivedOnPriceServer
,bddcr.FullCommissions
,bddcr.RollOverFee
FROM BI_DB.dbo.BI_DB_DailyCommisionReport bddcr
INNER JOIN DWH.dbo.Dim_Instrument di 
ON bddcr.InstrumentID = di.InstrumentID
WHERE bddcr.DateID >=20220101
and bddcr.InstrumentTypeID in (4,2,1)
GROUP BY 
bddcr.FullDate
,bddcr.InstrumentID
,bddcr.[Instrument]
,bddcr.[InstrumentTypeID]
,bddcr.[InstrumentType]
,di.InstrumentDisplayName
,di.ReceivedOnPriceServer
,bddcr.FullCommissions
,RollOverFee