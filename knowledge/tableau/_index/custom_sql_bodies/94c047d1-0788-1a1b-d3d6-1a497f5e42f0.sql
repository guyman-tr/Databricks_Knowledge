select 
r.GCID
 ,r.RealCID
 , r.[Crypto Name] as 'Redeem Crypto'
 , r.TranDate as 'Redeem Date'
 , r.Country
 , r.Region
 , r.IsRealUser
 , r.Regulation
 , r.Club
 , r.[Unit Amount] as 'Redeem USD'
 , r.[Unit Amount] as 'Redeem Coin'
, s.[Crypto Name] as 'Sent out Crypto'
, s.[Unit Amount] as 'Sent out Coin'
, s.[USD Amount] as 'Sent out USD'
, s.TranDate as 'Sent out Date'
from 

(select 
      tr.GCID
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
 FROM
        EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
 		JOIN DWH_dbo.Dim_Customer dc WITH (nolock) on dc.RealCID=tr.RealCID
	 JOIN DWH_dbo.Dim_PlayerLevel p WITH (nolock) on dc.PlayerLevelID = p.PlayerLevelID
		JOIN DWH_dbo.Dim_Country c WITH (nolock) on c.CountryID=dc.CountryID
 JOIN DWH_dbo.Dim_Regulation dr WITH (nolock) on dc.RegulationID =dr.DWHRegulationID 
			where 1=1
			and tr.TranStatusID=2 --verified 
 and tr.ActionTypeID =2 AND tr.IsRedeem=1  and tr.GCID >0 )r

Join

(select 
      tr.GCID
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
      	 FROM
        EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
 					where 1=1
			and tr.TranStatusID=2 --verified 
and tr.ActionTypeID =1 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 and tr.GCID >0) s
on r.GCID=s.GCID and r.TranDateID =s.TranDateID