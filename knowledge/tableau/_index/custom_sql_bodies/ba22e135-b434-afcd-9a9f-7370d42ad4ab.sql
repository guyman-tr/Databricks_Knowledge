SELECT a.Regulatiuon
      ,COUNT(*) AS TotalCIDs
	  ,sum(ISNULL(a.CFDs_Amount, 0)) AS CFDs_Amount
	  ,sum(isnull(a.CFDs_PnL, 0)) AS CFDs_PnL
	  ,sum(isnull(a.CFDs_Equity, 0)) AS CFDs_Equity
	  ,sum(isnull(a.CFDs_Crypto_Amount, 0)) AS CFDs_Crypto_Amount
	  ,sum(isnull(a.CFDs_Crypto_PnL, 0)) AS CFDs_Crypto_PnL
	  ,sum(isnull(a.CFDs_Crypto_Equity, 0)) AS CFDs_Crypto_Equity

FROM
(SELECT a.RealCID
      ,r.Name AS Regulatiuon
	  ,isnull(b.CFDs_Amount, 0) AS CFDs_Amount
	  ,isnull(b.CFDs_PnL, 0) AS CFDs_PnL
	  ,isnull(b.CFDs_Equity, 0) AS CFDs_Equity
	  ,isnull(b.CFDs_Crypto_Amount, 0) AS CFDs_Crypto_Amount
	  ,isnull(b.CFDs_Crypto_PnL, 0) AS CFDs_Crypto_PnL
	  ,isnull(b.CFDs_Crypto_Equity, 0) AS CFDs_Crypto_Equity

FROM BI_DEV..CID_List_ASIC_to_Seychell_CSV a

     INNER JOIN DWH.dbo.Fact_SnapshotCustomer f ON a.RealCID = f.RealCID
	                                           AND f.IsCreditReportValidCB = 1
     INNER JOIN DWH.dbo.Dim_Range dr ON f.DateRangeID = dr.DateRangeID
                                    AND CONVERT(CHAR(8), GETDATE()-1, 112)  BETWEEN dr.FromDateID and dr.ToDateID										 
     INNER JOIN DWH..Dim_Regulation r ON f.RegulationID = r.DWHRegulationID

	 LEFT JOIN (SELECT b.CID,
	                   SUM(b.Amount) AS CFDs_Amount,
					   SUM(b.PositionPnL) AS CFDs_PnL,
					   SUM(b.Amount) + SUM(b.PositionPnL) AS CFDs_Equity,
					   SUM(CASE WHEN di.InstrumentTypeID = 10 THEN b.Amount ELSE 0 END) AS CFDs_Crypto_Amount,
					   SUM(CASE WHEN di.InstrumentTypeID = 10 THEN b.PositionPnL ELSE 0 END) AS CFDs_Crypto_PnL,
					   SUM(CASE WHEN di.InstrumentTypeID = 10 THEN b.Amount + b.PositionPnL ELSE 0 END) AS CFDs_Crypto_Equity
	            FROM BI_DB..BI_DB_PositionPnL b 
				INNER JOIN DWH..Dim_Instrument di ON b.InstrumentID = di.InstrumentID
                WHERE b.DateID = CONVERT(CHAR(8), GETDATE()-1, 112) 
				AND b.IsSettled = 0
                GROUP BY b.CID
			   )b ON a.RealCID = b.CID) a

GROUP BY a.Regulatiuon