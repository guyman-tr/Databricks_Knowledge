SELECT a.*, ISNULL(b.AMLComment,'No AML Comment') AMLComment
		   ,ISNULL(b.ValidFrom,'1900-01-01') ValidFrom
FROM BI_DB_dbo.BI_DB_AML_Periodic_Review_AR a
LEFT JOIN 
(SELECT hbc.CID
  ,hbc.AMLComment        
  ,ROW_NUMBER() OVER (PARTITION BY hbc.CID ORDER BY hbc.ValidFrom DESC) rankAML
  ,hbc.ValidFrom
FROM [general].[etoro_History_BackOfficeCustomer] hbc
WHERE hbc.AMLComment IS NOT NULL) b ON a.CID=b.CID AND b.rankAML=1
 
WHERE a.CID = <[Parameters].[Parameter 1]>