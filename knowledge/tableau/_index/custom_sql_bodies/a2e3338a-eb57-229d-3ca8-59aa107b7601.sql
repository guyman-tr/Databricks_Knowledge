select nus.*, InstrumentType from BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 nus
join DWH_dbo.Dim_Instrument di 
    on nus.InstrumentID = di.InstrumentID
where SettlementDate between 
<[Parameters].[Parameter 3]>
and 
<[Parameters].[Parameter 4]>