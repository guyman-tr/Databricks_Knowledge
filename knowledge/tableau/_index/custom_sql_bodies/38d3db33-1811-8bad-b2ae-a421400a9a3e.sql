select    cl.RealCID 
	     ,cl.Date	
		 ,cl.DateID	
		 ,cl.TotalCLAmount	
		 ,cl.MonthlyTableFeeCost	
		 ,cl.DailyFee	
		 ,cl.Liabilities	
		 ,cl.CLRatio	
		 ,cl.IsExceeded	
		 ,cl.ExceedingDaysCount	
		 ,cl.DateReceive	
		 ,cl.DateDeduct
		 ,cl.UpdateDate
         ,dr.Name Regulation
		 ,dm.FirstName+' '+dm.LastName as Manager
		 ,vl.Credit AS Balance
from dbo.BI_DB_Daily_CreditLine cl
join DWH.dbo.Dim_Customer dc
on dc.RealCID = cl.RealCID
join DWH.dbo.Dim_Regulation dr
on dr.DWHRegulationID = dc.RegulationID
join DWH.dbo.Dim_Manager dm
on dm.ManagerID = dc.AccountManagerID
LEFT JOIN [DWH].[dbo].[V_Liabilities] vl WITH (NOLOCK)
ON cl.RealCID = vl.CID
AND cl.DateID = vl.DateID