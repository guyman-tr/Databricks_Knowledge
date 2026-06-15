/*
-can we amend the ITEM ID to only have the numbers (eg 9.3.1.1.(non-remote) - be be amended - 9.3.1.1
- the Monetary value can the minus be amended and the values be positive?
- Payment Visa scheme can be blank
- TerminalLocation needs to be a 2 alpha code not 3
-Can Puerto Rico be added under US?
-Can we add Monaco,Guadalupe and French Riveriea under FR aswell?
-Also for MCC codes can it be amended to the below?
G300 -  (codes between 3000 and 3350)
G335 -  (codes between 3351 and 3500)
G350 - (codes between 3501 and 3999)
So instead of 3000-3350 it is listed as G300
*/
-----


 SELECT sub1.ItemID
        ,NULL AS 'CounterPartArea'
        ,CASE WHEN sub1.LongAbbreviation = 'QZZ' THEN 'XK' 
		      WHEN sub1.LongAbbreviation ='PRI'  THEN 'US' 
			  WHEN sub1.LongAbbreviation  IN ('GLP','MCO','REU') THEN 'FR'
		  ELSE sub1.TerminalLocation   END TerminalLocation
		,sub1.LongAbbreviation  
		,sub1.PaymentScheme
		,CASE WHEN sub1.MCC BETWEEN 3000 and 3350   THEN 'G300' 
		      WHEN sub1.MCC BETWEEN 3351 and 3500   THEN 'G335'
			  WHEN sub1.MCC BETWEEN 3501 and 3999   THEN 'G350'
			  ELSE cast(sub1.MCC AS VARCHAR )END MCC
		,COUNT(sub1.TransactionId)Units
		,SUM(sub1.HolderAmount)Monetaryvalue
		,sub1.HolderCurrencyAlpha
		--,sub1.DateID
	     --,sub1.Date
		,sub1.ExistingUser
		,sub1.AccountSubProgram
		,sub1.IsTestAccount
		,sub1.ProgramName
		,sub1.Type
		,IsPayment
		
  FROM (
  
  SELECT DISTINCT --adding distinct as i saw dupps on data
	  st.AccountId
	  ,st.Bin
	  ,st.TransactionCode
	  ,st.TransactionCodeDescription
	  ,abs(st.HolderAmount) HolderAmount
	  ,st.HolderCurrencyCode
	  ,st.HolderCurrencyAlpha
	  ,st.DateID  
	  ,st.Date 
	  ,st.TransactionId
	   ,CASE WHEN coalesce(d.GCID,d1.GCID) IS NULL THEN 0 ELSE 1 END ExistingUser
	   ,coalesce(d.CID,d1.CID) AS CID
	   ,coalesce(d.AccountSubProgram,d1.AccountSubProgram) AS AccountSubProgram
	   ,coalesce(d.Entity,d1.Entity) AS Entity
	   ,coalesce(d.IsTestAccount,d1.IsTestAccount) AS IsTestAccount
	  ,st.ProgramName
      ,RIGHT(CONCAT('0000', st.Mcc), 4) MCC
      ,st.MerchantCountryCodeAlpha LongAbbreviation 
	  ,dcc.Abbreviation  TerminalLocation
      ,st.MerchantCountryName
, CASE WHEN  st.EntryModeCode  IN (3,8) --E-COMMERCE,MOTO
	  THEN 'Remote' ELSE 'Non-Remote'  END 'Type'
, CASE WHEN  st.EntryModeCode  IN (3,8) --E-COMMERCE,MOTO
	  THEN '9.3.1.2.M2' ELSE '9.3.1.1.M1'  END 'ItemID' 
	    ,st.EntryModeCodeDescription
        ,st.EntryModeCode
		, 'Visa' AS PaymentScheme
,CASE WHEN st.HolderAmount <0 THEN 1 ELSE 0 END IsPayment
FROM eMoney_dbo.ETL_SettlementsTransactions st WITH(NOLOCK)
LEFT JOIN DWH_dbo.Dim_Country dcc 
ON dcc.LongAbbreviation =st.MerchantCountryCodeAlpha

 LEFT JOIN 
 (SELECT DISTINCT 
    mda.GCID
  , mda.CID
  , mda.ProviderHolderID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.Entity
  , mda.IsTestAccount
 FROM eMoney_dbo.eMoney_Dim_Account mda 
 WHERE mda.GCID_Unique_Count=1) d 
	   ON st.AccountId =d.ProviderCurrencyBalanceID
 LEFT JOIN 
(SELECT DISTINCT mda.GCID
  , mda.CID
  , mda.ProviderHolderID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.Entity
  , mda.IsTestAccount

 FROM eMoney_dbo.eMoney_Dim_Account mda 
 WHERE mda.GCID_Unique_Count=1) d1
	   ON st.HolderId =d1.ProviderHolderID 
WHERE  1=1
AND coalesce(d.Entity,d1.Entity) ='eToro Money Malta'
AND st.Date >= <[Parameters].[Parameter 3]>
AND st.Date<= <[Parameters].[Parameter 4]>

 )sub1
 GROUP BY 
         sub1.ItemID
        ,CASE WHEN sub1.LongAbbreviation = 'QZZ' THEN 'XK' 
		      WHEN sub1.LongAbbreviation ='PRI'  THEN 'US' 
			  WHEN sub1.LongAbbreviation  IN ('GLP','MCO','REU') THEN 'FR'
		  ELSE sub1.TerminalLocation   END
		,sub1.LongAbbreviation
		,sub1.PaymentScheme
		,sub1.MCC
		,sub1.HolderCurrencyAlpha
		,sub1.ExistingUser
		,sub1.AccountSubProgram
		,sub1.IsTestAccount
		,sub1.ProgramName
		,sub1.Type
		,IsPayment
----------------------------**********************************---------------------------------------------
UNION ALL

  SELECT sub2.ItemID
        ,NULL AS 'CounterPartArea'
        ,CASE WHEN sub2.LongAbbreviation = 'QZZ' THEN 'XK' 
		      WHEN sub2.LongAbbreviation ='PRI'  THEN 'US' 
			  WHEN sub2.LongAbbreviation  IN ('GLP','MCO','REU') THEN 'FR'
		  ELSE sub2.TerminalLocation   END TerminalLocation
		,sub2.LongAbbreviation
		,sub2.PaymentScheme
		,NULL AS  MCC
		,COUNT(sub2.TransactionId)Units
		,SUM(sub2.HolderAmount)Monetaryvalue
		,sub2.HolderCurrencyAlpha
		--,sub2.DateID
	     --,sub2.Date
		,sub2.ExistingUser
		,sub2.AccountSubProgram
		,sub2.IsTestAccount
		,sub2.ProgramName
		,sub2.Type
		,IsPayment
		
  FROM (
  
  SELECT DISTINCT --adding distinct as i saw dupps on data
	  st.AccountId
	  ,st.Bin
	  ,st.TransactionCode
	  ,st.TransactionCodeDescription
	  ,abs(st.HolderAmount) HolderAmount
	  ,st.HolderCurrencyCode
	  ,st.HolderCurrencyAlpha
	  ,st.DateID  
	  ,st.Date 
	  ,st.TransactionId
	   ,CASE WHEN coalesce(d.GCID,d1.GCID) IS NULL THEN 0 ELSE 1 END ExistingUser
	   ,coalesce(d.CID,d1.CID) AS CID
	   ,coalesce(d.AccountSubProgram,d1.AccountSubProgram) AS AccountSubProgram
	   ,coalesce(d.Entity,d1.Entity) AS Entity
	  ,coalesce(d.IsTestAccount,d1.IsTestAccount) AS IsTestAccount
	  ,st.ProgramName
      ,RIGHT(CONCAT('0000', st.Mcc), 4) MCC
      ,st.MerchantCountryCodeAlpha LongAbbreviation 
	  ,dcc.Abbreviation  TerminalLocation
      ,st.MerchantCountryName
, CASE WHEN  st.EntryModeCode  IN (3,8) --E-COMMERCE,MOTO
	  THEN 'Remote' ELSE 'Non-Remote'  END 'Type'
, CASE WHEN  st.EntryModeCode  IN (3,8) --E-COMMERCE,MOTO
	  THEN '9.3.1.2' ELSE '9.3.1.1'  END 'ItemID' 
	    ,st.EntryModeCodeDescription
        ,st.EntryModeCode
		, 'Visa' AS PaymentScheme
,CASE WHEN st.HolderAmount <0 THEN 1 ELSE 0 END IsPayment
FROM eMoney_dbo.ETL_SettlementsTransactions st WITH(NOLOCK)
LEFT JOIN DWH_dbo.Dim_Country dcc 
ON dcc.LongAbbreviation =st.MerchantCountryCodeAlpha
 LEFT JOIN 
 (SELECT DISTINCT 
    mda.GCID
  , mda.CID
  , mda.ProviderHolderID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.Entity
  , mda.IsTestAccount
 FROM eMoney_dbo.eMoney_Dim_Account mda 
 WHERE mda.GCID_Unique_Count=1) d 
	   ON st.AccountId =d.ProviderCurrencyBalanceID
	   LEFT JOIN 
(SELECT DISTINCT mda.GCID
  , mda.CID
  , mda.ProviderHolderID
  , mda.AccountSubProgram
  , mda.ProviderCurrencyBalanceID
  , mda.Entity
  , mda.IsTestAccount

 FROM eMoney_dbo.eMoney_Dim_Account mda 
 WHERE mda.GCID_Unique_Count=1) d1
	   ON st.HolderId =d1.ProviderHolderID 
WHERE  1=1
AND coalesce(d.Entity,d1.Entity) ='eToro Money Malta'
AND st.Date >=  <[Parameters].[Parameter 3]>
AND st.Date<=  <[Parameters].[Parameter 4]>

 )sub2

 GROUP BY 
       sub2.ItemID
       ,CASE WHEN sub2.LongAbbreviation = 'QZZ' THEN 'XK' 
		      WHEN sub2.LongAbbreviation ='PRI'  THEN 'US' 
			  WHEN sub2.LongAbbreviation  IN ('GLP','MCO','REU') THEN 'FR'
		  ELSE sub2.TerminalLocation   END
	   ,sub2.LongAbbreviation
		,sub2.PaymentScheme
		--,sub2.MCC
		,sub2.HolderCurrencyAlpha
		,sub2.ExistingUser
		,sub2.AccountSubProgram
		,sub2.IsTestAccount
		,sub2.ProgramName
		,sub2.Type
		,IsPayment