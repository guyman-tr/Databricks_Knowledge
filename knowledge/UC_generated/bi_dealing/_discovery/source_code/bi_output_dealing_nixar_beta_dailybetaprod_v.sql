-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v
-- Captured: 2026-05-19T12:33:53Z
-- ==========================================================================

SELECT InstrumentName, Date, SectorBeta, SectorName, SectorBeta30, SectorBeta90, AskClose, BidClose, InstrumentAskPctChange, PriceTime, SectorAskClose, 
              SectorBidClose, SectorAskPctChange, SectorPriceTime, InstrumentID, SectorID, Correlation30, Correlation, Correlation90, UpdateDate 
        FROM bi_dealing.bi_output_dealing_nixar_beta_DailyBetaProd
        WHERE Date = (SELECT MAX(Date) FROM bi_dealing.bi_output_dealing_nixar_beta_DailyBetaProd)
