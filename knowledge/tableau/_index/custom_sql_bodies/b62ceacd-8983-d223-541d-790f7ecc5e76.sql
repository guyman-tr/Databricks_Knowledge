select 
      tr.GCID
      ,tr.RealCID
      ,tr.CryptoId
      ,tr.CryptoName as 'Crypto Name'
      ,tr.TranDate
	  ,tr.TranDateID
	  , tr.TranID
	  , tr.WalletID
	  ,tr.TranStatus
	  , tr.BlockchainTransactionId 
	  , tr.SenderAddress
	  , tr.ReciverAddress
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
      , edu.Country
      , edu.Region
	  , edu.Club
	  , edu.Regulation
	  ,CASE
		WHEN e.IsTestAccount =1     THEN 'TestUser'
		When e.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
   , Case
  WHEN tr.ActionTypeID =1 AND tr.TransactionTypeID =1  then 'Customer Money Out' 
  WHEN tr.ActionTypeID =2 AND tr.IsRedeem=0 and tr.IsConversion=0 and tr.IsPayment=0 and tr.GCID >0 then 'Recieved from Outside' 
WHEN tr.ActionTypeID =1 AND tr.IsConversion=1 and tr.GCID >0  then 'Conversion (Sent by User to Omnibus)' 
WHEN tr.ActionTypeID =2 AND tr.IsConversion=1  and tr.GCID >0  then 'Conversion(Recieved by User from Omnibus)' 
 WHEN tr.ActionTypeID =2 AND tr.IsRedeem=1  and tr.GCID >0 then 'Redeem' 
 WHEN tr.ActionTypeID =2 AND tr.IsPayment=1 and tr.GCID >0 then 'Payment'
 WHEN tr.TransactionTypeID =9 THEN 'Staking'
 ---when tr.GCID <=0 and tr.EtoroFees>0 and tr.TransactionTypeID =7 then 'Payment Fees'
 --- when tr.GCID <=0 and tr.EtoroFees>0 and tr.TransactionTypeID =6 then 'Conversion Fees'
 ELSE 'NA'
 end 'Activity'
 , e.JoinDate
 --, e.Username
-- , e.FirstName
 --, e.LastName
 FROM
        EXW_dbo.EXW_FactTransactions tr with (NOLOcK) 
 	JOIN EXW_dbo.EXW_DimUser_Enriched e on e.GCID =tr.GCID 
	JOIN EXW_dbo.EXW_DimUser edu ON  edu.GCID =tr.GCID
			where 1=1
			--and tr.TranStatusID=2 --verified 
and  (
tr.GCID =  <[Parameters].[Parameter 1]>
OR tr.RealCID = <[Parameters].[Insert GCID (copy)_2542000520539303936]>
OR tr.BlockchainTransactionId =  CAST(<[Parameters].[Parameter 2]> AS VARCHAR(MAX))
 OR tr.SenderAddress  =CAST(<[Parameters].[Parameter 3]> AS VARCHAR(MAX))
 OR tr.ReciverAddress =CAST( <[Parameters].[Parameter 4]> AS VARCHAR(MAX))

)