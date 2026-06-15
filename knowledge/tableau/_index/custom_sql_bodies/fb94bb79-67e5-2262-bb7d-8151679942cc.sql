SELECT _row
	  ,start_date
	  ,end_date
	  ,campaign_name
	  ,instrument_id_pi_number
	  ,_fivetran_synced 
	  ,ISNULL(dc.UserName,di.InstrumentDisplayName) UserName
FROM [BI_DB_dbo].[External_Fivetran_gsheets_investment_office_kpi_criteria] et
LEFT JOIN DWH_dbo.Dim_Customer dc
ON et.instrument_id_pi_number = dc.RealCID
LEFT JOIN DWH_dbo.Dim_Instrument di
ON et.instrument_id_pi_number = di.InstrumentID