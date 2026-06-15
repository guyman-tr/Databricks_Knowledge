select
w.CID,
dc.GCID,
w.ModificationDate as [Status Modification Time],
w.RequestDate as [Request Time],
cs.Name as [Withdraw Status],
w.PayeeNameAsString,
w.CustomerNameAsString,
w.ClientBankNameAsString,
w.IBANCodeAsString,
w.SwiftCodeAsString,
country1.Name as Country,
w.SortCodeAsString,
w.RoutingNumberAsString,
w.BSBNumberAsString,
w.ClientAddressAsString,
w.ExchangeRate,
--w.AccountIDAsString,
--w.AccountIDAsDecimal,
--w.AccountTypeAsString,
--w.MaskedAccountIDAsString as Last4DigitsOfAcccount,
--w.ACHBankAccountIDAsInteger, 
--w.BankDetailsAccountIDAsString,
--w.BankAddressAsString,
--w.BankNameAsString,
--w.BankName,
--w.BankAccountAsString,
--w.CityAsString,
--w.EmailAsString,
--w.PayerIDAsString,
--w.PurseAsString,
--w.PayerPurseAsString,
--w.SortCodeAsString,
--'Preparation Status' as [Preparation Status],
w.Approved,
--'3rd Party'  as [3rd Party],
w.Amount_Withdraw as [Net Cashout Amount],
 CAST(w.Amount_Withdraw + ISNULL(w.Fee, 0) AS DECIMAL(16, 2)) AS [Orig. Cashout Amount],
 w.Fee as [Cashout Fee],
 ft.Name as [Funding Method (Request Only)],
 w.WithdrawID,
 country.Name as [Country by Reg IP],
 ps.Name as [Customer Status],
 pl.Name as [Customer Level],
 cm.CashoutModeName AS [Preparation Type],
 --'Prepared By' as [Prepared By],
 currency.Abbreviation as Currency,
 cr.Name as [Back Office Withdraw Reason],
 --'Intermediary Bank Details' as [Intermediary Bank Details],
 --'Additional Information Details' as [Additional Information Details],
 --'Report Non Valid MOP' AS [Report Non Valid MOP],
 --'Proof Of MOP' AS [Proof Of MOP],
 w.Comment as [Internal Comment],
 --'Third Party Comment' as [Third Party Comment],
 dr.Name as Regulation,
 w.FundingTypeID_Withdraw  AS [Funding Type ID (Request Only)],
 w.FundingID,
 currency1.Abbreviation as [AMOP Currency],
ft1.Name as [FundingType (Sent)]


from DWH_dbo.Fact_BillingWithdraw w 
join DWH_dbo.Dim_CashoutStatus cs on cs.[CashoutStatusID]=w.CashoutStatusID_Withdraw
left join DWH_dbo.Dim_FundingType ft on ft.FundingTypeID=w.FundingTypeID_Withdraw
left join DWH_dbo.Dim_FundingType ft1 on ft1.FundingTypeID=w.FundingTypeID_Funding
join DWH_dbo.Dim_Customer dc on dc.RealCID=w.CID
LEFT JOIN DWH_dbo.Dim_Country country on country.CountryID=dc.CountryIDByIP
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=dc.PlayerStatusID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=dc.PlayerLevelID
left join DWH_dbo.Dim_CashoutMode cm on cm.CashoutModeID=w.CashoutModeID
left join DWH_dbo.Dim_Currency currency on currency.CurrencyID=w.CurrencyID
left join DWH_dbo.Dim_CashoutReason cr on cr.CashoutReasonID=w.CashoutReasonID
left join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
left join DWH_dbo.Dim_Currency currency1 on currency1.CurrencyID=w.AccountCurrencyID
left join DWH_dbo.Dim_Country country1 on country1.CountryID=w.CountryIDAsInteger
where w.ModificationDate>=dateadd(month,DATEDIFF(MONTH,0,getdate())-6,0) and 
w.CashoutStatusID_Withdraw=3