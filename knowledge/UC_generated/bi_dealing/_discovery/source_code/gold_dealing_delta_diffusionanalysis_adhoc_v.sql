-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.gold_dealing_delta_diffusionanalysis_adhoc_v
-- Captured: 2026-05-19T12:42:19Z
-- ==========================================================================

SELECT PositionsTime, InstrumentName, InstrumentID, HedgeServerID, format_number(NOP,',###')  NOP, format_number(NOP_80Percent,',###') NOP_80Percent, IFF(Sigma IS NULL, 'Missing Sigma', format_number(Delta,',###')) Delta, IFF(Sigma IS NULL, 'Missing Sigma', format_number(DeltaSquared,',###'))  DeltaSquared, Mid, T, IFNULL(Sigma, 'Missing Sigma') Sigma, SigmaDate 
         FROM bi_dealing.gold_dealing_Delta_DiffusionAnalysis_adhoc
        WHERE date_trunc('HOUR', PositionsTime) = date_trunc('HOUR', current_timestamp())
