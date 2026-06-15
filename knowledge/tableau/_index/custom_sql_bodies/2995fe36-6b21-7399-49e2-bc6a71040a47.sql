SELECT bdad.* 
,dc.PlayerStatusID
,dps.Name AS PlayerStatus
,dc.UserName
,adr.TerminalID
FROM BI_DB..BI_DB_Airdrop_Data bdad  WITH (NOLOCK)
JOIN DWH..Dim_Customer dc WITH (NOLOCK)
ON dc.RealCID = bdad.CID
LEFT JOIN DWH..Dim_PlayerStatus dps  WITH (NOLOCK)
ON dc.PlayerStatusID = dps.PlayerStatusID
LEFT JOIN (
SELECT ad.CID	
,MAX(CAST(ad.ExecutionOccurred AS DATE)) ExecutionOccurred
,MAX(ad.TerminalID) AS TerminalID
FROM [AZR-W-REAL-DB-2-BIDBUser].[etoro].[Trade].[PositionAirdropLog] ad	 WITH (NOLOCK)
WHERE ad.ExecutionOccurred >= '20211201'
AND ad.Result =1
AND ad.TerminalID LIKE '%PROMO%'
GROUP BY ad.CID	
) adr
ON adr.CID = bdad.CID
AND CAST(adr.ExecutionOccurred AS DATE) = bdad.ExecutionOccurred