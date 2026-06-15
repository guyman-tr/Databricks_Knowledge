SELECT [Dim_Country].[Abbreviation] AS [Abbreviation],
  [BI_DB_CID_DailyPanel_Club].[AccountManagerID] AS [AccountManagerID],
  [BI_DB_CID_DailyPanel_Club].[AmountToRemain] AS [AmountToRemain],
  [BI_DB_CID_DailyPanel_Club].[AmountToUpgrade] AS [AmountToUpgrade],
  [Dim_Country].[CFKey] AS [CFKey],
  [Interest].[CID] AS [CID (Custom SQL Query)],
  [BI_DB_CID_DailyPanel_Club].[CID] AS [CID],
  [Dim_Date].[CalendarQuarter] AS [CalendarQuarter],
  [Dim_Date].[CalendarSemester] AS [CalendarSemester],
  [Dim_Date].[CalendarYearMonth] AS [CalendarYearMonth],
  [Dim_Date].[CalendarYearQtr] AS [CalendarYearQtr],
  [Dim_Date].[CalendarYear] AS [CalendarYear],
  [BI_DB_CID_DailyPanel_Club].[CashoutFeeExemption] AS [CashoutFeeExemption],
  [BI_DB_CID_DailyPanel_Club].[CashoutFeePaid] AS [CashoutFeePaid],
  [LastTier].[CashoutPendingHours] AS [CashoutPendingHours (Dim_PlayerLevel)],
  [CurrentTier].[CashoutPendingHours] AS [CashoutPendingHours],
  [BI_DB_CID_DailyPanel_Club].[Classification] AS [Classification],
  [Dim_Country].[CountryID] AS [CountryID (Dim_Country)],
  [BI_DB_CID_DailyPanel_Club].[CountryID] AS [CountryID],
  [BI_DB_CID_DailyPanel_Club].[CurrentTier] AS [CurrentTier],
  [Dim_Country].[DWHCountryID] AS [DWHCountryID],
  [LastTier].[DWHPlayerLevelID] AS [DWHPlayerLevelID (Dim_PlayerLevel)],
  [CurrentTier].[DWHPlayerLevelID] AS [DWHPlayerLevelID],
  [BI_DB_CID_DailyPanel_Club].[DailyCalculationInterest] AS [DailyCalculationInterest],
  [BI_DB_CID_DailyPanel_Club].[DailyFee] AS [DailyFee],
  [Dim_Date].[DateFilter] AS [DateFilter],
  [BI_DB_CID_DailyPanel_Club].[DateID] AS [DateID],
  [Dim_Date].[DateKey] AS [DateKey],
  [BI_DB_CID_DailyPanel_Club].[Date] AS [Date],
  [Dim_Date].[DayNameAbbreviation] AS [DayNameAbbreviation],
  [Dim_Date].[DayName] AS [DayName],
  [BI_DB_CID_DailyPanel_Club].[DaysFromFTD] AS [DaysFromFTD],
  [BI_DB_CID_DailyPanel_Club].[DaysInClub] AS [DaysInClub],
  [BI_DB_CID_DailyPanel_Club].[DaysInCurrentClub] AS [DaysInCurrentClub],
  [BI_DB_CID_DailyPanel_Club].[DaysTillFTC] AS [DaysTillFTC],
  [BI_DB_CID_DailyPanel_Club].[DepositAmountWireTransfer] AS [DepositAmountWireTransfer],
  [BI_DB_CID_DailyPanel_Club].[DepositAmount] AS [DepositAmount],
  [BI_DB_CID_DailyPanel_Club].[DepositConversionFeeExemption] AS [DepositConversionFeeExemption],
  [BI_DB_CID_DailyPanel_Club].[DepositConversionFee] AS [DepositConversionFee],
  [BI_DB_CID_DailyPanel_Club].[DepositTransactions] AS [DepositTransactions],
  [BI_DB_CID_DailyPanel_Club].[DepositWireTransferTransactions] AS [DepositWireTransferTransactions],
  [Dim_Country].[Desk] AS [Desk],
  [Dim_Country].[EU] AS [EU],
  [BI_DB_CID_DailyPanel_Club].[Equity] AS [Equity],
  [BI_DB_CID_DailyPanel_Club].[ExpectedDowngradeDate] AS [ExpectedDowngradeDate],
  [BI_DB_CID_DailyPanel_Club].[ExpectedDowngradePlayerLevelID] AS [ExpectedDowngradePlayerLevelID],
  [BI_DB_CID_DailyPanel_Club].[ExpectedDowngradeStartDate] AS [ExpectedDowngradeStartDate],
  [BI_DB_CID_DailyPanel_Club].[ExpectedDowngradeTierLT] AS [ExpectedDowngradeTierLT],
  [BI_DB_CID_DailyPanel_Club].[FTCDate] AS [FTCDate],
  [BI_DB_CID_DailyPanel_Club].[FTDDate] AS [FTDDate],
  [LastTier].[FromSumDeposit] AS [FromSumDeposit (Dim_PlayerLevel)],
  [CurrentTier].[FromSumDeposit] AS [FromSumDeposit],
  [LastTier].[FromSumLotCount] AS [FromSumLotCount (Dim_PlayerLevel)],
  [CurrentTier].[FromSumLotCount] AS [FromSumLotCount],
  [Dim_Date].[FullDate] AS [FullDate],
  [Dim_Country].[InsertDate] AS [InsertDate (Dim_Country)],
  [LastTier].[InsertDate] AS [InsertDate (Dim_PlayerLevel)],
  [CurrentTier].[InsertDate] AS [InsertDate],
  [Interest].[InterestPaid] AS [InterestPaid],
  [BI_DB_CID_DailyPanel_Club].[InvestedAmount] AS [InvestedAmount],
  [BI_DB_CID_DailyPanel_Club].[IsClosedCreditLine] AS [IsClosedCreditLine],
  [BI_DB_CID_DailyPanel_Club].[IsCreditEligible] AS [IsCreditEligible],
  [BI_DB_CID_DailyPanel_Club].[IsCreditLineCustomer] AS [IsCreditLineCustomer],
  [BI_DB_CID_DailyPanel_Club].[IsDowngrade] AS [IsDowngrade],
  [Dim_Country].[IsEligibleForRAFBonusCountry] AS [IsEligibleForRAFBonusCountry],
  [Dim_Country].[IsEuropeanCountry] AS [IsEuropeanCountry],
  [BI_DB_CID_DailyPanel_Club].[IsExpectedDowngrade] AS [IsExpectedDowngrade],
  [BI_DB_CID_DailyPanel_Club].[IsFTC] AS [IsFTC],
  [BI_DB_CID_DailyPanel_Club].[IsFundedCurrentTier] AS [IsFundedCurrentTier],
  [BI_DB_CID_DailyPanel_Club].[IsFunded] AS [IsFunded],
  [Dim_Country].[IsHighRiskCountry] AS [IsHighRiskCountry],
  [Dim_Date].[IsLastDayOfMonth] AS [IsLastDayOfMonth],
  [BI_DB_CID_DailyPanel_Club].[IsOpenCreditLine] AS [IsOpenCreditLine],
  [BI_DB_CID_DailyPanel_Club].[IsOptInInterest] AS [IsOptInInterest],
  [BI_DB_CID_DailyPanel_Club].[IsProCustomer] AS [IsProCustomer],
  [BI_DB_CID_DailyPanel_Club].[IsUpgrade] AS [IsUpgrade],
  [Dim_Date].[IsYesterday] AS [IsYesterday],
  [BI_DB_CID_DailyPanel_Club].[LastContacted] AS [LastContacted],
  [BI_DB_CID_DailyPanel_Club].[LastTier] AS [LastTier],
  [Dim_Country].[LongAbbreviation] AS [LongAbbreviation],
  [Dim_Country].[MarketingRegionID] AS [MarketingRegionID],
  [Dim_Country].[MarketingRegionManualName] AS [MarketingRegionManualName],
  [BI_DB_CID_DailyPanel_Club].[MaxTier] AS [MaxTier],
  [BI_DB_CID_DailyPanel_Club].[Moneyfarm] AS [Moneyfarm],
  [Dim_Date].[MonthNameAbbreviation] AS [MonthNameAbbreviation],
  [Dim_Date].[MonthName] AS [MonthName],
  [Dim_Date].[MonthNumberOfQuarter] AS [MonthNumberOfQuarter],
  [Dim_Date].[MonthNumberOfYear] AS [MonthNumberOfYear],
  [Interest].[MonthOfInterest] AS [MonthOfInterest],
  [BI_DB_CID_DailyPanel_Club].[MonthlyInterestPayments] AS [MonthlyInterestPayments],
  [Dim_Country].[Name] AS [Name (Dim_Country)],
  [Dim_Regulation].[Name] AS [Regulation],
  [LastTier].[Name] AS [Name (Dim_PlayerLevel)],
  [CurrentTier].[Name] AS [Name],
  [BI_DB_CID_DailyPanel_Club].[OptInDate] AS [OptInDate],
  [LastTier].[PlayerLevelID] AS [PlayerLevelID (Dim_PlayerLevel)],
  [CurrentTier].[PlayerLevelID] AS [PlayerLevelID],
  [BI_DB_CID_DailyPanel_Club].[RealizedEquityClub] AS [RealizedEquityClub],
  [BI_DB_CID_DailyPanel_Club].[RealizedEquityNoCFD] AS [RealizedEquityNoCFD],
  [BI_DB_CID_DailyPanel_Club].[RealizedEquity] AS [RealizedEquity],
  [Dim_Country].[Region] AS [Region],
  [Dim_Country].[RegulationID] AS [RegulationID (Dim_Country)],
  [BI_DB_CID_DailyPanel_Club].[RegulationID] AS [RegulationID],
  [BI_DB_CID_DailyPanel_Club].[Revenue] AS [Revenue],
  [Dim_Country].[RiskGroupID] AS [RiskGroupID],
  [LastTier].[Sort] AS [Sort (Dim_PlayerLevel)],
  [CurrentTier].[Sort] AS [Sort],
  [Dim_Country].[StatusID] AS [StatusID (Dim_Country)],
  [LastTier].[StatusID] AS [StatusID (Dim_PlayerLevel)],
  [CurrentTier].[StatusID] AS [StatusID],
  [BI_DB_CID_DailyPanel_Club].[TierChangeDate] AS [TierChangeDate],
  [BI_DB_CID_DailyPanel_Club].[TierChangeType] AS [TierChangeType],
  [LastTier].[ToSumDeposit] AS [ToSumDeposit (Dim_PlayerLevel)],
  [CurrentTier].[ToSumDeposit] AS [ToSumDeposit],
  [LastTier].[ToSumLotCount] AS [ToSumLotCount (Dim_PlayerLevel)],
  [CurrentTier].[ToSumLotCount] AS [ToSumLotCount],
  [BI_DB_CID_DailyPanel_Club].[TotalCLAmount] AS [TotalCLAmount],
  [Dim_Country].[UpdateDate] AS [UpdateDate (Dim_Country)],
  [LastTier].[UpdateDate] AS [UpdateDate (Dim_PlayerLevel) #1],
  [CurrentTier].[UpdateDate] AS [UpdateDate (Dim_PlayerLevel)],
  [BI_DB_CID_DailyPanel_Club].[UpdateDate] AS [UpdateDate],
  [BI_DB_CID_DailyPanel_Club].[WithdrawAmountWallet] AS [WithdrawAmountWallet],
  [BI_DB_CID_DailyPanel_Club].[WithdrawAmountWireTransfer] AS [WithdrawAmountWireTransfer],
  [BI_DB_CID_DailyPanel_Club].[WithdrawAmount] AS [WithdrawAmount],
  [BI_DB_CID_DailyPanel_Club].[WithdrawConversionFeeExemption] AS [WithdrawConversionFeeExemption],
  [BI_DB_CID_DailyPanel_Club].[WithdrawConversionFee] AS [WithdrawConversionFee],
  [BI_DB_CID_DailyPanel_Club].[WithdrawTransactions] AS [WithdrawTransactions],
  [BI_DB_CID_DailyPanel_Club].[WithdrawWalletTransactions] AS [WithdrawWalletTransactions],
  [BI_DB_CID_DailyPanel_Club].[WithdrawWireTransferTransactions] AS [WithdrawWireTransferTransactions],
  [BI_DB_CID_DailyPanel_Club].[eMoneyBalance] AS [eMoneyBalance]
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_Club] [BI_DB_CID_DailyPanel_Club]
  INNER JOIN (
  SELECT dd.DateKey
  	  ,dd.FullDate
  	  ,dd.MonthNumberOfYear
  	  ,dd.MonthNumberOfQuarter
  	  ,dd.MonthName
  	  ,dd.MonthNameAbbreviation
  	  ,dd.DayName
  	  ,dd.DayNameAbbreviation
  	  ,dd.CalendarYear
  	  ,dd.CalendarYearMonth
  	  ,dd.CalendarYearQtr
  	  ,dd.CalendarSemester
  	  ,dd.CalendarQuarter
  	  ,dd.IsLastDayOfMonth
  	  ,CASE WHEN dd.FullDate = CONVERT(DATE,GETDATE()-1) THEN 1 ELSE 0 END IsYesterday
  	  ,CASE WHEN dd.FullDate = CONVERT(DATE,GETDATE()-1) OR dd.IsLastDayOfMonth = 'Y' THEN 1 ELSE 0 END DateFilter
  FROM DWH_dbo.Dim_Date dd WITH (NOLOCK)
) [Dim_Date] ON ([BI_DB_CID_DailyPanel_Club].[DateID] = [Dim_Date].[DateKey])
  LEFT JOIN [DWH_dbo].[Dim_PlayerLevel] [CurrentTier] ON ([BI_DB_CID_DailyPanel_Club].[CurrentTier] = [CurrentTier].[DWHPlayerLevelID])
  LEFT JOIN [DWH_dbo].[Dim_PlayerLevel] [LastTier] ON ([BI_DB_CID_DailyPanel_Club].[LastTier] = [LastTier].[PlayerLevelID])
  INNER JOIN [DWH_dbo].[Dim_Country] [Dim_Country] ON ([BI_DB_CID_DailyPanel_Club].[CountryID] = [Dim_Country].[CountryID])
  INNER JOIN [DWH_dbo].[Dim_Regulation] [Dim_Regulation] ON ([BI_DB_CID_DailyPanel_Club].[RegulationID]= [Dim_Regulation].[ID])
  LEFT JOIN (
  SELECT EOMONTH(MonthOfInterest) MonthOfInterest	
         ,CID
         ,SUM(ISNULL(FinalTaxedlnterest,0)) InterestPaid
  FROM BI_DB_dbo.External_Interest_Trade_InterestMonthly
  GROUP BY EOMONTH(MonthOfInterest)	
         ,CID
) [Interest] ON (([BI_DB_CID_DailyPanel_Club].[CID] = [Interest].[CID]) AND ([BI_DB_CID_DailyPanel_Club].[Date] = [Interest].[MonthOfInterest]))