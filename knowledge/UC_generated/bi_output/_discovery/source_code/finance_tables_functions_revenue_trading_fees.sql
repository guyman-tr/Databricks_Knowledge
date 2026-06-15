-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.finance_tables_functions_revenue_trading_fees
-- Captured: 2026-05-19T14:53:03Z
-- ==========================================================================

select 
		fca.RealCID
  , -1 * fca.Amount AS TradingFee
  , CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 117 THEN 'Administrationfee'
		WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID = 118 THEN 'SpotPriceAdjustment'
		WHEN fca.ActionTypeID = 35 AND fca.IsFeeDividend = 4 THEN 'TicketFee'
	ELSE 'NA' END AS TradingFeeType
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
          AND (fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117,118)) OR (fca.ActionTypeID = 35 AND fca.IsFeeDividend = 4)
