SELECT  tr.GCID
       ,tr.RealCID
	   ,tr.CryptoId
	   ,tr.TranID
       ,tr.CryptoName
       ,tr.TranDate 
	   ,tr.DateOccured
	   ,tr.Amount 
	   ,tr.AmountUSD  
     	   ,dc1.Name AS Country
	   ,fsc.CountryID
	   ,fsc.RegulationID
       ,tr.ActionTypeID
       ,tr.TranDateID 
       ,drr.Name AS Regulation
	   --,tr.ActionType
	   ,CASE
		WHEN dc.IsTestAccount =1   THEN 'TestUser'
		When fsc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
   ,p.Name as 'Club' 
   ,CASE
          WHEN tr.ActionTypeID =1 AND tr.TransactionTypeID=9 then 'Staking' 
          WHEN tr.ActionTypeID =1 AND tr.TransactionTypeID =1   then 'Sent Out'  
          WHEN tr.ActionTypeID =2 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 then 'Recieved from Outside' 
          WHEN tr.ActionTypeID =1 AND tr.IsConversion=1  then 'Conversion (Sent by User to Omnibus)' 
          WHEN tr.ActionTypeID =2 AND tr.IsConversion=1  then 'Conversion (Recieved by User from Omnibus)' 
          WHEN tr.ActionTypeID =2 AND tr.IsRedeem=1  then 'Redeem' 
          WHEN tr.ActionTypeID =2 AND tr.IsPayment=1 then 'Payment' 
END 'Activity'
,CASE WHEN wr.WalletRegulation IS NOT NULL THEN wr.WalletRegulation 
      WHEN edue.JoinDate >='2024-12-18' AND fsc.CountryID IN (191,54) AND fsc.RegulationID = 1 THEN 'eToro DA' -- Spain,Cyprus +   CySEC                                                                                                        
	  WHEN edue.JoinDate >='2024-12-18' AND fsc.CountryID IN (123)   AND fsc.RegulationID = 9 THEN 'eToro SEY'  --Malaysia +FSA Seychelles
	  WHEN (fsc.CountryID IN (219) OR  fsc.RegulationID    IN (7,8,6)) THEN 'US'
          ELSE 'eToroX' END WalletCompany

FROM    EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
        JOIN EXW_dbo.EXW_DimUser  dc  ON tr.GCID = dc.GCID
		JOIN EXW_dbo.EXW_DimUser_Enriched edue ON tr.GCID = edue.GCID  AND edue.JoinDate >'2019-06-11' --exclude old users when we had not relevant join date anyway ( DA is much newere anyway)
 		--LEFT JOIN EXW_dbo.EXW_TestUsers etu   WITH (nolock) on etu.GCID=tr.GCID
	    JOIN DWH_dbo.Fact_SnapshotCustomer fsc  ON dc.GCID = fsc.GCID
		JOIN DWH_dbo.Dim_Range dr 		ON fsc.DateRangeID = dr.DateRangeID 
				                                                 AND tr.TranDateID between  FromDateID and  ToDateID
   		JOIN DWH_dbo.Dim_Country dc1 ON fsc.CountryID=dc1.CountryID
	   
	    JOIN DWH_dbo.Dim_Regulation drr ON fsc.RegulationID =drr.DWHRegulationID
	    JOIN [DWH_dbo].[Dim_PlayerLevel] p WITH (nolock) on fsc.PlayerLevelID = p.PlayerLevelID
         LEFT JOIN EXW_dbo.EXW_WalletRegulation  wr  ON tr.GCID = wr.GCID 
		                                           AND tr.TranDateID BETWEEN  wr.FromDateID AND  wr.ToDateID 
	   			where 1=1
			
		
AND tr.TranStatusID =2 
	AND ISNULL(tr.TransactionTypeID,0)NOT IN (10,13)		 
	
	AND  CASE WHEN wr.WalletRegulation IS NOT NULL THEN wr.WalletRegulation 
      WHEN edue.JoinDate >='2024-12-18' AND fsc.CountryID IN (191,54) AND fsc.RegulationID = 1 THEN 'eToro DA' -- Spain,Cyprus +   CySEC                                                                                                        
	  WHEN edue.JoinDate >='2024-12-18' AND fsc.CountryID IN (123)   AND fsc.RegulationID = 9 THEN 'eToro SEY'  --Malaysia +FSA Seychelles
	  WHEN (fsc.CountryID IN (219) OR  fsc.RegulationID    IN (7,8,6)) THEN 'US'
          ELSE 'eToroX' END  ='eToro DA'  
     -- AND tr.SenderAddress NOT IN ('0x5be786ad38f5846f605a8003550074cdfd4899a1', 'rD4G6gtD2KwHqsRf7pcyA8r1neUzXT61ix')--exclude funding and xrpactivation
	AND  tr.TranDate>= edue.JoinDate  --to exclude funding and xrpactivation
and tr.AmountUSD >0.00001 --to exclude dust