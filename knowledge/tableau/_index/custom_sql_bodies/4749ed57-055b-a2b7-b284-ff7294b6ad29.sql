SELECT 
bdcbaln.DateID,
bdcbaln.Date,
bdcbaln.ToRegulation AS 'EOD Regulation',
SUM(bdcbaln.Deposits) AS Deposits,
sum(bdcbaln.CashoutsIncludingRedeem) Cashouts,
sum(bdcbaln.WithdrawableLiability) AS WithdrawableLiability 

FROM BI_DB..BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
WHERE bdcbaln.DateID>=20210101
GROUP BY bdcbaln.DateID,
bdcbaln.Date,
bdcbaln.ToRegulation