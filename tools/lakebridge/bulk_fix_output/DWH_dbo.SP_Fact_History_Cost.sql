USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_History_Cost(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN




DECLARE V_dateID INT ;

DECLARE V_row_count INT 
;
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
--EXEC [DWH_dbo].[SP_Fact_History_Cost] '2025-05-05'

SET V_dateID = CAST(date_format(V_dt, 'yyyyMMdd') AS int)
;
set V_Yesterday= cast(V_dt as TIMESTAMP) ;
set V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
	Delete
	from dwh_daily_process.migration_tables.Fact_History_Cost 
	where DateID >= cast(date_format(cast(V_Yesterday as date), 'yyyyMMdd') as INT)
	and	DateID < cast(date_format(cast(V_CurrentDate as date), 'yyyyMMdd') as INT);

-- INSERT Rows - Fact_History_Cost -----------------
	INSERT INTO dwh_daily_process.migration_tables.Fact_History_Cost
    (	
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
	DateID,
	UpdateDate
)
	select 	
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
	DateID,
	current_timestamp() as UpdateDate
	from dwh_daily_process.migration_tables.Ext_History_Cost
;
SET V_row_count = (
SELECT
COUNT(*) FROM dwh_daily_process.migration_tables.Fact_History_Cost NOLOCK WHERE DateID = V_dateID
	 LIMIT 1);
-- [stub] auxiliary SP call elided (helper not deployed / not needed in Databricks)
END;
