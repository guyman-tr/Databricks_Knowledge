SELECT RealCID
	  ,CountryName Country
FROM BI_DB_dbo.BI_DB_KYC_Panel
group by RealCID
	  ,CountryName