USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Cashout_Rollback_DL_To_Synapse(
IN V_dt TIMESTAMP)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN


DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
-- EXEC [DWH_dbo].[SP_Fact_Cashout_Rollback_DL_To_Synapse] '2023-07-22'
--declare @dt as date = '2020-01-01'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
----------------------------- delete rows --------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_Cashout_Rollback
	WHERE ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	and ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);

--------------------------------------------------------------------
	INSERT INTO dwh_daily_process.migration_tables.Fact_Cashout_Rollback
           (`CID`, 
			`WithdrawprocessingID`, 
			`WithdrawID`, 
			`ProcessTime`, 
			`NetAmount`, 
			`Currency`, 
			`NetUSDAmount`, 
			`RollbackDate`, 
			`RollbackAmount`, 
			`ExchangeRate`, 
			`FeeInPIPs`, 
			`RollbackUSDAmount`, 
			`ReferenceNumber`, 
			`RollbackReason`, 
			`PaymentStatusID`, 
			`FundingMethod`, 
			`Brand`, 
			`PaymentDetails`, 
			`FundingID`, 
			`Depot`, 
			`VerificationCode`, 
			`Regulation`, 
			`MIDName`, 
			`MID`, 
			`PaymentOrderStatus`, 
			`StatusModificationTime`,
            `ModificationDateID`,
			`UpdateDate`
		   )
     SELECT 
			`CID`, 
			`WithdrawprocessingID`, 
			`WithdrawID`, 
			`ProcessTime`, 
			`NetAmount`, 
			`Currency`, 
			`NetUSDAmount`, 
			`RollbackDate`, 
			`RollbackAmount`, 
			`ExchangeRate`, 
			`FeeInPIPs`, 
			`RollbackUSDAmount`, 
			`ReferenceNumber`, 
			`RollbackReason`, 
			`PaymentStatusID`, 
			`FundingMethod`, 
			`Brand`, 
			`PaymentDetails`, 
			`FundingID`, 
			`Depot`, 
			`VerificationCode`, 
			`Regulation`, 
			`MIDName`, 
			`MID`, 
			`PaymentOrderStatus`, 
			`StatusModificationTime`,
			CAST(date_format(DATEADD(day, DATEDIFF(0, StatusModificationTime), 0), 'yyyyMMdd') AS int) as ModificationDateID,
			current_timestamp() as UpdateDate
FROM dwh_daily_process.daily_snapshot.etoro_Billing_GetRollbackedPaymentOrdersReport
WHERE StatusModificationTime >= V_Yesterday AND StatusModificationTime < DATEADD(day, 1, V_CurrentDate);
--------------------------------------------------------------------
/*
select *
from [DWH_staging].[etoro_Billing_GetRollbackedPaymentOrdersReport]

select *
from [DWH_dbo].[Fact_Cashout_Rollback]
WHERE ModificationDateID = 20230721

*/
--------------------------------------------------------------------
END;
