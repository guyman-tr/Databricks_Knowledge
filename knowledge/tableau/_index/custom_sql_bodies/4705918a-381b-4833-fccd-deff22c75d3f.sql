SELECT 
count(distinct bdafm.CID) AS #OfClients,
bdafm.SerialID AS AffiliateID,
ps.Name as PlayerStatus,
CAST(CONVERT(VARCHAR(6), dc.RegisteredReal , 112) AS INT) as RegisteredYearMonth,
bdafm.Country,
bdafm.Verified,
CASE WHEN dc.PlayerStatusID in (2,4) then 1 else 0 end Blocked, 
max(case when v.CID is null then 0 else 1 end) as [DocAlerts]
FROM BI_DB_dbo.BI_DB_CIDFirstDates bdafm
join DWH_dbo.Dim_Customer dc on dc.RealCID=bdafm.CID
JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
left join [BI_DB_dbo].[BI_DB_Document_Vendors] v on v.CID=bdafm.CID AND 
											v.reasonList IS NOT NULL AND 
											v.reasonList NOT LIKE ('%Ok%') 
										AND
										(
										v.reasonList LIKE ('%Forged Document%') OR 
										v.reasonList LIKE ('%Not Authentic%') OR
										v.reasonList LIKE ('%Document On Printed Paper%')
										)

WHERE bdafm.SerialID IS NOT NULL 
AND dc.RegisteredReal>='20220901'
group by 
bdafm.SerialID,
ps.Name,
CAST(CONVERT(VARCHAR(6), dc.RegisteredReal , 112) AS INT),
bdafm.Country,
bdafm.Verified,
CASE WHEN dc.PlayerStatusID in (2,4) then 1 else 0 end,
bdafm.CID