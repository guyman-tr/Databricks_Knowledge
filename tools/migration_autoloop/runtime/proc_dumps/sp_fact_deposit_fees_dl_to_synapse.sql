BEGIN


DECLARE V_CurrentDate  TIMESTAMP
;
DECLARE V_Yesterday  TIMESTAMP
;
-- EXEC [DWH_dbo].[SP_Fact_Deposit_Fees_DL_To_Synapse] '2023-07-22'
--declare @dt as date = '2020-01-01'

SET V_Yesterday = CAST(V_dt as TIMESTAMP);
SET V_CurrentDate = DATEADD(DAY, 1, V_Yesterday);
----------------------------- delete rows --------------------------
	/*DELETE FROM [DWH_dbo].[Fact_Deposit_Fees]
	WHERE ModificationDateID >= convert(INT,convert(varchar, @Yesterday ,112))
	and ModificationDateID < convert(INT,convert(varchar, @CurrentDate ,112))*/

--------------------------------------------------------------------

	INSERT INTO dwh_daily_process.migration_tables.Fact_Deposit_Fees
           (`CID`, 
			`DepositStatus`, 
			`Threedsresponse`, 
			`DepositRiskStatus`, 
			`DepositAmount`, 
			`Currency`, 
			`StatusModificationTime`, 
			`DepositTime`, 
			`FirstApprovedTime`, 
			`DepositValueDate`, 
			`DepositCollarAmount`, 
			`FundingMethod`, 
			`Depot`, 
			`OldPaymentID`, 
			`DepositID`, 
			`TransactionID_Internal`, 
			`CountryByRegIP`, 
			`Riskstatus`, 
			`FTD`, 
			`BaseExchangeRate`, 
			`ExchangeRate`, 
			`FeeinPIPs`, 
			`PIPsinUSD`, 
			`CustomerStatus`, 
			`Brand`, 
			`CardCategory`, 
			`PaymentDetails`, 
			`FundingID`, 
			`ResponseCode`, 
			`TransactionResponse`, 
			`CustomerLevel`, 
			`AccountManager`, 
			`TotalRollbackDollarAmount`, 
			`TotalRollbackAmount`, 
			`RollbackReason`, 
			`UserName`, 
			`AffiliateID`, 
			`ExternalTransactionID`, 
			`Funnel`, 
			`Regulation`, 
			`WhiteLabel`, 
			`DepositType`, 
			`Threedsparameters`, 
			`MIDName`, 
			`MID`,
            `ModificationDateID`,
			`UpdateDate`
		   )
     SELECT 
		    `CID`, 
			`DepositStatus`, 
			`Threedsresponse`, 
			`DepositRiskStatus`, 
			`DepositAmount`, 
			`Currency`, 
			`StatusModificationTime`, 
			`DepositTime`, 
			`FirstApprovedTime`, 
			`DepositValueDate`, 
			`DepositCollarAmount`, 
			`FundingMethod`, 
			`Depot`, 
			`OldPaymentID`, 
			`DepositID`, 
			`TransactionID_Internal`, 
			`CountryByRegIP`, 
			`Riskstatus`, 
			`FTD`, 
			`BaseExchangeRate`, 
			`ExchangeRate`, 
			`FeeinPIPs`, 
			`PIPsinUSD`, 
			`CustomerStatus`, 
			`Brand`, 
			`CardCategory`, 
			`PaymentDetails`, 
			`FundingID`, 
			`ResponseCode`, 
			`TransactionResponse`, 
			`CustomerLevel`, 
			`AccountManager`, 
			`TotalRollbackDollarAmount`, 
			`TotalRollbackAmount`, 
			`RollbackReason`, 
			`UserName`, 
			`AffiliateID`, 
			`ExternalTransactionID`, 
			`Funnel`, 
			`Regulation`, 
			`WhiteLabel`, 
			`DepositType`, 
			`Threedsparameters`, 
			`MIDName`, 
			`MID`,
			CAST(date_format(DATEADD(day, DATEDIFF(0, StatusModificationTime), 0), 'yyyyMMdd') AS int) as ModificationDateID,
			current_timestamp() as UpdateDate
FROM dwh_daily_process.daily_snapshot.etoro_BackOffice_BillingDepositsPCIVersion;
--WHERE StatusModificationTime >= @Yesterday AND StatusModificationTime < dateadd(day,1, @CurrentDate)
--------------------------------------------------------------------
/*
select *
from [DWH_staging].[etoro_BackOffice_BillingDepositsPCIVersion]

select *
from [DWH_dbo].[Fact_Deposit_Fees]
WHERE ModificationDateID = 20230721

*/
--------------------------------------------------------------------
END