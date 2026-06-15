-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.gold_dealing_oms_delta_diffusionanalysis_v
-- Captured: 2026-05-19T12:46:16Z
-- ==========================================================================

with factors
as 
(
SELECT * from VALUES 
(335, 100, 42000) 
as Factors(InstrumentID, etoroFactor, contractFactor)
)
, raw_target
as
(
select
  *
from
  main.bi_dealing.gold_dealing_delta_diffusionanalysis
where
  InstrumentID in (335, 91)
  and Date = current_date()
  and date_trunc('HOUR', now()) = date_trunc('HOUR', PositionsTime)
)
select
CAST(InstrumentID as STRING) as Instrument,
"FuturesNOP" Model,
"portfolioId" ModelParameter,
"HS225-ExpiringFutures-Hedging_NOP" Value,
cast(PositionsTime as STRING) UpdateTime,
"1" ModelVersion,
"/api/db/table/PortfolioProperty" URL,
"portfolioId" OmsParam
from 
raw_target
UNION ALL
select
CAST(InstrumentID as STRING) as Instrument,
"FuturesNOP" Model,
"propertyId" ModelParameter,
CONCAT("NOP_", InstrumentID) Value,
cast(PositionsTime as STRING) UpdateTime,
"1" ModelVersion,
"/api/db/table/PortfolioProperty" URL,
"propertyId" OmsParam
from 
raw_target
UNION ALL
select
CAST(InstrumentID as STRING) as Instrument,
"FuturesNOP" Model,
"propertyValue" ModelParameter,
format_number(coalesce(aa.DeltaSquared /coalesce(ff.contractFactor, 1) * coalesce(ff.etoroFactor, 1), 0), 2) Value,
cast(PositionsTime as STRING) UpdateTime,
"1" ModelVersion,
"/api/db/table/PortfolioProperty" URL,
"propertyValue" OmsParam
from 
raw_target aa
left outer join
factors ff using (InstrumentID)
