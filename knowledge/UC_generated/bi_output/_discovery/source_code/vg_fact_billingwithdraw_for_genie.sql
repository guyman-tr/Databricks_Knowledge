-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_fact_billingwithdraw_for_genie
-- Captured: 2026-06-19T14:34:34Z
-- ==========================================================================

SELECT
    /* ===== Identity ===== */
    bw.CID
  , bw.WithdrawID
  , bw.FundingID

    /* ===== Amount & Currency ===== */
  , bw.Amount_Withdraw                 -- Amount
  , bw.ExchangeRate
  , bw.BaseExchangeRate
  , bw.Fee

    /* ===== Status / Processing ===== */
  , bw.CashoutStatusID_Withdraw        -- WithrawProcessingID
  , bw.CashoutReasonID                 -- RRE Reason
  , bw.ErrorCodeAsString               -- Decline Reason
  , bw.ResponseMessageAsString         -- Response

    /* ===== Dates ===== */
  , bw.ModificationDate                -- Last modified date

    /* ===== Funding / Provider ===== */
  , dft.Name as FundingType                -- Funding Type (name instead of ID)
  , e.WithdrawType as WithdrawType         
  , d.Name as DepotName                        -- Depot
  , bw.BankNameAsString                -- Provider / Bank Name By BIN Code
  , bw.ProtocolMIDSettingsID           -- MID

    /* ===== Card / BIN ===== */
  , bw.BinCodeAsString                 -- BIN Code
  , bw.BinCountryIDAsInteger           -- BIN Country
  , bw.CardTypeIDAsInteger             -- Card Type / Card Sub Type
  , bw.CardCategory                    -- Card Category / Card Sub Category



FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw bw
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft
    ON bw.FundingTypeID_Withdraw = dft.FundingTypeID
    left join main.billing.bronze_etoro_billing_depot d on bw.DepotID = d.DepotID
    left join main.bi_db.bronze_etoro_dictionary_withdrawtype e on bw.WithdrawTypeID = e.withdrawtypeid
