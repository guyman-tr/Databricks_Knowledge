SELECT 
DISTINCT 
edu.GCID
, edu.RealCID
,CASE
		WHEN edu.IsTestAccount =1 THEN 'TestUser'
		WHEN edu.IsValidCustomer =0 THEN 'eTorian'
		ELSE 'RealUser'
	END IsRealUser
	, efb.CryptoName

	--, efb.Balance
	, efb.BalanceUSD 'Calculated USD'
	 , CASE WHEN bkg.WalletId IS NULL THEN efb.BalanceUSD ELSE ef.BalanceUSD END 'Balance USD' 
	, G.closing_country_group
	, CASE WHEN f.CID IS NOT NULL THEN 'Y' ELSE 'N' END 'Is Exception CID'
	, edu.CountryID
	, edu.Country
	, dc.RiskGroupID
	, dc.IsHighRiskCountry
	, CASE WHEN eft.GCID IS NOT NULL THEN 'Y' ELSE 'N' END 'Has Redeems'
	, CASE WHEN ewec.CountryID IS NOT NULL THEN  'Y' ELSE 'N' END 'Open for Wallet'
--, CASE WHEN edu.CountryID IS NOT NULL THEN 'Y' ELSE 'N' END 'Country with open Wallets'
FROM EXW.dbo.EXW_DimUser edu 
LEFT JOIN EXW.dbo.EXW_UserCalculatedBalance  efb  ON efb.GCID = edu.GCID AND  efb.BalanceDateId =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
LEFT JOIN dbo.BalanceKnownGaps bkg ON efb.WalletId = bkg.WalletId AND efb.CryptoId = bkg.CryptoId
LEFT JOIN EXW.dbo.EXW_FactBalance ef
ON efb.CryptoId = ef.CryptoId AND efb.WalletId = ef.WalletID AND efb.GCID = ef.GCID AND ef.FullDateID =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
JOIN [ThirdParty_Fivetran].[Fivetran].[gsheets].[exw_countries_lists_for_tableau_include_closing_country]  G ON edu.CountryID = G.closing_country_id  
LEFT JOIN  EXW.dbo.EXW_FactTransactions eft ON edu.GCID = eft.GCID AND eft.IsRedeem =1 
LEFT JOIN EXW.dbo.EXW_WalletElligibleCountries ewec ON edu.CountryID = ewec.CountryID AND ewec.CountryOpenforWallet =1 
LEFT JOIN (SELECT  closing_country_cidexception AS CID FROM  [ThirdParty_Fivetran].[Fivetran].[gsheets].[exw_countries_lists_for_tableau_include_closing_country]  ) f 
ON edu.RealCID = f.CID
JOIN DWH.dbo.Dim_Country dc ON edu.CountryID = dc.CountryID