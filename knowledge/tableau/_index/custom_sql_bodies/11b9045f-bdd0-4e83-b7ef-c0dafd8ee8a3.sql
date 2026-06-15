SELECT dh.CID
	 , dh.DepositID
	 , dh.FundingType
	 , dh.[Amount in $]
	 , dh.PaymentStatus
	 , dh.[Country (customer)]
	 , dh.IsFTD
	 , dr.Name AS Regulation
         , pl.Name as PlayerLevel
	 , cast (dh.ModificationDate AS DATE) AS ApproveDate
         , dh.UpdateDate
FROM [BI_DB_All_Deposit_Hourly] dh
JOIN DWH..Dim_Customer dc
	ON dc.RealCID = dh.CID
JOIN DWH..Dim_Regulation dr
	ON dc.RegulationID = dr.DWHRegulationID
join DWH..Dim_PlayerLevel pl
    on dc.PlayerLevelID = pl.PlayerLevelID
WHERE dh.PaymentStatus = 'Approved'