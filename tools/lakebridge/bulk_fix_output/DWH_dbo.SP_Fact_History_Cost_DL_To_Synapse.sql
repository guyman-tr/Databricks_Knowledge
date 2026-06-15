USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_History_Cost_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_Yesterday  TIMESTAMP
;
DECLARE V_CurrentDate  TIMESTAMP
;
/********************************************************************************************
Author:      Daniel Kaplan
Date:        2025-05-15
Description: Insert in Fact_History_Cost
 
**************************
** Change History
**************************
Date            Author			Description   
----------      ----------		------------------------------------
2025-05-15		Daniel Kaplan	Create SP
*********************************************************************************************/
--EXEC [DWH_dbo].[SP_Fact_History_Cost_DL_To_Synapse] '2025-05-05'

-- select * from [DWH_staging].[History_Cost]
-- select * from [DWH_dbo].[Fact_History_Cost]

-- =============================================

set V_Yesterday= cast(V_dt as TIMESTAMP) ;
set V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- Extract Fact_History_Cost -----------------------

TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_History_Cost

;
	INSERT INTO dwh_daily_process.migration_tables.Ext_History_Cost
	SELECT   
	`CostID`, 
	`CID`, 
	`PartitionCol`, 
	`MirrorID`, 
	`CostConfigurationID`, 
	`ValueInAccountCurrency`, 
	`ValueInAssetCurrency`, 
	`ConversionRate`, 
	`CalculationTypeID`, 
	`CostConfigValue`, 
	`IsIncludedInTransactionValue`, 
	`TransactionUnits`, 
	`CostCurrencyID`, 
	`BalanceCurrencyID`, 
	`AssetCurrencyID`, 
	`ActionTypeID`, 
	`OperationTypeID`, 
	`CostTypeID`, 
	`CostSubTypeID`, 
	`PositionID`, 
	`OrderID`, 
	`CreditID`, 
	`Occurred`,
	CAST(date_format(`Occurred`, 'yyyyMMdd') AS int) DateID,
	current_timestamp() as UpdateDate
	FROM dwh_daily_process.daily_snapshot.HistoryCosts_History_Costs;
	--WHERE [Timestamp] = @Yesterday

-- Execute SP_Fact_History_Cost --------------------
call dwh_daily_process.migration_tables.SP_Fact_History_Cost(V_Yesterday);
END;
