SELECT   c.RealCID CID
        ,c.LastTierID
		,dpl.Name AS LastTier
        ,c.CurrentTierID
		,c.CurrentTier
        ,c.FromDateID
		,CASE WHEN mda.CID IS NOT NULL THEN 1 ELSE 0 END AS IS_eTM
		,CASE WHEN c.CountryID=218 THEN 'UK' ELSE 'EU' END AS 'UK/EU'
        ,dd.FullDate Date
        ,cast(convert(varchar(8),dd.FullDate,112) as int) DateID
		,c.CountryID
		,dc.Name
		,mda.AccountProgram
		,mda.AccountSubProgram
FROM  
    (SELECT fsc.RealCID
            ,dr.FromDateID
            ,fsc.AccountManagerID
            ,dr.ToDateID
			,fsc.PlayerLevelID
            ,fsc.PlayerLevelID AS CurrentTierID
			,dpl.Name AS CurrentTier
            ,dpl.Sort currenttier
            ,LAG(fsc.PlayerLevelID,1) OVER (PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ) LastTierID
			,fsc.CountryID
    FROM DWH.dbo.Fact_SnapshotCustomer fsc
    LEFT JOIN DWH.dbo.Dim_Range dr
    ON fsc.DateRangeID = dr.DateRangeID
    LEFT JOIN DWH.dbo.Dim_PlayerLevel  dpl
	ON fsc.PlayerLevelID = dpl.PlayerLevelID
	JOIN eMoney.dbo.eMoney_Dim_Country_Rollout mdcr 
	ON fsc.CountryID = mdcr.CountryID

    LEFT JOIN 
            (
            SELECT DISTINCT fsc.RealCID
                            ,dr.FromDateID
            FROM DWH.dbo.Fact_SnapshotCustomer fsc
            LEFT JOIN DWH.dbo.Dim_Range dr
            ON fsc.DateRangeID = dr.DateRangeID
            WHERE dr.FromDateID >=20230101
            AND fsc.IsDepositor = 1
            AND fsc.PlayerLevelID IN (7,6,2,3,5)
            ) 
        cc
        ON fsc.RealCID = cc.RealCID
    ) c
JOIN DWH.dbo.Dim_PlayerLevel  dpl
ON c.LastTierID = dpl.PlayerLevelID
JOIN DWH.dbo.Dim_Date dd
ON c.FromDateID = dd.DateKey
AND c.FromDateID >=20221201
AND c.currenttier>dpl.Sort
AND c.PlayerLevelID IN (2,3,6,7,5)
LEFT JOIN eMoney.dbo.eMoney_Dim_Account mda 
ON c.RealCID = mda.CID 
AND mda.IsValidETM=1 
AND mda.GCID_Unique_Count=1
JOIN DWH.dbo.Dim_Country dc ON c.CountryID=dc.CountryID