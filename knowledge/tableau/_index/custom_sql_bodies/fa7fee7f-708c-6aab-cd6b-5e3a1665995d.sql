select InstrumentID, Instrument, Regulation,
	EOMONTH(FullDate) AS EoM,
	sum(VolumeOnOpen) AS VolumeOnOpen, 
	sum(VolumeOnClose) AS VolumeOnClose,  
	sum(VolumeOnOpen) + sum(VolumeOnClose) AS TotalVolume
from BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
where  DateID>= 20250101
AND InstrumentTypeID = 10
AND Regulation IN ('FinCEN+FINRA','FinCEN')
AND IsValidCustomer=1
GROUP BY InstrumentID, Instrument, Regulation,
	EOMONTH(FullDate)
--ORDER BY EOMONTH(FullDate), InstrumentID