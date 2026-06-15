SELECT
   InstrumentID
   ,Instrument_Name
   ,ReportDate
   ,ISINCode
   ,Closing_Rate_Price_Unspreaded [Closing Bid Price UnSpreaded]
   ,Closing_Rate_Price_Spreaded AS [Closing Bid Price Spreaded]
   ,Actual_Avg_Price AS [Actual Avg. Price]
   ,GAML_Client_Holdings_In_Units AS [Total GAML Clients Holdings In Units]
   ,GAML_Client_Holdings_In_Units AS [Total Custodian Settled Positions In Units]
   ,GAML_Client_Holdings_In_$ AS [Total GAML Clients Holdings In $]
   ,GAML_Client_Holdings_In_$ AS [Total Custodian Settled Positions In $]
FROM dbo.BI_DB_Finance_Non_US_Settlement_Report
WHERE ReportDate = <[Parameters].[Parameter 1]>