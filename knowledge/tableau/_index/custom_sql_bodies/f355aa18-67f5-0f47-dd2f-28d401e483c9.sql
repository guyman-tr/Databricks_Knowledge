SELECT
   OpenDateID,
   di.InstrumentID,
   di.Name InstrumentName,
   CID,
    sum(AmountInUnitsDecimal) Units
    FROM DWH_dbo.Dim_Position dp
   JOIN DWH_dbo.Dim_Instrument di
   ON dp.InstrumentID = di.InstrumentID 
    and InstrumentTypeID=10
   AND dp.IsAirDrop=1
   and cast(OpenOccurred as Date) between <[Parameters].[Parameter 2]> and <[Parameters].[Parameter 3]>
group by 
    OpenDateID,
   di.InstrumentID,
   di.Name,
   CID