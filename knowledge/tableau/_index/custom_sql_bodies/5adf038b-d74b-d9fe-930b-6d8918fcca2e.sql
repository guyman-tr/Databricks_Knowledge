SELECT  a.AssetType AS AssetType,
  a.Club AS Club,
  a.Copy_IND AS Copy_IND,
  a.CountryID AS CountryID,
  a.Country AS Country,
  a.Current_PNL AS Current_PNL,
  a.Date_Relevance AS Date_Relevance,
  a.GCID AS GCID,
  a.InstrumentType AS InstrumentType,
  a.Invested_Amount AS Invested_Amount,
  a.IsValidCustomer AS IsValidCustomer,
  a.LogginInd AS LogginInd,
  a.PlayerLevelID AS PlayerLevelID,
  a.RealCID AS RealCID,
  a.RegulationID AS RegulationID,
  a.TradingInd AS TradingInd,
  CONCAT(dm.FirstName,' ' ,dm.LastName )AS 'AgentName',
  dc.AccountManagerID,
  dl.Name AS 'CommunicationLanguage',
  dc1.MarketingRegionManualName,
  a.UpdateDate AS UpdateDate
FROM BI_DB..BI_DB_ASIC_GAML_Invested_Amount   a
INNER JOIN DWH..Dim_Customer dc ON  dc.RealCID=a.RealCID  	and dc.RegulationID IN (4,10)
LEFT JOIN DWH..Dim_Country dc1 ON a.CountryID = dc1.CountryID 
LEFT JOIN DWH..Dim_Language dl ON dc.CommunicationLanguageID = dl.LanguageID
LEFT JOIN DWH..Dim_Manager dm ON dm.DWHManagerID=dc.AccountManagerID