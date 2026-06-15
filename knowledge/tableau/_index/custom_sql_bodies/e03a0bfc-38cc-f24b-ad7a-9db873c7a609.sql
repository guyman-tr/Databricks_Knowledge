select * from BI_DB..BI_DB_AllDeposits where ModificationDateID >=
 CAST(CONVERT(VARCHAR(8), DATEADD(MONTH,-6, getdate()), 112) AS INT)