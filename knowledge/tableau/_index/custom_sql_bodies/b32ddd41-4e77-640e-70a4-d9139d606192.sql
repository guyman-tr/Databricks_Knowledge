SELECT DISTINCT dm.CID 
FROM DWH_dbo.Dim_Mirror dm
INNER JOIN [DWH_dbo].[Dim_Customer] dc WITH (NOLOCK)
ON dc.RealCID = dm.CID