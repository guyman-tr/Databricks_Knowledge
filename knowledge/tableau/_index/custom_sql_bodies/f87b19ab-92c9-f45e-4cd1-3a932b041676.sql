SELECT bdcmpfd.Country,eomonth(bdcmpfd.ActiveDate) 'Month',sum(bdcmpfd.Revenue_Total)'Revenue_Total'
FROM BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData bdcmpfd
JOIN DWH_dbo.Dim_Customer dc ON bdcmpfd.CID=dc.RealCID
WHERE dc.DesignatedRegulationID=2
AND dc.IsValidCustomer=1
AND bdcmpfd.ActiveDate BETWEEN <[Parameters].[Parameter 2]> AND <[Parameters].[Parameter 3]>
group by bdcmpfd.Country,eomonth(bdcmpfd.ActiveDate)