-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly_report_v
-- Captured: 2026-05-19T12:40:43Z
-- ==========================================================================

select Date,StartTime,InstrumentID,InstrumentName,ADV_Last3Months,SharesOutStanding,EtoroVolumeExternalized,CustomersTotalUnits
	,CID,VolumeInUnitsDailyRealized,RealizedZero,VolumeExternalised_CID
FROM main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly
where Date= date_format(current_date(), 'yyyy-MM-dd') 
order by StartTime,InstrumentID
