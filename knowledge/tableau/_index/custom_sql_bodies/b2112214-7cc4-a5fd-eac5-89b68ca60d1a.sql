SELECT 
    a.RealCID,
    a.MarketingRegionManualName,
    EOMONTH(a.FirstDepositDate) AS EOM_FTD,
    a.FirstDepositDate,
    a.NegativeMarket_Status_Curr,
    a.Negative_Market_Status_with_History,
    a.DaysInGap_FTD_CFDBlock,
    CASE 
        WHEN ISNULL(a.DaysInGap_FTD_CFDBlock, 9999) < 0 THEN 'Blocked_Before_FTD'
        WHEN ISNULL(a.DaysInGap_FTD_CFDBlock, 9999) BETWEEN 0 AND 30 THEN 'Blocked_Upto30Days'
        WHEN ISNULL(a.DaysInGap_FTD_CFDBlock, 9999) > 30 AND ISNULL(a.DaysInGap_FTD_CFDBlock, 9999) < 9999 THEN 'Blocked_Above30Days'
        WHEN ISNULL(a.DaysInGap_FTD_CFDBlock, 9999) = 9999 THEN 'NotBlocked'
        ELSE 'Check' 
    END AS DaysInGap_Desc,
    a.FirstDepositDateTime,
    a.BlockDate,
    a.Regulation,
	case when a.Regulation in ('ASIC','ASIC & GAML') then 'ASIC & GMEL'
        else a.Regulation end as Regulation_new, 
     Country,
	VerificationLevelID,
	 PlayerLevelID
FROM #Basic_Pop_NM a