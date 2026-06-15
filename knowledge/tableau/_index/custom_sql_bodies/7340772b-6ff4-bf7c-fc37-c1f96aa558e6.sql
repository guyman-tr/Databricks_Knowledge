SELECT
CAST(aaa.WorkDate AS DATE) as Date
,CAST(aaa.WorkDate AS DATETIME) as WorkDate
, CAST(aaa.AccountId AS INT) as AccountId
, CAST(aaa.BillingCurrencyCode AS int) as BillingCurrencyCode 
, CAST(aaa.BillingCurrencyAlpha AS NVarchar(5)) as BillingCurrencyAlpha 
, CAST(aaa.CardNumberId AS INT) as CardNumberId
, CAST(aaa.CardPresent AS NVarchar(50)) as CardPresent 
, CAST(aaa.EntryModeCode AS int) as EntryModeCode 				
, CAST(aaa.EntryModeCodeDescription AS NVarchar(20)) as EntryModeCodeDescription 
, CAST(aaa.F0FeeName AS NVarchar(50)) as F0FeeName
, CAST(aaa.F0FeeCode AS NVarchar(50)) as F0FeeCode
, CAST(aaa.FunctionCode AS int) as FunctionCode 		
, CAST(aaa.FxFeeCode AS NVarchar(50)) as FxFeeCode
, CAST(aaa.FxFeeCurrency AS int) as FxFeeCurrency
, CAST(aaa.FxFeeName AS NVarchar(50)) as FxFeeName
, CAST(aaa.HolderAmount AS FLOAT) as HolderAmount
, CAST(aaa.HolderCurrencyCode AS INT) as HolderCurrencyCode
, CAST(aaa.HolderCurrencyAlpha AS NVarchar(100)) as HolderCurrencyAlpha
, CAST(aaa.MerchantName AS NVARCHAR(100)) as MerchantName 
, CAST(aaa.MessageReasonCode AS INT) as MessageReasonCode
, CAST(aaa.ProductId AS INT) as ProductId
, CAST(aaa.ProgramId AS INT) as ProgramId
, CAST(aaa.SettlementCurrencyCode AS int) as SettlementCurrencyCode 
, CAST(aaa.SettlementCurrencyAlpha AS NVarchar(5)) as SettlementCurrencyAlpha 
, CAST(aaa.SettlementDate AS date) as SettlementDate 		
, CAST(aaa.SettlementAmount AS float) as SettlementAmount 
, CAST(aaa.SettlementFlag AS int) as SettlementFlag 		
, CAST(aaa.SettlementConversionRate AS float) as SettlementConversionRate 
, CAST(aaa.TransLink AS NVARCHAR(100)) as TransLink
, CAST(aaa.TraceId AS bigINT) as TraceId
 , CAST(aaa.TransactionCode AS INT) as TransactionCode
, CAST(aaa.TransactionCodeDescription AS NVarchar(100)) as TransactionCodeDescription
, CAST(aaa.TransactionCurrencyAlpha AS NVarchar(5)) as TransactionCurrencyAlpha
, CAST(aaa.TransactionCurrencyCode AS INT) as TransactionCurrencyCode
, CAST(aaa.TransactionDateTime AS DATETIME) as TransactionDateTime
, CAST(aaa.AcquirerReferenceNumber AS float) as AcquirerReferenceNumber 		
, CAST(aaa.BillingAmount AS FLOAT) as BillingAmount
, CAST(aaa.Bin AS INT) as Bin
, CAST(aaa.ECIIndicator AS int) as ECIIndicator 	
, CAST(aaa.F0FeeAmount AS float) as F0FeeAmount
, CAST(aaa.F0FeeCurrency AS int) as F0FeeCurrency	
, CAST(aaa.FxFeeAmount AS float) as FxFeeAmount
, CAST(aaa.FxRate AS float) as FxRate
, CAST(aaa.InterchangeFeeAmount AS float) as InterchangeFeeAmount 		
, CAST(aaa.InterchangeFeeCurrency AS int) as InterchangeFeeCurrency 	
, CAST(aaa.TransactionAmount AS FLOAT) as TransactionAmount
, CAST(aaa.TransactionCodeIdentifier AS INT) as TransactionCodeIdentifier

FROM 	 [FiatDwhDB].[FiatDwhDB].[Tribe].[SettlementsTransactions-333243] AS aa WITH(NOLOCK)	
inner JOIN 
	 [FiatDwhDB].[FiatDwhDB].[Tribe].[SettlementsTransactions_SettlementTransaction-637239]  AS aaa WITH(NOLOCK)
ON aa.[@Id] = aaa.[@SettlementsTransactions@Id-333243]
WHERE aaa.[@Created] >=  cast(getdate()-1 as date)