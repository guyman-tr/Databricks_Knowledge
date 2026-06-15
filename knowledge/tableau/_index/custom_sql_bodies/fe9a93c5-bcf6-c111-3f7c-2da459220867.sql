SELECT
	affconv.YearMonth,
	affconv.NewMarketingRegion AS Region, 
	affconv.Country,
	affconv.AffiliateID,
	affconv.Channel,
	da.Contact,
	da.ContractName,
	da.AffiliatesGroupsName,
	SUM(affconv.Registrations) AS Registrations,
	SUM(affconv.FTD) AS FTD,
	SUM(affconv.V3) AS V3,
    SUM(affconv.TotalCost) AS TotalCost, 
    SUM(affconv.RevShare_Comm) AS RevShare_Comm, 
    SUM(affconv.CPA_Comm) AS CPA_Comm, 
    SUM(affconv.CPL_Comm) AS CPL_Comm, 
    SUM(affconv.Lead_Comm) AS Lead_Comm, 
    SUM(affconv.eCost) AS eCost, 
    SUM(affconv.NetRevenues) AS NetRevenues,
    SUM(affconv.TotalCostRelative_eCost) as TotalCostRelative_eCost,
	SUM(affconv.TotalCommission) AS TotalCommission,
	ISNULL(SUM(ltvftda.FTDA),0) as FTDA,
	ISNULL(SUM(ltvftda.avgLTV),0) AS avgLTV,
	trgts.ftds_target,
    trgts.cpa as CPA_target,
    SUM(depco.totaldeposit) as TotalDeposit,
    SUM(depco.totalco) as TotalCO
FROM #Affconv AS affconv
LEFT JOIN #ltvftda AS ltvftda  
	ON ltvftda.FTDDate = affconv.YearMonth
	AND ltvftda.AffiliateID = affconv.AffiliateID
	AND ltvftda.NewMarketingRegion = affconv.NewMarketingRegion
	AND ltvftda.Country = affconv.Country
LEFT JOIN BI_DB_dbo.External_Fivetran_google_sheets_target_region AS trgts ON trgts.region = affconv.NewMarketingRegion
LEFT JOIN DWH_dbo.Dim_Affiliate as da ON da.AffiliateID = affconv.AffiliateID
LEFT JOIN #totaldepco as depco on 
	depco.YearMonth = affconv.YearMonth AND
	depco.AffiliateID = affconv.AffiliateID AND
	depco.NewMarketingRegion = affconv.NewMarketingRegion AND
	depco.Country = affconv.Country 
GROUP BY 
	affconv.YearMonth, affconv.NewMarketingRegion, affconv.Country, affconv.AffiliateID, affconv.Channel,
	da.Contact, da.ContractName, da.AffiliatesGroupsName, trgts.ftds_target, trgts.cpa