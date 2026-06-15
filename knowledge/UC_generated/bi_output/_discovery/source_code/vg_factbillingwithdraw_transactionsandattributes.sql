-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_factbillingwithdraw_transactionsandattributes
-- Captured: 2026-05-19T14:58:04Z
-- ==========================================================================

SELECT
  -- ======================
  -- Core identifiers
  -- ======================
  fw.CID,
  fw.WithdrawPaymentID,
  x.Name AS FundingType,
  -- ======================
  -- Dates
  -- ======================
  fw.ModificationDate,
  -- ======================
  -- Amounts & currency
  -- ======================
  fw.Amount_Withdraw AS Amount_OriginalCurrency,
  cur.Abbreviation AS Currency,
  fw.BaseExchangeRate,
  fw.ExchangeFee,
  -- ======================
  -- Status
  -- ======================
  cs.Name AS WithdrawStatus,
  cr.Name AS CashoutReason,
  -- ======================
  -- PSP / Provider
  -- ======================
  depot.Name AS PSP_Name,
  fw.ProtocolMIDSettingsID AS MID_SettingsID,
  -- ======================
  -- Card - Brand (Visa / MasterCard / Amex / Diners)
  -- ======================
  ct.Name AS CardBrand_Visa_MC_Amex,
  -- ======================
  -- Card - Category / Tier (Classic / Gold / Platinum / Debit / Prepaid / Business)
  -- ======================
  fw.CardCategory AS CardCategory_Tier_And_Product,
  -- ======================
  -- Card - BIN & issuing bank
  -- ======================
  fw.BinCodeAsString AS BIN_Code,
  fw.BankNameAsString AS IssuingBank,
  cntry.Name AS CardIssuingCountry_BIN
FROM
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw fw
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency cur
      ON fw.CurrencyID = cur.CurrencyID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus cs
      ON fw.CashoutStatusID_Withdraw = cs.CashoutStatusID
    LEFT JOIN main.general.bronze_etoro_dictionary_cashoutreason cr
      ON fw.CashoutReasonID = cr.CashoutReasonID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot depot
      ON fw.DepotID = depot.DepotID
    LEFT JOIN main.general.bronze_etoro_dictionary_cardtype ct
      ON fw.CardTypeIDAsInteger = ct.CardTypeID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype x
      ON fw.FundingTypeID_Withdraw = x.FundingTypeID
    LEFT JOIN main.general.bronze_etoro_dictionary_country cntry
      ON fw.BinCountryIDAsInteger = cntry.CountryID
WHERE
  fw.FundingTypeID_Withdraw != 33
