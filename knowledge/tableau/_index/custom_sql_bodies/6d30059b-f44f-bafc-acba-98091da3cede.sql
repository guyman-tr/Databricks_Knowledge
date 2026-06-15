SELECT dc.IP
          ,dc.RealCID
	  ,dc.Address
	  ,dc.City
	  ,dc.FirstName
	  ,dc.LastName
	  ,dc.MiddleName
	  ,dc.UserName
	  ,vl.RealizedEquity
	  ,vl.PositionPnL
	  ,vl.InProcessCashouts
	  ,vl.TotalCash
	  ,dc.UpdateDate
FROM  DWH_dbo.Dim_Customer dc
INNER JOIN DWH_dbo.V_Liabilities vl ON dc.RealCID=vl.CID AND  vl.DateID=cast(convert(varchar(8),GETDATE()-1,112) as int)
WHERE dc.RealCID=<[Parameters].[Parameter 1]> --change to parametr