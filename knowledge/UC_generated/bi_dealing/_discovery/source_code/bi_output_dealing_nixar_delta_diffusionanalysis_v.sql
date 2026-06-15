-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis_v
-- Captured: 2026-05-19T12:34:22Z
-- ==========================================================================

SELECT Date, PositionsTime, InstrumentName, InstrumentID, format_number(NOP,',###')  NOP, format_number(NOP_80Percent,',###') NOP_80Percent, IFF(Sigma IS NULL, 'Missing Sigma', format_number(Delta,',###')) Delta, IFF(Sigma IS NULL, 'Missing Sigma', format_number(DeltaSquared,',###'))  DeltaSquared, Mid, T, IFNULL(Sigma, 'Missing Sigma') Sigma, UpdateDate 
         FROM bi_dealing.bi_output_dealing_nixar_Delta_DiffusionAnalysis
        WHERE date_trunc('HOUR', PositionsTime) = date_trunc('HOUR', current_timestamp())
