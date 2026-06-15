SELECT CID
	  ,dc.GCID
      ,q0.CurrentClub as ClubLevelName
      ,q0.CurrentClub NewClub 
      ,q0.Date as DateFirstTimeinClub
      ,dc.UserName
      ,dc.FirstName
      ,Rtrim(dl.Name) as Language
	  ,dc1.Name Country
	  ,dc.Email
	  ,dc1.CountryID

FROM
(
SELECT cclo.CID
      ,cclo.CurrentClub
	  ,cclo.Date
	  ,ROW_NUMBER() OVER (PARTITION BY CID ORDER BY cclo.Date DESC) rn
FROM BI_DB_dbo.BI_DB_ClubChangeLogProduct cclo WITH (NOLOCK)
WHERE cclo.CurrentClub  IN ('Platinum','Platinum Plus','Diamond')
AND NOT EXISTS
(
SELECT *
FROM BI_DB_dbo.BI_DB_ClubChangeLogProduct ccl 
WHERE 
ccl.CID = cclo.CID
AND 
ccl.CurrentClub  IN ('Platinum','Platinum Plus','Diamond')
AND ccl.Date <<[Parameters].[Parameter 1]>
)
AND CONVERT(char(6),cclo.Date,112) = CONVERT(char(6),<[Parameters].[Parameter 1]>,112)
)q0
INNER JOIN DWH_dbo.[Dim_Customer] dc 
ON q0.CID = dc.RealCID
INNER JOIN DWH_dbo.[Dim_Language] dl 
ON dc.LanguageID = dl.LanguageID
INNER JOIN DWH_dbo.[Dim_Country] dc1 
ON dc.CountryID = dc1.CountryID
WHERE q0.rn = 1
AND dc.IsDepositor = 1
--AND dc.AccountTypeID NOT IN (6,15)
AND ISNULL(dc.AccountStatusID,1) = 1