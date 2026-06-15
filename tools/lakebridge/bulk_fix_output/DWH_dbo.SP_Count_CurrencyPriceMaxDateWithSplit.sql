USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Count_CurrencyPriceMaxDateWithSplit(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN

-- WAITFOR DELAY '00:00:10';

Select Count(*) as Count_CurrencyPriceMaxDateWithSplit from dwh_daily_process.migration_tables.Ext_FCUPNL_CurrencyPriceMaxDateWithSplit
;
END;
