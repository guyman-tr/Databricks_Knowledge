--DROP TABLE IF EXISTS  #transactions
SELECT  tr.GCID
        ,tr.TranDate
	   ,tr.TranDateID
	  ,tr.TranID
      ,tr.EtoroFeesUSD
       ,tr.AmountUSD as 'USD Amount'
      ,tr.ActionTypeID
       ,tr.TransactionTypeID
      ,tr.IsRedeem
      ,tr.IsConversion
      ,tr.IsPayment
      , dc.Country
	  , dc.Region
	  ,CASE
		when dc.IsTestAccount=1
    THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
    ,p.Name as 'Club'
   	, dc.CountryID
	, dc.PlayerLevelID
	, dc.RegulationID
	, dc.Regulation
 -- INTO #transactions
 FROM   EXW_dbo.EXW_FactTransactions  tr  
     LEFT JOIN EXW_dbo.EXW_DimUser  dc  on dc.GCID=tr.GCID
     LEFT JOIN DWH_dbo.Dim_PlayerLevel  p    on dc.PlayerLevelID = p.PlayerLevelID
			WHERE  1=1
			AND tr.TranStatusID=2 
		    AND tr.SenderAddress <>'0x5be786ad38f5846f605a8003550074cdfd4899a1'  --sent promotion omnibus wallet
	        AND ISNULL(tr.TransactionTypeID,0)NOT IN (10,13)
			AND (CASE WHEN  CryptoId  =21 and  ActionTypeID  =2 AND AmountUSD  <=0.000001 then 1 else 0 END ) =0  --dust
			AND tr.TranDateID >=  CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 3, 0) AS DATE),'yyyyMMdd') as INT)