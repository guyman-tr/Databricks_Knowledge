SELECT bdcgp.InvestorCID, bdcgp.isOpen
FROM BI_DB_dbo.BI_DB_CapitalGuarantee_Panel bdcgp
WHERE bdcgp.isOpen = 1 
AND bdcgp.ParentUserName = 'AI-Edge'
AND bdcgp.Date >= GETDATE()-2