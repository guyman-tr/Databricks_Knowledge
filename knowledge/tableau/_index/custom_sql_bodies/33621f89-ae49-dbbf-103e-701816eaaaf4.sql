SELECT vl.CID
       ,syn.full_name AM
	   ,dc1.Name Country
	   ,syn.desk Desk
	   ,fd.LastContactDate
	   ,dc.FirstDepositDate
	   ,dc.FirstDepositAmount
       ,ISNULL(vl.Liabilities,0)+ISNULL(vl.ActualNWA,0) Equity
	   ,cat.TotalDeposit
	   ,cat.TotalCashout
FROM [DWH].[dbo].[V_Liabilities] vl WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
ON vl.CID = dc.RealCID
INNER JOIN [BI_DB].[dbo].[Syn_gsheets.customer_managers] syn WITH (NOLOCK)
ON dc.AccountManagerID = syn.manager_id
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
INNER JOIN [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
ON vl.CID = fd.CID
LEFT JOIN [BI_DB].[dbo].[BI_DB_CustomerAllTimeAggregatedData] cat WITH (NOLOCK)
ON vl.CID = cat.CID
WHERE vl.DateID = CONVERT(CHAR(8),getdate()-1,112)
AND ISNULL(vl.Liabilities,0)+ISNULL(vl.ActualNWA,0) <=200
AND position = 'Onboarding'
AND dc.IsValidCustomer = 1