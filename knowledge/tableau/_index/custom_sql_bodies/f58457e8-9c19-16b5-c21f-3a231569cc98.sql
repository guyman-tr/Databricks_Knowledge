SELECT [BI_DB_AcquisitionFunnel_AGG].[Channel] AS [Channel],
  [BI_DB_AcquisitionFunnel_AGG].[Country] AS [Country],
  [BI_DB_AcquisitionFunnel_AGG].[DateID] AS [DateID],
  [BI_DB_AcquisitionFunnel_AGG].[Date] AS [Date],
  [BI_DB_AcquisitionFunnel_AGG].[DepositAttDB] AS [DepositAttDB],
  [BI_DB_AcquisitionFunnel_AGG].[DesignatedRegulation] AS [DesignatedRegulation],
  [BI_DB_AcquisitionFunnel_AGG].[Desk] AS [Desk],
  [BI_DB_AcquisitionFunnel_AGG].[EmailVerification] AS [EmailVerification],
  [BI_DB_AcquisitionFunnel_AGG].[EvMatchStatus] AS [EvMatchStatus],
  [BI_DB_AcquisitionFunnel_AGG].[FTD] AS [FTD],
  [BI_DB_AcquisitionFunnel_AGG].[FunnelFrom] AS [FunnelFrom],
  [BI_DB_AcquisitionFunnel_AGG].[Install] AS [Install],
  [BI_DB_AcquisitionFunnel_AGG].[Installs] AS [Installs],
  [BI_DB_AcquisitionFunnel_AGG].[KYCFlow] AS [KYCFlow],
  [BI_DB_AcquisitionFunnel_AGG].[OpenTrade] AS [OpenTrade],
  [BI_DB_AcquisitionFunnel_AGG].[PhoneVerification] AS [PhoneVerification],
  [BI_DB_AcquisitionFunnel_AGG].[Platform] AS [Platform],
  [BI_DB_AcquisitionFunnel_AGG].[Platform_fromAction_FTD] AS [Platform_fromAction_FTD],
  [BI_DB_AcquisitionFunnel_AGG].[Platform_fromAction_Regs] AS [Platform_fromAction_Regs],
  [BI_DB_AcquisitionFunnel_AGG].[Region] AS [Region],
  [BI_DB_AcquisitionFunnel_AGG].[Registration] AS [Registration],
  [BI_DB_AcquisitionFunnel_AGG].[Regulation] AS [Regulation],
  [BI_DB_AcquisitionFunnel_AGG].[State] AS [State],
  [BI_DB_AcquisitionFunnel_AGG].[SubChannel] AS [SubChannel],
  [BI_DB_AcquisitionFunnel_AGG].[UpdateDate] AS [UpdateDate],
  [BI_DB_AcquisitionFunnel_AGG].[VerificationLevel1] AS [VerificationLevel1],
  [BI_DB_AcquisitionFunnel_AGG].[VerificationLevel2] AS [VerificationLevel2],
  [BI_DB_AcquisitionFunnel_AGG].[VerificationLevel3] AS [VerificationLevel3]
FROM [BI_DB_dbo].[BI_DB_AcquisitionFunnel_AGG] [BI_DB_AcquisitionFunnel_AGG]