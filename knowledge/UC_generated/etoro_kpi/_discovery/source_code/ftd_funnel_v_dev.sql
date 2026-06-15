-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.ftd_funnel_v_dev
-- Captured: 2026-05-19T15:15:52Z
-- ==========================================================================

SELECT
  dc.GCID,
  dc.RealCID as CID,
  /*User Dimensions*/
  reg_1.Name as Regulation,
  reg_2.Name as DesignatedRegulation,
  cfd.Club,
  cfd.Country as Country,
  cfd.NewMarketingRegion as MarketingRegion,
  ca.Age as CustomerAge,
  case
    when dc.GuruStatusID IN (2, 3, 4, 5, 6) then TRUE
    else FALSE
  end as IsPopularInvestor,
  /*User Dimensions: Player Status*/
  dps.Name as PlayerStatus,
  /*User Acquisition Info*/
  cfd.Channel,
  cfd.SubChannel,
  cfd.BannerID,
  cfd.SerialID,
  cfd.Language,
  /*User Dates & FTD Amount*/
  dc.VerificationLevelID as CurrentVerificationLevel,
  -- Registration
  CAST(dc.RegisteredReal AS DATE) AS Registration_Date,
  date_format(dc.RegisteredReal, 'HH:mm:ss') AS Registration_Time,
  -- Verification Level 1
  CAST(coalesce(kpi.DateTime_VL1, cfd.VerificationLevel1Date) AS DATE) AS VerificationLevel1_Date,
  date_format(
    coalesce(kpi.DateTime_VL1, cfd.VerificationLevel1Date),
    'HH:mm:ss'
  ) AS VerificationLevel1_Time,
  -- Verification Level 2
  CAST(coalesce(kpi.DateTime_VL2, cfd.VerificationLevel2Date) AS DATE) AS VerificationLevel2_Date,
  date_format(
    coalesce(kpi.DateTime_VL2, cfd.VerificationLevel2Date),
    'HH:mm:ss'
  ) AS VerificationLevel2_Time,
  -- Verification Level 3
  CAST(coalesce(kpi.DateTime_VL3, cfd.VerificationLevel3Date) AS DATE) AS VerificationLevel3_Date,
  date_format(
    coalesce(kpi.DateTime_VL3, cfd.VerificationLevel3Date),
    'HH:mm:ss'
  ) AS VerificationLevel3_Time,
  -- First Time Deposit
  CASE
    WHEN dc.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL
    ELSE CAST(dc.FirstDepositDate AS DATE)
  END AS FirstTimeDeposit_Date,
  CASE
    WHEN dc.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL
    ELSE date_format(dc.FirstDepositDate, 'HH:mm:ss')
  END AS FirstTimeDeposit_Time,
  dc.FirstDepositAmount as FirstTimeDepositAmountUSD,
  cfd.FirstDepositFundingType as FundingType,
  /*Onboarding Details*/
  kpi.KYCFlow,
  /*User Screening*/
  kpi.US_ScreeningStatus as UserScreening_Status,
  kpi.US_StartTime as UserScreening_StartTime,
  kpi.US_EndTime as UserScreening_EndTime,
  /*Electronic Verification*/
  case
    when kpi.EV_IsCountryEligible = 1 then true
    else false
  end as ElectronicVerification_IsCountryEligible,
  kpi.EV_MatchStatusDateTime as ElectronicVerification_MatchStatusDateTime,
  kpi.EV_MatchStatus as ElectronicVerification_MatchStatus,
  /*Proof of Identify*/
  case
    when kpi.VD_HasDocuments = 1 then 'Yes'
    when kpi.VD_HasDocuments = 0 then 'No'
    else 'No Indication'
  end as VD_HasDocuments,
  case
    when kpi.POI_IsApproved = 1 then 'Yes'
    when kpi.POI_IsApproved = 0 then 'No'
    else 'No Indication'
  end as ProofOfIdentity_IsApproved,
  kpi.POI_UploadDateTime as ProofOfIdentity_UploadDateTime,
  kpi.POI_ResponseDateTime as ProofOfIdentity_ResponseDateTime,
  /*Proof of Address*/
  case
    when kpi.POA_IsApproved = 1 then 'Yes'
    when kpi.POA_IsApproved = 0 then 'No'
    else 'No Indication'
  end as ProofOfAddress_IsApproved,
  kpi.POA_UploadDateTime as ProofOfAddress_UploadDateTime,
  kpi.POA_ResponseDateTime as ProofOfAddress_ResponseDateTime,
  /*Email Verification*/
  case
    when kpi.EmailVerification = 1 then 'Yes'
    when kpi.EmailVerification = 0 then 'No'
    else 'No Indication'
  end as IsEmailVerified,
  /*Phone Verification*/
  case
    when dc.IsPhoneVerified = true then 'Yes'
    when dc.IsPhoneVerified = false then 'No'
    else 'No Indication'
  end as IsPhoneVerified,
  dc.PhoneVerificationDate,
  Case
    When exl.GCID IS NOT NULL then True
    Else False
  End as IsExcludeUser,
  exl.excludeReason as ExcludeReason,
  /*KYC*/
  kyc.First_KYC_Answer as First_KYC_Answer_Input_DateTime,
  kyc.Last_KYC_Answer as Last_KYC_Answer_Input_DateTime,
  /*Mixpanel Deposit Clicks*/
  cast(ftdc.initial_deposit_clicks_combined as date) as Initial_DepositClick_Date,
  date_format(ftdc.initial_deposit_clicks_combined, 'HH:mm:ss') as Initial_DepositClick_Time,
  ftdc.initial_deposit_click_type as Initial_DepositClick_Type,
  cast(ftdc.final_deposit_click as date) as Final_DepositClick_Date,
  date_format(ftdc.final_deposit_click, 'HH:mm:ss') as Final_DepositClick_Time,
  /*Reg Platform*/
  p.Platform as RegistrationPlatform,
  cast(cfd.FirstPosOpenDate as date) as FirstPosOpenDate,
  date_format(cfd.FirstPosOpenDate, 'HH:mm:ss') as FirstPosOpenTime,
  f5a.FirstAction,
  f5a.FirstInstrument,
  f5a.FirstActionDate
from
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    LEFT JOIN main.general.bronze_etoro_customer_customer_masked cc
      ON (dc.RealCID = cc.CID)
    LEFT JOIN main.general.bronze_etoro_dictionary_platform p
      ON (cc.PlatformID = p.Id)
    INNER JOIN main.general.bronze_etoro_dictionary_country c
      ON (dc.CountryID = c.CountryID)
    LEFT JOIN bi_dealing.bi_output_dealing_cidage_data ca
      ON (ca.RealCID = dc.RealCID)
    left join main.general.bronze_etoro_dictionary_playerstatus dps
      on dc.PlayerStatusID = dps.PlayerStatusID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation reg_1
      on dc.RegulationID = reg_1.DWHRegulationID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation reg_2
      on dc.DesignatedRegulationID = reg_2.DWHRegulationID
    left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd
      on dc.RealCID = cfd.CID
    left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions f5a 
      on dc.RealCID = f5a.CID
    left join (
      select
        *
      from
        (
          select
            kpi.*,
            row_number() over (partition by kpi.CID order by kpi.CID) as rn
          from
            main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis kpi
        ) t
      where
        rn = 1
    ) kpi
      on dc.RealCID = kpi.CID
    left join main.etoro_kpi.ftd_funnel_kyc kyc
      on dc.GCID = kyc.GCID
    left join main.etoro_kpi.customer_exclude_list exl
      on (exl.GCID = dc.GCID)
    left join main.etoro_kpi.ftd_click_v ftdc
      on (ftdc.gcid = dc.GCID)
where
  dc.IsValidCustomer = 1
