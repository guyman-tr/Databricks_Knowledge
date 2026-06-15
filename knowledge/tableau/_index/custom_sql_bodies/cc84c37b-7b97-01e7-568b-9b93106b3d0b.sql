select fu.InstrumentID, di.Name, fu.Multiplier 
from [DWH_staging].[etoro_Trade_FuturesMetaData] fu
join [DWH_dbo].[Dim_Instrument] di
on fu.InstrumentID = di.InstrumentID