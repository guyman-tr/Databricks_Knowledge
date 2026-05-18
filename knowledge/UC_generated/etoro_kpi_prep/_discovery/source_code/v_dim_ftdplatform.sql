-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_dim_ftdplatform
-- Captured: 2026-05-18T08:04:58Z
-- ==========================================================================

SELECT ID as FTDPlatformID
	, CASE WHEN FTDPlatformID = 1 THEN 'TradingPlatform'
			WHEN FTDPlatformID = 2 THEN 'Options'
			WHEN FTDPlatformID = 3 THEN 'eMoney'
			WHEN FTDPlatformID = 4 THEN 'MoneyFarm'
		ELSE Name END AS Name
FROM main.bi_db.bronze_moneybusdb_dictionary_accounttypes
