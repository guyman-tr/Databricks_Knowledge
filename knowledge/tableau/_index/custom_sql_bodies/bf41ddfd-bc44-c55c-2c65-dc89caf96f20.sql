SELECT	 	
CAST(aaa.AccountId as INT   ) as [AccountId]  , 
CAST(aaa.WorkDate as Date  ) as [Date]  ,
CAST(aaa.EndToEndIdentifier as nvarchar(max)  ) as [EndToEndIdentifier]  ,
CAST(aaa.EpmTransactionId as BIGINT  ) as [EpmTransactionId]  ,
CAST(aaa.EpmTransactionStatusCode as  INT ) as [EpmTransactionStatusCode]  ,
CAST(aaa.HolderId as INT  ) as [HolderId]  ,
CAST(aaa.ProgramId as INT  ) as [ProgramId]  ,
CAST(aaa.Reference as nvarchar(max)  ) as [Reference]  ,
CAST(aaa.ReferenceNumber as nvarchar(max)  ) as [ReferenceNumber]  ,
CAST(aaa.TransLink as nvarchar(max)  ) as [TransLink]  ,
CAST(aaa.TransactionCode as INT  ) as [TransactionCode]  ,
CAST(aaa.TransactionCodeDescription as nvarchar(max)  ) as [TransactionCodeDescription]  ,
CAST(aaa.TransactionCurrencyAlpha as nvarchar(5)  ) as [TransactionCurrencyAlpha]  ,
CAST(aaa.TransactionCurrencyCode as INT  ) as [TransactionCurrencyCode]  ,
CAST(aaa.TransactionDateTime as DateTime  ) as [TransactionDateTime]  ,
CAST(aaa.TransactionDescription as nvarchar(max)  ) as [TransactionDescription]  ,
CAST(aaa.TransactionId as BIGINT  ) as  [TransactionId] ,
CAST(aaa.TransactionIdentifier as nvarchar(max)  ) as [TransactionIdentifier]  ,
CAST(aaa.WorkDate as DateTime  ) as [WorkDate]  ,
CAST(aaa.BalanceAdjustmentType as  INT) as [BalanceAdjustmentType]  ,
CAST(aaa.EpmTransactionType as  INT ) as [EpmTransactionType]  ,
CAST(aaa.LoadSource as INT  ) as [LoadSource]  ,
CAST(aaa.LoadType as INT  ) as [LoadType]  ,
CAST(aaa.TransactionAmount as FLOAT  ) as [TransactionAmount]  ,
CAST(aaa.HolderAmount as FLOAT  ) as  [HolderAmount]  

FROM	 [FiatDwhDB].[FiatDwhDB].Tribe.[AccountsActivities-862157] AS aa WITH(NOLOCK)	
		 inner JOIN 
		 [FiatDwhDB].[FiatDwhDB].[Tribe].[AccountsActivities_AccountActivity-833937]  AS aaa WITH(NOLOCK)
		 ON aa.[@Id] = aaa.[@AccountsActivities@Id-862157]
		 		 WHERE aaa.[@Created] >=  cast(getdate()-1 as date)