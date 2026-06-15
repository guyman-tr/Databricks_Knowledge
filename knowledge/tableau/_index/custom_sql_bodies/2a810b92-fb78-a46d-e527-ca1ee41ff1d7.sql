SELECT  ewi.CryptoID
	  , ewi.GCID
,dc.RealCID
	  , ewi.WalletID
	  , ewi.IsPromotionReady
	  , n.UserFirstDate
	  , n.WalletFirstDate
	  , e.TranDate as 'Sent Out Date'
	  , e.Amount as 'Sent Out Amount'
	 , Case when ewi.IsPromotionReady =1 then 'Yes' else 'No' End 'Get Promotion?'
	, case when e.GCID is not null then 'Shipped Out' else 'Kept' end as 'Did What?'
  , case when n.GCID is not null then 'Yes' else 'No' end as 'New User'
   , case when n.GCID is not null then 'Yes' else 'No' end as 'New Wallet'
	  , ewi.Allocated as Date
	  , c.Name as Country
	 , dc.FirstDepositDate
,dc.AffiliateID
	,Case WHEN dc.UserName LIKE '%RedeemProd%' OR
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
 FROM EXW.dbo.EXW_WalletInventory ewi with (NOLOCK) 
JOIN DWH..Dim_Customer dc 		ON ewi.GCID = dc.GCID and ewi.CryptoID =2
JOIN DWH..Dim_Country c        on dc.CountryID = c.CountryID 
left JOIN dbo.EXW_New_UserAndWallet n on ewi.GCID = n.GCID and ewi.CryptoID = n.CryptoId
left JOIN dbo.EXW_New_UserAndWallet n1 on ewi.GCID = n1.GCID and ewi.WalletID = n1.WalletID and ewi.CryptoID = n.CryptoId
LEFT JOIN
	(
	select distinct GCID, TranDate, Amount 	from EXW.dbo.EXW_FactTransactions-- with (NOLOCK)
	where 1=1	and CryptoId = 2 and ActionTypeID = 1 and IsConversion =0 AND GCID > 0 AND Amount between  0.06 and 0.1
		) e ON ewi.GCID = e.GCID 

where ewi.Allocated >=<[Parameters].[Parameter 2]>


--select * from EXW.dbo.EXW_WalletInventory ewi where ewi.GCID =5431414

--select * from dbo.EXW_FactBalance efb where efb.GCID =5431414

--select * from dbo.EXW_New_UserAndWallet efb where efb.GCID =5431414