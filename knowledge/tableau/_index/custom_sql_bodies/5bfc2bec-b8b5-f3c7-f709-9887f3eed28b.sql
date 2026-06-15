SELECT  
		ddr.EoM AS ReportDate,
		ddr.Regulation,
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
	select 
		Regulation,
		CAST(CONVERT(char(8), DateID) as date) EoM,
		sum(Equity) AS MSB_Equity,
        sum(Credit) AS MSB_Cash
	from BI_DB_dbo.[BI_DB_DDR_TimeRange_Aggregated_Country_Level] 
	WHERE Region='USA'
	and IsCreditReportValidCB=1
	AND IsValidCustomer=1
	AND Regulation in ('FinCEN', 'FinCEN+FINRA', 'eToroUS', 'FINRAONLY')
	--AND Country IN ('United States','US Virgin Islands','Puerto Rico') 
	AND TimeRange = 'Yesterday'
	and DateID IN (
			SELECT dd.DateKey FROM DWH_dbo.Dim_Date dd 
			WHERE IsLastDayOfMonth='Y' AND dd.DateKey BETWEEN CONVERT(nvarchar(8),DATEADD(QUARTER,-6,GETDATE()),112) AND CONVERT(nvarchar(8), GETDATE(), 112)		
			--union select CONVERT(nvarchar(8), dateadd(day, -1, GETDATE()), 112) as DateKey	
			)
	GROUP BY 
		Regulation,
		CAST(CONVERT(char(8), DateID) as date)
	--ORDER BY CAST(CONVERT(char(8), DateID) as date)
) ddr


LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			eomonth(CAST(CONVERT(char(8), fca.DateID) as date)) AS ReportDate, 
			count(DISTINCT fca.DepositID)						AS DepositsCount,
			SUM(fca.Amount)									    AS DepositsSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 7
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-6,GETDATE()),112)
		GROUP BY drg.Name, eomonth(CAST(CONVERT(char(8), fca.DateID) as date))

) main_dep
ON ddr.EoM = main_dep.ReportDate
	and ddr.Regulation = main_dep.Regulation

LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			eomonth(CAST(CONVERT(char(8), fca.DateID) as date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS AdjWithdrawalCount,
			SUM(fca.Amount)									    AS AdjWithdrawalSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 8
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.IsRedeem=0 --exclude coin redeem
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-6,GETDATE()),112)
		GROUP BY drg.Name, eomonth(CAST(CONVERT(char(8), fca.DateID) as date))
		--ORDER BY eomonth(CAST(CONVERT(char(8), fca.DateID) as date))--,fca.IsRedeem
) main_wit
ON ddr.EoM = main_wit.ReportDate
	and ddr.Regulation = main_wit.Regulation

LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			eomonth(CAST(CONVERT(char(8), fca.DateID) as date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS RedeemCount,
			SUM(fca.Amount)									    AS RedeemSum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE fca.ActionTypeID = 8
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated
		  AND fca.IsRedeem=1 
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-6,GETDATE()),112)
		GROUP BY drg.Name, eomonth(CAST(CONVERT(char(8), fca.DateID) as date))
		--ORDER BY eomonth(CAST(CONVERT(char(8), fca.DateID) as date)),fca.IsRedeem
) redeem
ON ddr.EoM = redeem.ReportDate
	and ddr.Regulation = redeem.Regulation


LEFT JOIN 
(
		SELECT 
			drg.Name as Regulation,
			eomonth(CAST(CONVERT(char(8), fca.DateID) as date)) AS ReportDate, 
			count(DISTINCT fca.WithdrawID)						AS pi_affiliate_payment_count,
			SUM(fca.Amount)									    AS pi_affiliate_payment_sum
		FROM DWH_dbo.Fact_CustomerAction fca
			JOIN DWH_dbo.Dim_Customer dc1
				ON fca.RealCID = dc1.RealCID 
				AND dc1.IsValidCustomer=1 
				AND dc1.RegulationID IN (6,7,8) --AND dc1.DesignatedRegulationID IN (7,8)
			join DWH_dbo.Dim_Regulation drg
				ON dc1.RegulationID=drg.ID
		WHERE (fca.ActionTypeID=36 AND fca.CompensationReasonID IN (41,51)) -- locate affiliate and PI payments 
		  AND fca.FundingTypeID!=42 -- exclude eToroOptions as it's not validated for comprehensiveness
		  AND fca.IsRedeem=0 --exclude coin redeem
		  AND fca.DateID >= CONVERT(nvarchar(8),DATEADD(QUARTER,-6,GETDATE()),112)
		GROUP BY drg.Name, eomonth(CAST(CONVERT(char(8), fca.DateID) as date))
		--ORDER BY eomonth(CAST(CONVERT(char(8), fca.DateID) as date)),fca.IsRedeem
) pi_aff
ON ddr.EoM=pi_aff.ReportDate
	and ddr.Regulation = pi_aff.Regulation
--ORDER BY ddr.EoM, ddr.Regulation