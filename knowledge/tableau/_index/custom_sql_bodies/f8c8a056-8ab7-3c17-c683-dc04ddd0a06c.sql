SELECT bddcr.FullDate
,di.InstrumentID
,di.Name Instrument
,di.[InstrumentTypeID]
,di.[InstrumentType]
,di.InstrumentDisplayName
,di.ReceivedOnPriceServer
,bddcr.FullCommissions
,bddcr.RollOverFee
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr
INNER JOIN DWH_dbo.Dim_Instrument di 
ON bddcr.InstrumentID = di.InstrumentID
WHERE bddcr.DateID >=20220101
and bddcr.InstrumentTypeID in (4,2,1)
GROUP BY 
bddcr.FullDate
,di.InstrumentID
,di.Name 
,di.[InstrumentTypeID]
,di.[InstrumentType]
,di.InstrumentDisplayName
,di.ReceivedOnPriceServer
,bddcr.FullCommissions
,bddcr.RollOverFee