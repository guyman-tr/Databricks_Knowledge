SELECT
        COUNT(DISTINCT  b.[eToro Unique ID 1 GCID]) 'Number Of Users'
	   --,SUM(b.[Reporting Balance]) 'Unit Balance'
	   ,SUM(b.[Reporting Balance USD]) 'USD Balance'
	 --  ,b.Cryptoasset AS 'Crypto Name'
       ,b.ReportingDate AS FullDate
       ,b.Country
       ,b.Regulation
	   ,b.[Closed Country AND Regulation]   AS 'Closed Country Event'
	    ,b.[Test accounting classifier]
FROM EXW.dbo.EXW_EOMReportingBalances  b

WHERE 1 = 1
AND b.[Public Wallet Address] NOT  IN 
---Below is the list of addresses we removing from bloxtable procedure since they are old beta version (staRTING WITH 3) THIS IS temp solution, I need to apply this condition to calculated also
('3GqmgFcTKd9KyzMWPAtFnJNX2kB72So3SD'
,'3JZ2EkmeHFKKWXERXiT5PE9DoJHsDmTNpm'
,'3KjmsAn7YyX84bic8D2C6x3dx4zdXC1DF2'
,'3Peo3MTcv8WBj9NXJFhzt6qtzEa4iTs4bn'
,'3Qjmwe3rVwzrKJNkNHoC8N6Z3u94NmnXwg')
AND b.Cryptoasset <>'MEDX'
AND b.ReportingDateID >= CAST(CONVERT(VARCHAR(8), DATEADD(MONTH,  -<[Parameters].[Parameter 1]>, GETDATE()-1), 112) AS INT)
--AND efb.Balance > 0
GROUP BY
      --  b.Cryptoasset  
       b.ReportingDate  
       ,b.Country
       ,b.Regulation
	   ,b.[Closed Country AND Regulation]    
	    , b.[Test accounting classifier]