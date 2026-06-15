SELECT DATEFROMPARTS(YEAR(bdcsm.FullDate),MONTH(bdcsm.FullDate),1) ActiveDate
       ,bdcsm.CID
       ,bdcsm.Total_Products
	   ,LAG(Total_Products) OVER (PARTITION BY bdcsm.CID ORDER BY FullDate ) Total_Products_Last
FROM BI_DB_dbo.BI_DB_Cross_Selling_Monthly bdcsm
inner join #cid_cross cr
ON bdcsm.CID = cr.CID
AND ActiveDate = DATEFROMPARTS(YEAR(bdcsm.FullDate),MONTH(bdcsm.FullDate),1)