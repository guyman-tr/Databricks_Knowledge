SELECT  
		--dateadd(DAY,-6,ddr.EoW_Sat) AS ReportDate,

		COALESCE(main_dep.EoW_Sat, ddr.EoW_Sat) AS EoW_Sat_adj,
		main_dep.EoW_Sat as EoW_Sat_dep,
		ddr.EoW_Sat AS EoW_Sat_ddr,
		COALESCE(ddr.Regulation, main_dep.Regulation) AS Regulation_adj,
		ddr.MSB_Equity,
		ddr.MSB_Cash,
		--NULL AS Chargeback_loss,
		main_dep.DepositsCount,
		main_dep.DepositsSum,
		redeem.RedeemCount, 
		redeem.RedeemSum,
		(main_wit.AdjWithdrawalSum   - COALESCE(pi_aff.pi_affiliate_payment_sum,0))	  AS AdjWithdrawalSum,
		(main_wit.AdjWithdrawalCount - COALESCE(pi_aff.pi_affiliate_payment_count,0)) AS AdjWithdrawalCount
 FROM 

(
		SELECT 
			drg.Name as Regulation,
			-- Always return the Saturday of the week that the date belongs to (Sunday–Saturday week)
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date)) AS EoW_Sat, 
			count(DISTINCT fca.DepositID)						AS DepositsCount,
			SUM(fca.Amount)									    AS DepositsSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8,12,14) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 7
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112)
		GROUP BY drg.Name,	
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date))
) main_dep
FULL outer JOIN 
(
	select 
		Regulation,
		CAST(CONVERT(char(8), DateID) as date) EoW_Sat,
		sum(Equity) AS MSB_Equity,
        sum(Credit) AS MSB_Cash
	from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] 
	WHERE Region='USA'
	and IsCreditReportValidCB=1
	AND IsValidCustomer=1
	AND Regulation in ('FinCEN', 'FinCEN+FINRA', 'eToroUS', 'FINRAONLY','NYDFS+FINRA')
	--AND Country IN ('United States','US Virgin Islands','Puerto Rico') 
	AND TimeRange = 'Yesterday'
	and DateID IN (
			SELECT dd.DateKey FROM DWH_dbo.Dim_Date dd
			WHERE dd.DateKey >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112) --AND CONVERT(nvarchar(8), GETDATE(), 112)	
				AND dd.DayNumberOfWeek_Sun_Start=7 -- target: saturdays
			--ORDER BY dd.DateKey
			)
	GROUP BY 
		Regulation,
		CAST(CONVERT(char(8), DateID) as date)
	--ORDER BY CAST(CONVERT(char(8), DateID) as date)
) ddr
ON ddr.EoW_Sat = main_dep.EoW_Sat
	and ddr.Regulation = main_dep.Regulation

LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS AdjWithdrawalCount,
			SUM(fca.Amount)									    AS AdjWithdrawalSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8,12,14) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 8
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.IsRedeem=0 --exclude coin redeem
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112)
		GROUP BY drg.Name, 
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date))
		--ORDER BY EoW_Satonth(CAST(CONVERT(char(8), fca.DateID) as date))--,fca.IsRedeem
) main_wit
ON ddr.EoW_Sat = main_wit.ReportDate
	and ddr.Regulation = main_wit.Regulation

LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS RedeemCount,
			SUM(fca.Amount)									    AS RedeemSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8,12,14) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 8
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.IsRedeem=1 
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112)
		GROUP BY drg.Name, 
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date))
		--ORDER BY EoW_Satonth(CAST(CONVERT(char(8), fca.DateID) as date)),fca.IsRedeem
) redeem
ON ddr.EoW_Sat = redeem.ReportDate
	and ddr.Regulation = redeem.Regulation


LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS pi_affiliate_payment_count,
			SUM(fca.Amount)									    AS pi_affiliate_payment_sum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8,12,14) AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE (fca.ActionTypeID=36 AND fca.CompensationReasonID IN (41,51)) -- locate affiliate and PI payments 
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated for comprehensiveness
		  AND fca.IsRedeem=0 --exclude coin redeem
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-1,GETDATE()),112)
		GROUP BY drg.Name, 
			DATEADD(DAY, 
					(7 - DATEPART(WEEKDAY, CAST(CONVERT(char(8), fca.DateID) AS date))) % 7, 
					CAST(CONVERT(char(8), fca.DateID) AS date))
		--ORDER BY EoW_Satonth(CAST(CONVERT(char(8), fca.DateID) as date)),fca.IsRedeem
) pi_aff
ON ddr.EoW_Sat=pi_aff.ReportDate
	and ddr.Regulation = pi_aff.Regulation
/*
ORDER BY 
	main_dep.EoW_Sat,
	main_dep.Regulation
*/