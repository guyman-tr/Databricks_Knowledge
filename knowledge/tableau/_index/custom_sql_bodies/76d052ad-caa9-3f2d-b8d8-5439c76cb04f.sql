SELECT tr.GCID
      ,tr.RealCID
	 ,<[Parameters].[Parameter 1]>  FromDate
	  ,<[Parameters].[Parameter 2]>  ToDate
      ,tr.CryptoId
	  ,tr.TranID
      ,tr.CryptoName
      ,tr.TranDate 
	  ,tr.DateOccured
	  ,CAST(tr.LastStatusUpdateOccurred  AS DATE) LastStatusUpdateOccurred
	  ,CASE WHEN tr.DateOccured   BETWEEN  <[Parameters].[Parameter 1]>   AND <[Parameters].[Parameter 2]>  
	   AND  CAST(tr.LastStatusUpdateOccurred  AS DATE)   BETWEEN <[Parameters].[Parameter 1]>  
	   AND <[Parameters].[Parameter 2]> THEN 1
	   ELSE 0 END IsRecordedInPeriod
	  ,tr.Amount 
	  ,tr.AmountUSD  
      ,dc1.Region
	  ,pp.Name AS UserRegion
	  ,dc1.Name AS Country
	  ,fsc.CountryID
	  ,fsc.RegulationID
       ,tr.ActionTypeID
  ,tr.TranDateID 
      ,drr.Name AS Regulation
	  ,CASE
		WHEN dc.IsTestAccount =1   THEN 'TestUser'
		When fsc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
   ,p.Name as 'Club' 
   ,CASE WHEN  ps.CountryID IS NOT NULL THEN  CONCAT(ps.CountryName,ps.Regulation)   ELSE 'Active Country' END 'Closed Country Event'
   ,CASE
          WHEN tr.ActionTypeID =1 AND tr.TransactionTypeID=9 then 'Staking' 
          WHEN tr.ActionTypeID =1 AND tr.TransactionTypeID =1   then 'Sent Out'  
          WHEN tr.ActionTypeID =2 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 then 'Recieved from Outside' 
          WHEN tr.ActionTypeID =1 AND tr.IsConversion=1  then 'Conversion (Sent by User to Omnibus)' 
          WHEN tr.ActionTypeID =2 AND tr.IsConversion=1  then 'Conversion (Recieved by User from Omnibus)' 
          WHEN tr.ActionTypeID =2 AND tr.IsRedeem=1  then 'Redeem' 
          WHEN tr.ActionTypeID =2 AND tr.IsPayment=1 then 'Payment' 
END 'Activity'
/*,CASE WHEN wr.WalletRegulation IS NOT NULL THEN wr.WalletRegulation 
      WHEN edue.JoinDate >='2024-12-18'AND fsc.CountryID IN (191,54) AND fsc.RegulationID = 1 THEN 'eToro DA' -- Spain,Cyprus +   CySEC                                                                                                        
	  WHEN edue.JoinDate >='2024-12-18' AND fsc.CountryID IN (123)   AND fsc.RegulationID = 9 THEN 'eToro SEY'  --Malaysia +FSA Seychelles
	  WHEN (fsc.CountryID IN (219) OR  fsc.RegulationID    IN (7,8,6)) THEN 'US'
          ELSE 'eToroX' END WalletCompany */


,ewe.WalletEntity


FROM         EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
        JOIN EXW_dbo.EXW_DimUser  dc  ON tr.GCID = dc.GCID
		LEFT JOIN EXW_dbo.EXW_DimUser_Enriched edue ON tr.GCID = edue.GCID
 		--LEFT JOIN EXW_dbo.EXW_TestUsers etu   WITH (nolock) on etu.GCID=tr.GCID
	    JOIN DWH_dbo.Fact_SnapshotCustomer fsc  ON dc.GCID = fsc.GCID
		JOIN DWH_dbo.Dim_Range dr 		ON fsc.DateRangeID = dr.DateRangeID 
				                                                 AND tr.TranDateID between  FromDateID and  ToDateID
   		JOIN DWH_dbo.Dim_Country dc1 ON fsc.CountryID=dc1.CountryID
		LEFT JOIN EXW_dbo.EXW_WalletClosedCountryProjects ps 
		                                                  ON fsc.CountryID = ps.CountryID 
									AND (fsc.RegulationID = ps.RegulationID 
											OR ps.RegulationID IS NULL)						   																    
	    JOIN DWH_dbo.Dim_Regulation drr ON fsc.RegulationID =drr.DWHRegulationID
	    JOIN [DWH_dbo].[Dim_PlayerLevel] p WITH (nolock) on fsc.PlayerLevelID = p.PlayerLevelID
        LEFT JOIN  [DWH_dbo].[Dim_State_and_Province] pp ON fsc.RegionID = pp.RegionByIP_ID
		--LEFT JOIN EXW_dbo.EXW_WalletRegulation  wr  ON tr.GCID = wr.GCID  AND tr.TranDateID BETWEEN  wr.FromDateID AND  wr.ToDateID 
		LEFT JOIN EXW_dbo.EXW_WalletEntity ewe ON   tr.GCID = ewe.GCID   AND tr.TranDateID  = ewe.DateID

	   			where 1=1
			
		
AND tr.TranStatusID =2 
			--AND fsc.CountryID =169 ORDER BY [Closed Country Event]

			--and tr.TranDateID BETWEEN   20230101 AND  20231231  
			AND tr.TranDateID BETWEEN CAST(FORMAT(CAST(<[Parameters].[Parameter 1]> AS DATE),'yyyyMMdd') as INT)  AND  CAST(FORMAT(CAST(<[Parameters].[Parameter 2]> AS DATE),'yyyyMMdd') as INT) 
			AND ISNULL(tr.TransactionTypeID,0)NOT IN (10,13)