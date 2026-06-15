SELECT  ReportDate,ME_Type_Desc,count(1) cnt
  FROM [RegReportDB_Prod].[dbo].[Reg_US_NOrders] a
  JOIN Reg_US_Rep_Dictionary b ON  a.ME_Type=b.ME_Type_ID
  AND ME_Type <>2
 	  GROUP BY ReportDate,ME_Type_Desc

 UNION ALL
   SELECT ReportDate,ME_Type_Desc,count(1) cnt
  FROM [RegReportDB_Prod].[dbo].[Reg_US_ROrders] a
  JOIN Reg_US_Rep_Dictionary b ON  a.ME_Type=b.ME_Type_ID
    
	 AND ME_Type <>3
	  	  GROUP BY ReportDate,ME_Type_Desc
 UNION ALL
  SELECT ReportDate,ME_Type_Desc,count(1) cnt
  FROM [RegReportDB_Prod].[dbo].[Reg_US_Fullfilment] a
  JOIN Reg_US_Rep_Dictionary b ON  a.ME_Type=b.ME_Type_ID
	  GROUP BY ReportDate,ME_Type_Desc