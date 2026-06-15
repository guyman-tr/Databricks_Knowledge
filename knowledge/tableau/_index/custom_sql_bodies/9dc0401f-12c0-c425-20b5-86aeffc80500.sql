SELECT  mbpu.HolderId
	  ,mbpu.AccountId
	  ,mbpu.ExternalBankAccountId
	  ,cast(mbpu.BankAccountNumber AS VARCHAR) AS BankAccount 
	  ,mbpu.TransactionCode
	  ,NULL  AS 'Transaction Type'
	  ,mbpu.TransactionDateTime
	  ,mbpu.TransactionAmount
	  ,mbpu.TransactionCurrencyCode
	  ,mbpu.TransactionCurrencyAlpha
	  ,mbpu.HolderAmount
	  ,mbpu.HolderCurrencyAlpha
	  ,mbpu.TransactionId
	  ,mbpu.EpmMethodId
	  ,mbpu.BankActivityType
	  ,mbpu.Created
	  ,mbpu.Date
           ,'Tribe' AS 'Source'
	 FROM eMoney_dbo.eMoney_BankPaymentsUK mbpu

WHERE mbpu.Date = <[Parameters].[Parameter 1]>

UNION  all

SELECT 	 
       Null AS HolderId
	  ,NULL AS  AccountId
	  ,NULL ExternalBankAccountId
	  ,bank_account_name AS BankAccount 
	  ,transaction_code TransactionCode
	  ,transactiontype AS 'Transaction Type'
	  ,NULL TransactionDateTime
	  ,transaction_amount AS TransactionAmount
	  ,transaction_currency_code  as TransactionCurrencyCode
	  ,transaction_currency_alpha TransactionCurrencyAlpha
	  ,transaction_amount HolderAmount
	  ,transaction_currency_alpha HolderCurrencyAlpha
	  ,NULL TransactionId
	  ,NULL EpmMethodId
	  ,bank_activity_type AS BankActivityType
	  ,NULL AS Created
	  ,date AS Date
          ,'Manual' AS 'Source'
 from [BI_DB_dbo].[External_Fivetran_gsheets_emoney_bank_payments_manual_entries]  b

WHERE  date = <[Parameters].[Parameter 1]>