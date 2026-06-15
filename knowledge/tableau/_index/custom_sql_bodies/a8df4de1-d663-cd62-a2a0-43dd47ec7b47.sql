SELECT 
	Gap_Type
   ,ProviderID
   ,Provider
   ,InstrumentID
   ,Instrument_Name
   ,ReportDate
   ,ISINCode
   ,Symbol
   ,Closing_Rate_Price_Unspreaded
   ,Closing_Rate_Price_Spreaded
   ,Total_Client_Holdings_In_Units
   ,Total_Custodian_Settled_Positions_In_Units
   ,Custodian_vs_Client_Holdings_Difference_In_units
   ,Total_Clients_Holdings_in_$
   ,Total_Custodian_Settled_Positions_in_$
   ,Custodian_vs_Client_Holdings_Difference_In_$
   ,ASIC_Client_Holdings_In_Units
   ,CySEC_Client_Holdings_In_Units
   ,FCA_Client_Holdings_In_Units
   ,GAML_Client_Holdings_In_Units
   ,ASIC_Client_Holdings_In_$
   ,CySEC_Client_Holdings_In_$
   ,FCA_Client_Holdings_In_$
   ,GAML_Client_Holdings_In_$
   ,Actual_Avg_Price
,IsGermanBaFin
  , Seychelles_Client_Holdings_In_Units
 , Seychelles_Client_Holdings_In_$
 ,FinCENFINRA_Client_Holdings_In_Units	
 ,FinCENFINRA_Client_Holdings_In_$
FROM
BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_Report 
where ReportDate = CAST(CONVERT(VARCHAR(8),cast(<[Parameters].[Parameter 3]> as date) , 112) AS INT)