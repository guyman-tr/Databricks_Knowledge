SELECT DISTINCT cs.TicketID						
               ,cs.CID						
			   ,cs.Role			
			   ,cs.SubType			   
			   ,cs.FirstCsat 			
               ,YEAR(cs.CreatedDate)*100+MONTH(cs.CreatedDate) MonthCreatedDate						
	       ,cs.ServiceLanguage			
	       ,cs.CreatedDate
,MAX(cs.NumberOfTouches)NumberOfTouches												
FROM [dbo].[BI_DB_SF_Cases_New] cs						
JOIN (
SELECT  cs.TicketID						
       ,MAX(cs.Date) MaxDate						
FROM [dbo].[BI_DB_SF_Cases_New] cs						
WHERE cs.CreatedDate >= '20210701'						
AND cs.Source = 'Portal'						
AND cs.Role = 'Tier 2'						
GROUP BY cs.TicketID
)d
ON cs.TicketID = d.TicketID						
AND cs.Date = d.MaxDate						
WHERE cs.CreatedDate >= '20210701'						
AND cs.Source = 'Portal'						
AND cs.Role = 'Tier 2'						
GROUP BY cs.TicketID						
               ,cs.CID						
,cs.Role			
,cs.SubType			   
,cs.FirstCsat 			
,YEAR(cs.CreatedDate)*100+MONTH(cs.CreatedDate) 						
,cs.ServiceLanguage
,cs.CreatedDate