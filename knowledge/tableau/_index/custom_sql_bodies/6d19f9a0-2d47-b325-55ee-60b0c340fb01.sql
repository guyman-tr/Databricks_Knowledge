SELECT [Dealing_NonHBCFailureProbability].[Date] AS [Date],
  [Dealing_NonHBCFailureProbability].[FailCount] AS [FailCount],
  [Dealing_NonHBCFailureProbability].[HedgeServerID] AS [HedgeServerID],
  [Dealing_NonHBCFailureProbability].[InstrumentType] AS [InstrumentType],
  [Dealing_NonHBCFailureProbability].[LiquidityAccountID] AS [LiquidityAccountID],
  [Dealing_NonHBCFailureProbability].[SuccessCount] AS [SuccessCount],
  [Dealing_NonHBCFailureProbability].[TotalCount] AS [TotalCount],
  [Dealing_NonHBCFailureProbability].[UpdateDate] AS [UpdateDate],
   b.LiquidityAccountName 
FROM [dbo].[Dealing_NonHBCFailureProbability] [Dealing_NonHBCFailureProbability]
join 
(
	select * 		
from openquery ( [AZR-W-REAL-DB-2-BIDBUser],			
		'select	
		LiquidityAccountName	
,LiquidityAccountID			
FROM [etoro].[Trade].[LiquidityAccounts]  TP WITH(NOLOCK)					
			'
)			
)
b on b.LiquidityAccountID = [Dealing_NonHBCFailureProbability].LiquidityAccountID