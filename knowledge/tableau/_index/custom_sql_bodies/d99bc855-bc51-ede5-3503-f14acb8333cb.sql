SELECT	bdcmpfd.Active_Month
		,bdcmpfd.ActiveDate
		,'Q' + CAST(DATEPART(QUARTER, bdcmpfd.ActiveDate) AS VARCHAR) [QuarterDate]
		,bdcmpfd.CID
		,bdcmpfd.Country
		,bdcmpfd.NewMarketingRegion
		,bdcmpfd.Region
		,bdcmpfd.EOM_Regulation
		,dr.Name [Regulation_Latest]
		,bdcmpfd.EOM_Club
		,CASE WHEN bdcmpfd.EOM_Club IN ('LowBronze', 'HighBronze') THEN 'Bronze' ELSE bdcmpfd.EOM_Club END [ClubTiers_EoM]
		,bdcd.Club [Club_Latest]
		,bdcmpfd.TotalDeposits
		,bdcmpfd.TotalCashouts
		,bdcmpfd.CashoutsAdjusted
		,bdcmpfd.NewTrades_Total
		,bdcmpfd.Revenue_Total
		,bdcmpfd.EOM_Equity
		,dtbl.RealizedEquity
		,dtbl.ActiveDate [DateREquity_Extracted]
		,AVG(bdcd.RealizedEquity) OVER(PARTITION BY bdcmpfd.CID) [RealizedEquity_AvgPerMth]
		,AVG(bdcd.RealizedEquity) OVER(PARTITION BY bdcmpfd.CID, (DATEPART(QUARTER, bdcmpfd.ActiveDate))) [RealizedEquity_AvgPerQtrMth]
		,AVG(dtbl.Equity) OVER(PARTITION BY bdcmpfd.CID) [EquityEOD_AvgPerMth]
		,AVG(dtbl.Equity) OVER(PARTITION BY bdcmpfd.CID, (DATEPART(QUARTER, bdcmpfd.ActiveDate))) [EquityEOD_AvgPerQtrMth]
		,AVG(bdcmpfd.Revenue_Total) OVER(PARTITION BY bdcmpfd.CID) [RevTotal_AvgPerMth]
		,AVG(bdcmpfd.Revenue_Total) OVER(PARTITION BY bdcmpfd.CID, (DATEPART(QUARTER, bdcmpfd.ActiveDate))) [RevTotal_AvgPerQtrMth]
		,SUM(bdcmpfd.Revenue_Total) OVER(PARTITION BY bdcmpfd.CID) [RevTotal_YTD]
		,SUM(bdcmpfd.Revenue_Total) OVER(PARTITION BY bdcmpfd.CID, (DATEPART(QUARTER, bdcmpfd.ActiveDate))) [RevTotal_SumPerQtr]
/*		,(CASE WHEN (bdcmpfd.Revenue_Total >= 100 AND bdcd.RealizedEquity >= 100) THEN (CAST(bdcmpfd.Revenue_Total AS FLOAT)/CAST(dtbl.RealizedEquity AS FLOAT))
		ELSE NULL END) AS [Rev/RE Ratio]
		*/
FROM BI_DB..BI_DB_CID_MonthlyPanel_FullData bdcmpfd
INNER JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON bdcmpfd.CID = bdcd.CID
LEFT JOIN DWH..Dim_Regulation dr ON bdcd.RegulationID = dr.DWHRegulationID
LEFT JOIN (SELECT bdcdpfd.Active_Month
				, bdcdpfd.ActiveDate
				, bdcdpfd.CID
				, bdcdpfd.RealizedEquity
				, bdcdpfd.Equity
				, bdcdpfd.EOD_Club 
				FROM BI_DB..BI_DB_CID_DailyPanel_FullData bdcdpfd 
				WHERE bdcdpfd.ActiveDate = EOMONTH(bdcdpfd.ActiveDate)) dtbl ON (bdcmpfd.CID = dtbl.CID AND bdcmpfd.Active_Month = dtbl.Active_Month)
WHERE bdcmpfd.Active_Month BETWEEN 202201 AND (DATEPART(YEAR,GETDATE())*100 + DATEPART(MONTH,GETDATE()) - 1)
AND bdcd.Blocked = 0
AND bdcd.RegulationID = 9	/*FSA Seychelles*/
AND bdcd.Verified = 3
AND bdcd.FirstDepositDate <= DATEADD(MONTH, -4, EOMONTH(GETDATE()))