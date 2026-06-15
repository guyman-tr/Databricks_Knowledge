SELECT mprd.*,mpfd.FMI_Date
FROM eMoney_DEV.dbo.eMoney_Panel_Retention_Monthly  mprd
LEFT JOIN eMoney.dbo.eMoney_Panel_FirstDates mpfd ON mprd.GCID = mpfd.GCID
WHERE mpfd.FMI_Date>='20220101'