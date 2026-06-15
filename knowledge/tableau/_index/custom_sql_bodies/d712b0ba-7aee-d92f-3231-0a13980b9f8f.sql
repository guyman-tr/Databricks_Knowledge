SELECT em.*
       ,CASE WHEN em.Country IN ('Norway','Sweden','Finland','Denmark','Iceland') THEN 'Non_Euro'
	        WHEN em.Country = 'United Kingdom' THEN 'GBP'
	   ELSE 'Euro' END AS 'Euro_Non_Euro'
FROM [eMoney_dbo].[eMoney_Daily_MIMO_New_Reports_Action] em