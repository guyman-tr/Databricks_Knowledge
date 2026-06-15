SELECT a.*
FROM
(
SELECT f.*, edu.Region, edu.Country,
        dr.Name as Regulation
		,iw.InternalType
		,ROW_NUMBER() OVER (PARTITION BY f.RedeemID ORDER BY [f].[etoro - ModificationDate] DESC) AS RN
		,sp.ShortName AS StateCode
		,sp.Name AS State
FROM EXW_dbo.EXW_RedeemReconciliation  f with (nolock)
left join DWH_dbo.Dim_Customer dc with (nolock)
    on f.[etoro - CID] = dc.RealCID
join DWH_dbo.Dim_Regulation dr with (nolock)
    on dc.RegulationID = dr.DWHRegulationID
LEFT JOIN EXW_dbo.EXW_DimUser edu with (nolock)
	ON dc.GCID = edu.GCID
LEFT join EXW_dbo.EXW_InternalWallet iw with (nolock)
	on f.[Wallet - SendingWalletID] = iw.Id
LEFT JOIN DWH_dbo.[Dim_State_and_Province] sp with (nolock)
	ON dc.RegionID = sp.RegionByIP_ID
) a
WHERE a.RN = 1
-- AND a.[etoro - RequestDateID] >= CAST(CONVERT(VARCHAR(8), getdate()-31, 112) AS INT)