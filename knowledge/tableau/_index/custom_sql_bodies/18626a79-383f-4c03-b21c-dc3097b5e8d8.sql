select 
distinct stp.RedeemID,
stp.CID,
stp.AmountOnRequest,
stp.LastModificationDate,
stp.RedeemStatus,
stp.OPSApproved,
stp.RiskApproved,
stp.TradingApproved,
stp.AMLApproved,
stp.AmdinistratorsApproved,
stp.Approval,
stp.PlayerLevel,
stp.Regulation,
stp.ExecutionApproval,
sum(stp.Units) as Units
, left(di.Name,3) AS Coin, fbr.RequestDate
FROM BI_DB_dbo.BI_DB_STP_Redeems stp
JOIN DWH_dbo.Fact_BillingRedeem fbr ON fbr.RedeemID=stp.RedeemID
JOIN DWH_dbo.Dim_Position dp ON dp.PositionID=fbr.PositionID
JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID=dp.InstrumentID
group by
stp.RedeemID,
stp.CID,
stp.AmountOnRequest,
stp.LastModificationDate,
stp.RedeemStatus,
stp.OPSApproved,
stp.RiskApproved,
stp.TradingApproved,
stp.AMLApproved,
stp.AmdinistratorsApproved,
stp.Approval,
stp.PlayerLevel,
stp.Regulation,
stp.ExecutionApproval
, left(di.Name,3), fbr.RequestDate