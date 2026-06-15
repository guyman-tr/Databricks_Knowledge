SELECT a.*, b.SellCurrency
FROM 
(
select  
	 DateID
	 , CID
	 , cast(DepositWithdrawID as bigint) as DepositWithdrawID
	 , Occurred
	 , CreditTypeID
	 , cast(REPLACE(REPLACE (TransactionID, 'D', ''), 'W', '') as bigint) AS TransactionID
	 , Date
	 , Customer
	 , TransactionType
	 , PaymentMethod
	 , Amount
	 , Currency
	 , ExchangeRate
	 , AmountUSD
	 , RegulationID
	 , LabelID
	 , PlayerLevelID
	 , Regulation
	 , [Label]
	 , IsValidCustomer
	 , UpdateDate
	 , BaseExchangeRate
	 , ExchangeFee
	 , ExternalTransactionID
	 , Depot
	 , MIDValue
	 , Club
	 , PlayerStatus
	 , PIPsCalculation
	 , RegCountry
	 , RegCountryByIP
	 , CardType
	 , CardCategory
	 , BinCountry
	 , MOPCountry
	 , IsGermanBaFin
	 , 'NA' AS Entity
        , IsIBANTrade
from BI_DB_dbo.BI_DB_DepositWithdrawFee with (nolock)
where Date between <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>
UNION ALL
SELECT bdwrp.DateID
	 , bdwrp.CID
	 , cast(DepositWithdrawID as bigint) as DepositWithdrawID
	 , bdwrp.Occurred
	 , bdwrp.CreditTypeID
	 , cast(REPLACE(REPLACE (TransactionID, 'D', ''), 'W', '') as bigint) AS TransactionID
	 , bdwrp.Date
	 , bdwrp.Customer
	 , bdwrp.TransactionType
	 , bdwrp.PaymentMethod
	 , bdwrp.Amount
	 , bdwrp.Currency
	 , bdwrp.ExchangeRate
	 , bdwrp.AmountUSD
	 , bdwrp.RegulationID
	 , bdwrp.LabelID
	 , bdwrp.PlayerLevelID
	 , bdwrp.Regulation
	 , bdwrp.[Label]
	 , bdwrp.IsValidCustomer
	 , bdwrp.UpdateDate
	 , bdwrp.BaseExchangeRate
	 , bdwrp.ExchangeFee
	 , bdwrp.ExternalTransactionID
	 , bdwrp.Depot
	 , bdwrp.MIDValue
	 , bdwrp.Club
	 , bdwrp.PlayerStatus
	 , bdwrp.PIPsCalculation
	 , bdwrp.RegCountry
	 , bdwrp.RegCountryByIP
	 , bdwrp.CardType
	 , bdwrp.CardCategory
	 , bdwrp.BinCountry
	 , bdwrp.MOPCountry
	 , bdwrp.IsGermanBaFin
	 , bdwrp.Entity
        , NULL as IsIBANTrade
FROM BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs bdwrp
WHERE Date BETWEEN <[Parameters].[Parameter 3 1]>  and <[Parameters].[Parameter 4 1]>
UNION ALL
SELECT bddrp.DateID
	 , bddrp.CID
	 , cast(DepositWithdrawID as bigint) as DepositWithdrawID
	 , bddrp.Occurred
	 , bddrp.CreditTypeID
	 , cast(REPLACE(REPLACE (TransactionID, 'D', ''), 'W', '') as bigint) AS TransactionID
	 , bddrp.Date
	 , bddrp.Customer
	 , bddrp.TransactionType
	 , bddrp.PaymentMethod
	 , bddrp.Amount
	 , bddrp.Currency
	 , bddrp.ExchangeRate
	 , bddrp.AmountUSD
	 , bddrp.RegulationID
	 , bddrp.LabelID
	 , bddrp.PlayerLevelID
	 , bddrp.Regulation
	 , bddrp.[Label]
	 , bddrp.IsValidCustomer
	 , bddrp.UpdateDate
	 , bddrp.BaseExchangeRate
	 , bddrp.ExchangeFee
	 , bddrp.ExternalTransactionID
	 , bddrp.Depot
	 , bddrp.MIDValue
	 , bddrp.Club
	 , bddrp.PlayerStatus
	 , bddrp.PIPsCalculation
	 , bddrp.RegCountry
	 , bddrp.RegCountryByIP
	 , bddrp.CardType
	 , bddrp.CardCategory
	 , bddrp.BinCountry
	 , bddrp.MOPCountry
	 , bddrp.IsGermanBaFin
	 , bddrp.Entity	
        , NULL as IsIBANTrade
FROM BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs bddrp 
WHERE Date BETWEEN <[Parameters].[Parameter 3 1]>  and <[Parameters].[Parameter 4 1]>
) a
LEFT JOIN 
(
SELECT bdpcti.WithdrawPaymentID as TransactionID
    , cast(fbw.CID as bigint) as CID
    , cast (fbw.ModificationDate_WithdrawToFunding as Date) as MIMODate
	, CAST(FORMAT(CAST(fbw.ModificationDate_WithdrawToFunding AS DATE),'yyyyMMdd') as INT) AS MIMODateID
    , cast(di.SellCurrency as varchar(10)) as SellCurrency
    , 'Withdraw' as TransactionType
FROM BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN bdpcti -- select * from BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN bdpcti
	JOIN DWH_dbo.Fact_BillingWithdraw fbw
		ON bdpcti.WithdrawPaymentID = fbw.WithdrawPaymentID
	LEFT JOIN DWH_dbo.Dim_Position dp
		ON bdpcti.PositionID = dp.PositionID
	LEFT JOIN DWH_dbo.Dim_Instrument di
		ON dp.InstrumentID = di.InstrumentID
where cast (fbw.ModificationDate_WithdrawToFunding as Date) between <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>

union ALL

select cast(bdpofi.DepositID as bigint) as TransactionID
    , cast(fbd.CID as bigint) as CID
    , cast(ModificationDate as Date) as MIMODate
	, CAST(FORMAT(CAST(fbd.ModificationDate AS DATE),'yyyyMMdd') as INT) AS MIMODateID
    , cast(di1.SellCurrency as varchar(10)) as SellCurrency
    , 'Deposit' as TransactionType
from BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN  bdpofi
	JOIN DWH_dbo.Fact_BillingDeposit fbd
		ON bdpofi.DepositID = fbd.DepositID
	LEFT JOIN DWH_dbo.Dim_Position dp1
		ON bdpofi.PositionID = dp1.PositionID
	LEFT JOIN DWH_dbo.Dim_Instrument di1
		ON dp1.InstrumentID = di1.InstrumentID
where cast(fbd.ModificationDate as Date) between <[Parameters].[Parameter 3 1]> and <[Parameters].[Parameter 4 1]>
) b
ON a.TransactionID = b.TransactionID
	AND a.DateID = b.MIMODateID
	AND a.TransactionType = b.TransactionType