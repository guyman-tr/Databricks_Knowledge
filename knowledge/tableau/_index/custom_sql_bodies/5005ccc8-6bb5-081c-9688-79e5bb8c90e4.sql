SELECT b.* ,  dc.FirstName, dc.LastName, dc.Email
FROM BI_DB..BI_DB_USA_FinanceReport_forTax_CreditID b
JOIN DWH..Dim_Customer dc ON b.CID = dc.RealCID AND dc.IsValidCustomer=1