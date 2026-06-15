SELECT	bdad.DepositID,
		bdad.CID,
		CAST(bdad.[Deposit Time] AS DATE) [DepositDate],
		CAST(bdad.ModificationDate AS DATE) [ModificationDate],
		bdad.FundingType,
		bdad.Funnel,
		bdad.[Amount in $] [AmountDeposited_USD],
		bdad.[Amount In Orig Curr] [AmountDeposited_OG_Curcy],
		bdad.Currency,
		bdad.PaymentStatus,
		bdad.[Country (customer)] [CountryOFClient],
		dc.MarketingRegionManualName [RegionOfClient],
		bdad.[Country By Reg IP],
		bdad.BINCountry,
		bdad.[Bank name by Bincode],
		bdad.Provider,
		bdad.CardType,
		bdad.CardSubType,
		bdad.RiskStatus,
		bdad.[Deposit Risk Status],
		bdad.IsFTD,
		clb.EOD_Club,
		bdad.Regulation,
		bdad.DesignatedRegulation
FROM BI_DB..BI_DB_AllDeposits bdad
JOIN DWH..Dim_Country dc ON bdad.[Country (customer)] = dc.Name
JOIN (SELECT bdcdpfd.CID, CAST(bdcdpfd.ActiveDate AS DATE) [DateActive], bdcdpfd.EOD_Club FROM BI_DB..BI_DB_CID_DailyPanel_FullData bdcdpfd WHERE bdcdpfd.Active_Month >= 202301) clb ON bdad.CID = clb.CID AND CAST(bdad.ModificationDate AS DATE) = clb.DateActive
WHERE CAST(bdad.[Deposit Time] AS DATE) >= CAST('2023-01-01' AS DATE)