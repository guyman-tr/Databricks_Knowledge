-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_fact_billingdepost_forgenie_new
-- Captured: 2026-06-19T14:34:29Z
-- ==========================================================================

SELECT
  -- ======================
  -- Core identifiers
  -- ======================
  fd.CID,
  fd.DepositID,
  x.Name as FundingType,


  -- ======================
  -- Dates
  -- ======================
  fd.ModificationDate,

  -- ======================
  -- Amounts & currency
  -- ======================
  fd.AmountUSD,
  cur.Abbreviation                       AS Currency,
  fd.BaseExchangeRate,

  -- ======================
  -- Status & flags
  -- ======================
  fd.IsFTD,
  ps.Name                                AS PaymentStatus,

  -- ======================
  -- Funding / provider
  -- ======================
  depot.Name                             AS Provider,
  fd.DepotID,
  fd.PSPCodeAsString,

  -- ======================
  -- Card / BIN / bank
  -- ======================
  
  fd.BinCodeAsString,
  ct.Name                                AS CardType,
  fd.CardCategory                        AS CardSubType,
  fd.BankNameAsString                    AS BankName,

  -- ======================
  -- Responses / 3DS
  -- ======================
  fd.ResponseMessageAsString             AS DeclineReason,
  fd.ErrorCodeAsString                   AS RREReason,
  fd.ThreeDsAsJson                       AS ThreeDSResponseJson,

  -- ======================
  -- Misc useful
  -- ======================
  fd.ProtocolMIDSettingsID,
  fd.TransactionIDAsString
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fd
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency cur
  ON fd.CurrencyID = cur.CurrencyID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ps
  ON fd.PaymentStatusID = ps.PaymentStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_billingdepot depot
  ON fd.DepotID = depot.DepotID
LEFT JOIN main.general.bronze_etoro_dictionary_cardtype ct
  ON fd.CardTypeIDAsInteger = ct.CardTypeID
  left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype x on fd.FundingTypeID=x.FundingTypeID
