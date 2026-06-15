SELECT * FROM (
SELECT CID
      ,vl.RealizedEquity RealizedEquity_StartDate 
	  ,ISNULL(vl.Liabilities,0) + ISNULL(vl.ActualNWA,0) Equity_StartDate
	  ,vl.Credit Balance_StartDate
	  ,CASE WHEN Credit >0 THEN 1 ELSE 0 END IsCredit
	  ,dc.AccountManagerID
            ,vl.FullDate
FROM DWH_dbo.V_Liabilities vl WITH (NOLOCK)
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dc.RealCID = vl.CID 
WHERE IsValidCustomer = 1) vl
WHERE (1.0*vl.Balance_StartDate)/vl.RealizedEquity_StartDate >=0.2
AND vl.RealizedEquity_StartDate>=500