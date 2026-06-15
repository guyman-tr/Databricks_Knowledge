---Population

With x as (

SELECT DISTINCT dc.RealCID
,gs.ExternalUserId
,dp.PositionID
,gp.Occurred
,gs.Occurred
,gp.CreatedOn
,gp.NotificationSubCategory
,di.InstrumentType
,gp.notification_alert
,di.InstrumentTypeID
,dp.IsSettled
,di.Symbol
,Left(dp.OpenOccurred,10) AS Date1, Left(gp.Occurred,10) AS Date2
,(CASE WHEN dp.OpenOccurred BETWEEN gp.Occurred AND DATEADD(minute, 10, gp.Occurred) 
    THEN 1 ELSE 0 END) AS PNClass
 FROM main.urban.gold_message_send gs
JOIN main.urban.gold_push_body gp
ON gp.UrbanPushId = gs.body_push_id
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
ON dc.ExternalID = gs.ExternalUserId
JOIN dwh.dim_position dp 
ON dc.RealCID = dp.CID
JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
ON dp.InstrumentID = di.InstrumentID AND Left(dp.OpenOccurred,10) = Left(gp.Occurred,10) AND (CHARINDEX(di.InstrumentDisplayName, gp.notification_alert) > 0 OR (CHARINDEX(di.Symbol, gp.notification_alert) > 0) OR (CHARINDEX(di.SymbolFull, gp.notification_alert) > 0))
WHERE gp.NotificationSubCategory = 'Auto Volatility'
AND dc.RegulationID = 2
AND dp.MirrorID = 0
AND dc.IsDepositor = 1
AND dc.IsValidCustomer = 1

),

--- Counting PN+/- Positions

z as (

Select RealCID, COALESCE(SUM(CASE WHEN PNClass = 1 AND IsSettled = 0 THEN 1 ELSE 0 END),'') AS Count_CFD_PN_Plus
,COALESCE(SUM(CASE WHEN PNClass = 0 AND IsSettled = 0 THEN 1 ELSE 0 END),'') AS Count_CFD_PN_Minus
,COALESCE(SUM(CASE WHEN PNClass = 1 AND IsSettled = 1 AND (InstrumentTypeID = 5 OR InstrumentTypeID = 6) THEN 1 ELSE 0 END),'') AS Count_Stock_PN_Plus
,COALESCE(SUM(CASE WHEN PNClass = 0 AND IsSettled = 1 AND (InstrumentTypeID = 5 OR InstrumentTypeID = 6) THEN 1 ELSE 0 END),'') AS Count_Stock_PN_Minus
,COALESCE(SUM(CASE WHEN PNClass = 1 AND IsSettled = 1 AND (InstrumentTypeID = 10) THEN 1 ELSE 0 END),'') AS Count_Crypto_PN_Plus
,COALESCE(SUM(CASE WHEN PNClass = 0 AND IsSettled = 1 AND (InstrumentTypeID = 10) THEN 1 ELSE 0 END),'') AS Count_Crypto_PN_Minus
FROM x
GROUP BY RealCID
)

--- Percentage PN+/-

Select x.RealCID, COALESCE(ROUND((Count_CFD_PN_Plus / (Count_CFD_PN_Minus + Count_CFD_PN_Plus)) * 100, 2),0) AS CFD_PN_Plus,
    COALESCE(ROUND((Count_CFD_PN_Minus / (Count_CFD_PN_Minus + Count_CFD_PN_Plus)) * 100, 2),0) AS CFD_PN_Minus,
    COALESCE(ROUND((Count_Stock_PN_Plus / (Count_Stock_PN_Minus + Count_Stock_PN_Plus)) * 100, 2),0) AS Stock_ETF_PN_Plus,
    COALESCE(ROUND((Count_Stock_PN_Minus / (Count_Stock_PN_Minus + Count_Stock_PN_Plus)) * 100, 2),0) AS Stock_ETF_PN_Minus,
    COALESCE(ROUND((Count_Crypto_PN_Plus / (Count_Crypto_PN_Minus + Count_Crypto_PN_Plus)) * 100, 2),0) AS Crypto_PN_Plus,
    COALESCE(ROUND((Count_Crypto_PN_Minus / (Count_Crypto_PN_Minus + Count_Crypto_PN_Plus)) * 100, 2),0) AS Crypto_PN_Minus
From x
LEFT JOIN z
ON x.RealCID = z.RealCID
GROUP BY x.RealCID, COALESCE(ROUND((Count_CFD_PN_Plus / (Count_CFD_PN_Minus + Count_CFD_PN_Plus)) * 100, 2), 0),
    COALESCE(ROUND((Count_CFD_PN_Minus / (Count_CFD_PN_Minus + Count_CFD_PN_Plus)) * 100, 2),0),
    COALESCE(ROUND((Count_Stock_PN_Plus / (Count_Stock_PN_Minus + Count_Stock_PN_Plus)) * 100, 2),0),
    COALESCE(ROUND((Count_Stock_PN_Minus / (Count_Stock_PN_Minus + Count_Stock_PN_Plus)) * 100, 2),0),
    COALESCE(ROUND((Count_Crypto_PN_Plus / (Count_Crypto_PN_Minus + Count_Crypto_PN_Plus)) * 100, 2),0),
    COALESCE(ROUND((Count_Crypto_PN_Minus / (Count_Crypto_PN_Minus + Count_Crypto_PN_Plus)) * 100, 2),0)
Order by x.RealCID