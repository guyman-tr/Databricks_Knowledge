USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_BillingWithdraw_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS


BEGIN


DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
/***************************
** Change History
**************************
Date           Author        Description   
----------     ----------    ------------------------------------
2024-08-22     Katy F        Add WithdrawTypeID

--**********************************************************************************************************************/


--DECLARE @dt [Date]  = '20211113'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Fact_BillingWithdraw -----------------
	--SELECT [IndRun]
	--FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
	--WHERE [TableName] = 'Fact_BillingWithdraw'
--------------------------------------------------------------------
-- DELETE ROWS ------------------------------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_BillingWithdraw
	WHERE
	ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS int)
	and
	ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS int);
--------------------------------------------------------------------
-- Extract Ext_Fact_BillingWithdraw --------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FBW_Fact_BillingWithdraw
	
;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FBW_Fact_BillingWithdraw
	(
	
WithdrawID
,CID
,CurrencyID
,FundingTypeID_Withdraw
,RequestDate
,Amount_Withdraw
,Commission
,Approved
,ModificationDate
,ModificationDateID
,Fee
,FundingID
,CashoutReasonID
,ClientWithdrawReasonID
,AccountCurrencyID
,CashoutStatusID_Withdraw
,CashoutStatusID_Funding
,ProcessCurrencyID
,ExchangeRate
,Amount_WithdrawToFunding
,ModificationDate_WithdrawToFunding
,AccountIDAsString
,ACHBankAccountIDAsInteger
,BinCodeAsString
,BinCountryIDAsInteger
,BSBNumberAsString
,CardTypeIDAsInteger
,CityAsString
,ClientAddressAsString
,ClientBankNameAsString
,CountryIDAsInteger
,ExpirationDateAsString
,ErrorCodeAsString
,IBANCodeAsString
,InitialTransactionIDAsString
,MD5AsString
,PayeeNameAsString
,PayerPurseAsString
,ReferenceNumberAsString
,ResponseMessageAsString
,ResponseTimeAsString
,RoutingNumberAsString
,SecuredCardDataAsString
,SortCodeAsString
,SwiftCodeAsString
,DepositID
,CashoutTypeID
,VerificationCode
,ProcessorValueDate
,DepotID
,ExchangeFee
,FundingTypeID_Funding
,AccountIDAsDecimal
,AccountNameAsString
,AccountTypeAsString
,BankAccountAsString
,BankAddressAsString
,BankCodeAsString
,BankDetailsAccountIDAsString
,BankIDAsInteger
,BankIDAsString
,BankNameAsString
,CardNumberAsString
,CryptoCodeAsString
,CustomerAddressAsString
,CustomerNameAsString
,EmailAsString
,ExpirationDateID
,InstrumentIDAsInteger
,MaskedAccountIDAsString
,PayerIDAsString
,PurseAsString
,SecureIDAsDecimal
,UpdateDate
,WithdrawPaymentID 
,BaseExchangeRate
,ProtocolMIDSettingsID
,Comment
,CashoutModeID
,FlowID
,WithdrawTypeID
	)
	SELECT
	bw.WithdrawID
	,bw.CID
	,bw.CurrencyID
	,bw.FundingTypeID AS FundingTypeID_Withdraw
	,bw.RequestDate
	,bw.Amount AS Amount_Withdraw
	,bw.Commission
	,cast(bw.Approved AS INT) AS Approved
	,bw.ModificationDate
	,CAST(date_format(DATEADD(day, DATEDIFF(0, bw.ModificationDate), 0), 'yyyyMMdd') AS int) AS ModificationDateID
	,bw.Fee
	,bw.FundingID
	,bw.CashoutReasonID
	,bw.ClientWithdrawReasonID
	,bw.AccountCurrencyID
	,bw.CashoutStatusID AS CashoutStatusID_Withdraw
	,wtf.CashoutStatusID AS CashoutStatusID_Funding
	,wtf.ProcessCurrencyID
	,wtf.ExchangeRate
	,wtf.Amount AS Amount_WithdrawToFunding
	,wtf.ModificationDate AS ModificationDate_WithdrawToFunding
	--  ,wtf.WithdrawData -- parse
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('AccountIDAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('AccountIDAsString',bf.FundingData)) AS AccountIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ACHBankAccountIDAsInteger',wtf.WithdrawData) AS ACHBankAccountIDAsInteger
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('BinCodeAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('BinCodeAsString',bf.FundingData)) AS BinCodeAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('BinCountryIDAsInteger',wtf.WithdrawData) ,dwh_daily_process.migration_tables.ExtractXMLValue('BinCountryIDAsInteger',bf.FundingData)) AS BinCountryIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('BSBNumberAsString',wtf.WithdrawData) AS BSBNumberAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('CardTypeIDAsInteger',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('CardTypeIDAsInteger',bf.FundingData)) AS CardTypeIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('CityAsString',wtf.WithdrawData) AS CityAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ClientAddressAsString',wtf.WithdrawData) AS ClientAddressAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('ClientBankNameAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('ClientBankNameAsString',bf.FundingData)) AS ClientBankNameAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('CountryIDAsInteger',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('CountryIDAsInteger',bf.FundingData)) AS CountryIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',wtf.WithdrawData) AS ExpirationDateAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ErrorCodeAsString',wtf.WithdrawData) as ErrorCodeAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('IBANCodeAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('IBANCodeAsString',bf.FundingData)) as IBANCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('InitialTransactionIDAsString',wtf.WithdrawData) as InitialTransactionIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('MD5AsString',wtf.WithdrawData) as MD5AsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayeeNameAsString',wtf.WithdrawData) as PayeeNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerPurseAsString',wtf.WithdrawData) as PayerPurseAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ReferenceNumberAsString',wtf.WithdrawData) as ReferenceNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ResponseMessageAsString',wtf.WithdrawData) as ResponseMessageAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ResponseTimeAsString',wtf.WithdrawData) as ResponseTimeAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('RoutingNumberAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('RoutingNumberAsString',bf.FundingData)) as RoutingNumberAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('SecuredCardDataAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('SecuredCardDataAsString',bf.FundingData)) as SecuredCardDataAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('SortCodeAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('SortCodeAsString',bf.FundingData)) as SortCodeAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('SwiftCodeAsString',wtf.WithdrawData),dwh_daily_process.migration_tables.ExtractXMLValue('SwiftCodeAsString',bf.FundingData)) as SwiftCodeAsString
	,wtf.DepositID
	,wtf.CashoutTypeID
	,wtf.VerificationCode
	,wtf.ProcessorValueDate
	,wtf.DepotID
	,wtf.ExchangeFee
	,bf.FundingTypeID AS FundingTypeID_Funding
	--,bf.FundingData --parse
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountIDAsDecimal',bf.FundingData) as AccountIDAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountNameAsString',bf.FundingData) as AccountNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountTypeAsString',bf.FundingData ) as AccountTypeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankAccountAsString',bf.FundingData) as BankAccountAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankAddressAsString',bf.FundingData) as BankAddressAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankCodeAsString',bf.FundingData) as BankCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankDetailsAccountIDAsString',bf.FundingData) as BankDetailsAccountIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankIDAsInteger',bf.FundingData) as BankIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankIDAsString',bf.FundingData ) as BankIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankNameAsString',bf.FundingData) as BankNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CardNumberAsString',bf.FundingData) as CardNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CryptoCodeAsString',bf.FundingData) as CryptoCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CustomerAddressAsString',bf.FundingData) as CustomerAddressAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CustomerNameAsString',bf.FundingData) as CustomerNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('EmailAsString',bf.FundingData) as EmailAsString
	,Case when dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',bf.FundingData) is null then 190001
		  when LENGTH(dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',bf.FundingData))<4 then 190001
	      else 
	      200000
	      +
	      RIGHT(dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',bf.FundingData),2) * 100
	      +
	      Left(dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',bf.FundingData),2)
	      end
	as ExpirationDateID
	,dwh_daily_process.migration_tables.ExtractXMLValue('InstrumentIDAsInteger', bf.FundingData) as InstrumentIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('MaskedAccountIDAsString', bf.FundingData) as MaskedAccountIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerIDAsString', bf.FundingData) as PayerIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PurseAsString', bf.FundingData) as PurseAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('SecureIDAsDecimal', bf.FundingData) as SecureIDAsDecimal
	,current_timestamp() as UpdateDate
	,wtf.ID as WithdrawPaymentID 
	,wtf.BaseExchangeRate
	,wtf.ProtocolMIDSettingsID
	,bw.Comment 
	,wtf.CashoutModeID 
	,bw.FlowID
	-----,isnull(bw.SessionID,0) as SessionID 
	, bw.WithdrawTypeID
	FROM dwh_daily_process.daily_snapshot.etoro_Billing_Withdraw bw 
	LEFT JOIN dwh_daily_process.daily_snapshot.etoro_Billing_WithdrawToFunding wtf 
	ON bw.WithdrawID = wtf.WithdrawID
	LEFT JOIN dwh_daily_process.daily_snapshot.etoro_Billing_Funding bf 
	ON wtf.FundingID = bf.FundingID
	where
	-------bw.CashoutStatusID = 3 and
	bw.ModificationDate >=  V_Yesterday AND bw.ModificationDate < V_CurrentDate;
--------------------------------------------------------------------
-- DELETE AND INSERT INTO Fact_BillingWithdraw ------------------------------------------------
  
MERGE INTO dwh_daily_process.migration_tables.Fact_BillingWithdraw w_tgt 
USING (
select *   
FROM dwh_daily_process.migration_tables.Fact_BillingWithdraw w  
INNER JOIN dwh_daily_process.migration_tables.Ext_FBW_Fact_BillingWithdraw e  ON w.`WithdrawID`=e.`WithdrawID`  
)   ON  COALESCE(w.`WithdrawID`,'_NULL_') = COALESCE(w_tgt.`WithdrawID`,'_NULL_') 
WHEN MATCHED THEN DELETE ;
	INSERT INTO dwh_daily_process.migration_tables.Fact_BillingWithdraw 
	(
		`CID`
      ,`WithdrawID`
      ,`CurrencyID`
      ,`FundingTypeID_Withdraw`
      ,`RequestDate`
      ,`Amount_Withdraw`
      ,`Commission`
      ,`Approved`
      ,`ModificationDate`
      ,`ModificationDateID`
      ,`Fee`
      ,`FundingID`
      ,`CashoutReasonID`
      ,`ClientWithdrawReasonID`
      ,`AccountCurrencyID`
      ,`CashoutStatusID_Withdraw`
      ,`CashoutStatusID_Funding`
      ,`ProcessCurrencyID`
      ,`ExchangeRate`
      ,`Amount_WithdrawToFunding`
      ,`ModificationDate_WithdrawToFunding`
      ,`DepositID`
      ,`CashoutTypeID`
      ,`VerificationCode`
      ,`ProcessorValueDate`
      ,`DepotID`
      ,`ExchangeFee`
      ,`FundingTypeID_Funding`
      ,`SecuredCardDataAsString`
      ,`BinCodeAsString`
      ,`BinCountryIDAsInteger`
      ,`CardTypeIDAsInteger`
      ,`ExpirationDateID`
      ,`UpdateDate`
      ,`WithdrawPaymentID`
      ,`AccountIDAsString`
      ,`ACHBankAccountIDAsInteger`
      ,`BSBNumberAsString`
      ,`CityAsString`
      ,`ClientAddressAsString`
      ,`ClientBankNameAsString`
      ,`CountryIDAsInteger`
      ,`ExpirationDateAsString`
      ,`ErrorCodeAsString`
      ,`IBANCodeAsString`
      ,`InitialTransactionIDAsString`
      ,`MD5AsString`
      ,`PayeeNameAsString`
      ,`PayerPurseAsString`
      ,`ReferenceNumberAsString`
      ,`ResponseMessageAsString`
      ,`ResponseTimeAsString`
      ,`RoutingNumberAsString`
      ,`SortCodeAsString`
      ,`SwiftCodeAsString`
      ,`AccountIDAsDecimal`
      ,`AccountNameAsString`
      ,`AccountTypeAsString`
      ,`BankAccountAsString`
      ,`BankAddressAsString`
      ,`BankCodeAsString`
      ,`BankDetailsAccountIDAsString`
      ,`BankIDAsInteger`
      ,`BankIDAsString`
      ,`BankNameAsString`
      ,`CardNumberAsString`
      ,`CryptoCodeAsString`
      ,`CustomerAddressAsString`
      ,`CustomerNameAsString`
      ,`EmailAsString`
      ,`InstrumentIDAsInteger`
      ,`MaskedAccountIDAsString`
      ,`PayerIDAsString`
      ,`PurseAsString`
      ,`SecureIDAsDecimal`
      ,`BaseExchangeRate`
      ,`ProtocolMIDSettingsID`
	  ,`Comment`
	  ,`CashoutModeID`
	  ,FlowID
	  ,WithdrawTypeID
-------------,SessionID
	  )
  SELECT 
		`CID`
      ,`WithdrawID`
      ,`CurrencyID`
      ,`FundingTypeID_Withdraw`
      ,`RequestDate`
      ,`Amount_Withdraw`
      ,`Commission`
      ,`CAST(Approved AS INT)`
      ,`ModificationDate`
      ,`ModificationDateID`
      ,`Fee`
      ,`FundingID`
      ,`CashoutReasonID`
      ,`ClientWithdrawReasonID`
      ,`AccountCurrencyID`
      ,`CashoutStatusID_Withdraw`
      ,`CashoutStatusID_Funding`
      ,`ProcessCurrencyID`
      ,`ExchangeRate`
      ,`Amount_WithdrawToFunding`
      ,`ModificationDate_WithdrawToFunding`
      ,`DepositID`
      ,`CashoutTypeID`
      ,`VerificationCode`
      ,`ProcessorValueDate`
      ,`DepotID`
      ,`ExchangeFee`
      ,`FundingTypeID_Funding`
      ,`SecuredCardDataAsString`
      ,`BinCodeAsString`
      ,`BinCountryIDAsInteger`
      ,`CardTypeIDAsInteger`
      ,`ExpirationDateID`
      ,`UpdateDate`
      ,`WithdrawPaymentID`
      ,`AccountIDAsString`
      ,`ACHBankAccountIDAsInteger`
      ,`BSBNumberAsString`
      ,`CityAsString`
      ,`ClientAddressAsString`
      ,`ClientBankNameAsString`
      ,`CountryIDAsInteger`
      ,`ExpirationDateAsString`
      ,`ErrorCodeAsString`
      ,`IBANCodeAsString`
      ,`InitialTransactionIDAsString`
      ,`MD5AsString`
      ,`PayeeNameAsString`
      ,`PayerPurseAsString`
      ,`ReferenceNumberAsString`
      ,`ResponseMessageAsString`
      ,`ResponseTimeAsString`
      ,`RoutingNumberAsString`
      ,`SortCodeAsString`
      ,`SwiftCodeAsString`
      ,`AccountIDAsDecimal`
      ,`AccountNameAsString`
      ,`AccountTypeAsString`
      ,`BankAccountAsString`
      ,`BankAddressAsString`
      ,`BankCodeAsString`
      ,`BankDetailsAccountIDAsString`
      ,`BankIDAsInteger`
      ,`BankIDAsString`
      ,`BankNameAsString`
      ,`CardNumberAsString`
      ,`CryptoCodeAsString`
      ,`CustomerAddressAsString`
      ,`CustomerNameAsString`
      ,`EmailAsString`
      ,`InstrumentIDAsInteger`
      ,`MaskedAccountIDAsString`
      ,`PayerIDAsString`
      ,`PurseAsString`
      ,`SecureIDAsDecimal`
      ,`BaseExchangeRate`
      ,`ProtocolMIDSettingsID`
	  ,`Comment`
	  ,`CashoutModeID`
	  ,FlowID
		---------,SessionID
		,WithdrawTypeID
	FROM dwh_daily_process.migration_tables.Ext_FBW_Fact_BillingWithdraw;
--------------------------------------------------------------------
-- Execute SQL Task - SP_Fact_BillingWithdraw ----------------------
call dwh_daily_process.migration_tables.SP_Fact_BillingWithdraw(V_date = V_Yesterday);
END;
