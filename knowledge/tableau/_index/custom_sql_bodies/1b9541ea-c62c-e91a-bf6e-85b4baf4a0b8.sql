SELECT	edue.RealCID, edue.GCID, edue.Country, edue.JoinDate , ewe.WalletEntity
FROM EXW_dbo.EXW_DimUser_Enriched edue
LEFT JOIN EXW_dbo.EXW_WalletEntity ewe 
ON edue.GCID = ewe.GCID
AND ewe.DateID   = ( SELECT MAX(DateID) FROM EXW_dbo.EXW_WalletEntity) 
WHERE (edue.RealCID =   <[Parameters].[Parameter 5]>
    --OR dc.Email = <[Parameters].[Parameter 2]> 
    OR edue.GCID =  <[Parameters].[Parameter 6]>
    
) 
    AND edue.RealCID NOT IN (0,1) AND edue.GCID NOT IN (0,1)