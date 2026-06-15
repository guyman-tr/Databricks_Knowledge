SELECT 
    Country,
    Date,
	EOMONTH(Date)as EOM,
    TransferCoins,
    TransferCoinFees,
    TransferCoins - LAG(TransferCoins) OVER (PARTITION BY Country ORDER BY Date) AS TransferCoins_Diff,
TransferCoinFees - LAG(TransferCoinFees) OVER (PARTITION BY Country ORDER BY Date) AS TransferCoinsFees_Diff
FROM (
    SELECT 
        bdcbaln.Country,
        bdcbaln.Date, 
        SUM(bdcbaln.TransferCoins) AS TransferCoins,
        SUM(bdcbaln.TransferCoinFees) AS TransferCoinFees
    FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
    WHERE bdcbaln.IsCreditReportValidCB = 1
and bdcbaln.DateID >= 20240101
    GROUP BY bdcbaln.Country,bdcbaln.Date,EOMONTH(Date)
) AS Monthly