SELECT dp_gl.ThisMonth, 
	CASE WHEN LOWER(dp_gl.InstrumentDisplayName) LIKE '%ishares%' THEN 'iShares' ELSE 'Non iShares' END AS iShares_filter,
	CASE WHEN LOWER(dp_gl.InstrumentDisplayName) LIKE '%bond%' THEN 'Bond' ELSE 'Non Bond' END AS bond_filter,
	dp_gl.InstrumentDisplayName, dp_gl.Name, dp_gl.global_new_volume, COALESCE(dp_us.us_new_volume,0) AS us_new_volume, 
        dp_gl.global_new_volume-COALESCE(dp_us.us_new_volume,0) AS non_us_new_volume	
FROM 
(
	SELECT EOMONTH(dp.OpenOccurred) ThisMonth, di.InstrumentDisplayName, di.Name, SUM(dp.Amount) global_new_volume
	FROM DWH_dbo.Dim_Position dp	
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dp.CID AND dc.IsValidCustomer=1 AND dc.IsCreditReportValidCB=1
	JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID=di.InstrumentID AND di.InstrumentTypeID=6	
	WHERE dp.OpenDateID >= CONVERT(nvarchar(8), DATEADD(QUARTER,-18, GETDATE()), 112) 
	GROUP BY EOMONTH(dp.OpenOccurred), di.InstrumentDisplayName, di.Name
)dp_gl
LEFT JOIN (
	SELECT EOMONTH(OpenOccurred) ThisMonth, di.InstrumentDisplayName, di.Name, SUM(dp.Amount) us_new_volume	
	FROM DWH_dbo.Dim_Position dp	
	JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=dp.CID AND dc.IsValidCustomer=1 AND dc.IsCreditReportValidCB=1 AND dc.CountryID=219 
            AND dc.RegulationID IN (6,7,8) AND dc.DesignatedRegulationID IN (6,7,8)	
	JOIN DWH_dbo.Dim_Instrument di ON dp.InstrumentID=di.InstrumentID AND di.InstrumentTypeID=6	
	WHERE dp.RegulationIDOnOpen IN (7,8) AND 
	dp.OpenDateID >= CONVERT(nvarchar(8), DATEADD(QUARTER,-18, GETDATE()), 112) 
	GROUP BY EOMONTH(OpenOccurred), di.InstrumentDisplayName, di.Name	
)dp_us ON dp_gl.ThisMonth=dp_us.ThisMonth AND dp_gl.Name=dp_us.Name
GROUP BY dp_gl.ThisMonth, CASE WHEN LOWER(dp_gl.InstrumentDisplayName) LIKE '%ishares%' THEN 'iShares' ELSE 'Non iShares' END,
CASE WHEN LOWER(dp_gl.InstrumentDisplayName) LIKE '%bond%' THEN 'Bond' ELSE 'Non Bond' END,
dp_gl.InstrumentDisplayName, dp_gl.Name, dp_gl.global_new_volume, dp_us.us_new_volume, dp_gl.global_new_volume-dp_us.us_new_volume