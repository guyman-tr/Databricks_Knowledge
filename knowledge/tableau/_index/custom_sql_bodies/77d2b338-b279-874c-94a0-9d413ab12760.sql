select a.*, InstrumentType from BI_DB.dbo.BI_DB_PriceAlgo_Hourly a
join DWH.dbo.Dim_Instrument b
on a.InstrumentID=b.InstrumentID