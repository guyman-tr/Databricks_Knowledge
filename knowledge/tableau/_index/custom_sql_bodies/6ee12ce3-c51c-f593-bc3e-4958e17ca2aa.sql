SELECT DISTINCT p_np.GCID, p_np.GCID_Flag, p_np.BillingPeriod, p_np.TradeMonth, p_np.TradeDate, p_np.BillingKey, p_np.Symbol, 
p_np.ClearingAccount, p_np.OrderID, SUM(p_np.TotalQuantity) TotalQuantity, 
	CASE WHEN BillingKey IN ('SPY','QQQ','IWM') AND p_np.Type_Auxiliar='Simple' THEN 0.1785
		WHEN BillingKey IN ('SPY','QQQ','IWM') AND p_np.Type_Auxiliar='Spread' THEN 0.4335
		WHEN p_np.Symbol_Auxiliar='Penny' AND p_np.Type_Auxiliar='Simple' THEN 0.2125
		WHEN p_np.Symbol_Auxiliar='NonPenny' AND p_np.Type_Auxiliar='Simple' THEN 0.51
		WHEN p_np.Symbol_Auxiliar='Penny' AND p_np.Type_Auxiliar='Spread' THEN 0.442
		WHEN p_np.Symbol_Auxiliar='NonPenny' AND p_np.Type_Auxiliar='Spread' THEN 0.68
	END AS pfof_rate, 
	CASE WHEN BillingKey IN ('SPY','QQQ','IWM') AND p_np.Type_Auxiliar='Simple' THEN 0.1785
		WHEN BillingKey IN ('SPY','QQQ','IWM') AND p_np.Type_Auxiliar='Spread' THEN 0.4335
		WHEN p_np.Symbol_Auxiliar='Penny' AND p_np.Type_Auxiliar='Simple' THEN 0.2125
		WHEN p_np.Symbol_Auxiliar='NonPenny' AND p_np.Type_Auxiliar='Simple' THEN 0.51
		WHEN p_np.Symbol_Auxiliar='Penny' AND p_np.Type_Auxiliar='Spread' THEN 0.442
		WHEN p_np.Symbol_Auxiliar='NonPenny' AND p_np.Type_Auxiliar='Spread' THEN 0.68
	END *SUM(p_np.TotalQuantity) AS pfof_per_order

FROM (
	SELECT DISTINCT op.GCID, 
					CASE WHEN op.GCID IS NOT NULL AND dc.CountryID=218 THEN 'UK Pilot' 
					WHEN op.GCID IS NOT NULL AND dc.CountryID=219 THEN 'New US Signups'
					ELSE  'Legacy Gatsby'  END AS GCID_Flag,
		rev.BillingPeriod, rev.TradeMonth, rev.TradeDate, rev.GatewayRouteRequested,  rev.Symbol, rev.BillingKey,
		rev.Description,
		SUBSTRING(Description, 1, CHARINDEX('_', Description) - 1) AS Venue,
		SUBSTRING(Description, CHARINDEX('_', Description) + 1, CHARINDEX('_', Description, CHARINDEX('_', Description) + 1) - CHARINDEX('_', Description) - 1) AS Type_Auxiliar,
		SUBSTRING(Description, CHARINDEX('_', Description, CHARINDEX('_', Description) + 1) + 1, LEN(Description) - CHARINDEX('_', REVERSE(Description))) AS Symbol_Auxiliar,
		SUM(rev.TotalQuantity) TotalQuantity, rev.OrderID, rev.ClearingAccount
	FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports rev
	LEFT JOIN main.general.bronze_usabroker_apex_options op ON op.OptionsApexID=rev.ClearingAccount
	LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON op.GCID = dc.GCID
	WHERE (ClearingAccount LIKE '%4GS%' or ClearingAccount LIKE '%5GU%' )
	--and rev.TradeMonth = '202305' --AND TradeDate = '2023-05-01 00:00:00'
	AND  rev.Description LIKE '%Penny' 
	--AND rev.OrderID='!1230428034049759'
	--ORDER BY rev.Description
	GROUP BY op.GCID, CASE WHEN op.GCID IS NOT NULL AND dc.CountryID=218 THEN 'UK Pilot' 
					WHEN op.GCID IS NOT NULL AND dc.CountryID=219 THEN 'New US Signups'
					ELSE  'Legacy Gatsby'  END,
		rev.BillingPeriod, rev.TradeMonth, rev.TradeDate, rev.GatewayRouteRequested,  rev.Symbol, rev.BillingKey,
		rev.Description,
		SUBSTRING(Description, 1, CHARINDEX('_', Description) - 1),
		SUBSTRING(Description, CHARINDEX('_', Description) + 1, CHARINDEX('_', Description, CHARINDEX('_', Description) + 1) - CHARINDEX('_', Description) - 1) ,
		SUBSTRING(Description, CHARINDEX('_', Description, CHARINDEX('_', Description) + 1) + 1, LEN(Description) - CHARINDEX('_', REVERSE(Description))), rev.OrderID, rev.ClearingAccount
) p_np
--WHERE p_np.OrderID='!1230525106694452'
GROUP BY p_np.GCID, p_np.GCID_Flag, p_np.BillingPeriod, p_np.TradeMonth, p_np.TradeDate, p_np.BillingKey, p_np.Symbol, 
p_np.Type_Auxiliar, p_np.Symbol_Auxiliar, p_np.ClearingAccount, p_np.OrderID

UNION ALL

SELECT DISTINCT op.GCID, 
					CASE WHEN op.GCID IS NOT NULL AND dc.CountryID=218 THEN 'UK Pilot' 
					WHEN op.GCID IS NOT NULL AND dc.CountryID=219 THEN 'New US Signups'
					ELSE  'Legacy Gatsby'  END AS GCID_Flag,
				p_np.BillingPeriod, p_np.TradeMonth, p_np.TradeDate, p_np.BillingKey, p_np.Symbol, 
				p_np.ClearingAccount, p_np.OrderID, SUM(p_np.TotalQuantity) TotalQuantity, 
	CASE WHEN p_np.Description='NMS_>=1' THEN 0.001275
		WHEN p_np.Description='NMS_Non_Marketable' THEN 0.002465
	END AS pfof_rate,
	CASE WHEN p_np.Description='NMS_>=1' THEN 0.001275
		WHEN p_np.Description='NMS_Non_Marketable' THEN 0.002465
	END *SUM(p_np.TotalQuantity) AS pfof_per_order
FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports p_np
	LEFT JOIN main.general.bronze_usabroker_apex_options op ON op.OptionsApexID=p_np.ClearingAccount
	LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON op.GCID = dc.GCID
WHERE (ClearingAccount LIKE '%4GS%' or ClearingAccount LIKE '%5GU%' )
	--and TradeMonth = '202305' --AND TradeDate = '2023-05-01 00:00:00'
	AND  Description NOT LIKE '%Penny' 
GROUP BY op.GCID, 
					CASE WHEN op.GCID IS NOT NULL AND dc.CountryID=218 THEN 'UK Pilot' 
					WHEN op.GCID IS NOT NULL AND dc.CountryID=219 THEN 'New US Signups'
					ELSE  'Legacy Gatsby'  END, 
	p_np.BillingPeriod, p_np.TradeMonth, p_np.TradeDate, p_np.BillingKey, p_np.Symbol, 
	p_np.ClearingAccount, p_np.OrderID, CASE WHEN p_np.Description='NMS_>=1' THEN 0.001275
		WHEN p_np.Description='NMS_Non_Marketable' THEN 0.002465
	END