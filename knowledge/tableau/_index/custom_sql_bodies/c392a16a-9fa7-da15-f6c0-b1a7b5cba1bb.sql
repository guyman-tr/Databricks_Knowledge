SELECT  dc.RealCID
      ,CAST(dc.FirstDepositDate AS DATE) FTDDate
	  ,dc1.Name Country
	  ,dm1.FirstName + ' ' + dm1.LastName AM
	  ,DATEDIFF(DAY,dc.FirstDepositDate,GETDATE()) DaysSinceFTD
	  ,CASE 
		WHEN dm1.FirstName + ' ' + dm1.LastName = 'Tali Salomon'   AND  dc1.Region = 'South & Central America' then 'Spanish (Americas)'
		WHEN dm1.FirstName + ' ' + dm1.LastName = 'Tali Salomon'   AND  dc1.Region = 'Spain' then 'Spanish (Europe)'
		when dm1.FirstName + ' ' + dm1.LastName = 'George Naddaf'	then 'Arabic'
		when dm1.FirstName + ' ' + dm1.LastName = 'Elie Edery'		then 'French'
		when dm1.FirstName + ' ' + dm1.LastName = 'Emanuela Manor'	then 'Italian'
		when dm1.FirstName + ' ' + dm1.LastName = 'Dennis Austinat'	then 'German'
		when dm1.FirstName + ' ' + dm1.LastName = 'Robert Hallamm'	then 'UK'
		when dm1.FirstName + ' ' + dm1.LastName = 'Boulos Shakkourr' AND  dc1.Region ='ROW'	then 'ROW'
		when dm1.FirstName + ' ' + dm1.LastName = 'Boulos Shakkourr' AND  dc1.Region IN ('Eastern Europe') then 'E.Europe' 
		ELSE 'Other Europe' END AS Desk
	  ,dc.FirstDepositAmount
FROM [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Manager] dm1 WITH (NOLOCK)
ON dc.AccountManagerID = dm1.ManagerID
INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK)
ON dc.CountryID = dc1.CountryID
left JOIN [BI_DB].[dbo].[BI_DB_AB_Test] ab
ON dc.RealCID = ab.RealCID
WHERE dc.AccountManagerID IN 
(
94
,268
,664
,753
,880
,957
,1147
)
and dc.FirstDepositAmount <5000
AND ab.RealCID is NULL
AND dc1.Region <> 'Arabic Other'
AND dc.PlayerStatusID <> 2