SELECT bdcd.CID,
cast(bdcd.registered AS DATE) AS RegistrationDate,
SUM(bdad.[Amount in $]) AS 'Total$DepositsLifetime'

FROM [BI_DB_dbo].BI_DB_CIDFirstDates bdcd
JOIN [BI_DB_dbo].BI_DB_AllDeposits bdad ON bdcd.CID = bdad.CID
WHERE bdcd.RegulationID IN (6,7,8)--US Regulation
AND bdad.PaymentStatus IN ('Approved')

GROUP BY bdcd.CID, bdcd.registered