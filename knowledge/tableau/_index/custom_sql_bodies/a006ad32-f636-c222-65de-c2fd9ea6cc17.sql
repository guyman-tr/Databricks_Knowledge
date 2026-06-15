SELECT  
ReportDate, 
case IsFractional when 0 then 'Not Fractional' when 1 then 'Fractional' end IsFractional,
count (*) cnt
  FROM [RegReportDB_Prod].[dbo].[Reg_US_NOrders] a
  WHERE  ME_Type =1
  GROUP BY ReportDate,IsFractional