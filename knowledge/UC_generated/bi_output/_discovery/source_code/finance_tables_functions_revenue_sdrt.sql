-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.finance_tables_functions_revenue_sdrt
-- Captured: 2026-06-19T14:32:07Z
-- ==========================================================================

WITH SDRTPrep AS (
    SELECT
	fca.RealCID
  , fca.Occurred
  , fca.Amount
  , fca.DateID
  , fsc.GCID
  , fsc.CountryID
  , fsc.LabelID
  , fsc.LanguageID
  , fsc.VerificationLevelID
  , fsc.DocsOK
  , fsc.PlayerStatusID
  , fsc.Bankruptcy
  , fsc.RiskStatusID
  , fsc.RiskClassificationID
  , fsc.CommunicationLanguageID
  , fsc.PremiumAccount
  , fsc.Evangelist
  , fsc.GuruStatusID
  , fsc.UpdateDate
  , fsc.RegulationID
  , fsc.AccountStatusID
  , fsc.AccountManagerID
  , fsc.PlayerLevelID
  , fsc.AccountTypeID
  , fsc.DateRangeID
  , fsc.IsDepositor
  , fsc.PendingClosureStatusID
  , fsc.DocumentStatusID
  , fsc.SuitabilityTestStatusID
  , fsc.MifidCategorizationID
  , fsc.IsEmailVerified
  , fsc.IsValidCustomer
  , fsc.DesignatedRegulationID
  , fsc.EvMatchStatus
  , fsc.RegionID
  , fsc.PlayerStatusReasonID
  , fsc.IsCreditReportValidCB
  , fsc.AffiliateID
  , fsc.Email
  , fsc.City
  , fsc.Address
  , fsc.Zip
  , fsc.PhoneNumber
  , fsc.IsPhoneVerified
  , fsc.PhoneVerificationDateID
  , fsc.PlayerStatusSubReasonID
    FROM
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc ON fca.RealCID = fsc.RealCID
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID >= dr.FromDateID AND fca.DateID <= dr.ToDateID
    WHERE 1 = 1
        --and fca.DateID BETWEEN @sdateInt AND @edateInt
        AND fca.ActionTypeID = 35
        AND IsFeeDividend = 3
),
SDRTPrep2 AS (
    SELECT
	  f.RealCID
	, f.Occurred
	, f.DateID
	, f.GCID
	, f.CountryID
	, f.LabelID
	, f.LanguageID
	, f.VerificationLevelID
	, f.DocsOK
	, f.PlayerStatusID
	, f.Bankruptcy
	, f.RiskStatusID
	, f.RiskClassificationID
	, f.CommunicationLanguageID
	, f.PremiumAccount
	, f.Evangelist
	, f.GuruStatusID
	, f.RegulationID
	, f.AccountStatusID
	, f.AccountManagerID
	, f.PlayerLevelID
	, f.AccountTypeID
	, f.DateRangeID
	, f.IsDepositor
	, f.PendingClosureStatusID
	, f.DocumentStatusID
	, f.SuitabilityTestStatusID
	, f.MifidCategorizationID
	, f.IsEmailVerified
	, f.IsValidCustomer
	, f.DesignatedRegulationID
	, f.EvMatchStatus
	, f.RegionID
	, f.PlayerStatusReasonID
	, f.IsCreditReportValidCB
	, f.AffiliateID
	, f.Email
	, f.City
	, f.Address
	, f.Zip
	, f.PhoneNumber
	, f.IsPhoneVerified
	, f.PhoneVerificationDateID
	, f.PlayerStatusSubReasonID
    , -1 * f.Amount AS SDRT
    FROM
        SDRTPrep f
)
SELECT *
FROM
    SDRTPrep2
