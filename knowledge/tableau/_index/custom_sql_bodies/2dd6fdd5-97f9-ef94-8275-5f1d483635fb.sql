SELECT  bdcmpfd.Active_Month
       ,bdcmpfd.NewMarketingRegion AS Region
	   ,bdcmpfd.Channel
	   ,YEAR(bdcmpfd.FTDdate) AS FTD_Year
	   ,COUNT(*) AS Churn
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd
INNER JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=bdcmpfd.CID AND dc.IsValidCustomer=1
--INNER JOIN BI_DB_dbo.Function_Population_Churned(20250622) fpc ON dc.RealCID = fpc.RealCID AND fpc.IsChurned=1
LEFT JOIN BI_DB_dbo.BI_DB_LTV_BI_Actual bdlba ON bdcmpfd.CID = bdlba.CID
LEFT JOIN BI_DB_dbo.BI_DB_KYC_Score_CID_Level bdkscl ON dc.RealCID = bdkscl.RealCID
LEFT JOIN (
SELECT 
    vl.CID,
    MAX(CASE 
            WHEN vl.RealizedEquity < 0 THEN 0 
            ELSE vl.RealizedEquity 
        END) AS Max_RealizedEquity
FROM DWH_dbo.V_Liabilities vl WITH(NOLOCK)
GROUP BY 
    vl.CID) e ON e.CID=dc.RealCID
WHERE bdcmpfd.Active_Month>=202401 
AND bdcmpfd.IsEOM_Funded_NEW=0
AND dc.VerificationLevelID=3
AND bdcmpfd.FirstAction IS NOT NULL
GROUP BY bdcmpfd.Active_Month
       ,bdcmpfd.NewMarketingRegion 
	   ,bdcmpfd.Channel
	   ,YEAR(bdcmpfd.FTDdate)