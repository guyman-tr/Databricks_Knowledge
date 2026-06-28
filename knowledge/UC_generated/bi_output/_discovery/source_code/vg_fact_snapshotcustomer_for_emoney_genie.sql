-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie
-- Captured: 2026-06-19T14:34:38Z
-- ==========================================================================

SELECT
    b.FromDateID,
    b.ToDateID,

    -- Customer identifiers (valid in snapshot period)
    a.GCID      AS GCID,
    a.RealCID  AS CID,

    -- Geography & regulation (valid in snapshot period)
    a.CountryID     AS CountryID_FromDate_ToDate,
    a.RegionID      AS RegionID_FromDate_ToDate,
    a.RegulationID  AS RegulationID_FromDate_ToDate,

    -- Language & communication (valid in snapshot period)
    a.LanguageID                AS LanguageID_FromDate_ToDate,
    a.CommunicationLanguageID   AS CommunicationLanguageID_FromDate_ToDate,

    -- Customer status & risk (valid in snapshot period)
    a.VerificationLevelID   AS VerificationLevelID_FromDate_ToDate,
    a.PlayerStatusID        AS PlayerStatusID_FromDate_ToDate,
    a.RiskStatusID          AS RiskStatusID_FromDate_ToDate,
    a.RiskClassificationID  AS RiskClassificationID_FromDate_ToDate,
    a.AccountStatusID       AS AccountStatusID_FromDate_ToDate,
    a.IsValidCustomer       AS IsValidCustomer_FromDate_ToDate,
    a.IsEmailVerified       AS IsEmailVerified_FromDate_ToDate,
    a.IsPhoneVerified       AS IsPhoneVerified_FromDate_ToDate,

    -- Commercial / segmentation (valid in snapshot period)
    a.PlayerLevelID     AS PlayerLevelID_FromDate_ToDate,
    c.Name              AS Club_FromDate_ToDate,
    a.AccountTypeID     AS AccountTypeID_FromDate_ToDate,
    a.IsDepositor       AS IsDepositor_FromDate_ToDate,
    a.GuruStatusID      AS GuruStatusID_FromDate_ToDate,
    a.AccountManagerID  AS AccountManagerID_FromDate_ToDate,

    -- Location (valid in snapshot period)
    a.City     AS City_FromDate_ToDate,
    a.Address  AS Address_FromDate_ToDate, 
    d.Name as Country_FromDate_ToDate

FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked a
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range b
    ON a.DateRangeID = b.DateRangeID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel c
    ON a.PlayerLevelID = c.PlayerLevelID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country d ON a.CountryID=d.CountryID
