SELECT cd.CID, 
	g.GCID, 
	cd.DocumentID, 
	cd.DateAdded, 
	concat(g.FirstName, ' ' , g.LastName) as CustomerName,
	dps.Name AS PlayerStatus,
	dr.Name AS Regulation,
	dr2.Name AS DesignatedRegulation

FROM [DWH_staging].[etoro_BackOffice_CustomerDocumentToDocumentType] dt
join [DWH_staging].[etoro_BackOffice_CustomerDocument] cd on cd.SuggestedDocumentTypeID=dt.DocumentTypeID
join DWH_dbo.Dim_Customer g ON cd.CID = g.RealCID --and g.CountryID in (219, 
join DWH_dbo.Dim_Country dc ON g.CountryID = dc.CountryID and dc.MarketingRegionManualName='USA'
JOIN DWH_dbo.Dim_PlayerStatus dps ON g.PlayerStatusID=dps.PlayerStatusID AND dps.PlayerStatusID<>4
JOIN DWH_dbo.Dim_Regulation dr ON g.RegulationID=dr.ID
JOIN DWH_dbo.Dim_Regulation dr2 ON g.DesignatedRegulationID=dr2.ID

where dt.DocumentTypeID=19
	AND g.RegulationID IN (6,7,8,12) AND g.DesignatedRegulationID IN (7,8,12)
	--and cd.CID=41630129
GROUP BY cd.CID, g.GCID, cd.DocumentID, cd.DateAdded, concat(g.FirstName, ' ', g.LastName), 
	dps.Name, dr.Name, dr2.Name