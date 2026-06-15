SELECT 
          COUNT(frst.CID) AS Reg,
	  SUM(CASE WHEN dc.IsDepositor = 1 THEN 1 ELSE 0 END) AS FTD,
          dc.BannerID,
          frst.SerialID,
	  cntr.Name AS Country
	      

FROM BI_DB_dbo.BI_DB_CIDFirstDates AS frst
JOIN DWH_dbo.Dim_Customer AS dc    ON dc.RealCID = frst.CID 
JOIN DWH_dbo.Dim_Country  AS cntr  ON frst.CountryID = cntr.CountryID 


WHERE dc.BannerID in ('21525','21495','21492','21490','21491','21419','21494','21496','21493')
GROUP BY 
          dc.BannerID,
          frst.SerialID,
	 cntr.Name