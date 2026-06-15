SELECT [Date]
      ,[CID1]
      ,[ParentUserName1]
      ,[Type1]
      ,[CID2]
      ,[ParentUserName2]
      ,[Type2]
      ,[COV]
      ,[STD1]
      ,[AUM1]
      ,[RealizedAUM1]
      ,[eCopiers1]
      ,[rn_AUM1]
      ,[rn_eCopiers1]
      ,[STD2]
      ,[AUM2]
      ,[RealizedAUM2]
      ,[eCopiers2]
      ,[rn_AUM2]
      ,[rn_eCopiers2]
      ,[Pearson]
  FROM BI_DB_dbo.[BI_DB_rsk_Risk_PI_Correl]
  WHERE Date>=dateadd (dd, -1 , GETDATE())