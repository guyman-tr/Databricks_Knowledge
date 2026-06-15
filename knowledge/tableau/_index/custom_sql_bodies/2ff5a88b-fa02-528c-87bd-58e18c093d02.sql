SELECT a.*
FROM
(
SELECT f.*, edu.Region, edu.Country,
        dr.Name as Regulation
		,iw.InternalType
		,ROW_NUMBER() OVER (PARTITION BY f.RedeemID ORDER BY [f].[Wallet - RedeemStatus] DESC) AS RN
		,sp.ShortName AS StateCode
		,sp.Name AS State
FROM EXW_dbo.EXW_RedeemReconciliation f
left join DWH_dbo.Dim_Customer dc
    on f.[etoro - CID] = dc.RealCID
join DWH_dbo.Dim_Regulation dr
    on dc.RegulationID = dr.DWHRegulationID
LEFT JOIN EXW_dbo.EXW_DimUser edu
	ON dc.GCID = edu.GCID
LEFT join EXW_dbo.EXW_InternalWallet iw
	on f.[Wallet - SendingWalletID] = iw.Id
LEFT JOIN DWH_dbo.Dim_State_and_Province sp
	ON dc.RegionID = sp.RegionByIP_ID
) a
WHERE a.RN = 1
-- AND a.[etoro - RequestDateID] >= CAST(CONVERT(VARCHAR(8), getdate()-31, 112) AS INT)