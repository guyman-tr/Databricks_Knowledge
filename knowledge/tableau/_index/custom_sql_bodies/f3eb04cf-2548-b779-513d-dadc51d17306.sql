SELECT DISTINCT mp.CID
		,mp.ActiveDate
		,mp.EOM_Club
                ,mp.AccountManager
		,mp.ActiveOpenWOAirdropManual
		,mp.EOM_Balance AvailableBalance
		,bdcd.LastPosOpenDate
		,mp.Country
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp
JOIN [BI_DB_dbo].[External_Fivetran_google_sheets_account_manager_targets_2024] t 
ON t.account_manager = mp.AccountManager
JOIN BI_DB_dbo.BI_DB_CIDFirstDates bdcd
ON mp.CID = bdcd.CID
WHERE  mp.ActiveDate = (SELECT MAX(mp1.ActiveDate) FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mp1)
AND mp.EOM_Club IN ('Diamond','Platinum Plus')