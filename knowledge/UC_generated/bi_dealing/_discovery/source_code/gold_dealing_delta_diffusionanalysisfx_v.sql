-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.gold_dealing_delta_diffusionanalysisfx_v
-- Captured: 2026-05-19T12:43:12Z
-- ==========================================================================

SELECT PositionsTime, InstrumentName, InstrumentID, HedgeServerID, format_number(USD_NOP,',###')  USD_NOP, format_number(UnitsNOP,',###')  UnitsNOP, IFF(Sigma IS NULL, 'Missing Sigma', format_number(Delta,',###')) Delta, IFF(Sigma IS NULL, 'Missing Sigma', DeltaRatio) DeltaRatio, IFF(Sigma IS NULL, 'Missing Sigma', format_number(DeltaSquared,',###'))  DeltaSquared, IFF(Sigma IS NULL, 'Missing Sigma', DeltaSquaredRatio) DeltaSquaredRatio, Mid, T, IFNULL(Sigma, 'Missing Sigma') Sigma, SigmaDate 
         FROM bi_dealing.gold_dealing_Delta_DiffusionAnalysisFX
        WHERE date_trunc('HOUR', PositionsTime) = date_trunc('HOUR', current_timestamp())
