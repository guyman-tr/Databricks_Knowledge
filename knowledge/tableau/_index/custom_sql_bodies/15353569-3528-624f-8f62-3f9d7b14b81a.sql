SELECT tt.CID
	  ,tt.DepositDate
	  ,tt.DepositAmount
	  ,bdsmu.Name [Account Manager]
	  ,bdsmu.AccountManagerID ManagerID
	  ,CASE WHEN tt.DepositAmount IS NULL THEN 0
			WHEN tt.DepositAmount<192000 THEN 1 ELSE 2 END Bonus
            ,bdsmu.Position
            ,bdsmu.IsActive
            ,bdsmu.Team
FROM BI_DB_SF_M_Users bdsmu
LEFT JOIN (SELECT bdad.CID
		,CAST(bdad.ModificationDate AS DATE) DepositDate
		,dm1.FirstName + ' ' + dm1.LastName [Account Manager] 
		,dm1.ManagerID
		,SUM(bdad.[Amount in $]) DepositAmount
FROM BI_DB_AllDeposits bdad
JOIN DWH.dbo.Fact_SnapshotCustomer fsc
ON bdad.CID = fsc.RealCID
JOIN DWH.dbo.Dim_Manager dm1
ON dm1.ManagerID = fsc.AccountManagerID
JOIN DWH.dbo.Dim_Range dr
ON fsc.DateRangeID = dr.DateRangeID
AND bdad.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID
WHERE bdad.ModificationDate>EOMONTH(DATEADD(MONTH,-4,GETDATE()))
And PaymentStatus = 'Approved'
GROUP BY bdad.CID
		,CAST(bdad.ModificationDate AS DATE) 
		,dm1.FirstName + ' ' + dm1.LastName 
		,dm1.ManagerID
HAVING SUM(bdad.[Amount in $])>=96000) tt
ON tt.ManagerID =bdsmu.AccountManagerID
WHERE bdsmu.ToDate = '9999-12-31'