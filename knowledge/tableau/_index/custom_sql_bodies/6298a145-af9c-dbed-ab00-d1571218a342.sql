SELECT * FROM BI_DB_SF_M_Users bdsmu
WHERE GETDATE()>= bdsmu.FromDate
AND GETDATE()<=bdsmu.ToDate