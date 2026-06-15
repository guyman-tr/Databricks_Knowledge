Select Trade_Date, Type, Count
From(
SELECT TOP (1000) R.[Trade_Date]
      ,[Accepted]
      ,[Rejected]
	  ,(S.Total - [Accepted] - [Rejected]) [Submitted]
      ,R.[Total]
	  ,S.Total AS [TOTAL]
      ,R.[UpdateDate]
  FROM [RegReportDB_Prod].[dbo].[TR_EMIR_Responses] R
  Left Join [RegReportDB_Prod].[dbo].[TR_EMIR_Submissions] S
  On R.Trade_Date = S.Trade_Date)p

  UNPIVOT
(Count for Type IN
  ( [Accepted],[Rejected],[Submitted],[TOTAL])) AS upvt