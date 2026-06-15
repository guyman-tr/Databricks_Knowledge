SELECT
    Table_Name,
    DateID,
    SumDiff,
	ProcedureName,
    CASE
        WHEN RunningTotal <> 0 THEN 0
        ELSE 1
    END AS StreakOK
FROM (
    SELECT
        Table_Name,
        DateID,
        SumDiff,
		ProcedureName,
        SUM(SumDiff) OVER (ORDER BY Table_Name, DateID ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS RunningTotal
    FROM
        #all
) AS a
WHERE a.DateID = CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)
AND a.DateID < CAST(CONVERT(VARCHAR(8), getdate(), 112) AS INT)