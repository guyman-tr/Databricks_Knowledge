SELECT DISTINCT di.InstrumentID,di.Name,di.InstrumentDisplayName,di.InstrumentTypeID,di.InstrumentType
 FROM Dim_Instrument di
 LEFT JOIN [ThirdParty_Fivetran].[Fivetran].[gsheets].[ccr_percentage] AS ccr
 ON ccr.instrument_id = di.InstrumentID
 WHERE ccr.instrument_id IS NULL
 AND di.InstrumentID<>0