SELECT TOP (1) CONVERT(varchar,DateInt,101) as  ReportDate, 'ActimizeHedgeExecution' as TableName, count (*) as  NumberOfRecords
      
  FROM [RegReportDB_Prod].[dbo].[ActimizeHedgeExecution] group by [DateInt] order by [DateInt] desc
 union

SELECT TOP (1) CONVERT(varchar,DateInt,101) as  ReportDate, 'ActimizeHedgeOrder' as TableName, count (*) as  NumberOfRecords
      
  FROM [RegReportDB_Prod].[dbo].[ActimizeHedgeOrder] group by [DateInt] order by [DateInt] desc