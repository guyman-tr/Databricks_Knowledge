SELECT [InstrumentID]
      ,[InstrumentDisplayName]
       ,InstrumentType
      ,[Symbol]
      ,[Exchange]
      ,lower([Industry]) as [Industry]
      ,[CompanyInfo]
      ,[Tradable]
      ,[ISINCode] 
      ,SellCurrency
	  ,ReceivedOnPriceServer
  FROM 
  [DWH].[dbo].[Dim_Instrument] aa
where aa.[InstrumentID] !=0