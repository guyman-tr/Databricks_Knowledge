SELECT cp.[DateID]
      ,cp.[Date]
      ,cp.[CID]
      ,cp.[IsUpgrade]
      ,cp.[IsDowngrade]
      ,cp.[TierChangeDate]
      ,cp.[TierChangeType]
      ,cp.[CurrentTier]
      ,cp.[LastTier] AS PreviousTier
      ,dc1.Name Country
	  ,CASE WHEN dc1.Name IN ('Netherlands','Netherlands Antilles') THEN 'Netherlands'
       WHEN dc1.Name IN ('Mexico') THEN 'Mexico'
       WHEN dc1.Name IN ('Romania') THEN 'Romania'
       WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
       WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
       WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
       WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
       WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
       WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END AS Region
      ,cp.[FTDDate]
      ,cp.[FTCDate]
      ,cp.[IsFTC]
      ,cp.[DaysInCurrentClub]
      ,cp.[IsExpectedDowngrade]
      ,cp.[ExpectedDowngradePlayerLevelID]
      ,cp.[IsOptInInterest]
      ,cp.[OptInDate]
      ,cp.[DepositAmount]
      ,cp.[DepositTransactions]
      ,cp.[DepositAmountWireTransfer]
      ,cp.[DepositWireTransferTransactions]
      ,cp.[DepositConversionFee]
      ,cp.[DepositConversionFeeExemption]
      ,cp.[WithdrawAmount]
      ,cp.[WithdrawAmountWireTransfer]
      ,cp.[WithdrawTransactions]
      ,cp.[WithdrawWireTransferTransactions]
      ,cp.[WithdrawAmountWallet]
      ,cp.[WithdrawWalletTransactions]
      ,cp.[WithdrawConversionFee]
      ,cp.[WithdrawConversionFeeExemption]
      ,cp.[CashoutFeeExemption]
      ,cp.[CashoutFeePaid]
      ,cp.[TotalCLAmount]
      ,cp.[DailyFee]
      ,cp.[IsOpenCreditLine]
      ,cp.[IsClosedCreditLine]
      ,cp.[IsCreditLineCustomer]
      ,cp.[IsCreditEligible]
      ,cp.[DailyCalculationInterest]
      ,cp.[MonthlyInterestPayments]
	  ,kpi.KPI
FROM [dbo].[BI_DB_CID_DailyPanel_Club] cp WITH (NOLOCK)
  INNER JOIN [DWH].[dbo].[Dim_Country] dc1 WITH (NOLOCK) 
  ON dc1.CountryID = cp.CountryID
  LEFT JOIN [dbo].[BI_DB_ClubRegionsKPI] kpi
  ON CASE WHEN cp.[IsDowngrade] = 1 THEN cp.[LastTier] ELSE cp.[CurrentTier] END = kpi.PlayerLevelID
  AND DATEFROMPARTS(YEAR(cp.[Date]),MONTH(cp.[Date]),1) = kpi.Date
  AND CASE WHEN dc1.Name IN ('Netherlands','Netherlands Antilles') THEN 'Netherlands'
       WHEN dc1.Name IN ('Mexico') THEN 'Mexico'
       WHEN dc1.Name IN ('Romania') THEN 'Romania'
       WHEN dc1.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
       WHEN dc1.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
       WHEN dc1.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
       WHEN dc1.Region IN ('China','Other Asia') THEN 'China & Other Asia'
       WHEN dc1.Region IN ('Spain') THEN 'Spanish' 
       WHEN dc1.Region IN ('South & Central America') THEN 'LATAM' ELSE dc1.Region END = kpi.Region
  WHERE DateID > CONVERT(CHAR(8),EOMONTH(DATEADD(MONTH,-2,GETDATE())),112)
AND ([CurrentTier] !=1
  OR 
  [IsDowngrade] = 1
)