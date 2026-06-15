SELECT 
	   bdticr.Regulation
	  ,bdticr.DateID
	  ,cast (bdticr.Occurred AS DATE) AS Date
	  ,bdticr.Month
	  ,bdticr.Description
	  ,COUNT(bdticr.CreditID) AS Transactions
	  ,COUNT(DISTINCT bdticr.CID) AS Customers
      ,SUM(bdticr.Payment) AS 'Compensations_Usd'
	  ,CIDs 'CIDs_IND'


FROM BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk bdticr 
LEFT JOIN (SELECT bdticr1.DateID,
                  bdticr1.Description,
				  COUNT(DISTINCT bdticr1.CID) AS CIDs 
           FROM BI_DB_dbo.BI_DB_Technical_Issues_Compensation_Risk bdticr1
		   GROUP BY bdticr1.DateID,
                  bdticr1.Description
		   HAVING COUNT(DISTINCT bdticr1.CID)>1
		   )a ON a.DateID=bdticr.DateID AND a.Description=bdticr.Description
WHERE bdticr.Occurred>='20230101' AND bdticr.Payment>0
GROUP BY  bdticr.Regulation
	  ,bdticr.DateID
	  ,cast (bdticr.Occurred AS DATE)
	  ,bdticr.Month
	  ,bdticr.Description
	  ,CIDs