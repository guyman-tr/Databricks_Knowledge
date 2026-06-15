SELECT bdcd.CID
      ,bdcd.State
   ,bdfa.FirstAction
   ,CAST (bdcd.registered AS DATE) AS RegistrationDate
   ,CAST (bdcd.FirstDepositDate AS DATE)FirstDepositDate
FROM BI_DB_dbo.BI_DB_CIDFirstDates  bdcd
LEFT JOIN DWH_dbo.Dim_Customer dc
ON dc.RealCID=bdcd.CID
LEFT JOIN BI_DB_dbo.BI_DB_First5Actions bdfa
ON bdcd.CID = bdfa.CID
WHERE bdcd.SerialID = 113182
AND bdcd.CountryID = 219
AND bdcd.State != 'Minnesota'
AND bdcd.State != 'Nevada'
AND bdcd.State != 'Tennessee'
AND bdcd.State != 'New York'
AND bdcd.State != 'Puerto Rico'
AND bdfa.FirstAction IS NOT NULL
AND dc.RegisteredReal >= '20220301'