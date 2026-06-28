-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_bidb_alldeposits_for_genie
-- Captured: 2026-06-19T14:33:25Z
-- ==========================================================================

SELECT
    -- ======================
    -- Core identifiers
    -- ======================
    CID,
      DepositID,
       FundingType,

    -- ======================
    -- Dates (single main date + tx time)
    -- ======================
    ModificationDate,
  
   

    -- ======================
    -- Amounts & currency (requested)
    -- ======================
    Amount_In_Orig_Curr    AS AmountOrig,
    Amount_in_USD          AS AmountUSD,
    Currency,
    BaseExchangeRate,
   

    -- ======================
    -- Status & flags (requested)
    -- ======================
    IsFTD,
    PaymentStatus,
    PaymentStatusAsInteger,
    Category               AS DepositCategory,

    -- ======================
    -- Funding / provider (requested)
    -- ======================
   
    Provider,
    DepotID,
    PSPCode,

    -- ======================
    -- Card / BIN / bank (requested)
    -- ======================
    BINCountry,
    BinCode,
    BinCodeAsString,
    CardType,
    CardSubType,
    CardTypeIDAsInteger,
    Bank_name_by_Bincode,

    -- ======================
    -- Risk & regulation (requested)
    -- ======================
    RiskStatus,
    
    Regulation,
    DesignatedRegulation,

    -- ======================
    -- Geography / attribution (requested)
    -- ======================
    Country_customer        AS RegistrationCountry,
    CountryIDAsInteger      AS CountryID,
    Region,
    Funnel,
    FunnelFrom,
    Affiliate_ID,

    -- ======================
    -- Responses / 3DS (requested)
    -- ======================
    Response,
    ResponseMessageAsString AS DeclineReason,
    ErrorCodeAsString       AS RREReason,
    ThreeDsAsJson           AS ThreeDSResponseJson,

    -- ======================
    -- GCID / customer linkage (likely needed)
    -- ======================
    CustomerIDAsString      AS GCID,

    -- ======================
    -- Misc useful
    -- ======================
    MID,
    TransactionIDAsString

FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
