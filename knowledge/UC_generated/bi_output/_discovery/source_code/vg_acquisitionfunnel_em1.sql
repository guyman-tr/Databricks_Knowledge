-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_acquisitionfunnel_em1
-- Captured: 2026-06-19T14:33:18Z
-- ==========================================================================

SELECT
    -- Identifiers
    a.CID,
    a.GCID,

    -- Customer attributes (as of yesterday)
    a.Country                              AS Country_as_of_yesterday,
    a.Club                                 AS Club_as_of_yesterday,

    -- Funnel & verification flags (as of yesterday)
    a.IsValidForFunnel                     AS IsValidForFunnel_as_of_yesterday,
    a.IsVerifiedFTD                        AS IsVerifiedFTD_as_of_yesterday,
    a.IsVerifiedFTDPlus2Weeks              AS IsVerifiedFTDPlus2Weeks_as_of_yesterday,
    a.IsActiveMIMO                         AS IsActiveMIMO_as_of_yesterday,
    a.IseMoneyAccount                      AS HasEMoneyAccount_as_of_yesterday,

    -- FMI / FMO / Card flags (by yesterday)
    a.IsFMI                                AS IsFMI_as_of_yesterday,
    a.IsFMO                                AS IsFMO_as_of_yesterday,
    a.IsCardCreated                        AS IsCardCreated_as_of_yesterday,
    a.IsCardActivated                      AS IsCardActivated_as_of_yesterday,
    a.IsCardFirstTx                        AS IsCardFirstTx_as_of_yesterday,

    -- eMoney account program (as of yesterday)
    b.AccountSubProgram                    AS AccountSubProgram_as_of_yesterday,
    b.AccountSubProgramID                  AS AccountSubProgramID_as_of_yesterday,
    b.AccountCreateDate                   AS eMoneyAccountCreateDate

FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel a
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account b
    ON a.CID = b.CID
   AND b.GCID_Unique_Count = 1
   AND b.IsValidETM = 1
   AND b.IsValidCustomer = 1
