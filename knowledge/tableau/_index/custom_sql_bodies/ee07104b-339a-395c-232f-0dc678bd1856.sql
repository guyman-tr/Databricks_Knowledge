SELECT [Dealing_HBCFailureProbability].[Date] AS [Date],
  [Dealing_HBCFailureProbability].[FailCount] AS [FailCount],
  [Dealing_HBCFailureProbability].[HedgeServerID] AS [HedgeServerID],
  [Dealing_HBCFailureProbability].[InstrumentType] AS [InstrumentType],
  [Dealing_HBCFailureProbability].[LiquidityAccountID] AS [LiquidityAccountID],
  [Dealing_HBCFailureProbability].[SuccessCount] AS [SuccessCount],
  [Dealing_HBCFailureProbability].[TotalCount] AS [TotalCount],
  [Dealing_HBCFailureProbability].[UpdateDate] AS [UpdateDate],
  b.LiquidityAccountName
FROM [dbo].[Dealing_HBCFailureProbability] [Dealing_HBCFailureProbability]
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
b on b.LiquidityAccountID = [Dealing_HBCFailureProbability].LiquidityAccountID