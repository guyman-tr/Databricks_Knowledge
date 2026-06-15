SELECT RealCID
	,SUM(CASE WHEN fca1.ActionTypeID IN (7) THEN fca1.Amount END) AS 'Deposit'
        ,SUM(CASE WHEN fca1.ActionTypeID IN (8) THEN (-1*fca1.Amount) END) AS 'Cashout'
	FROM DWH_dbo.Fact_CustomerAction fca1 WITH (NOLOCK)
	WHERE fca1.ActionTypeID IN (7,8)
	AND fca1.DateID>=20240501
	AND fca1.DateID<=20240630
	GROUP BY RealCID