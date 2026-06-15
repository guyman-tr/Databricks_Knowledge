select 
 nt.noTX
 --, nt.GCID
 , tx.isTX
 ,tx.GCID
 , tx.RealCID
 , tx.CryptoId
 , tx.[Crypto Name]
 , tx.TranDate
 , tx.TranDateID
 , tx.TranID
 , tx.WalletID
 , tx.[Unit Amount]
 , tx.[USD Amount]
 , tx.ActionTypeID
 , tx.ActionTypeName
 , tx.TransactionTypeID
 , tx.TransactionType
 , tx.IsRedeem
 , tx.IsConversion
 , tx.IsPayment
 , tx.Country
 , tx.IsRealUser
 , tx.Activity
 , tx.JoinDate
 , tx.Club
 , tx.Region
 ,tx.Regulation
 
 FROM 
  
(
select 'Tx last 2 days' as 'isTX'
      ,tr.GCID
      ,tr.RealCID
      ,tr.CryptoId
      ,tr.CryptoName as 'Crypto Name'
      ,tr.TranDate
	  ,tr.TranDateID
	  , tr.TranID
	  , tr.WalletID
	 ,tr.EtoroFees
	 ,tr.EtoroFeesUSD
      ,tr.Amount as 'Unit Amount'
	   ,tr.AmountUSD as 'USD Amount'
      ,tr.ActionTypeID
      ,tr.ActionTypeName
      ,tr.TransactionTypeID
      ,tr.TransactionType
      ,tr.IsRedeem
      ,tr.IsConversion
      ,tr.IsPayment
      , c.Name as Country
      , c.Region
	  ,CASE
		WHEN dc.UserName LIKE '%RedeemProd%' OR
			dc.UserName LIKE '%RedeemProd%' OR
			dc.UserName LIKE '%WalletProd%' OR
			dc.UserName LIKE '%InternalProd%' OR
			dc.UserName LIKE '%NoWalletProd' OR
            dc.UserName = 'RonaMaltz' OR
            dc.UserName = 'DanGanon'
    THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
 ,p.Name as 'Club'
    , dr.Name as 'Regulation'
  , Case
  WHEN tr.ActionTypeID =1 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 and tr.GCID >0  then 'Sent Out (exclude Conversion)' 
  WHEN tr.ActionTypeID =2 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 and tr.GCID >0 then 'Recieved from Outside' 
WHEN tr.ActionTypeID =1 AND tr.IsConversion=1 and tr.GCID >0  then 'Conversion (User sent to Omnibus)' 
WHEN tr.ActionTypeID =2 AND tr.IsConversion=1  and tr.GCID >0  then 'Conversion (User recieved from Omnibus)' 
 WHEN tr.ActionTypeID =2 AND tr.IsRedeem=1  and tr.GCID >0 then 'Redeem' 
 WHEN tr.ActionTypeID =2 AND tr.IsPayment=1 and tr.GCID >0 then 'Payment'
 ---when tr.GCID <=0 and tr.EtoroFees>0 and tr.TransactionTypeID =7 then 'Payment Fees'
 --- when tr.GCID <=0 and tr.EtoroFees>0 and tr.TransactionTypeID =6 then 'Conversion Fees'
ELSE 'NA'
 end 'Activity'
 , e.JoinDate
 FROM
        [EXW_dbo].EXW_FactTransactions tr with (NOLOcK) 
 		JOIN [DWH_dbo].[Dim_Customer] dc WITH (nolock) on dc.RealCID=tr.RealCID
	 JOIN [DWH_dbo].[Dim_PlayerLevel] p WITH (nolock) on dc.PlayerLevelID = p.PlayerLevelID
		JOIN [DWH_dbo].[Dim_Country] c WITH (nolock) on c.CountryID=dc.CountryID
 JOIN DWH_dbo.Dim_Regulation dr WITH (nolock) on dc.RegulationID =dr.DWHRegulationID 
		JOIN EXW_dbo.EXW_DimUser_Enriched e on e.GCID =tr.GCID
			where 1=1
			and tr.TranStatusID=2 --verified 
		--and tr.GCID >0 
		and tr.TranDateID >=  CAST(CONVERT(VARCHAR(8),  DATEADD(Day,-1, getdate()), 112) AS INT)
		and e.JoinDate <= CAST( DATEADD(Month,-6, getdate()) AS DATE)  
)tx
left JOIN
(select 'Tx last 6 month' as 'noTX'
      ,tr.GCID
      FROM
        [EXW_dbo].EXW_FactTransactions tr with (NOLOcK) 
 		JOIN EXW_dbo.EXW_DimUser_Enriched e on e.GCID =tr.GCID
			where 1=1
		and tr.TranDateID >=  CAST(CONVERT(VARCHAR(8),  DATEADD(Month,-6, getdate()), 112) AS INT)
		and tr.TranDateID <  CAST(CONVERT(VARCHAR(8),  DATEADD(Day,-1, getdate()), 112) AS INT)
		and e.JoinDate <= CAST( DATEADD(Month,-6, getdate()) AS DATE)
  ) nt
		
on tx.GCID =nt.GCID 
WHERE nt.GCID is null