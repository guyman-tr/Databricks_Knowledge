select CEP.*,
di.InstrumentType 
from [dbo].BI_DB_CEP_ExecutionMonitoring CEP
join 
DWH.dbo.Dim_Instrument di
on CEP.InstrumentID=di.InstrumentID