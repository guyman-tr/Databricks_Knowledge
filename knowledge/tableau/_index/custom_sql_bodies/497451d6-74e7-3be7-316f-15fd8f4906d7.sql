select 
	red.RedeemID, 
	red.CID, 
	red.AmountOnRequest, 
	mt.InstrumentDisplayName as Instrument, 
	LastModificationDate,
	pl.Name as PlayerLevel,
        rs.DisplayName as RedeemStatus,
dr.Name as Regulation,
max (CASE WHEN R.UserGroupID=2 AND R.Approved =1 THEN 'Yes' ELSE 'No' END) AS OPSApproved,
MAX (CASE WHEN R.UserGroupID=3 AND R.Approved =1 THEN 'Yes' ELSE 'No' END) AS RiskApproved,
MAX (CASE WHEN R.UserGroupID=6 AND R.Approved =1 THEN 'Yes' ELSE 'No' END) AS TradingApproved,
MAX (CASE WHEN  R.UserGroupID=36 AND R.Approved =1 THEN 'Yes' ELSE 'No' END) AS AMLApproved,
MAX (CASE WHEN  R.UserGroupID=1 AND R.Approved =1 THEN 'Yes' ELSE 'No' END) AS AmdinistratorsApproved
 from  BI_DB_dbo.External_etoro_Billing_Redeem red 
join DWH_dbo.Dim_Customer cc on cc.RealCID=red.CID 
JOIN [BI_DB_dbo].[External_etoro_Trade_InstrumentMetaData] mt on mt.InstrumentID=red.InstrumentID
join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=cc.PlayerLevelID
join DWH_dbo.Dim_RedeemStatus rs on rs.RedeemStatusID=red.RedeemStatusID
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=cc.RegulationID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_RedeemApproval R ON R.RedeemID=red.RedeemID

WHERE 
cast(LastModificationDate as date)>=dateadd(DAY,-30,cast(getdate()as date)) and cast(LastModificationDate as date)<cast(getdate() as date) 
AND red.RedeemStatusID=1
GROUP BY
red.RedeemID, 
	red.CID, 
	red.AmountOnRequest, 
	mt.InstrumentDisplayName, 
	LastModificationDate,
	pl.Name ,
    rs.DisplayName,
dr.Name,
R.RedeemID