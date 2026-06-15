SELECT
	cc.RealCID AS CID
   ,cc.UserName
   ,cc.Address
   ,cc.City
   ,SUBSTRING(cc.Zip, 1, 4) AS Zip
   ,cc.Zip AS [Zip (full)]
   ,fd.FirstDepositDate
   ,cc.FirstDepositAmount
   ,fa.FirstAction
   ,fa.FirstInstrument
   ,fd.Channel
   ,cc.RegisteredReal
   ,CASE
		WHEN EXISTS (SELECT
					m.CID
				FROM DWH.dbo.Dim_Mirror m
				WHERE m.CloseDateID = 0
				AND cc.RealCID = m.CID) THEN 1
		ELSE 0
	END AS HasCopyMirror
	, cc.Gender
	, DATEDIFF(YEAR, cc.BirthDate, GETDATE()) AS Age
FROM DWH.dbo.Dim_Customer cc
JOIN BI_DB.dbo.BI_DB_CIDFirstDates fd
	ON cc.RealCID = fd.CID
		AND (fd.FirstDepositDate >= DATEADD(YEAR, -2, GETDATE())) --or fd.FirstDepositDate >= DateAdd(Day,-21,GetDate()))
LEFT JOIN BI_DB.dbo.BI_DB_First5Actions fa
	ON cc.RealCID = fa.CID
WHERE cc.CountryID = 218