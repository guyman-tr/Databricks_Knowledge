SELECT [BI_DB_Operations_Onboarding_Flow_UserKPIs].[CID] AS [CID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[CountVLChangesCount] AS [CountVLChangesCount],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[CountryID] AS [CountryID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[CountryName] AS [CountryName],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[CurrentRegulation] AS [CurrentRegulation],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DDCategoryVL0toVL3] AS [DDCategoryVL0toVL3],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DDMinutes_VL0toVL1] AS [DDMinutes_VL0toVL1],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DDMinutes_VL0toVL3] AS [DDMinutes_VL0toVL3],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DDMinutes_VL1toVL2] AS [DDMinutes_VL1toVL2],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DDMinutes_VL2toVL3] AS [DDMinutes_VL2toVL3],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DateTime_FTD] AS [DateTime_FTD],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DateTime_VL0] AS [DateTime_VL0],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DateTime_VL1] AS [DateTime_VL1],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DateTime_VL2] AS [DateTime_VL2],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DateTime_VL3] AS [DateTime_VL3],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DepositAttempt] AS [DepositAttempt],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[DesignatedRegulation] AS [DesignatedRegulation],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EV_DDMinutes_VL2toEVMatch] AS [EV_DDMinutes_VL2toEVMatch],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EV_IsCountryEligible] AS [EV_IsCountryEligible],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EV_MatchStatusDateTime] AS [EV_MatchStatusDateTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EV_MatchStatusID] AS [EV_MatchStatusID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EV_MatchStatus] AS [EV_MatchStatus],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[EmailVerification] AS [EmailVerification],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[FirstActionDate] AS [FirstActionDate],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[FirstAction] AS [FirstAction],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[FirstDepositAmount] AS [FirstDepositAmount],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[FirstDepositAttemptDate] AS [FirstDepositAttemptDate],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[GCID] AS [GCID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsFTD] AS [IsFTD],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsRegAndVL3SameDay] AS [IsRegAndVL3SameDay],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsSTP_User] AS [IsSTP_User],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsSTP_eToro] AS [IsSTP_eToro],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVL0] AS [IsVL0],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVL1] AS [IsVL1],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVL2] AS [IsVL2],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVL3In24HRsFromReg] AS [IsVL3In24HRsFromReg],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVL3] AS [IsVL3],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[IsVLChangesCountOkay] AS [IsVLChangesCountOkay],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[KYCFlowID] AS [KYCFlowID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[KYCFlow] AS [KYCFlow],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[LTV] AS [LTV],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[MarketingRegion] AS [MarketingRegion],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[NonVerificationReason] AS [NonVerificationReason],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_CountDeclines] AS [POA_CountDeclines],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_HasOnlyDeclines] AS [POA_HasOnlyDeclines],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_IsApproved] AS [POA_IsApproved],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_IsResponseAutomatic] AS [POA_IsResponseAutomatic],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_Manager] AS [POA_Manager],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_ResponseDateTime] AS [POA_ResponseDateTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_SLAMinutes] AS [POA_SLAMinutes],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POA_UploadDateTime] AS [POA_UploadDateTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_CountDeclines] AS [POI_CountDeclines],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_HasOnlyDeclines] AS [POI_HasOnlyDeclines],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_IsApproved] AS [POI_IsApproved],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_IsResponseAutomatic] AS [POI_IsResponseAutomatic],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_Manager] AS [POI_Manager],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_ResponseDateTime] AS [POI_ResponseDateTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_SLAMinutes] AS [POI_SLAMinutes],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[POI_UploadDateTime] AS [POI_UploadDateTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[PhoneVerification] AS [PhoneVerification],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[PlayerStatusID] AS [PlayerStatusID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[PlayerStatusReasonID] AS [PlayerStatusReasonID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[PlayerStatusSubReasonID] AS [PlayerStatusSubReasonID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[Region] AS [Region],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[RejectionReasonPOA] AS [RejectionReasonPOA],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[RejectionReasonPOI] AS [RejectionReasonPOI],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[RiskGroupID] AS [RiskGroupID],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_EndTime] AS [US_EndTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_IsAutomatic] AS [US_IsAutomatic],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_IsCaseResolved] AS [US_IsCaseResolved],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_ProviderName] AS [US_ProviderName],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_ProviderStatus] AS [US_ProviderStatus],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_SLAMinutes] AS [US_SLAMinutes],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_ScreeningPriority] AS [US_ScreeningPriority],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_ScreeningProcess] AS [US_ScreeningProcess],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_ScreeningStatus] AS [US_ScreeningStatus],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_StartTime] AS [US_StartTime],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_TotalHits] AS [US_TotalHits],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_UnresolvedHits] AS [US_UnresolvedHits],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[US_UpdatedBy] AS [US_UpdatedBy],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[UpdateDate] AS [UpdateDate],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[VD_HasDocuments] AS [VD_HasDocuments],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[VendorPOA] AS [VendorPOA],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[VendorPOI] AS [VendorPOI],
  [BI_DB_Operations_Onboarding_Flow_UserKPIs].[VerificationLevelID] AS [VerificationLevelID]



FROM BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs [BI_DB_Operations_Onboarding_Flow_UserKPIs]