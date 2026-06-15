SELECT CAST(DATEADD(dd, -(DATEPART(dw, bdcd.registered)-1), bdcd.registered) AS DATE) YearMonth
		,CASE WHEN bdcd.Country = 'Portugal' THEN 'Portugal' 
			  WHEN bdcd.Country = 'Austria' THEN 'Austria' 
			  WHEN bdcd.Country = 'Switzerland' THEN 'Switzerland' 
			  WHEN bdcd.Country = 'Norway' THEN 'Norway' ELSE bdcd.NewMarketingRegion END AS Region
		,SUM(CASE WHEN DATEDIFF(DAY,bdcd.registered,bdcd.FirstNewFundedDate) <= 7 THEN 1 ELSE 0 end)*1.00/COUNT(*) Reg_Funded
		,SUM(CASE WHEN DATEDIFF(DAY,bdcd.registered,bdcd.FirstDepositDate) <= 7 THEN 1 ELSE 0 end)*1.00/COUNT(*) Reg_FTD
		,SUM(CASE WHEN DATEDIFF(DAY,bdcd.registered,bdcd.VerificationLevel3Date) <= 7 THEN 1 ELSE 0 end)*1.00/COUNT(*) Reg_V3
		,SUM(CASE WHEN DATEDIFF(DAY,bdcd.registered,bdfa.FirstActionDate) <= 7 THEN 1 ELSE 0 end)*1.00/COUNT(*) Reg_FirstAction
		,SUM(CASE WHEN bdcd.FirstDepositAmount < 200 AND DATEDIFF(DAY,bdcd.registered,bdcd.FirstDepositDate) <= 7 THEN 1 ELSE 0 END)*1.00/COUNT(*) LowFTDA
		,SUM(CASE WHEN bdcd.FirstDepositAmount < 200 AND DATEDIFF(DAY,bdcd.registered,bdcd.FirstNewFundedDate) <= 30  THEN 1  ELSE 0 END)*1.00/COUNT(*) LowFTDA_Funded
		,SUM(CASE WHEN bdcd.FirstDepositAmount < 200 AND DATEDIFF(DAY,bdcd.registered,bdcd.VerificationLevel3Date) <= 30  THEN 1  ELSE 0 END)*1.00/COUNT(*) LowFTDA_Verified
FROM BI_DB_dbo.BI_DB_CIDFirstDates  bdcd
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa
ON bdcd.CID=bdfa.CID
WHERE bdcd.registered >= '20200101'
AND bdcd.Region <> 'Unknown'
AND bdcd.Channel NOT IN ('Club', 'Events', 'Sponsorships', 'Productions', 'OOH', 'PR', 'TV', 'systems', 'Social Organic')
GROUP BY CAST(DATEADD(dd, -(DATEPART(dw, bdcd.registered)-1), bdcd.registered) AS DATE) ,CASE WHEN bdcd.Country = 'Portugal' THEN 'Portugal' 
			  WHEN bdcd.Country = 'Austria' THEN 'Austria' 
			  WHEN bdcd.Country = 'Switzerland' THEN 'Switzerland' 
			  WHEN bdcd.Country = 'Norway' THEN 'Norway' ELSE bdcd.NewMarketingRegion END