SELECT dc.FunnelFromID
       ,CAST(dc.RegisteredReal AS DATE) RegDate
	   ,CAST(dc.FirstDepositDate AS DATE) FtdDate
FROM DWH_dbo.Dim_Customer dc
WHERE dc.RealCID = <[Parameters].[Parameter 1]>