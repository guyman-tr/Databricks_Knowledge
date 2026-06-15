SELECT DISTINCT --distinct is a must because of multiple files
      -- aa.WorkDate
      --,aa.ProgramId
	   aa.HolderId
	  ,aa.AccountId
	  ,aa.TransactionCode
	  ,aa.TransactionCodeDescription
	  ,aa.TransactionDateTime
	  ,aa.TransactionCurrencyCode
	  ,aa.TransactionCurrencyAlpha
	  ,aa.TransLink
	  ,aa.TransactionDescription
	  ,aa.ReferenceNumber
	  ,aa.BalanceAdjustmentType
	  ,aa.LoadType
	  ,aa.LoadSource
	  ,aa.Reference
	  ,aa.HolderCurrencyAlpha
	  ,aa.DateID  
	  ,aa.TransactionId
	  ,Date
      ,CASE WHEN aa.HolderCurrencyAlpha = 'GBP' THEN 'eToro Money UK' 
	        WHEN aa.HolderCurrencyAlpha = 'EUR' THEN 'eToro Money Malta' 
			WHEN aa.HolderCurrencyAlpha = 'AUD'  THEN 'eToro Money AUS' 
			ELSE 'New' END AS 'Entity'
      ,aa.Network
	  ,aa.HolderAmount
	  ,aa.ProgramName
      ,CASE WHEN aa.EpmMethodId = 4 THEN 'ClearBank'  
            WHEN aa.EpmMethodId= 5 THEN 'OpenPayd'  
            WHEN aa.EpmMethodId = 6 THEN 'Banking Circle' 
			ELSE 'NA'END  FI
	 
	  ,aa.BankAccountId
	  ,aa.BankAccountSortCode
	  , aa.BankAccountBic
	  ,aa.BankAccountNumber
	  , aa.BankAccountIban
 	  , aa.Action
	  , aa.CountryIson
	  ,aa.ExternalBban
	  ,aa.ExternalIban
	  ,aa.ExternalAccountName
	 
	  , aa.ExternalBic
	  , aa.ExternalSortCode
	   ,aa.ExternalBankAccountId
	  	  ,CASE WHEN aa.Network = 'External Payment' AND aa.TransactionCode<>66  AND aa.HolderAmount>0        THEN 'BankPayIns-External'  --normal tx  in
	        WHEN aa.Network = 'External Payment' AND aa.TransactionCode =65                                   THEN 'BankPayIns-BankingReturn' --banking return ( External Payment	= 65 Inbound Return)
			WHEN                                     aa.TransactionCode =13 AND LoadSource =33	              THEN 'BankPayIns -DebitAdj' --internal Returns (13 - DEBIT_ADJUSTMENT	,33 - Balance adjustment load by system)
						--
            WHEN aa.Network = 'External Payment' AND aa.TransactionCode<>65  AND aa.HolderAmount<0            THEN 'BankPayOuts-External'  --normal tx out
	        WHEN aa.Network = 'External Payment' AND aa.TransactionCode =66                                   THEN 'BankPayOuts-BankingReturn' --banking return ( External Payment	= = 66 Inbound Return)
			WHEN                                     aa.TransactionCode =11 AND LoadSource =33	              THEN 'BankPayOuts-DebitAdj' --internal Returns (11 - DEBIT_ADJUSTMENT	,33 - Balance adjustment load by system)
		             --
           WHEN aa.TransactionCode =1  AND aa.LoadType =1 AND aa.LoadSource IN(30,35,25) THEN 'EtoroDeposits'  --normal tx load(1-load, 1-eWallet,30 - External client Wallet)
	        --
          WHEN aa.TransactionCode =4  AND aa.LoadType =1 AND aa.LoadSource IN(30,35,25) THEN 'EtoroCashouts'  --normal tx unload(4-Unload, 1-eWallet,30 - External client Wallet)
	      WHEN aa.TransactionCode =1  AND aa.LoadType =1 AND aa.LoadSource =34 THEN 'EtoroC2FDeposits'  --normal tx load(1-load, 1-eWallet,34 - Crypto)
	      WHEN aa.TransactionCode IN(11,13)  AND aa.LoadSource IN(31,32) THEN 'BalanceAdjustments'  -- 11-creditadjust,13-debit_adjust 31- balance adj load from Gui  32 - Balance adjustment load from PM API
	      WHEN aa.TransactionCode =79   THEN 'ChargeBackAdjustments-DISPUTE_CREDIT'  --DISPUTE_CREDIT_ADJUSTMENT
	      
			END   ActivityType
	  ,LEFT(aa.BankAccountIban,2) IBANPrefix
	  ,LEFT(aa.ExternalIban,2) ExternalIBANPrefix
	  , dc.Name CountryExternal
	  ,dc1.Name Country
FROM eMoney_dbo.ETL_AccountsActivities aa 
 LEFT JOIN DWH_dbo.Dim_Country dc 
 ON LEFT(aa.ExternalIban,2) =dc.Abbreviation
LEFT JOIN DWH_dbo.Dim_Country dc1 
 ON LEFT(aa.BankAccountIban,2) =dc1.Abbreviation
WHERE aa.Network IN ('Internal Payment', 'External Payment')
      AND aa.TransactionCode NOT IN (6, 14, 15, 24, 25, 64)
	  AND aa.Date >=<[Parameters].[Parameter 1]>
           AND aa.Date<=<[Parameters].[Parameter 2]>
--and aa.HolderCurrencyAlpha = 'EUR'