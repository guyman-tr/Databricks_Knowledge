SELECT max(CAST(fca.Occurred AS DATE)) LastLoginDate_ThisMonth, count(DISTINCT fca.RealCID) mau_by_login_to_date,r.Name as Regulation
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
	AND fca.DateID >=FORMAT(GETDATE(), 'yyyyMM') + '01' --CONVERT(nvarchar(8), DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1), 112)
GROUP BY 
	r.Name