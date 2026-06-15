SELECT
fbr.CID,
fbr.RedeemID,
dc1.Name AS Country,
CASE WHEN dr.Name IN ('eToroUS','FinCEN','FinCEN+FINRA') THEN 'FinCEN' 
	WHEN dr.Name IN ('ASIC','ASIC & GAML') THEN 'ASIC' 
	ELSE dr.Name END AS Regulation, 
CAST(fbr.RequestDate AS DATE) AS RequestDate,
fbr.AmountOnRequest,
fbr.AmountOnClose,
di.Symbol,
drs.Name AS RedeemStatus
FROM DWH_dbo.Fact_BillingRedeem fbr
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID=fbr.CID
LEFT JOIN DWH_dbo.Dim_Country dc1 ON dc1.CountryID=dc.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation dr ON dr.ID=dc.RegulationID
LEFT JOIN DWH_dbo.Dim_Position dp ON dp.PositionID=fbr.PositionID
LEFT JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID=dp.InstrumentID
LEFT JOIN DWH_dbo.Dim_RedeemStatus drs ON drs.RedeemStatusID=fbr.RedeemStatusID
WHERE fbr.RequestDate>=DATEADD(MONTH, -4, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))