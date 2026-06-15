/****** Script for SelectTopNRows command from SSMS  ******/

Select [Report_Date]
	,MeasureName,RowsCount
	From
	(


SELECT [Report_Date]
      ,[Accepted #]
	  ,([Total #] - ([Accepted #]+[Rejected #])) [Submitted #]
      ,[Rejected #]
      ,[Total #]
      ,[UpdateDate]
  FROM [RegReportDB_Prod].[dbo].[RegOps_ASIC_DTCC_Responses])p
  Unpivot
  (RowsCount for MeasureName IN
  ([Accepted #],[Submitted #],[Rejected #], [Total #])) as upvt