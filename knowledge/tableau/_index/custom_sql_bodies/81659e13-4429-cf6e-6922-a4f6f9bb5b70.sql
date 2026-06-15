SELECT Reg_EOM, KYCFlow, CountryName, COUNT(CID) AS Users
FROM #temp
WHERE Reg_EOM >= '2024-08-01'
GROUP BY KYCFlow, Reg_EOM, CountryName