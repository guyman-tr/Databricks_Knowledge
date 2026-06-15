-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_fullbincodelist
-- Captured: 2026-05-19T14:58:13Z
-- ==========================================================================

SELECT
  b.BinCode AS bin_code,
  c.Name AS issuing_country,
  b.IssuingBank AS issuer_name,
    ct.Name AS card_type,
  b.CardSubType AS card_subtype,
  b.SupportsAFT AS aft_support,
    CASE WHEN x.BinFrom IS NOT NULL THEN TRUE ELSE FALSE END AS is_bad_bin
FROM main.general.bronze_etoro_dictionary_countrybin b
LEFT JOIN main.general.bronze_etoro_dictionary_country c
  ON b.CountryID = c.CountryID
INNER JOIN main.general.bronze_etoro_dictionary_cardtype ct
  ON b.CardTypeID = ct.CardTypeID
LEFT JOIN main.billing.bronze_etoro_billing_badbin x
  ON b.BinCode = x.BinFrom
