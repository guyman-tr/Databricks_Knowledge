-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v
-- Captured: 2026-05-19T12:34:00Z
-- ==========================================================================

SELECT InstrumentID,InstrumentIDToHedge,Multiplier 
         FROM bi_dealing.bi_output_dealing_nixar_beta_DailyBetaTarget
        WHERE Date = current_date()
