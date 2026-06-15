SELECT [TradeDate]
      ,[Side]
      ,[Symbol]
      ,[Description]
	  ,[Cusip]
      ,[InstrumentName]
      ,[InstrumentID]
      ,SUM([Total_Amount]) AS TotalAmount
      ,SUM(ABS([CustomerPFOFPayback])) AS CustomerPFOFPayback 
      ,SUM(ABS([CustomerPFOFPayback])*[PriceFiller]) AS TotalRevenue
      ,count(OrderID) as Transactions
FROM BI_DB_dbo.BI_DB_US_Stocks_Apex_PFOF a
WHERE TradeDate>=<[Parameters].[Parameter 1]>
GROUP BY  [TradeDate]
		 ,[Side]
		 ,[Symbol]
		 ,[Description]
		 ,[Cusip]
		 ,[InstrumentName]
		 ,[InstrumentID]