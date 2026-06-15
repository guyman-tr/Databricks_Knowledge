SELECT fca.RealCID,
       fca.Amount,
	 --  fca.HistoryID,
	   fca.IsRedeem,
	   dcr.Name AS 'Compensation Reason',
	   CASE WHEN fca.ActionTypeID=8 AND fca.IsRedeem=1 THEN 'Redeem to Wallet' else dat.Name end AS 'ActionType',
	   fca.Occurred
FROM DWH_dbo.Fact_CustomerAction fca
INNER JOIN DWH_dbo.Dim_ActionType dat ON fca.ActionTypeID = dat.ActionTypeID
LEFT JOIN DWH_dbo.Dim_CompensationReason dcr ON fca.CompensationReasonID = dcr.CompensationReasonID
WHERE fca.ActionTypeID IN (7,8,36,9,38) and fca.RealCID=<[Parameters].[Parameter 1]>  AND fca.DateID>= cast(convert(varchar(8),DATEADD(month,-3,GETDATE()),112) as int)