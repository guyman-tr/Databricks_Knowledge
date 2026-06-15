USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Fact_Reverse_Deposits_DL_To_Synapse(
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
-- EXEC [DWH_dbo].[SP_Fact_Reverse_Deposits_DL_To_Synapse] '2023-07-22'
--declare @dt as date = '2020-01-01'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
----------------------------- delete rows --------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_Reverse_Deposits 
	WHERE ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	and ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);

--------------------------------------------------------------------
	INSERT INTO dwh_daily_process.migration_tables.Fact_Reverse_Deposits
           (`CID`, 
			`WhiteLabelID`, 
			`DepositID`, 
			`DepositTime`, 
			`DepositAmount`, 
			`Currency`, 
			`DepositUSDAmount`, 
			`DepositStatus`, 
			`PreviousDepositStatus`, 
			`DepositStatusModificationTime`, 
			`RollbackDate`, 
			`RollbackAmount`, 
			`ExchangeRate`, 
			`ConversionFee`, 
			`RollbackUSDAmount`, 
			`ReferenceNumber`, 
			`RollbackReason`, 
			`RollbackCanceled`, 
			`FundingMethod`, 
			`Brand`, 
			`PaymentDetails`, 
			`FundingID`, 
			`Depot`, 
			`CustomerStatus`, 
			`RiskStatus`, 
			`VerificationLevel`, 
			`CustomerLevel`, 
			`CountryByRegIP`, 
			`Regulation`, 
			`WhiteLabel`,
			`AccountManager`, 
			`Balance`, 
			`TotalDeposits`, 
			`TotalProcessedCashouts`, 
			`TotalCommissions`, 
			`PIPsInUSD`, 
			`TotalPnL`, 
			`TotalCompensations`, 
			`TotalCredits`, 
			`MIDName`, 
			`MID`, 
			`ThreedsParameters`,
			`ThreedsResponse`, 
			`OldPaymentID`,
            `ModificationDateID`,
			`UpdateDate`
		   )
     SELECT 
			`CID`, 
			`WhiteLabelID`, 
			`DepositID`, 
			`DepositTime`, 
			`DepositAmount`, 
			`Currency`, 
			`DepositUSDAmount`, 
			`DepositStatus`, 
			`PreviousDepositStatus`, 
			`DepositStatusModificationTime`, 
			`RollbackDate`, 
			`RollbackAmount`, 
			`ExchangeRate`, 
			`ConversionFee`, 
			`RollbackUSDAmount`, 
			`ReferenceNumber`, 
			`RollbackReason`, 
			`RollbackCanceled`, 
			`FundingMethod`, 
			`Brand`, 
			`PaymentDetails`, 
			`FundingID`, 
			`Depot`, 
			`CustomerStatus`, 
			`RiskStatus`, 
			`VerificationLevel`, 
			`CustomerLevel`, 
			`CountryByRegIP`, 
			`Regulation`, 
			`WhiteLabel`,
			`AccountManager`, 
			`Balance`, 
			`TotalDeposits`, 
			`TotalProcessedCashouts`, 
			`TotalCommissions`, 
			`PIPsInUSD`, 
			`TotalPnL`, 
			`TotalCompensations`, 
			`TotalCredits`, 
			`MIDName`, 
			`MID`, 
			`ThreedsParameters`,
			`ThreedsResponse`, 
			`OldPaymentID`,
			CAST(date_format(DATEADD(day, DATEDIFF(0, `DepositStatusModificationTime`), 0), 'yyyyMMdd') AS int) as ModificationDateID,
			current_timestamp() as UpdateDate
FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_GetRiskExposureReportPCIVersion
WHERE `DepositStatusModificationTime` >= V_Yesterday AND `DepositStatusModificationTime` < DATEADD(day, 1, V_CurrentDate);
--------------------------------------------------------------------
/*
select *
from [DWH_staging].[etoro_BackOffice_GetRiskExposureReportPCIVersion]

select *
from [DWH_dbo].[Fact_Reverse_Deposits]
WHERE ModificationDateID = 20230722

*/
--------------------------------------------------------------------
END;
