SELECT mda.CID
		,mda.IsValidETM
		,mda.IsTestAccount
		,cc.Counrty 
		,mda.ProviderHolderID HID
		,dc1.Name Citizenship
		,dc.FirstName
		,dc.LastName
                ,mdt.TransactionID
		,CASE WHEN mdt.HolderAmount<0 THEN mdt.HolderAmount*(-1) ELSE mdt.HolderAmount END AS HolderAmount
		,CASE WHEN mdt.USDAmountApprox<0 THEN mdt.USDAmountApprox*(-1) ELSE mdt.USDAmountApprox END AS USDAmountApprox
		,mdt.TxType
                ,mdt.TxTypeID
                ,CASE WHEN mdt.TxTypeID=8 THEN mdt.TxLocalCountryNameISO 
				WHEN mdt.TxTypeID=7 THEN dc2.Name 
				ELSE cc.Counrty
				END AS ISOCountry
		,mdt.TxTypeCategory
		,mda.RegAccountSubProgram
		,mdt.TxStatusModificationDate
		,mdt.IsTxSettled
                ,mda.IsValidCustomer
                ,CASE WHEN mdt.HolderAmount=0.01 THEN 'Test transactions' ELSE 'transaction' END AS 'Test/not'
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
JOIN eMoney_dbo.eMoney_Dim_Account mda
ON mda.CID=mdt.CID
JOIN DWH_dbo.Dim_Customer dc
ON mda.GCID = dc.GCID
JOIN DWH_dbo.Dim_Country dc1
ON dc1.CountryID=dc.CitizenshipCountryID
JOIN (SELECT DISTINCT fsc.RealCID, dc.Name Counrty FROM DWH_dbo.Fact_SnapshotCustomer fsc
		JOIN DWH_dbo.V_M2M_Date_DateRange vmmddra
		ON fsc.DateRangeID = vmmddra.DateRangeID
		JOIN eMoney_dbo.eMoney_Dim_Account mda
		ON fsc.GCID = mda.GCID
		AND mda.CurrencyBalanceCreateDate=vmmddra.FullDate
		JOIN DWH_dbo.Dim_Country dc
		ON fsc.CountryID=dc.CountryID) cc
		ON cc.RealCID=mda.CID
LEFT JOIN eMoney_dbo.FiatBankAccount fba
ON mdt.ExternalBankAccountID= fba.Id
LEFT JOIN DWH_dbo.Dim_Country dc2
ON LEFT(fba.Iban,2)=dc2.Abbreviation
WHERE mda.GCID_Unique_Count=1