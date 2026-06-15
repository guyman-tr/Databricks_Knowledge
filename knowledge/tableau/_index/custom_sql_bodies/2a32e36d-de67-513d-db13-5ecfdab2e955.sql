SELECT *
FROM BI_DB.python.BI_DB_BigQueryGAData bdbqg
WHERE Date>=(GETDATE()-58) AND Date<GETDATE()