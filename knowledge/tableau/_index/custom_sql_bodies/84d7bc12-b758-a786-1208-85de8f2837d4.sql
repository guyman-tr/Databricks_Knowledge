SELECT DISTINCT cc.RealCID
	  ,cc.PlayerLevelID
	  ,cc.SortClub
	  ,cc.ClubName
	  ,bdic.CID CIDInterest
	  ,bdic.ValidFrom
	  ,bdic.ValidTo
	  ,mp.Region
	  ,ISNULL(bdic.ConsentStatusID,2) ConsentStatusID
            ,mp.TotalDeposits
		,mp.TotalCashouts
                ,mp.ActiveDate
FROM 
(SELECT DISTINCT fsc.RealCID
		,fsc.PlayerLevelID
		,dpl.Sort SortClub
		,dpl.Name ClubName
		,ROW_NUMBER() OVER (PARTITION BY fsc.RealCID,EOMONTH(dd.FullDate) ORDER BY dd.DateKey DESC) rn
		,DATEFROMPARTS(YEAR(dd.FullDate),MONTH(dd.FullDate),1) StartOfMonth

FROM DWH_dbo.Fact_SnapshotCustomer fsc
JOIN DWH_dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID
JOIN DWH_dbo.Dim_Date dd
ON dd.FullDate = <[Parameters].[EndOfMonth Parameter]>
JOIN DWH_dbo.Dim_PlayerLevel dpl
ON fsc.PlayerLevelID = dpl.PlayerLevelID
WHERE dr.FromDateID<=dd.DateKey--CAST(CONVERT(VARCHAR(10), <[Parameters].[EndOfMonth Parameter]>, 112) AS INT)
AND dr.ToDateID>=dd.DateKey--CAST(CONVERT(VARCHAR(10), <[Parameters].[EndOfMonth Parameter]>, 112) AS INT)
AND fsc.PlayerLevelID IN (2,3,5,6,7)
AND fsc.RegulationID NOT IN (6,7,8,9)
) cc
JOIN BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
ON mp.CID = cc.RealCID
AND mp.ActiveDate = DATEFROMPARTS(YEAR(<[Parameters].[EndOfMonth Parameter]>),MONTH(<[Parameters].[EndOfMonth Parameter]>),1)
LEFT JOIN (
SELECT distinct bdic.CID
		,bdic.ValidFrom
		,bdic.ValidTo
		,bdic.ConsentStatusID
		,ROW_NUMBER() OVER (PARTITION BY bdic.CID ORDER BY bdic.ValidFrom DESC) rn
FROM BI_DB_dbo.BI_DB_InterestConsent bdic
WHERE <[Parameters].[EndOfMonth Parameter]> >= bdic.ValidFrom
AND bdic.ValidTo>=<[Parameters].[EndOfMonth Parameter]>
) bdic
ON bdic.CID = cc.RealCID
AND bdic.rn = 1
WHERE cc.rn = 1