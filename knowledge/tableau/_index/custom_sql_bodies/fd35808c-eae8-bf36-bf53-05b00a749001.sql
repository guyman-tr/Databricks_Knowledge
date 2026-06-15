SELECT b.* ,  dc.FirstName, dc.LastName, dc.Email, dc.Address, dc.BuildingNumber, dc.Zip
FROM BI_DB..BI_DB_USA_FinanceReport_forTax b
JOIN DWH..Dim_Customer dc ON b.RealCID = dc.RealCID AND dc.IsValidCustomer=1