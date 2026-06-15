SELECT --a.Date,
--a.Country,
a.AffiliateID,
a.SubAffiliateID,
a.Contact,
SUM(CASE WHEN DATEDIFF(mm,[Date],getdate()) = 0 AND [Date] < GETDATE() THEN FTDs ELSE 0 END) AS [FTDs AffWizz- MTD],
SUM(CASE when  DATEDIFF(mm,[Date],getdate())=1 AND  DAY([Date]) < DAY(GETDATE()) THEN FTDs ELSE 0 END) [FTDs AffWizz-PMTD],
SUM(CASE WHEN DATEDIFF(mm,[Date],getdate()) = 0 AND [Date] < GETDATE() THEN REG else 0 END) AS [Regs AffWizz- MTD],

SUM(CASE when  DATEDIFF(mm,[Date],getdate())=1 AND  DAY([Date]) < DAY(GETDATE()) THEN REG ELSE 0 END) [Regs AffWizz-PMTD]

FROM #DB_RegFTD1 a
--WHERE AffiliateID=121548 

GROUP BY --a.Date,
--a.Country,
a.AffiliateID,
a.SubAffiliateID,
a.Contact