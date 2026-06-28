-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_ouput_v_dim_instrumenttype
-- Captured: 2026-06-19T14:17:34Z
-- ==========================================================================

SELECT ct.CurrencyTypeID AS InstrumentTypeID
	 , COALESCE(di.InstrumentType , ct.Name) AS InstrumentType
	from main.general.bronze_etoro_dictionary_currencytype ct 
		LEFT JOIN (SELECT DISTINCT InstrumentTypeID, InstrumentType FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument) di
			ON ct.CurrencyTypeID = di.InstrumentTypeID
      group by ct.CurrencyTypeID 
	 , COALESCE(di.InstrumentType , ct.Name)
