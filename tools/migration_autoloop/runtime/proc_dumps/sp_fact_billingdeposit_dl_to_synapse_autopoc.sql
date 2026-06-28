BEGIN


DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
/********************************************************************************************
Author:      Boris Slutski
Date:        2020-07-05
Description: Create SP_Fact_BillingDeposit
 
**************************
** Change History
**************************
Date             Author       Description   
----------     ----------   ------------------------------------
03/02/2025		Daniel		Add columns IsAftSupportedAsBool ,IsAftEligibleAsBool  ,IsAftProcessedAsBool
2025-04-17     Katy F       Switch Amount (line 200) to CASE for handling extreme values. 
*********************************************************************************************/

--declare @dt as date = '02-02-2025' EXEC [DWH_dbo].[SP_Fact_BillingDeposit_DL_To_Synapse] @dt

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Select Parameter Run Ind - Fact_BillingDeposit ------------------
	--SELECT [IndRun]
	--FROM [DWH_dbo].[DataSolutionsTablesRunInd](nolock)
	--where [TableName] = 'Fact_BillingDeposit'
--------------------------------------------------------------------
-- delete rows -----------------------------------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_BillingDeposit 
	WHERE
	ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	and
	ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);
	
--------------------------------------------------------------------
-- Extract Ext_Fact_BillingDeposit ---------------------------------
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_FBD_Fact_BillingDeposit

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_FBD_Fact_BillingDeposit
	(
	   `CID`
      ,`CurrencyID`
      ,`Commission`
      ,`Approved`
      ,`ModificationDate`
      ,`ModificationDateID`
      ,`FundingID`
      ,`ExchangeRate`
      ,`DepositID`
	  ,`ProcessorValueDate`
      ,`DepotID`
      ,`SecuredCardDataAsString`
      ,`BinCodeAsString`
      ,`BinCountryIDAsInteger`
	  ,`CardTypeIDAsInteger`
      ,`PaymentStatusID`
      ,`ManagerID`
      ,`RiskManagementStatusID`
      ,`Amount`
      ,`PaymentDate`
	  ,`IPAddress`
      ,`ClearingHouseEffectiveDate`
      ,`IsFTD`
      ,`RefundVerificationCode`
      ,`MatchStatusID`
      ,`BonusStatusID`
      ,`BonusAmount`
      ,`BonusErrorCode`
      ,`ExTransactionID`
	  ,`FundingTypeID`
      ,`IsRefundExcluded`
      ,`DocumentRequired`
      ,`UpdateDate`
      ,`ExpirationDateID`
      ,`CountryIDAsInteger`
      ,`StateIDAsInteger`
      ,`BankIDAsInteger`
      ,`AccountNameAsString`
	  ,`AccountTypeAsString`
      ,`BankAccountAsString`
      ,`BankAddressAsString`
      ,`BankCodeAsDecimal`
      ,`BankDetailsAccountIDAsString`
      ,`BankIDAsString`
      ,`BankNameAsString`
      ,`BICCodeAsString`
      ,`CIDAsString`
      ,`v`
	  ,`CustomerAddressAsString`
      ,`CustomerNameAsString`
      ,`FundingType`
      ,`MaskedAccountIDAsString`
      ,`PurseAsString`
      ,`RoutingNumberAsString`
      ,`SecureIDAsDecimal`
      ,`SortCodeAsString`
      ,`AccountBalanceAsDecimal`
      ,`AccountHolderAsString`
      ,`AccountIDAsDecimal`
      ,`ACHBankAccountIDAsInteger`
      ,`Address1AsString`
      ,`Address2AsString`
	  ,`AdviseAsString`
      ,`AvailableBalanceAsDecimal`
      ,`BankCodeAsString`
      ,`BillNumberAsString`
      ,`BuildingNumberAsString`
      ,`CardHolderPhoneNumberBodyAsString`
      ,`CardHolderPhoneNumberPrefixAsString`
      ,`CardNumberAsString`
      ,`CityAsString`
      ,`CountryIDAsString`
      ,`CountryNameAsString`
      ,`CreatedAtAsString`
      ,`CurrentBalanceAsDecimal`
      ,`CustomerIDAsString`
      ,`EmailAsString`
      ,`EndPointIDAsString`
	  ,`ErrorCodeAsString`
      ,`ErrorTypeAsString`
      ,`FirstNameAsString`
      ,`IBANCodeAsString`
      ,`InitialTransactionIDAsString`
      ,`IPAsString`
      ,`LanguageIDAsInteger`
      ,`LastNameAsString`
      ,`MD5AsString`
      ,`PayerAsString`
      ,`PayerBusiness`
      ,`PayerIDAsString`
      ,`PayerPurseAsString`
      ,`PayerStatus`
      ,`PaymentAmountAsDecimal`
      ,`PaymentDateAsDateTime`
      ,`PaymentGuaranteeAsString`
      ,`PaymentModeAsInteger`
	  ,`PaymentProviderTransactionStatusAsString`
      ,`PaymentStatusAsInteger`
      ,`PaymentTypeAsString`
      ,`PlaidItemIDAsString`
      ,`PlaidNamesAsString`
      ,`PlatformIDAsInteger`
      ,`PromotionCodeAsString`
      ,`PSPCodeAsString`
      ,`RapidFirstNameAsString`
      ,`RapidLastNameAsString`
      ,`ResponseMessageAsString`
      ,`ResponseTimeAsString`
      ,`SecretKeyAsString`
      ,`ThreeDsAsJson`
      ,`ThreeDsResponseType`
      ,`TokenAsString`
      ,`TransactionIDAsString`
      ,`ZipCodeAsString`
      ,`BaseExchangeRate`
      ,`ExchangeFee`
      ,`ProtocolMIDSettingsID`
      ,`FunnelID`
      ,`SessionID`
      ,`SwiftCodeAsString`
      ,`ClientBankNameAsString`
	  ,PaymentGeneration
	  ,ProcessRegulationID
	  ,MerchantAccountID
	  ,IsSetBalanceCompleted
	  ,RoutingReasonID
	  ,IsRecurring
	  ,FlowID
	  ,IsAftSupportedAsBool
	  ,IsAftEligibleAsBool
	  ,IsAftProcessedAsBool
	)
	SELECT  
	`CID`
	,`CurrencyID`
	,`Commission`
	,CAST(Approved AS INT)
	,`ModificationDate`
	,CAST(date_format(ModificationDate, 'yyyyMMdd') AS int) as ModificationDateID
	,d.`FundingID`
	,`ExchangeRate`
	,`DepositID`
	,`ProcessorValueDate`
	,`DepotID`
	,dwh_daily_process.migration_tables.ExtractXMLValue('SecuredCardDataAsString',f.FundingData) as SecuredCardDataAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BinCodeAsString',f.FundingData) as BinCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BinCountryIDAsInteger',f.FundingData) as BinCountryIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('CardTypeIDAsInteger',f.FundingData) as CardTypeIDAsInteger
	,`PaymentStatusID`
	,d.`ManagerID`
	,`RiskManagementStatusID`
	--,[Amount] -- 2025-04-17 add case to handle extreme values KF. 
	, CASE WHEN Amount >= 1000000000 THEN 99999999 
                WHEN Amount <= -1000000000 THEN -99999999
                ELSE Amount 
            END AS Amount
	,`PaymentDate`
	,`IPAddress`
	,`ClearingHouseEffectiveDate`
	,COALESCE(cast(`IsFTD` as int), 0)  as IsFTD
	,`RefundVerificationCode`
	,`MatchStatusID`
	,`BonusStatusID`
	,`BonusAmount`
	,`BonusErrorCode`
	, ExTransactionID
	,f.`FundingTypeID`
	,cast(f.`IsRefundExcluded` as int) as IsRefundExcluded
	,cast(f.`DocumentRequired` as int) as DocumentRequired
	, current_timestamp() as UpdateDate
	, Case when dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',f.FundingData) is null then 190001
		 when LENGTH(dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',f.FundingData))<4 then 190001
	else 
	200000
	+
	RIGHT(dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',f.FundingData),2) * 100
	+	  
	Left( dwh_daily_process.migration_tables.ExtractXMLValue('ExpirationDateAsString',f.FundingData),2)
	end
	 as ExpirationDateID
	,dwh_daily_process.migration_tables.ExtractXMLValue('CountryIDAsInteger',f.FundingData) as CountryIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('StateIDAsInteger',d.PaymentData) as StateIDAsInteger
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('BankIDAsInteger',d.PaymentData), dwh_daily_process.migration_tables.ExtractXMLValue('BankIDAsInteger',f.FundingData)) as BankIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountNameAsString',f.FundingData) as AccountNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountTypeAsString',f.FundingData) as AccountTypeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankAccountAsString',f.FundingData) as BankAccountAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankAddressAsString',f.FundingData) as BankAddressAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankCodeAsDecimal',f.FundingData) as BankCodeAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankDetailsAccountIDAsString',f.FundingData) as BankDetailsAccountIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankIDAsString',f.FundingData) as BankIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BankNameAsString',f.FundingData) as BankNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BICCodeAsString',f.FundingData) as BICCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CIDAsString',f.FundingData) as CIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ClientBankNameAsString',f.FundingData) as v
	,dwh_daily_process.migration_tables.ExtractXMLValue('CustomerAddressAsString',f.FundingData) as CustomerAddressAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CustomerNameAsString',f.FundingData) as CustomerNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('FundingType',f.FundingData) as FundingType
	,dwh_daily_process.migration_tables.ExtractXMLValue('MaskedAccountIDAsString',f.FundingData) as MaskedAccountIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PurseAsString',f.FundingData) as PurseAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('RoutingNumberAsString',f.FundingData) as RoutingNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('SecureIDAsDecimal',f.FundingData) as SecureIDAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('SortCodeAsString',f.FundingData) as SortCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountBalanceAsDecimal',d.PaymentData) as AccountBalanceAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('AccountHolderAsString',d.PaymentData) as AccountHolderAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('AccountIDAsDecimal',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('AccountIDAsDecimal',f.FundingData)) as AccountIDAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('ACHBankAccountIDAsInteger',d.PaymentData) as ACHBankAccountIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('Address1AsString',d.PaymentData) as Address1AsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('Address2AsString',d.PaymentData) as Address2AsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('AdviseAsString',d.PaymentData) as AdviseAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('AvailableBalanceAsDecimal',d.PaymentData) as AvailableBalanceAsDecimal
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('BankCodeAsString',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('BankCodeAsString',f.FundingData)) as BankCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BillNumberAsString',d.PaymentData) as BillNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('BuildingNumberAsString',d.PaymentData) as BuildingNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CardHolderPhoneNumberBodyAsString',d.PaymentData) as CardHolderPhoneNumberBodyAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CardHolderPhoneNumberPrefixAsString',d.PaymentData) as CardHolderPhoneNumberPrefixAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('CardNumberAsString',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('CardNumberAsString',f.FundingData)) as CardNumberAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CityAsString',d.PaymentData) as CityAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CountryIDAsString',d.PaymentData) as CountryIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CountryNameAsString',d.PaymentData) as CountryNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CreatedAtAsString',d.PaymentData) as CreatedAtAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('CurrentBalanceAsDecimal',d.PaymentData) as CurrentBalanceAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('CustomerIDAsString',d.PaymentData) as CustomerIDAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('EmailAsString',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('EmailAsString',f.FundingData)) as EmailAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('EndPointIDAsString',d.PaymentData ) as EndPointIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ErrorCodeAsString',d.PaymentData) as ErrorCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ErrorTypeAsString',d.PaymentData) as ErrorTypeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('FirstNameAsString',d.PaymentData) as FirstNameAsString
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('IBANCodeAsString',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('IBANCodeAsString',f.FundingData)) as IBANCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('InitialTransactionIDAsString',d.PaymentData ) as InitialTransactionIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('IPAsString',d.PaymentData) as IPAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('LanguageIDAsInteger',d.PaymentData) as LanguageIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('LastNameAsString',d.PaymentData) as LastNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('MD5AsString',d.PaymentData) as MD5AsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerAsString',d.PaymentData) as PayerAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerBusiness',d.PaymentData) as PayerBusiness
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('PayerIDAsString',d.PaymentData),dwh_daily_process.migration_tables.ExtractXMLValue('PayerIDAsString',f.FundingData)) as PayerIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerPurseAsString',d.PaymentData) as PayerPurseAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PayerStatus',d.PaymentData) as PayerStatus
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentAmountAsDecimal',d.PaymentData) as PaymentAmountAsDecimal
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentDateAsDateTime',d.PaymentData) as PaymentDateAsDateTime
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentGuaranteeAsString',d.PaymentData) as PaymentGuaranteeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentModeAsInteger',d.PaymentData) as PaymentModeAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentProviderTransactionStatusAsString',d.PaymentData) as PaymentProviderTransactionStatusAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentStatusAsInteger',d.PaymentData) as PaymentStatusAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('PaymentTypeAsString',d.PaymentData) as PaymentTypeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PlaidItemIDAsString',d.PaymentData) as PlaidItemIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PlaidNamesAsString',d.PaymentData) as PlaidNamesAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PlatformIDAsInteger',d.PaymentData) as PlatformIDAsInteger
	,dwh_daily_process.migration_tables.ExtractXMLValue('PromotionCodeAsString',d.PaymentData) as PromotionCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('PSPCodeAsString',d.PaymentData) as PSPCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('RapidFirstNameAsString',d.PaymentData) as RapidFirstNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('RapidLastNameAsString',d.PaymentData) as RapidLastNameAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ResponseMessageAsString',d.PaymentData) as ResponseMessageAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ResponseTimeAsString',d.PaymentData) as ResponseTimeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('SecretKeyAsString',d.PaymentData) as SecretKeyAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ThreeDsAsJson',d.PaymentData) as ThreeDsAsJson
	,dwh_daily_process.migration_tables.ExtractXMLValue('ThreeDsResponseType',d.PaymentData) as ThreeDsResponseType
	,dwh_daily_process.migration_tables.ExtractXMLValue('TokenAsString',d.PaymentData) as TokenAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('TransactionIDAsString',d.PaymentData) as TransactionIDAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ZipCodeAsString',d.PaymentData) as ZipCodeAsString
	,d.BaseExchangeRate
	, d.ExchangeFee
	, d.ProtocolMIDSettingsID 
	, d.FunnelID
	,COALESCE(d.SessionID, 0) as SessionID 
	,dwh_daily_process.migration_tables.ExtractXMLValue('SwiftCodeAsString',f.FundingData) AS SwiftCodeAsString
	,dwh_daily_process.migration_tables.ExtractXMLValue('ClientBankNameAsString',f.FundingData) AS ClientBankNameAsString
	,d.PaymentGeneration
	,d.ProcessRegulationID
	,d.MerchantAccountID
	,CAST(d.IsSetBalanceCompleted AS INT) AS IsSetBalanceCompleted
	,d.RoutingReasonID
	,COALESCE(Recurring.IsRecurring, 0) IsRecurring
	,FlowID
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('IsAftSupportedAsBool',d.PaymentData), 0) as IsAftSupportedAsBool
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('IsAftEligibleAsBool',d.PaymentData), 0)  as IsAftEligibleAsBool
	,COALESCE(dwh_daily_process.migration_tables.ExtractXMLValue('IsAftProcessedAsBool',d.PaymentData), 0) as IsAftProcessedAsBool
	FROM 
	dwh_daily_process.daily_snapshot.etoro_Billing_Deposit d 
	join dwh_daily_process.daily_snapshot.etoro_Billing_Funding f 
	on d.`FundingID` = f.`FundingID`
	LEFT JOIN LATERAL (SELECT 1 AS IsRecurring FROM  dwh_daily_process.daily_snapshot.etoro_Billing_RecurringDeposit 
				WHERE DepositID = d.DepositID
			) Recurring ON true
	where
	------[PaymentStatusID] = 2 and 
	ModificationDate >= V_Yesterday AND ModificationDate <DATEADD(day, 1, V_CurrentDate);

--------------------------------------------------------------------
-- Delete and insert Fact_BillingDeposit ---------------------------
  
MERGE INTO dwh_daily_process.migration_tables.Fact_BillingDeposit w_tgt 
USING (
select *   
FROM dwh_daily_process.migration_tables.Fact_BillingDeposit w  
INNER JOIN dwh_daily_process.migration_tables.Ext_FBD_Fact_BillingDeposit e  ON w.DepositID=e.DepositID    

QUALIFY ROW_NUMBER() OVER (PARTITION BY w.DepositID ORDER BY 1) = 1
)   ON w.DepositID = w_tgt.DepositID
WHEN MATCHED THEN DELETE ;
	INSERT INTO dwh_daily_process.migration_tables.Fact_BillingDeposit
           (`CID`
           ,`CurrencyID`
           ,`Commission`
           ,`Approved`
           ,`ModificationDate`
           ,`ModificationDateID`
           ,`FundingID`
           ,`ExchangeRate`
           ,`DepositID`
           ,`ProcessorValueDate`
           ,`DepotID`
           ,`SecuredCardDataAsString`
           ,`BinCodeAsString`
           ,`BinCountryIDAsInteger`
           ,`CardTypeIDAsInteger`
           ,`PaymentStatusID`
           ,`ManagerID`
           ,`RiskManagementStatusID`
           ,`Amount`
           ,`PaymentDate`
           ,`IPAddress`
           ,`ClearingHouseEffectiveDate`
           ,`IsFTD`
           ,`RefundVerificationCode`
           ,`MatchStatusID`
           ,`BonusStatusID`
           ,`BonusAmount`
           ,`BonusErrorCode`
           ,`ExTransactionID`
           ,`FundingTypeID`
           ,`IsRefundExcluded`
           ,`DocumentRequired`
           ,`UpdateDate`
           ,`ExpirationDateID`
           ,`CountryIDAsInteger`
           ,`StateIDAsInteger`
           ,`BankIDAsInteger`
           ,`AccountNameAsString`
           ,`AccountTypeAsString`
           ,`BankAccountAsString`
           ,`BankAddressAsString`
           ,`BankCodeAsDecimal`
           ,`BankDetailsAccountIDAsString`
           ,`BankIDAsString`
           ,`BankNameAsString`
           ,`BICCodeAsString`
           ,`CIDAsString`
           ,`v`
           ,`CustomerAddressAsString`
           ,`CustomerNameAsString`
           ,`FundingType`
           ,`MaskedAccountIDAsString`
           ,`PurseAsString`
           ,`RoutingNumberAsString`
           ,`SecureIDAsDecimal`
           ,`SortCodeAsString`
           ,`AccountBalanceAsDecimal`
           ,`AccountHolderAsString`
           ,`AccountIDAsDecimal`
           ,`ACHBankAccountIDAsInteger`
           ,`Address1AsString`
           ,`Address2AsString`
           ,`AdviseAsString`
           ,`AvailableBalanceAsDecimal`
           ,`BankCodeAsString`
           ,`BillNumberAsString`
           ,`BuildingNumberAsString`
           ,`CardHolderPhoneNumberBodyAsString`
           ,`CardHolderPhoneNumberPrefixAsString`
           ,`CardNumberAsString`
           ,`CityAsString`
           ,`CountryIDAsString`
           ,`CountryNameAsString`
           ,`CreatedAtAsString`
           ,`CurrentBalanceAsDecimal`
           ,`CustomerIDAsString`
           ,`EmailAsString`
           ,`EndPointIDAsString`
           ,`ErrorCodeAsString`
           ,`ErrorTypeAsString`
           ,`FirstNameAsString`
           ,`IBANCodeAsString`
           ,`InitialTransactionIDAsString`
           ,`IPAsString`
           ,`LanguageIDAsInteger`
           ,`LastNameAsString`
           ,`MD5AsString`
           ,`PayerAsString`
           ,`PayerBusiness`
           ,`PayerIDAsString`
           ,`PayerPurseAsString`
           ,`PayerStatus`
           ,`PaymentAmountAsDecimal`
           ,`PaymentDateAsDateTime`
           ,`PaymentGuaranteeAsString`
           ,`PaymentModeAsInteger`
           ,`PaymentProviderTransactionStatusAsString`
           ,`PaymentStatusAsInteger`
           ,`PaymentTypeAsString`
           ,`PlaidItemIDAsString`
           ,`PlaidNamesAsString`
           ,`PlatformIDAsInteger`
           ,`PromotionCodeAsString`
           ,`PSPCodeAsString`
           ,`RapidFirstNameAsString`
           ,`RapidLastNameAsString`
           ,`ResponseMessageAsString`
           ,`ResponseTimeAsString`
           ,`SecretKeyAsString`
           ,`ThreeDsAsJson`
           ,`ThreeDsResponseType`
           ,`TokenAsString`
           ,`TransactionIDAsString`
           ,`ZipCodeAsString`
           ,`BaseExchangeRate`
           ,`ExchangeFee`
           ,`ProtocolMIDSettingsID`
	       ,FunnelID
	       ,SessionID
	       ,AmountUSD
	       ,SwiftCodeAsString
	       ,ClientBankNameAsString
		   ,PaymentGeneration
		   ,MerchantAccountID
		   ,IsSetBalanceCompleted
		   ,ProcessRegulationID
		   ,RoutingReasonID
		   ,IsRecurring
		   ,FlowID
		   ,IsAftSupportedAsBool
		   ,IsAftEligibleAsBool
		   ,IsAftProcessedAsBool
		   )
     SELECT 
			`CID`
           ,`CurrencyID`
           ,`Commission`
           ,CAST(Approved AS INT)
           ,`ModificationDate`
           ,`ModificationDateID`
           ,`FundingID`
           ,`ExchangeRate`
           ,`DepositID`
           ,`ProcessorValueDate`
           ,`DepotID`
           ,`SecuredCardDataAsString`
           ,`BinCodeAsString`
           ,`BinCountryIDAsInteger`
           ,`CardTypeIDAsInteger`
           ,`PaymentStatusID`
           ,`ManagerID`
           ,`RiskManagementStatusID`
           ,`Amount`
           ,`PaymentDate`
           ,`IPAddress`
           ,`ClearingHouseEffectiveDate`
           ,CAST(IsFTD AS INT)
           ,`RefundVerificationCode`
           ,`MatchStatusID`
           ,`BonusStatusID`
           ,`BonusAmount`
           ,`BonusErrorCode`
           ,`ExTransactionID`
           ,`FundingTypeID`
           ,CAST(IsRefundExcluded AS INT)
           ,CAST(DocumentRequired AS INT)
           ,`UpdateDate`
           ,`ExpirationDateID`
           ,`CountryIDAsInteger`
           ,`StateIDAsInteger`
           ,`BankIDAsInteger`
           ,`AccountNameAsString`
           ,`AccountTypeAsString`
           ,`BankAccountAsString`
           ,`BankAddressAsString`
           ,`BankCodeAsDecimal`
           ,`BankDetailsAccountIDAsString`
           ,`BankIDAsString`
           ,`BankNameAsString`
           ,`BICCodeAsString`
           ,`CIDAsString`
           ,`v`
           ,`CustomerAddressAsString`
           ,`CustomerNameAsString`
           ,`FundingType`
           ,`MaskedAccountIDAsString`
           ,`PurseAsString`
           ,`RoutingNumberAsString`
           ,`SecureIDAsDecimal`
           ,`SortCodeAsString`
           ,`AccountBalanceAsDecimal`
           ,`AccountHolderAsString`
           ,`AccountIDAsDecimal`
           ,`ACHBankAccountIDAsInteger`
           ,`Address1AsString`
           ,`Address2AsString`
           ,`AdviseAsString`
           ,`AvailableBalanceAsDecimal`
           ,`BankCodeAsString`
           ,`BillNumberAsString`
           ,`BuildingNumberAsString`
           ,`CardHolderPhoneNumberBodyAsString`
           ,`CardHolderPhoneNumberPrefixAsString`
           ,`CardNumberAsString`
           ,`CityAsString`
           ,`CountryIDAsString`
           ,`CountryNameAsString`
           ,`CreatedAtAsString`
           ,`CurrentBalanceAsDecimal`
           ,`CustomerIDAsString`
           ,`EmailAsString`
           ,`EndPointIDAsString`
           ,`ErrorCodeAsString`
           ,`ErrorTypeAsString`
           ,`FirstNameAsString`
           ,`IBANCodeAsString`
           ,`InitialTransactionIDAsString`
           ,`IPAsString`
           ,`LanguageIDAsInteger`
           ,`LastNameAsString`
           ,`MD5AsString`
           ,`PayerAsString`
           ,`PayerBusiness`
           ,`PayerIDAsString`
           ,`PayerPurseAsString`
           ,`PayerStatus`
           ,`PaymentAmountAsDecimal`
           ,`PaymentDateAsDateTime`
           ,`PaymentGuaranteeAsString`
           ,`PaymentModeAsInteger`
           ,`PaymentProviderTransactionStatusAsString`
           ,`PaymentStatusAsInteger`
           ,`PaymentTypeAsString`
           ,`PlaidItemIDAsString`
           ,`PlaidNamesAsString`
           ,`PlatformIDAsInteger`
           ,`PromotionCodeAsString`
           ,`PSPCodeAsString`
           ,`RapidFirstNameAsString`
           ,`RapidLastNameAsString`
           ,`ResponseMessageAsString`
           ,`ResponseTimeAsString`
           ,`SecretKeyAsString`
           ,`ThreeDsAsJson`
           ,`ThreeDsResponseType`
           ,`TokenAsString`
           ,`TransactionIDAsString`
           ,`ZipCodeAsString`
           ,`BaseExchangeRate`
           ,`ExchangeFee`
           ,`ProtocolMIDSettingsID`
		   ,FunnelID
		   ,SessionID
		   ,Amount * ExchangeRate as AmountUSD
		   ,SwiftCodeAsString
		   ,ClientBankNameAsString
		   ,PaymentGeneration
		   ,MerchantAccountID
		   ,CAST(IsSetBalanceCompleted AS INT)
		   ,ProcessRegulationID
		   ,RoutingReasonID
		   ,IsRecurring
		   ,FlowID
		   ,IsAftSupportedAsBool
		   ,IsAftEligibleAsBool
		   ,IsAftProcessedAsBool
	FROM dwh_daily_process.migration_tables.Ext_FBD_Fact_BillingDeposit;
--------------------------------------------------------------------
-- Update PlatformID -----------------------------------------------
DROP VIEW IF EXISTS TEMP_TABLE_Fact_BillingDepositAction;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_Fact_BillingDepositAction  
	 AS
	SELECT RealCID, SessionID, PlatformID, Occurred,ActionTypeID
	
	FROM dwh_daily_process.migration_tables.Fact_CustomerAction
	WHERE ActionTypeID  =14 
	and DateID >= 19000101;
	
	
call dwh_daily_process.migration_tables.SP_Fact_BillingDeposit_autopoc(V_Yesterday);
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_Fact_BillingDepositAction;
END