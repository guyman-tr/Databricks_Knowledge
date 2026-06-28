BEGIN


DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
-- EXEC [DWH_dbo].[SP_Fact_Withdraw_Fees_DL_To_Synapse] '2023-07-22'
--declare @dt as date = '2020-01-01'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
--------------------------------------------------------------------
-- delete rows -----------------------------------------------------

	DELETE FROM dwh_daily_process.migration_tables.Fact_Withdraw_Fees 
	WHERE
	ModificationDateID >= CAST(date_format(V_Yesterday, 'yyyyMMdd') AS INT)
	and
	ModificationDateID < CAST(date_format(V_CurrentDate, 'yyyyMMdd') AS INT);

--------------------------------------------------------------------
	INSERT INTO dwh_daily_process.migration_tables.Fact_Withdraw_Fees
           (`CID`, 
			`PaymentOrderStatus`, 
			`ProcessTime`, 
			`RequestTime`, 
			`StatusModificationTime`, 
            `ModificationDateID`,
			`WithdrawStatus`, 
			`NetCashoutDollarAmount`, 
			`FundingMethod`, 
			`PaymentDetails`, 
			`FundingID`, 
			`WithdrawProcessingID`, 
			`WithdrawID`, 
			`CustomerStatus`, 
			`CustomerLevel`, 
			`PreparationType`, 
			`Executedby`, 
			`ExecutionType`, 
			`ExchangeRate`, 
			`FeeInPIPs`, 
			`PIPsinUSD`, 
			`NetAmountinOrigCurrency`, 
			`Currency`, 
			`Brand`, 
			`Depot`, 
			`ProcessorValueDate`, 
			`VerificationCode`, 
			`VendorCode`, 
			`DepositID`, 
			`CashoutType`, 
			`BackOfficeWithdrawReason`, 
			`WhiteLabel`, 
			`Regulation`, 
			`MIDName`, 
			`MID`,
			`UpdateDate`
		   )
     SELECT 
			`CID`, 
			`PaymentOrderStatus`, 
			`ProcessTime`, 
			`RequestTime`, 
			`StatusModificationTime`, 
			CAST(date_format(DATEADD(day, DATEDIFF(0, StatusModificationTime), 0), 'yyyyMMdd') AS int) as ModificationDateID,
			`WithdrawStatus`, 
			`NetCashoutDollarAmount`, 
			`FundingMethod`, 
			`PaymentDetails`, 
			`FundingID`, 
			`WithdrawProcessingID`, 
			`WithdrawID`, 
			`CustomerStatus`, 
			`CustomerLevel`, 
			`PreparationType`, 
			`Executedby`, 
			`ExecutionType`, 
			`ExchangeRate`, 
			`FeeInPIPs`, 
			`PIPsinUSD`, 
			`NetAmountinOrigCurrency`, 
			`Currency`, 
			`Brand`, 
			`Depot`, 
			`ProcessorValueDate`, 
			`VerificationCode`, 
			`VendorCode`, 
			`DepositID`, 
			`CashoutType`, 
			`BackOfficeWithdrawReason`, 
			`WhiteLabel`, 
			`Regulation`, 
			`MIDName`, 
			`MID`,
			current_timestamp() as UpdateDate
FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_GetProcessedWithdrawPCIVersion
WHERE StatusModificationTime >= V_Yesterday AND StatusModificationTime < DATEADD(day, 1, V_CurrentDate);
--------------------------------------------------------------------
/*

select *
from [DWH_dbo].Fact_Withdraw_Fees 
WHERE ModificationDateID = 20230721

*/
END