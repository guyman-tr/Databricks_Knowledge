select  
        CAST(pos.OpenOccurred AS DATE) AS OpenDate,
		EOMONTH(pos.OpenOccurred) EndOfMonth,
		inst.Name,
		inst.InstrumentType,
		inst.Exchange,
		pos.Leverage,
		pos.IsBuy,
        frst.NewMarketingRegion AS Region,
		frst.Country,
        frst.Channel,
		frst.SubChannel,
        SUM(CAST(pos.Amount AS BIGINT)) AS #Amount, 
        SUM(CAST(pos.Volume AS BIGINT)) AS #Volume, 
	    COUNT(pos.PositionID) as #Positions

from DWH_dbo.Dim_Position as pos 
join DWH_dbo.Dim_Instrument as inst        on inst.InstrumentID = pos.InstrumentID
JOIN BI_DB_dbo.BI_DB_CIDFirstDates as frst on frst.CID = pos.CID

WHERE 
    (pos.OpenDateID >= '20240801')   
and isnull(pos.IsPartialCloseChild,0) = 0 
and pos.MirrorID = 0 AND ISNULL(pos.IsAirDrop,0) =0 

GROUP BY 
        CAST(pos.OpenOccurred AS DATE),
		EOMONTH(pos.OpenOccurred),
		inst.Name,
		inst.InstrumentType,
		inst.Exchange,
		pos.Leverage,
		pos.IsBuy,
        frst.NewMarketingRegion,
		frst.Country,
        frst.Channel,
		frst.SubChannel