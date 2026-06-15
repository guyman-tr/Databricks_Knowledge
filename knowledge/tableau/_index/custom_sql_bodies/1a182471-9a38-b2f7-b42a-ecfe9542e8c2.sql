SELECT 
	r.RedeemID
	,r.CID
	,r.AmountOnRequest
	,i.InstrumentDisplayName as Instrument
	,r.LastModificationDate
	,pl.Name as PlayerLevel
	,rs.DisplayName as RedeemStatus
	,v.ActualNWA
	,p.InitialUnits as Units
	,re.Name as Regulation
	,ISNULL(ISNULL(p.Amount,0) + ISNULL(p.PnLInDollars,0),0) as CurrentValue
from 
	DWH_dbo.Fact_BillingRedeem r
LEFT JOIN 
	DWH_dbo.Dim_Customer dc on dc.RealCID = r.CID
LEFT JOIN 
	DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN 
	DWH_dbo.Dim_Regulation re on re.ID = dc.RegulationID
left JOIN 
	DWH_dbo.V_Liabilities v ON v.CID=r.CID AND v.DateID=CONVERT(varchar, getdate()-1, 112)
LEFT JOIN 
	DWH_dbo.Dim_Position p on p.PositionID = r.PositionID
LEFT JOIN 
	DWH_dbo.Dim_Instrument i on i.InstrumentID = p.InstrumentID
LEFT JOIN 
	DWH_dbo.Dim_RedeemStatus rs on rs.RedeemStatusID = r.RedeemStatusID
WHere 
	cast(LastModificationDate as date)>=dateadd(DAY,-30,cast(getdate()as date)) 
	and cast(LastModificationDate as date)<=cast(getdate() as date) 
	and r.RedeemStatusID = 1
	--and r.CID = 19541926