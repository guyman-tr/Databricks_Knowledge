SELECT 
        CAST(bdomkc.ModificationDate AS DATE) AS [ModDate],
        dft.Name AS [FundingType],
        bdomkc.FundingTypeID,
        CASE 
            WHEN bdomkc.Comment LIKE '%Auto Approval%' THEN 1 
            ELSE 0
        END AS [AutoApproval],
        dcr.Name AS [CashoutReason],
        bdomkc.CashoutStatusID,
        bdomkc.Regulation,
        dcy.Name AS [Country_Client],
        dcy.MarketingRegionManualName AS [MarketingRegion_Client],
        dcy.Desk,
        COUNT(DISTINCT bdomkc.CID) AS [UniqCID_Count],
        SUM(bdomkc.Amount) AS [Cashout_Amount],
        SUM(bdomkc.Fee) AS [Fees],
        COUNT(bdomkc.WithdrawID) AS [WithdrawID_Count],
        SUM(bdomkc.SLA) AS [Within_SLA24],
        SUM(bdomkc.SLA48) AS [Within_SLA48],
        SUM(bdomkc.SLA5days) AS [Within_SLA5Days]
    FROM BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Cashouts bdomkc
    INNER JOIN 
		DWH_dbo.Dim_FundingType dft ON bdomkc.FundingTypeID = dft.FundingTypeID
    LEFT JOIN 
		DWH_dbo.Dim_CashoutReason dcr ON bdomkc.CashoutReasonID = dcr.CashoutReasonID
    INNER JOIN
		DWH_dbo.Dim_Customer dc ON bdomkc.CID = dc.RealCID
    INNER JOIN
		DWH_dbo.Dim_Country dcy ON dc.CountryID = dcy.CountryID
    WHERE 
		bdomkc.CashoutReasonID NOT IN (12, 15) -- not affiliate payout or foreclosure
    AND YEAR(bdomkc.RequestDate) >= 2023
    GROUP BY
        CAST(bdomkc.ModificationDate AS DATE),
        dft.Name,
        bdomkc.FundingTypeID,
        CASE 
            WHEN bdomkc.Comment LIKE '%Auto Approval%' THEN 1 
            ELSE 0
        END,
        dcr.Name,
        bdomkc.CashoutStatusID,
        bdomkc.Regulation,
        dcy.Name,
        dcy.MarketingRegionManualName,
        dcy.Desk