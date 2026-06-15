/** Total Clients **/
SELECT CASE WHEN dr.DWHRegulationID IN (4,10) THEN 'ASIC / ASIC & GAML'  
 	        WHEN dr.DWHRegulationID NOT IN (4,10) THEN dr.Name END AS Regulation
      ,COUNT(dc.RealCID) AS 'Total Clients'
FROM DWH.dbo.Dim_Customer dc
JOIN DWH.dbo.Dim_Regulation dr ON dr.DWHRegulationID = dc.RegulationID AND dc.RegulationID NOT IN (0,3,5,6)
WHERE dc.IsValidCustomer =1 AND dc.VerificationLevelID = 3 AND dc.IsDepositor =1
GROUP BY 
CASE WHEN dr.DWHRegulationID IN (4,10) THEN 'ASIC / ASIC & GAML'  
 	        WHEN dr.DWHRegulationID NOT IN (4,10) THEN dr.Name END