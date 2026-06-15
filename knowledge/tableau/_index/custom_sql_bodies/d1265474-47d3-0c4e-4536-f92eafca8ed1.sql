SELECT 'eToro Users' AS Users
,  COUNT(*)No
, dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dpl.Name Club
, dr.Name Regulation
, c.Name Country
 ,(SELECT  COUNT(*) FROM DWH.dbo.Dim_Customer dc
JOIN DWH.dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_Regulation dr ON dc.RegulationID=dr.DWHRegulationID
JOIN DWH.dbo.Dim_Country c ON dc.CountryID = c.CountryID
WHERE dc.GCID NOT IN ( SELECT etu.GCID FROM EXW.dbo.EXW_TestUsers etu)
 AND dc.VerificationLevelID =3 
AND   dc.IsValidCustomer =1   
AND dc.PlayerLevelID <>4) AS 'TotalEtoro'
FROM DWH.dbo.Dim_Customer dc
JOIN DWH.dbo.Dim_PlayerLevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_Regulation dr ON dc.RegulationID=dr.DWHRegulationID
JOIN DWH.dbo.Dim_Country c ON dc.CountryID = c.CountryID
WHERE dc.GCID NOT IN ( SELECT etu.GCID FROM EXW.dbo.EXW_TestUsers etu)
 
AND dc.VerificationLevelID =3 
AND   dc.IsValidCustomer =1   
AND dc.PlayerLevelID <>4
GROUP BY 
   dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dpl.Name  
, dr.Name  
, c.Name 

UNION ALL


SELECT 'Wallet Users' AS Users
,  COUNT(*)No
, dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country
, NULL  AS 'TotalEtoro'
FROM EXW.dbo.EXW_DimUser dc 
WHERE dc.IsTestAccount =0 
AND dc.IsValidCustomer =1 
AND dc.VerificationLevelID =3 
AND dc.PlayerLevelID <>4
GROUP BY 
dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country
UNION ALL
SELECT 'Coin Transfer Users' AS Users
,  COUNT(*)No
, dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country
, NULL  AS 'TotalEtoro'
FROM EXW.dbo.EXW_FactTransactions eft 
JOIN EXW.dbo.EXW_DimUser dc ON eft.GCID = dc.GCID
WHERE dc.IsTestAccount =0 
AND dc.IsValidCustomer =1 
AND dc.VerificationLevelID =3 
AND dc.PlayerLevelID <>4
AND eft.IsRedeem =1 
AND eft.ActionTypeID =2
GROUP BY 
dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country

UNION ALL
SELECT 'WalletBalance >100$' AS Users
,  COUNT(*)No
, dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country
, NULL  AS 'TotalEtoro'
FROM
(SELECT SUM(b.[Reporting Balance USD])B
, b.[eToro Unique ID 1 GCID] GCID 
FROM  EXW.dbo.EXW_EOMReportingBalances b 
WHERE   b.ReportingDateID ='20220630'
GROUP BY  b.[eToro Unique ID 1 GCID] 
HAVING SUM(b.[Reporting Balance USD]) >=100
)bal
JOIN EXW.dbo.EXW_DimUser dc ON bal.GCID = dc.GCID
WHERE dc.IsTestAccount =0 
AND dc.IsValidCustomer =1 
AND dc.VerificationLevelID =3 
AND dc.PlayerLevelID <>4
GROUP BY 
dc.RegulationID
, dc.PlayerLevelID
, dc.CountryID
, dc.Club
, dc.Regulation
, dc.Country