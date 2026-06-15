SELECT 'Registration' Type 
     ,CAST(fd.registered AS DATE) [Date]
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region
     ,COUNT(*) Leads
FROM [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
WHERE fd.registered>=DATEADD(MONTH,-6,GETDATE())
GROUP BY CAST(fd.registered AS DATE) 
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region
UNION ALL
SELECT 'Deposit' Type  
     ,CAST(fd.FirstDepositDate AS DATE) [Date]
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region
      ,SUM(CASE WHEN YEAR(fd.registered)*100 + MONTH(fd.registered) = YEAR(fd.FirstDepositDate)*100 + MONTH(fd.FirstDepositDate) THEN 1 ELSE 0 END) Leads
FROM [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
WHERE fd.FirstDepositDate>=DATEADD(MONTH,-6,GETDATE())
GROUP BY CAST(fd.FirstDepositDate AS DATE) 
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region
UNION ALL
SELECT 'Funded' Type  
     ,CAST(fd.FirstNewFundedDate AS DATE) [Date]
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region
     ,SUM(CASE WHEN YEAR(fd.registered)*100 + MONTH(fd.registered) = YEAR(fd.FirstNewFundedDate)*100 + MONTH(fd.FirstNewFundedDate) THEN 1 ELSE 0 END) Leads
FROM [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)
WHERE fd.FirstNewFundedDate>=DATEADD(MONTH,-6,GETDATE())
GROUP BY CAST(fd.FirstNewFundedDate AS DATE) 
     ,fd.Gender
	 ,fd.Country
	 ,fd.Region