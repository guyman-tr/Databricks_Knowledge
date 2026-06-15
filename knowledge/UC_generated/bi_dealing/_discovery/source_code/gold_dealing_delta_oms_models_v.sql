-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.gold_dealing_delta_oms_models_v
-- Captured: 2026-05-19T12:43:35Z
-- ==========================================================================

select Instrument, Model, ModelParameter, Value, UpdateTime, ModelVersion, URL, OmsParam from main.bi_dealing.gold_dealing_delta_oms_diffusion
where Instrument = 335
and etr_ymd = current_date()
and date_trunc('HOUR', now()) = date_trunc('HOUR', UpdateTime)
