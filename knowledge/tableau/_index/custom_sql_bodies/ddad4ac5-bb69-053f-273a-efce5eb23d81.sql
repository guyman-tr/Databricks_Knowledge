Select Trade_Date, Type, Count
From(
SELECT [Trade_Date]
      ,[Accepted]
      ,[Rejected]
	  ,([Total] - [Accepted] - [Rejected]) [Submitted]
      ,[Total]
      ,[UpdateDate]
  FROM [RegReportDB_Prod].[dbo].[TR_EMIR_Responses])p

  UNPIVOT
(Count for Type IN
  ( [Accepted],[Rejected],[Submitted],[Total])) AS upvt