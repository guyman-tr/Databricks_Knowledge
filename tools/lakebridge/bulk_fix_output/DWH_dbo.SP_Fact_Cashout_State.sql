USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Cashout_State(
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

	DELETE FROM dwh_daily_process.migration_tables.Fact_Cashout_State
	WHERE ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	and ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);

--------------------------------------------------------------------
	INSERT INTO dwh_daily_process.migration_tables.Fact_Cashout_State
           (`CID`
		  ,`TransactionType`
		  ,`PreviousStatus`
		  ,`WithdrawID`
		  ,`WPID`
		  ,`DepositID`
		  ,`FundingID`
		  ,`DepotID`
		  ,`CashoutStatusID`
		  ,`CashoutStatus`
		  ,`Amount`
		  ,`CurrencyID`
		  ,`AmountInUSD`
		  ,`BaseExchangeRate`
		  ,`ExchangeFee`
		  ,`ExchangeRate`
		  ,`ExTransactionID`
		  ,`ModificationDate`
		  ,`RequestDate`
		  ,`ProtocolMIDSettingsID`
		  ,`MerchantAccountID`
		  ,`PIPsInUSD`
		  ,`ExchaFeeInPercentage`
		  ,`MID`
		  ,`MIDName`
          ,`ModificationDateID`
		  ,`UpdateDate`
		  ,`CreditID` -- guym added 2025-08-13
		   )
     SELECT 
			`CID`
		  ,`TransactionType`
		  ,`PreviousStatus`
		  ,`WithdrawID`
		  ,`WPID`
		  ,`DepositID`
		  ,`FundingID`
		  ,`DepotID`
		  ,`CashoutStatusID`
		  ,`CashoutStatus`
		  ,`Amount`
		  ,`CurrencyID`
		  ,`AmountInUSD`
		  ,`BaseExchangeRate`
		  ,`ExchangeFee`
		  ,`ExchangeRate`
		  ,`ExTransactionID`
		  ,`ModificationDate`
		  ,`RequestDate`
		  ,`ProtocolMIDSettingsID`
		  ,`MerchantAccountID`
		  ,`PIPsInUSD`
		  ,`ExchaFeeInPercentage`
		  ,`MID`
		  ,`MIDName`
		  ,CAST(date_format(DATEADD(day, DATEDIFF(0, `ModificationDate`), 0), 'yyyyMMdd') AS int) as ModificationDateID
		  ,current_timestamp() as UpdateDate
		 ,`CreditID` -- guym added 2025-08-13
FROM dwh_daily_process.daily_snapshot.etoro_Billing_BI_Cashout_State_Report
WHERE `ModificationDate` >= V_Yesterday AND `ModificationDate` < DATEADD(day, 1, V_CurrentDate)

;
END;
