SELECT
    dc.RealCID,
    dc.GCID,
    dc.AffiliateID,
    da.Contact AS Affiliate_Contact,
    da.ContractName AS Affiliate_ContractName,
    aty.Name AS AccountType,
    pl.Name AS ClubLevel,
    dc.FunnelID,
    dc.FunnelFromID,
    CASE
        WHEN dc.FunnelFromID = 65 THEN 'From SMSF Funnel'
        WHEN aty.Name IN ('SMSF') THEN aty.Name
    END AS [SMSF/FromSMSFfunnel],
    dc.RegisteredReal AS RegDate,
    CASE WHEN dc.FirstDepositDate > dc.RegisteredReal THEN dc.FirstDepositDate ELSE NULL END [FTD_Date],
    fd.FirstDepositAmount,
    dc.VerificationLevelID,
	bdcmpfd.V2_Complete,
	bdcmpfd.V3_Complete,
    dm.FirstName + ' ' + dm.LastName AS AccountManager,
    dr.Name AS Regulation,
    DATEDIFF(YEAR, dc.BirthDate, GETDATE()) AS Age,
    DESK.CFDesk AS Desk,
	fd.RealizedEquity,
	bdcmpfd.ACC_TotalDeposits,
	bdcmpfd.ACC_TotalCashouts,
	bdcmpfd.ACC_NetDeposits,
	bdcmpfd.ACC_Revenue_Total,
	bdcmpfd.ACC_PnL_Total,
        bdcmpfd.UpdateDate
FROM
    DWH_dbo.Dim_Customer dc
LEFT JOIN
    DWH_dbo.Dim_AccountType aty ON aty.AccountTypeID = dc.AccountTypeID
LEFT JOIN
    DWH_dbo.Dim_Regulation dr ON dr.ID = dc.RegulationID
LEFT JOIN
    [BI_DB_dbo].[BI_DB_CIDFirstDates] fd ON fd.CID = dc.RealCID
LEFT JOIN
    DWH_dbo.Dim_Manager dm ON dm.ManagerID = dc.AccountManagerID
LEFT JOIN
    DWH_dbo.Dim_PlayerLevel pl ON pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN
    DWH_dbo.Dim_Desk DESK ON DESK.CountryID = dc.CountryID AND DESK.LanguageID = dc.LanguageID
LEFT JOIN
     DWH_dbo.Dim_Affiliate da ON dc.AffiliateID = da.AffiliateID
LEFT JOIN
	(SELECT *, ROW_NUMBER() OVER (PARTITION BY mpf.CID ORDER BY mpf.Active_Month DESC) rn FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData mpf) bdcmpfd ON dc.RealCID = bdcmpfd.CID AND bdcmpfd.rn = 1
WHERE
    dc.AccountTypeID = 14 -- SMSF
    OR dc.FunnelFromID = 65