select dc.*, WalletEntity   from EXW_dbo.EXW_AML_Users_Report dc
	LEFT JOIN EXW_dbo.EXW_WalletEntity ewe 
    ON dc.GCID = ewe.GCID
    AND ewe.DateID   = ( SELECT MAX(DateID) FROM EXW_dbo.EXW_WalletEntity) 
WHERE (dc.RealCID = <[Parameters].[Parameter 1]> 
    --OR dc.Email = <[Parameters].[Parameter 2]> 
    OR dc.GCID = <[Parameters].[Parameter 3]>
    OR ProviderUserID = <[Parameters].[Parameter 4]>
OR ProviderUserIDNormalized = <[Parameters].[Parameter 4]>
) 
    AND dc.RealCID NOT IN (0,1) AND dc.GCID NOT IN (0,1)