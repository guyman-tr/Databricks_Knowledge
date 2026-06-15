SELECT a.Date 
       ,a.CID
	  ,a.Curr_RegulationID
	  ,dr.Name AS Curr_Regulation
	  ,a.Prev_RegulationID
	  ,dr1.Name AS Prev_Regulation
	  ,cm.RealizedEquity
	  ,cm.Credit
	  ,cm.BonusCredit
	  ,cm.TotalCash
	  ,cm.BSLRealFunds

FROM (
		SELECT cast(GETDATE() as Date) Date,
                        boc.CID, 
			   boc.ValidFrom,
			   boc.ValidTo,
			   boc.RegulationID AS Curr_RegulationID,
			   LAG(boc.RegulationID,1,0) OVER(PARTITION BY boc.CID ORDER BY boc.ValidTo ASC) AS Prev_RegulationID
		FROM  [AZR-W-REAL-DB-2-BIDBUser].[etoro].History.BackOfficeCustomer boc
		WHERE boc.ValidFrom > DATEADD(DAY,0 ,CONVERT(CHAR(8), GETDATE(), 112))
	  )a

			 LEFT JOIN [AZR-W-REAL-DB-2-BIDBUser].[etoro].Customer.CustomerMoney cm ON a.CID = cm.CID
			 LEFT JOIN DWH..Dim_Regulation dr ON a.Curr_RegulationID = dr.DWHRegulationID
			 LEFT JOIN DWH..Dim_Regulation dr1 ON a.Prev_RegulationID = dr1.DWHRegulationID

WHERE a.Prev_RegulationID IN (4, 10)
      AND a.Curr_RegulationID NOT IN (4, 10)