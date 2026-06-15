SELECT cd.*
		,dr1.Name AS Regulation
                ,dc.FirstName
				,dc.LastName
				,dc.Email
                ,dc.GCID
FROM [BI_DB_dbo].[BI_DB_CopyDailyData] as cd with(nolock)
join DWH_dbo.Dim_Customer dc with(nolock)
on dc.RealCID = cd.CID
JOIN DWH_dbo.Dim_Regulation dr1 with(nolock)
ON dr1.DWHRegulationID = dc.RegulationID
where (dc.GuruStatusID >=2 or dc.AccountTypeID=9)
AND cd.DateID>=CONVERT(CHAR(8),'20220101',112)

--SELECT cd.*
--		,dr1.Name AS Regulation
--                ,dc.FirstName
--				,dc.LastName
--				,dc.Email
--                                ,dc.GCID
--FROM DWH_dbo.Fact_SnapshotCustomer sc with(nolock)
--join DWH_dbo.Dim_Range dr with(nolock)
--on dr.DateRangeID = sc.DateRangeID
--join [BI_DB_dbo].[BI_DB_CopyDailyData] as cd with(nolock)
--on cd.CID = sc.RealCID
--and cd.DateID BETWEEN  dr.FromDateID AND dr.ToDateID
--JOIN DWH_dbo.Dim_Regulation dr1 with(nolock)
--ON dr1.DWHRegulationID = sc.RegulationID
--join DWH_dbo.Dim_Customer dc with(nolock)
--on dc.RealCID = cd.CID
--where dc.GuruStatusID >=2 or dc.AccountTypeID=9