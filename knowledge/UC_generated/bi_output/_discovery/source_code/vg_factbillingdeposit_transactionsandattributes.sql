-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_factbillingdeposit_transactionsandattributes
-- Captured: 2026-05-19T14:57:56Z
-- ==========================================================================

SELECT
  -- ======================
  -- Core identifiers
  -- ======================
  fd.CID,
  fd.DepositID,
  x.Name                                           AS FundingType,

  -- ======================
  -- Dates
  -- ======================
  fd.PaymentDate,
  fd.ModificationDate,

  -- ======================
  -- Amounts & currency
  -- ======================
  fd.Amount                                        AS Amount_OriginalCurrency,
  fd.AmountUSD,
  cur.Abbreviation                                 AS Currency,
  fd.BaseExchangeRate,
  fd.ExchangeFee,

  -- ======================
  -- Status & approval
  -- ======================
  fd.IsFTD,
  ps.Name                                          AS PaymentStatus,

  -- ======================
  -- RRE (Risk Rule Engine) - pre-PSP decline
  -- ======================
  rms.Name                                         AS RRE_DeclineReason,

  -- ======================
  -- 3D Secure
  -- ======================
  CASE
    WHEN fd.ThreeDsAsJson IS NULL AND fd.ThreeDsResponseType IS NULL THEN 'No 3DS'
    WHEN fd.ThreeDsResponseType = '1' THEN '3DS Success'
    WHEN fd.ThreeDsResponseType = '0' THEN '3DS Failed'
    WHEN fd.ThreeDsResponseType = '2' THEN '3DS Challenge Required'
    ELSE '3DS Other'
  END                                              AS ThreeDS_Result,
  fd.ThreeDsAsJson                                 AS ThreeDS_FullJson,

  -- ======================
  -- PSP / Provider
  -- ======================
  depot.Name                                       AS PSP_Name,
  fd.MerchantAccountID,
  fd.ProtocolMIDSettingsID                         AS MID_SettingsID,

  -- ======================
  -- Card - Brand (Visa / MasterCard / Amex / Diners)
  -- ======================
  ct.Name                                          AS CardBrand_Visa_MC_Amex,

  -- ======================
  -- Card - Category / Tier (Classic / Gold / Platinum / Debit / Prepaid / Business)
  -- ======================
  fd.CardCategory                                  AS CardCategory_Tier_And_Product,

  -- ======================
  -- Card - BIN & issuing bank
  -- ======================
  fd.BinCodeAsString                               AS BIN_Code,
  fd.BankNameAsString                              AS IssuingBank,
  cntry.Name                                       AS CardIssuingCountry_BIN,

  -- ======================
  -- AFT (Account Funding Transaction)
  -- ======================
  CASE WHEN fd.IsAftSupportedAsBool = true THEN 'Yes' ELSE 'No' END  AS AFT_Supported,
  CASE WHEN fd.IsAftEligibleAsBool = true THEN 'Yes' ELSE 'No' END   AS AFT_Eligible,
  CASE WHEN fd.IsAftProcessedAsBool = true THEN 'Yes' ELSE 'No' END  AS AFT_Processed,

  -- ======================
  -- Regulation
  -- ======================
  reg.Name                                         AS Regulation

FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fd
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency cur
    ON fd.CurrencyID = cur.CurrencyID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ps
    ON fd.PaymentStatusID = ps.PaymentStatusID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot depot
    ON fd.DepotID = depot.DepotID
  LEFT JOIN main.general.bronze_etoro_dictionary_cardtype ct
    ON fd.CardTypeIDAsInteger = ct.CardTypeID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype x
    ON fd.FundingTypeID = x.FundingTypeID
  LEFT JOIN main.general.bronze_etoro_dictionary_riskmanagementstatus rms
    ON fd.RiskManagementStatusID = rms.RiskManagementStatusID
  LEFT JOIN main.general.bronze_etoro_dictionary_country cntry
    ON fd.BinCountryIDAsInteger = cntry.CountryID
  LEFT JOIN main.general.bronze_etoro_dictionary_regulation reg
    ON fd.ProcessRegulationID = reg.ID
WHERE fd.FundingTypeID != 33
