select 
	red.RedeemID, 
	red.CID, 
	red.AmountOnRequest, 
	mt.InstrumentDisplayName as Instrument, 
	LastModificationDate,
	pl.Name as PlayerLevel,
        rs.DisplayName as RedeemStatus
		,
dr.Name as Regulation
 from  BI_DB_dbo.External_etoro_Billing_Redeem red 
join DWH_dbo.Dim_Customer cc on cc.RealCID=red.CID 
join DWH_dbo.Dim_Position p on p.PositionID=red.PositionID
JOIN [DWH_dbo].[Dim_Instrument] mt on mt.InstrumentID=p.InstrumentID
join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=cc.PlayerLevelID
join [DWH_dbo].[Dim_RedeemStatus] rs on rs.RedeemStatusID=red.RedeemStatusID
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=cc.RegulationID
where 
cast(LastModificationDate as date)>=dateadd(DAY,-30,cast(getdate()as date))