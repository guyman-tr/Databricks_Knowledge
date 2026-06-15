SELECT 
    stp.RedeemID,
    stp.CID,
    stp.AmountOnRequest,
    stp.LastModificationDate,
    stp.RedeemStatus,
    MAX(CASE WHEN stp.OPSApproved = 1 THEN 1 ELSE 0 END) AS OPSApproved,
    MAX(CASE WHEN stp.RiskApproved = 1 THEN 1 ELSE 0 END) AS RiskApproved,
    MAX(CASE WHEN stp.TradingApproved = 1 THEN 1 ELSE 0 END) AS TradingApproved,
    MAX(CASE WHEN stp.AMLApproved = 1 THEN 1 ELSE 0 END) AS AMLApproved,
    MAX(CASE WHEN stp.AmdinistratorsApproved = 1 THEN 1 ELSE 0 END) AS AmdinistratorsApproved,
    stp.Approval,
    stp.PlayerLevel,
    stp.Regulation,
    case when wtf.ManagerID=0 and wtf.CashoutStatusID=3 then 'Auto' else 'Manual' end as ExecutionApproval,
    MAX(stp.Units) AS Units,
    LEFT(di.Name, 3) AS Coin,
    fbr.RequestDate
FROM 
    BI_DB_dbo.BI_DB_STP_Redeems stp
JOIN 
    DWH_dbo.Fact_BillingRedeem fbr ON fbr.RedeemID = stp.RedeemID
JOIN 
    DWH_dbo.Dim_Position dp ON dp.PositionID = fbr.PositionID
JOIN 
    DWH_dbo.Dim_Instrument di ON di.InstrumentID = dp.InstrumentID
 join  [BI_DB_dbo].[External_etoro_Billing_Redeem] red  on red.RedeemID=stp.RedeemID
left join [BI_DB_dbo].[External_etoro_Billing_vWithdrawToFunding] wtf on red.WithdrawToFundingID=wtf.ID
GROUP BY 
    stp.RedeemID,
    stp.CID,
    stp.AmountOnRequest,
    stp.LastModificationDate,
    stp.RedeemStatus,
    stp.Approval,
    stp.PlayerLevel,
    stp.Regulation,
    LEFT(di.Name, 3),
    fbr.RequestDate,case when wtf.ManagerID=0 and wtf.CashoutStatusID=3 then 'Auto' else 'Manual' end