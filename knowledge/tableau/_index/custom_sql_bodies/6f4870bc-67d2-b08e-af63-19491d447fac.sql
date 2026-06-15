SELECT DISTINCT us.PrimaryKey, us.ReportMonth,  us.ReportWeek, 
   CASE WHEN us.PlayerLevel =  'Silver' THEN '1 Silver'
		WHEN us.PlayerLevel =  'Gold' then '2 Gold'
		WHEN us.PlayerLevel = 'Platinum' THEN '3 Platinum'
		WHEN us.PlayerLevel = 'Platinum Plus' THEN '4 Platinum Plus'
		WHEN us.PlayerLevel = 'Diamond' THEN '5 Diamond' END AS PlayerLevel,
	us.Deposits, us.Cashouts, us.TransferCoins, us.CashoutsAdjusted, us.DepositsCount, us.CashoutsCount, us.NetDeposit, us.AdjustedNetDeposit,
	uk.UK_Deposits, uk.UK_Cashouts, uk.UK_TransferCoins, uk.UK_CashoutsAdjusted, uk.UK_DepositsCount, uk.UK_CashoutsCount,uk.UK_NetDeposit, uk.UK_AdjustedNetDeposit
	FROM (
	SELECT DISTINCT  CONCAT(DATEPART(MONTH, DATEADD(DAY, -1, ReportDate)), '-',DATEPART(wk,DATEADD(DAY, -1, ReportDate)), PlayerLevel) PrimaryKey,
			EOMONTH(ReportDate) AS ReportMonth,   
			DATEADD(dd, 7-(DATEPART(dw, ReportDate)), ReportDate) AS ReportWeek,
			PlayerLevel,
			SUM(Deposits) Deposits, 		
			SUM(Cashouts) Cashouts,
			SUM(TransferCoins) TransferCoins, 
			SUM(CashoutsAdjusted) CashoutsAdjusted,
			SUM(DepositsCount) AS DepositsCount,
			SUM(CashoutsCount) AS CashoutsCount,
			SUM(NetDeposit) NetDeposit,
			SUM(AdjustedNetDeposit) AdjustedNetDeposit
	FROM BI_DB_dbo.BI_DB_DDR_Daily_Aggregated
		where DateID >= 20220401
		AND Regulation IN ('FinCEN+FINRA', 'FinCEN') AND PlayerLevel IN ('Diamond','Platinum Plus','Platinum','Gold','Silver')
		AND IsCreditReportValidCB =1 AND IsValidCustomer =1
	GROUP BY  CONCAT(DATEPART(MONTH, DATEADD(DAY, -1, ReportDate)), '-',DATEPART(wk,DATEADD(DAY, -1, ReportDate)), PlayerLevel),
			EOMONTH(ReportDate),   
			DATEADD(dd, 7-(DATEPART(dw, ReportDate)), ReportDate),
			PlayerLevel
	)us
	inner JOIN (
	SELECT DISTINCT   CONCAT(DATEPART(MONTH, DATEADD(DAY, -1, ReportDate)), '-',DATEPART(wk,DATEADD(DAY, -1, ReportDate)), PlayerLevel)  UK_PrimaryKey,
			EOMONTH(ReportDate) AS UK_ReportMonth,   
			DATEADD(dd, 7-(DATEPART(dw, ReportDate)), ReportDate) AS UK_ReportWeek,
			PlayerLevel UK_PlayerLevel,
			SUM(Deposits) UK_Deposits, 		
			SUM(Cashouts) UK_Cashouts,
			SUM(TransferCoins) UK_TransferCoins, 
			SUM(CashoutsAdjusted) UK_CashoutsAdjusted,
			SUM(DepositsCount) AS UK_DepositsCount,
			SUM(CashoutsCount) AS UK_CashoutsCount,
			SUM(NetDeposit) UK_NetDeposit,
			SUM(AdjustedNetDeposit) UK_AdjustedNetDeposit
	FROM BI_DB_dbo.BI_DB_DDR_Daily_Aggregated
		where DateID >= 20220401
		AND Regulation IN ('FCA') AND PlayerLevel IN ('Diamond','Platinum Plus','Platinum','Gold','Silver')
		AND IsCreditReportValidCB =1 AND IsValidCustomer =1
	GROUP BY  CONCAT(DATEPART(MONTH, DATEADD(DAY, -1, ReportDate)), '-',DATEPART(wk,DATEADD(DAY, -1, ReportDate)), PlayerLevel),
			EOMONTH(ReportDate),   
			DATEADD(dd, 7-(DATEPART(dw, ReportDate)), ReportDate),
			PlayerLevel
	)uk ON us.PrimaryKey = uk.UK_PrimaryKey
	--WHERE us.ReportMonth ='2022 Month 9'
	--ORDER BY us.ReportMonth, us.ReportWeek,PlayerLevel