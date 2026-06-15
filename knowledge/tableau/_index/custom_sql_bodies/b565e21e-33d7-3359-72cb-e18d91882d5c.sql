SELECT CAST(fca.Occurred AS DATE) LoginDate,r.Name as Regulation,  count(DISTINCT fca.RealCID) dau_by_login
	--fca.RealCID, dr.FromDateID, dr.ToDateID
FROM [DWH_dbo].[Fact_CustomerAction] fca
JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID 
    AND fsc.CountryID in (219,166,214) 
    AND fsc.RegulationID IN (14) 
    AND fsc.DesignatedRegulationID  IN (14) 
    AND fsc.IsValidCustomer=1
JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
left join DWH_dbo.Dim_Regulation r on r.ID = fsc.RegulationID
WHERE fca.ActionTypeID = 14
	AND fca.DateID >= CONVERT(nvarchar(8), DATEADD(WEEK,-10, GETDATE()),112)
group by CAST(fca.Occurred AS DATE),r.Name