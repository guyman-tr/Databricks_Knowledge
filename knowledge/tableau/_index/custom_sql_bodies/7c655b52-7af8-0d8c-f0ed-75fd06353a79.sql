select nus.*, InstrumentType from BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 nus
join DWH_dbo.Dim_Instrument di 
    on nus.InstrumentID = di.InstrumentID
where DateID between 
CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)
and 
CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT)