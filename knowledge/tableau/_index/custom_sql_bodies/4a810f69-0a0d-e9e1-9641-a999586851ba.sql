SELECT AA.[AffiliateID]
      ,AA.DateID
      ,AA.Date
      ,AA.[CountryName]
	  ,AA.CountryID
      ,AA.[Region]
      ,AA.[Desk]
	  ,AA.[NewMarketingRegion]
      ,AA.[DateCreated]
      ,AA.[Channel]
      ,AA.[SubChannel]
      ,Funnel
      ,AA.[Organic/Paid]
      ,AA.[Contact]
      ,AA.[ContractName]
      ,AA.[ContractType]
      ,AA.[AffiliatesGroupsName]
      ,[Registration]
      ,[SameDayFTD]
      ,[FTD]
      ,[FTDA]
	  ,[Installs]
	  ,[UpdateDate]
FROM (SELECT [AffiliateID]
            ,bdmdrd.DateID
            ,bdmdrd.Date 
			,bdmdrd.CountryID
            ,[CountryName]
            ,[Region]
            ,[Desk]
            ,CAST([DateCreated] AS DATE) [DateCreated]
            ,[Channel]
            ,[SubChannel]
            ,[Organic/Paid]
            ,Funnel
            ,[Contact]
            ,[ContractName]
            ,[ContractType]
            ,[AffiliatesGroupsName]
		    ,[NewMarketingRegion]
            ,sum([Registration]) AS [Registration]
            ,sum([SameDayFTD]) AS [SameDayFTD]
            ,sum([FTD]) AS [FTD]
            ,sum([FTDA]) AS [FTDA]
			,sum([Installs]) AS [Installs]
			,MAX([UpdateDate])  AS [UpdateDate]
    
      FROM BI_DB_dbo.BI_DB_MarketingDailyRawData bdmdrd 
      GROUP BY [AffiliateID]
              ,[CountryID] 
              ,bdmdrd.DateID
		      ,bdmdrd.Date
		      ,[CountryName]
              ,[Region]
              ,[Desk]
              ,CAST([DateCreated] AS DATE)
              ,[Channel]
              ,[SubChannel]
              ,[Organic/Paid]
              ,Funnel
              ,[Contact]
              ,[ContractName]
              ,[ContractType]
              ,[AffiliatesGroupsName]
              ,[AccountActivated]
		      ,[NewMarketingRegion])AA