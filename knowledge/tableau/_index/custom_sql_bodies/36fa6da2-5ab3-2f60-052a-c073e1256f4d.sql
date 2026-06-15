SELECT final.CID
		,final.FTD_Date
		,final.V3_Date
		,DATEDIFF(DAY,final.FTD_Date,GETDATE()) AS 'Days_From_FTD'
		,CASE WHEN final.FTD_Date>=final.V3_Date THEN 'FTD after V3'
		ELSE 'FTD_before V3' END 'FTD_Date_Ind',
		CAST(GETDATE() AS DATE) AS 'Sent_Date'
  FROM --select from final table
 		(SELECT boc.CID
				,a.FirstTimeDepositSuccessDate AS 'FTD_Date'
				,MIN(boc.ValidFrom) AS 'V3_Date'
				
		  FROM [etoro_rep].History.BackOfficeCustomer boc WITH (NOLOCK) -- to find V3 first date
		  INNER JOIN [etoro_rep].BackOffice.Customer c WITH (NOLOCK) ON boc.CID = c.CID AND c.RegulationID IN (4,10) --AU regulations
		  INNER JOIN etoro_rep.Customer.CustomerStatic cs   WITH (NOLOCK) ON c.CID = cs.CID AND cs.CountryID=12
		  INNER JOIN	(SELECT  CID
								 ,FirstTimeDepositSuccessDate
			       
						 FROM [etoro_rep].[BackOffice].[CustomerAllTimeAggregatedData_1]   WITH (NOLOCK)--FTD Date
						 WHERE FirstTimeDepositSuccessDate <= DATEADD(DAY,-2,CAST(GETDATE() AS DATE))
						       AND  FirstTimeDepositSuccessDate >= DATEADD(DAY,-5,CAST(GETDATE() AS DATE))
						        
						 )  a	ON a.CID=boc.CID
	      LEFT JOIN     ( SELECT distinct pt.CID
						 FROM [etoro_rep].[Trade].PositionTbl pt WITH(nolock) --find customers from AU that oppened at least 1 psoition, 
																			  --then to exclude them
						 INNER JOIN [etoro_rep].BackOffice.Customer c WITH (NOLOCK) ON pt.CID = c.CID AND c.RegulationID IN (4,10)
						 WHERE pt.Occurred>= DATEADD(DAY,-5,CAST(GETDATE() AS DATE)) 
						 
						 UNION
		
						 SELECT  DISTINCT pt.CID
						 FROM [etoro_rep].History.Position  pt WITH(nolock)	--find custo,ers from AU that oppened at least 1 psoition, 
																			 --then to exclude them
						 INNER JOIN [etoro_rep].BackOffice.Customer c WITH (NOLOCK) ON pt.CID = c.CID AND c.RegulationID IN (4,10)
						 WHERE pt.OpenOccurred>= DATEADD(DAY,-5,CAST(GETDATE() AS DATE))
						 AND pt.CloseOccurred >=DATEADD(DAY,-5,CAST(GETDATE() AS DATE))
				      ) trd ON trd.CID=c.CID
 WHERE boc.VerificationLevelID=3 AND trd.CID IS null --exclude with FA
 GROUP BY boc.CID,
          a.FirstTimeDepositSuccessDate
		 ) final

 WHERE  IIF (final.FTD_Date>=final.V3_Date ,2,5) =DATEDIFF(DAY,final.FTD_Date,CAST(GETDATE() AS DATE))