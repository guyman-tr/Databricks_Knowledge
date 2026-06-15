SELECT
	md.RealCID,
	md.Regulation,
	md.Country,
	md.FullDate,
	md.DateID,
	-- All
	SUM(md.FullCommissions) AS FullCommissions_All,
	SUM(md.Commissions) AS Commissions_All,
	SUM(md.RollOverFee) AS RollOverFee_All,
	-- CFD
	SUM(CASE WHEN md.IsSettled = 0 THEN md.FullCommissions ELSE 0 END) AS FullCommissions_CFD,
	SUM(CASE WHEN md.IsSettled = 0 THEN md.Commissions ELSE 0 END) AS Commissions_CFD,
	SUM(CASE WHEN md.IsSettled = 0 THEN md.RollOverFee ELSE 0 END) AS RollOverFee_CFD,	
	-- CFD crypto
	SUM(CASE WHEN md.IsSettled = 0 AND md.InstrumentType = 'Crypto Currencies' THEN md.FullCommissions ELSE 0 END) AS FullCommissions_CFD_crypto,
	SUM(CASE WHEN md.IsSettled = 0 AND md.InstrumentType = 'Crypto Currencies' THEN md.Commissions ELSE 0 END) AS Commissions_CFD_crypto,
	SUM(CASE WHEN md.IsSettled = 0 AND md.InstrumentType = 'Crypto Currencies' THEN md.RollOverFee ELSE 0 END) AS RollOverFee_CFD_crypto
FROM 
(
SELECT *
FROM BI_DB_dbo.BI_DB_DailyCommisionReport bddcr
WHERE 1=1
	AND bddcr.RegulationID = 13 -- MAS regulation
	AND bddcr.FullDate >= CAST('2025-07-01' AS DATE) -- 1 July 2025 onwards
) md
GROUP BY
	md.RealCID,
	md.Regulation,
	md.Country,
	md.FullDate,
	md.DateID
--ORDER BY md.RealCID, md.FullDate