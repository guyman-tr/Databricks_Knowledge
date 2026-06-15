SELECT fd.Manager, bdrik.Invitee, bdrik.Country InviteeCountry ,bdrik.Inviter, bdrik.registered, bdrik.FirstDepositDate, bdrik.TotalDepositAmount, bdrik.TotalCashoutAmount
,bdrik.TotalDepositAmount - bdrik.TotalCashoutAmount AS NetDeposits, dc.FirstDepositAmount, bdrik.RevenueFromUser, bdrik.NoOfTotalDeposits
,bdrik.NoOfTotalCashout, bdrik.LastCashoutDate, bdrik.FirstPosOpenDate, bdrik.TradesAmount, ffa.FirstAction, ffa.FirstInstrument
FROM [BI_DB_dbo].BI_DB_RAF_Invitees_KPIs bdrik
JOIN [BI_DB_dbo].[BI_DB_CIDFirstDates] fd ON fd.CID = bdrik.Inviter
LEFT JOIN [BI_DB_dbo].[BI_DB_First5Actions] ffa ON ffa.CID = bdrik.Invitee
LEFT JOIN [DWH_dbo].[Dim_Customer] dc ON bdrik.Invitee = dc.RealCID


WHERE bdrik.registered >= '20220101' AND bdrik.Country IN ('United Kingdom', 'Ireland')