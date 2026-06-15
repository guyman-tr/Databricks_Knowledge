select 
distinct stp.RedeemID,
stp.CID,
stp.AmountOnRequest,
stp.LastModificationDate,
stp.RedeemStatus,
MAX(CASE WHEN stp.OPSApproved=1 THEN 1 ELSE 0 END) AS OPSApproved,
MAX(CASE WHEN stp.RiskApproved=1 THEN 1 ELSE 0 END) AS RiskApproved,
MAX(CASE WHEN stp.TradingApproved=1 THEN 1 ELSE 0 END) AS TradingApproved,
MAX(CASE WHEN stp.AMLApproved=1 THEN 1 ELSE 0 END) AS AMLApproved,
MAX(CASE WHEN stp.AmdinistratorsApproved=1 THEN 1 ELSE 0 END) AS AmdinistratorsApproved,
stp.Approval,
stp.PlayerLevel,
stp.Regulation,
MAX ( CASE WHEN wtf.ManagerID=0 and wtf.CashoutStatusID=3 then 'Auto' else 'Manual' END) as ExecutionApproval,
MAX(stp.Units) as Units
, left(di.Name,3) AS Coin, fbr.RequestDate
FROM BI_DB_dbo.BI_DB_STP_Redeems stp
JOIN DWH_dbo.Fact_BillingRedeem fbr ON fbr.RedeemID=stp.RedeemID
JOIN DWH_dbo.Dim_Position dp ON dp.PositionID=fbr.PositionID
JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID=dp.InstrumentID
left join [BI_DB_dbo].[External_etoro_Billing_Redeem] red on red.RedeemID=stp.RedeemID
LEFT JOIN BI_DB_dbo.External_etoro_BackOffice_RedeemApproval R ON R.RedeemID=red.RedeemID
left join [BI_DB_dbo].[External_etoro_Billing_vWithdrawToFunding] wtf on red.WithdrawToFundingID=wtf.ID
--where stp.RedeemID=1176597 
group by
stp.RedeemID,
stp.CID,
stp.AmountOnRequest,
stp.LastModificationDate,
stp.RedeemStatus,
stp.Approval,
stp.PlayerLevel,
stp.Regulation
, left(di.Name,3), fbr.RequestDate