SELECT bdhsce.*, dr.Name as Reg
FROM BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation bdhsce
join DWH_dbo.Dim_Customer dc on dc.RealCID=bdhsce.CID
JOIN DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID