-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_potentialclients_attributes
-- Captured: 2026-05-19T14:56:46Z
-- ==========================================================================

WITH base_customers AS (
    -- Base population = all customers in eMoney-eligible countries
    SELECT
        dc.RealCID AS CID,
        dpl.Name AS Club,
        co.Name AS CountryName,
        dc.PlayerStatusID,
        dc.VerificationLevelID,
        dc.IsValidCustomer,
        dc.CountryID,
        dc.RegulationID,
        dc.ScreeningStatusID,
        dc.AccountTypeID,
        dc.PhoneVerifiedID,
        dc.POBCountryID
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
        ON dc.PlayerLevelID = dpl.PlayerLevelID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co
        ON dc.CountryID = co.CountryID
    WHERE dc.CountryID IN (
        95,54,119,79,154,184,165,57,67,112,143,191,
        100,52,135,196,32,218,72,185,82,13,74,117,
        19,118,126,102,94,55,164,168,12,197
    )
),

eligibility_au_only AS (
    -- Eligibility logic applies ONLY to Australia (CountryID = 12)
    SELECT
        *,
        CASE
            WHEN CountryID = 12
             AND IsValidCustomer = 1
             AND RegulationID = 10
             AND PlayerStatusID IN (1,12,5)
             AND VerificationLevelID = 3
             AND ScreeningStatusID = 1
             AND AccountTypeID = 1
             AND PhoneVerifiedID IN (1,2)
             AND POBCountryID IS NOT NULL
            THEN 1 ELSE 0
        END AS IsEligible_AU
    FROM base_customers
),

etm_accounts AS (
    -- All valid eMoney (ETM) accounts
    SELECT
        mda.CID,
        1 AS HasETMAccount,
        mda.AccountSubProgramID,
        mda.AccountCreateDateID
    FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account mda
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        ON mda.CID = fsc.RealCID
    INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
        ON dr.DateRangeID = fsc.DateRangeID
       AND mda.AccountCreateDateID BETWEEN dr.FromDateID AND dr.ToDateID
    WHERE mda.GCID_Unique_Count = 1
      AND mda.IsValidETM = 1
      AND mda.IsTestAccount = 0
)

SELECT
    e.CID,
    e.CountryName,
    e.Club,
    e.PlayerStatusID,
    e.VerificationLevelID,
    e.IsEligible_AU AS IsEligible,
    COALESCE(a.HasETMAccount,0) AS HasETMAccount,
    a.AccountSubProgramID,
    a.AccountCreateDateID
FROM eligibility_au_only e
LEFT JOIN etm_accounts a
    ON e.CID = a.CID
