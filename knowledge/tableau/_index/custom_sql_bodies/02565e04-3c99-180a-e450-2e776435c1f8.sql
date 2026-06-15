SELECT 
 CAST(AffiliateID AS CHAR) AS AffiliateID,
Aff_Country, 
AffiliatesGroupsName,
YearMonth, 
ISNULL(SUM(Registration),0) AS Registration,
ISNULL(SUM(FTD),0) AS FTD,
ISNULL(SUM(FTDA),0) AS FTDA, 
ISNULL(SUM(Lead_Comm),0) AS Lead_Comm,
ISNULL(SUM(TotalCommission),0) AS TotalCommission ,
ISNULL(SUM(Lead_Comm),0) + ISNULL(SUM(TotalCommission),0) AS  'TotalCommission_IncludeLeadComm_OnlyAffiliateChannel',
ISNULL(SUM(NetRevenues),0) AS NetRevenues,
ISNULL(SUM(NetRevenues),0) - ISNULL(SUM(Lead_Comm),0) - ISNULL(SUM(TotalCommission),0)  AS Profitability

FROM #temp 

WHERE 
    Channel = 'Affiliate'
AND YearMonthID >= '202406'

GROUP BY 
 CAST(AffiliateID AS CHAR),
Aff_Country, 
AffiliatesGroupsName,
YearMonth
--======