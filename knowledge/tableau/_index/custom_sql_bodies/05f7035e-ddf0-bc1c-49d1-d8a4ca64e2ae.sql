SELECT
	rb.CID
  , rb.Date
  , rb.DateID
  , rb.Year
  , rb.Regulation
  , rb.IsCreditReportValidCB
  , rb.PlayerStatus
  , rb.IsNonTradingAffiliate
  , rb.AccountStatusName
  , rb.IsLowRiskCustomer
  , rb.Country
  , rb.IsDepositor
  , rb.PEP
  , rb.[Complex/Unusual_TXs]
  , rb.Other_High_Risk_HNWI
  , rb.Other_High_Risk_SARS
  , rb.[Gaming/eGamling]
  , rb.EEA
  , rb.EU_High_Risk_Third
  , rb.FATF
  , rb.UN_Sanctions
  , rb.HMTreasury_UKList
  , rb.EU_Sanctions
  , rb.EU_Tax
  , rb.Deposits
  , rb.CashoutsIncRedeem
  , rb.CashoutExcRedeem
  , rb.ClientMoney
  , rb.Total_Volume
  , rb.Total_Volume_Financial_Instruments
  , rb.NotionalFinancialInstruments
  , rb.ReferenceDateLiability
  , rb.Liabilities_During_Period
  , rb.Deposited_In_Period
  , rb.Withdrew_In_Period
  , rb.UpdateDate
  , rb.MifidCategorization
  , rb.HadMIMOTXOver10KEUR
  , rb.CountBigDeposits
  , rb.CountBigWithdraws
  , rb.BigDepositAmountEuro
  , rb.BigWithdrawAmountEuro
  , rb.UserOwnedCFD
  , rb.HadNonUSDDeposits
  , rb.TotalNonUSDMIMO
  , rb.UserHadCreditLine
  , rb.UserHadRealCryptoLoan
  , rb.EOYEuroDollarRate
  , rb.IsAffiliate
  , rb.ClosingBalance
  , rb.TotalVolumeCFD
  , rb.TotalVolumeCFD_FX
  , rb.TotalVolumeCFD_NonFX
  , rb.CountCFDUsers
  , CASE WHEN da.GCID IS NOT null THEN 'UserIsAffiliate' ELSE 'UserIsNotAffiliate' END AS IsUserAffiliate
  , dcr.Name+','+dcr.Abbreviation AS CountryFormatted
  , dpl.Name AS PlayerLevel
 FROM BI_DB_RBSF rb
JOIN DWH..Fact_SnapshotCustomer fsc
	ON rb.CID = fsc.RealCID
JOIN DWH..Dim_Range dr
	ON fsc.DateRangeID = dr.DateRangeID AND rb.DateID BETWEEN dr.FromDateID AND dr.ToDateID
join DWH..Dim_Customer dc
on rb.CID = dc.RealCID
join DWH..Dim_Country dcr
on fsc.CountryID = dcr.CountryID
left JOIN DWH..Dim_Affiliate da
	ON dc.GCID = da.GCID
JOIN DWH..Dim_PlayerLevel dpl
	ON fsc.PlayerLevelID = dpl.PlayerLevelID