select InstrumentID, Instrument, Regulation,
	DATEADD(DAY, (7 - DATEPART(WEEKDAY, FullDate)) % 7, FullDate) AS EoW_Sat,
	sum(VolumeOnOpen) AS VolumeOnOpen, 
	sum(VolumeOnClose) AS VolumeOnClose,  
	sum(VolumeOnOpen) + sum(VolumeOnClose) AS TotalVolume
from BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
where  DateID>= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112)
AND InstrumentTypeID = 10
AND Regulation IN ('FinCEN+FINRA','FinCEN','NYDFS+FINRA')
AND IsValidCustomer=1
GROUP BY InstrumentID, Instrument, Regulation,
	 DATEADD(DAY, (7 - DATEPART(WEEKDAY, FullDate)) % 7, FullDate)
--ORDER BY EOMONTH(FullDate), InstrumentID