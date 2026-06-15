SELECT  c.GCID,
dc.RealCID,
       c.CustomerInteractionId,
       c.CompletedDate,
       c.IsActive,
       c.StateAdditionalData,
       c.CountInteractionID1,
       c.TotalCount,
       case when c.StateAdditionalData='Answer-Yes' then 'Approved'
            when c.StateAdditionalData='Answer-No' then 'Not Approved'
            when c.CountInteractionID1>0 then 'ClosedScreen'
            when c.IsActive=1 and (c.TotalCount=0 or c.TotalCount is NULL) then 'No Reaction'
            else 'PopupClosedBySystem' end as InteractionStatus,
	   CONCAT(dm.FirstName,' ' ,dm.LastName )AS 'AgentName',
       dc.AccountManagerID,
       dl.Name AS 'CommunicationLanguage',
	   dpl.Name AS 'Club',
	   dc1.MarketingRegionManualName AS 'MarketingRegion',
	   d.StocksEquity

       
from       
(SELECT  a.GCID,
       a.StateAdditionalData,
       a.CustomerInteractionId,
       a.IsActive,
       a.CompletedDate,
       sum(case when a.UserInteractionId=1 then b.Count else 0 end) as CountInteractionID1,
       sum(b.Count) as TotalCount
FROM [Compliance].[ComplianceStateDB].[Compliance].CustomerInteractions	a
left JOIN [Compliance].[ComplianceStateDB].[Compliance].CustomerInteractionActionCounts b on b.CustomerInteractionId=a.CustomerInteractionId
WHERE UserInteractionId = 31 
GROUP BY   a.GCID,
       a.StateAdditionalData,
       a.CustomerInteractionId,
       a.IsActive,
       a.CompletedDate) c

INNER JOIN DWH..Dim_Customer dc ON  dc.GCID=c.GCID 
LEFT JOIN (SELECT bdagia.RealCID,
                  SUM( bdagia.Invested_Amount+bdagia.Current_PNL ) AS 'StocksEquity'
		   FROM BI_DB..BI_DB_ASIC_GAML_Invested_Amount bdagia
		   GROUP BY bdagia.RealCID	) d ON dc.RealCID=d.RealCID
INNER JOIN DWH..Dim_Language dl ON dc.CommunicationLanguageID = dl.LanguageID
INNER JOIN DWH..Dim_Manager dm ON dm.DWHManagerID=dc.AccountManagerID
INNER JOIN DWH..Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
INNER JOIN DWH..Dim_Country dc1 ON dc.CountryID = dc1.CountryID