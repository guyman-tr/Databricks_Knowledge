select 
	red.RedeemID, 
	red.CID, 
	red.AmountOnRequest, 
	mt.InstrumentDisplayName as Instrument, 
	LastModificationDate,
	pl.Name as PlayerLevel,
        rs.DisplayName as RedeemStatus,
dr.Name as Regulation
 from  BI_DB_dbo.External_etoro_Billing_Redeem red 
join DWH_dbo.Dim_Customer cc on cc.RealCID=red.CID 
JOIN [BI_DB_dbo].[External_etoro_Trade_InstrumentMetaData] mt on mt.InstrumentID=red.InstrumentID
join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=cc.PlayerLevelID
join DWH_dbo.Dim_RedeemStatus rs on rs.RedeemStatusID=red.RedeemStatusID
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=cc.RegulationID
--and RequestDate>=dateadd(month,DATEDIFF(Month,0,dateadd(month,-1,getdate())),0) and red.RedeemStatusID=1
and cast(LastModificationDate as date)>=dateadd(DAY,-30,cast(getdate()as date)) 
--and 
--RedeemStatusID=1