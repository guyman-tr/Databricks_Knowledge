SELECT t.EoM_date, t.Channel, Metric, Value
FROM
(
	SELECT EOMONTH(cast((YearMonth+ '-01') as date)) EoM_date, 
		CASE WHEN SubChannel='YT' THEN 'YouTube'
			WHEN SubChannel='FB' THEN 'Facebook' 
                        when SubChannel='Google UAC' then 'UAC' ELSE SubChannel
		END AS Channel,
		SUM(ISNULL(Registration,0)) Affwiz_Regs,	
		SUM(ISNULL(VerificationLevelID2,0)) AS V2_converted,
		SUM(ISNULL(FTD,0)) AS Affwiz_FTD
	FROM BI_DB.dbo.BI_DB_MarketingMonthlyRawData
	WHERE SubChannel IN ('Google Brand','Google Search','YT','Google UAC','FB') 
	AND NewMarketingRegion='USA' and YearMonthID>= 202301	
	GROUP BY EOMONTH(cast((YearMonth+ '-01') as date)), 			
            CASE WHEN SubChannel='YT' THEN 'YouTube'
		WHEN SubChannel='FB' THEN 'Facebook' 
                when SubChannel='Google UAC' then 'UAC' ELSE SubChannel END 
        --ORDER BY YearMonth, Channel, SubChannel
)t
CROSS APPLY (
		VALUES
			('Affwiz_Regs', EoM_date, Channel, Affwiz_Regs),
			('V2_converted', EoM_date, Channel, V2_converted),
			('Affwiz_FTD', EoM_date, Channel, Affwiz_FTD)
	) 
	AS Unpivoted(Metric, EoM_date, Channel,Value)