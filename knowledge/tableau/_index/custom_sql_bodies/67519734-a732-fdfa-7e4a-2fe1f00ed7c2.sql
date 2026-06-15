SELECT 
DISTINCT 
dc1.GCID
, dc1.RealCID
	, efb.CryptoName 'Crypto Name'
	, CASE WHEN bkg.WalletId IS NULL THEN cb.Balance  ELSE efb.Balance  END 'Balance' 
	, CASE WHEN bkg.WalletId IS NULL THEN cb.BalanceUSD ELSE efb.BalanceUSD END 'BalanceUSD' 
	, CASE WHEN f.CID IS NOT NULL THEN 'Y' ELSE 'N' END 'Is Exception CID'
	, dc1.CountryID
	,dc.Name AS Country
	, dc.RiskGroupID 'Risk Group ID'
	, dc.IsHighRiskCountry 'Is High Risk Country'
	, dpl.Name AS Club
	, CASE WHEN eft.GCID IS NOT NULL THEN 'Y' ELSE 'N' END 'Has Redeems'
	, CASE WHEN efb.GCID IS NOT NULL THEN 'Y' ELSE 'N' END 'Has Wallet'
	, CASE WHEN ewec.CountryID IS NOT NULL THEN  'Y' ELSE 'N' END 'Open for Wallet'
--, CASE WHEN edu.CountryID IS NOT NULL THEN 'Y' ELSE 'N' END 'Country with open Wallets'
FROM DWH.dbo.Dim_Customer dc1 
LEFT JOIN EXW.dbo.EXW_FactBalance efb  ON efb.RealCID = dc1.RealCID AND  efb.FullDateID =CAST(CONVERT(VARCHAR(8), getdate()-1, 112) AS INT)
LEFT JOIN EXW.dbo.EXW_UserCalculatedBalance  cb  ON cb.RealCID = dc1.RealCID AND  cb.BalanceDateId =efb.FullDateID  
LEFT JOIN dbo.BalanceKnownGaps bkg ON cb.WalletId = bkg.WalletId AND cb.CryptoId = bkg.CryptoId
LEFT JOIN  EXW.dbo.EXW_FactTransactions eft ON dc1.GCID = eft.GCID AND eft.IsRedeem =1 
LEFT JOIN EXW.dbo.EXW_WalletElligibleCountries ewec ON dc1.CountryID = ewec.CountryID AND ewec.CountryOpenforWallet =1 
JOIN (SELECT  closing_country_cidexception AS CID FROM  [ThirdParty_Fivetran].[Fivetran].[gsheets].[exw_countries_lists_for_tableau_include_closing_country]  ) f 
ON dc1.RealCID = f.CID
JOIN DWH.dbo.Dim_Country dc ON dc1.CountryID = dc.CountryID  
JOIN DWH.dbo.Dim_PlayerLevel dpl ON dc1.PlayerLevelID = dpl.PlayerLevelID