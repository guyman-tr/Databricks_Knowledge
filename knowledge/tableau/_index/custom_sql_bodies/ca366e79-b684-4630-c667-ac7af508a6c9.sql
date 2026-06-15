SELECT	dp.*,
		bdcd.Region,
		bdcd.Country,
		bdcd.Verified
FROM DWH..Dim_Position dp
LEFT JOIN BI_DB..BI_DB_CIDFirstDates bdcd ON dp.CID = bdcd.CID
WHERE dp.OpenOccurred >= CONVERT(DATE, '2021-01-01')