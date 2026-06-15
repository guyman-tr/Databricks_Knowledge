-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_panel_firstdates_em1
-- Captured: 2026-05-19T14:56:38Z
-- ==========================================================================

SELECT
    /* =========================
       Identifiers
       ========================= */
    CID,
    GCID,

    /* =========================
       FMI / FMO (eMoney POV)
       ========================= */
    FMI_Date       AS emoney_fmi_date,
    FMI_Source     AS emoney_fmi_source,
    Seniority_FMI,

    FMO_Date       AS emoney_fmo_date,
    FMO_Target     AS emoney_fmo_target,
    FMO_MOP        AS emoney_fmo_mop,
    Seniority_FMO,

    /* =========================
       Settled transaction dates
       ========================= */
    LastSettledTXDate          AS emoney_last_settled_tx_date,
    Seniority_LastTXDate,
    FirstIBANSettledTXDate     AS emoney_first_settled_tx_date,
    LastIBANSettledTXDate      AS emoney_last_settled_tx_date_iban,

    /* =========================
       Generic action sequence (1–5)
       ========================= */
    1stActionDate              AS emoney_1st_action_date,
    1stActionType              AS emoney_1st_action_type,
    1stActionUSDApproxAmount   AS emoney_1st_action_amount_usd,

    2ndActionDate              AS emoney_2nd_action_date,
    2ndActionType              AS emoney_2nd_action_type,
    2ndActionUSDApproxAmount   AS emoney_2nd_action_amount_usd,

    3rdActionDate              AS emoney_3rd_action_date,
    3rdActionType              AS emoney_3rd_action_type,
    3rdActionUSDApproxAmount   AS emoney_3rd_action_amount_usd,

    4thActionDate              AS emoney_4th_action_date,
    4thActionType              AS emoney_4th_action_type,
    4thActionUSDApproxAmount   AS emoney_4th_action_amount_usd,

    5thActionDate              AS emoney_5th_action_date,
    5thActionType              AS emoney_5th_action_type,
    5thActionUSDApproxAmount   AS emoney_5th_action_amount_usd,

    /* =========================
       Card lifecycle & actions (1–5)
       ========================= */
    CardActivationTime         AS emoney_card_activation_date,

    Card1stActionDate          AS emoney_card_1st_action_date,
    Card1stActionType          AS emoney_card_1st_action_type,
    Card1stActionUSDApproxAmount AS emoney_card_1st_action_amount_usd,

    Card2ndActionDate          AS emoney_card_2nd_action_date,
    Card2ndActionType          AS emoney_card_2nd_action_type,
    Card2ndActionUSDApproxAmount AS emoney_card_2nd_action_amount_usd,

    Card3rdActionDate          AS emoney_card_3rd_action_date,
    Card3rdActionType          AS emoney_card_3rd_action_type,
    Card3rdActionUSDApproxAmount AS emoney_card_3rd_action_amount_usd,

    Card4thActionDate          AS emoney_card_4th_action_date,
    Card4thActionType          AS emoney_card_4th_action_type,
    Card4thActionUSDApproxAmount AS emoney_card_4th_action_amount_usd,

    Card5thActionDate          AS emoney_card_5th_action_date,
    Card5thActionType          AS emoney_card_5th_action_type,
    Card5thActionUSDApproxAmount AS emoney_card_5th_action_amount_usd

FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates
