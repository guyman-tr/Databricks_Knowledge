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
	  ,CASE WHEN  dc1.CountryID IN (
5
,10
,13
,14
,15
,19
,22
,32
,48
,52
,54
,55
,57
,62
,67
,69
,72
,74
,79
,81
,82
,83
,92
,94
,95
,100
,101
,102
,105
,107
,109
,112
,117
,118
,119
,126
,132
,135
,143
,154
,155
,161
,164
,165
,167
,168
,178
,179
,184
,185
,191
,196
,197
,216
,217
,218
,219
,222
,233
,242
,244
) THEN 1 ELSE 0 END IsValidCountry
FROM
(
SELECT cclo.CID
      ,cclo.CurrentClub
	  ,cclo.Date
	  ,ROW_NUMBER() OVER (PARTITION BY CID ORDER BY cclo.Date DESC) rn
FROM BI_DB_dbo.BI_DB_ClubChangeLogProduct  cclo WITH (NOLOCK)
WHERE cclo.CurrentClub  IN ('Platinum','Platinum Plus','Diamond')
AND NOT EXISTS
(
SELECT *
FROM BI_DB_dbo.BI_DB_ClubChangeLogProduct  ccl WITH (NOLOCK)
WHERE 
ccl.CID = cclo.CID
AND 
ccl.CurrentClub  IN ('Platinum','Platinum Plus','Diamond')
AND ccl.Date <<[Parameters].[Parameter 1]>
)
AND CONVERT(char(6),cclo.Date,112) = CONVERT(char(6),<[Parameters].[Parameter 1]>,112)
)q0
INNER JOIN DWH_dbo.[Dim_Customer] dc WITH (NOLOCK)
ON q0.CID = dc.RealCID
INNER JOIN DWH_dbo.[Dim_Language] dl WITH (NOLOCK)
ON dc.LanguageID = dl.LanguageID
INNER JOIN DWH_dbo.[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
WHERE q0.rn = 1
AND dc.IsDepositor = 1
--AND dc.AccountTypeID NOT IN (6,15)
AND ISNULL(dc.AccountStatusID,1) = 1