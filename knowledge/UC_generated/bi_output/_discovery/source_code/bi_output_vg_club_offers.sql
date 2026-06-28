-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_club_offers
-- Captured: 2026-06-19T14:30:08Z
-- ==========================================================================

SELECT STRING(clb.RealCID) AS RealCID
 ,clb.OfferID
 ,clb.OfferName
 ,clb.Inventorytype
 ,clb.DeliveryMethod
 ,clb.Type
 ,clb.SubType
 ,clb.Category
 ,clb.StartDate
 ,clb.IsEligble
 ,clb.HasOffer
 ,clb.CountryCriteria
 ,clb.RegulationCriteria
 ,clb.ClubCriteria
 ,clb.LanguageCriteria
 ,clb.ExcludeCountryCriteria
 ,clb.ActivationDate
 ,clb.CancellationDate
 ,clb.CancellationReason
 ,clb.ToBeCancelled
 ,clb.SendCouponDate
 ,clb.AssetStatus
 ,clb.ClaimedDate
 ,clb.IsEligbleOnRequest
 ,clb.RequestedBy
 ,clb.Active
 ,dc1.PlayerLevelID
 ,dpl.Name AS ClubTier
 ,dc1.RegulationID
 ,dr.Name AS Regulation
 ,dc1.VerificationLevelID
 ,dv.Name AS VerificationLevel
 ,dc1.CountryID
 ,dc.Name AS Country
 ,dc.MarketingRegionManualName AS Region
 ,dc1.AccountManagerID
 ,concat_ws(dm.FirstName, '', dm.LastName) AS AccountManager
 ,dc1.LanguageID
 ,dl.Name AS Language
 ,dc1.CommunicationLanguageID
 ,dcl.Name AS CommunicationLanguage
 ,dc1.AccountTypeID
 ,act.Name AS AccountType
 ,dc1.GuruStatusID
 ,gs.GuruStatusName
 ,CASE
    WHEN dc1.GuruStatusID > 1 THEN 1
    else 0
  END AS IsPI
 ,CASE WHEN dc1.MifidCategorizationID in (2,3) THEN 1
    ELSE 0
  END AS IsPro
 ,dc1.AccountStatusID
 ,ast.AccountStatusName
 ,dc1.PlayerStatusID
 ,pst.Name as PlayerStatusName
 ,pst.CanOpenPosition
 ,pst.CanClosePosition
 ,pst.CanEditPosition
 ,pst.CanBeCopied
 ,pst.CanDeposit
 ,pst.CanRequestWithdraw
 ,dc1.PlayerStatusReasonID
 ,psr.Name AS PlayerStatusReasonName
 ,dc1.PlayerStatusSubReasonID
 ,pssr.PlayerStatusSubReasonName
 ,dcu.CitizenshipCountryID
 ,dcz.Name CitizenshipCountry
 ,dcu.AffiliateID
FROM main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty clb
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
      on clb.RealCID = dc1.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
      on dc1.RealCID = dcu.RealCID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
      on dc1.PlayerLevelID = dpl.PlayerLevelID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm
      on dc1.AccountManagerID = dm.ManagerID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
      on dc1.RegulationID = dr.ID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
      on dc1.CountryID = dc.CountryID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
      on dc1.LanguageID = dl.LanguageID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel dv
      on dc1.VerificationLevelID = dv.ID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus gs
      on dc1.GuruStatusID = gs.GuruStatusID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus ast
      on dc1.AccountStatusID = ast.AccountStatusID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype act
      on dc1.AccountTypeID = act.AccountTypeID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pst
      on dc1.PlayerStatusID = pst.PlayerStatusID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
      on dc1.PlayerStatusReasonID = psr.PlayerStatusReasonID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr
      on dc1.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
    inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dcl
      on dc1.CommunicationLanguageID = dcl.LanguageID
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dcz
      on dcu.CitizenshipCountryID = dcz.CountryID
where
  dc1.IsValidCustomer = 1
  and dc1.IsCreditReportValidCB = 1
