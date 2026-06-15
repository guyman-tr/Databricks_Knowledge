SELECT  vad.FirstName, vad.LastName, vad.UserName, vad.Email, vad.GuruStatus, dc.Phone
FROM BI_DB_dbo.V_AUM_Dashboard vad
JOIN DWH_dbo.Dim_Customer dc 
ON dc.RealCID = vad.CID
AND dc.IsValidCustomer = 1