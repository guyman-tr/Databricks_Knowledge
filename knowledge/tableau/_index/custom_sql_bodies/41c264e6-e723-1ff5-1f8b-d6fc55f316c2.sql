SELECT
    Date,
    SUM(IsFunded) AS TotalFundedUsers,
    SUM(IsFirstTimeFunded) AS FirstTimeFunded,
    SUM(Funded_FirstFunded) AS Funded_FirstFunded,
    SUM(IsWinback) AS Winback,
    SUM(IsChurned) AS Churned,
    SUM(FirstTimeFunded) + SUM(IsWinback) - SUM(IsChurned) AS Net
FROM (
    SELECT
        s.Date,
        s.DateID,
        s.RealCID,
        s.IsFunded,
        s.FirstTimeFunded,
        s.Global_FTD_Date,
        s.FirstFundedDateID,
        LAG(s.IsFunded, 1, 0) OVER (PARTITION BY s.RealCID ORDER BY s.DateID) AS WasFundedYesterday,
        CASE 
            WHEN s.FirstTimeFunded = 1 
                 AND CONVERT(INT, CONVERT(vARCHAR(8), s.Global_FTD_Date, 112)) = s.FirstFundedDateID 
            THEN 1 ELSE 0 
        END AS Funded_FirstFunded,
        CASE WHEN s.FirstTimeFunded = 1 THEN 1 ELSE 0 END AS IsFirstTimeFunded,
        CASE 
            WHEN s.IsFunded = 1 
                 AND LAG(s.IsFunded, 1, 0) OVER (PARTITION BY s.RealCID ORDER BY s.DateID) = 0
                 AND s.FirstTimeFunded = 0
            THEN 1 ELSE 0 
        END AS IsWinback,
        CASE 
            WHEN s.IsFunded = 0 
                 AND LAG(s.IsFunded, 1, 0) OVER (PARTITION BY s.RealCID ORDER BY s.DateID) = 1 
            THEN 1 ELSE 0 
        END AS IsChurned
    FROM (
        SELECT
            Date,
            DateID,
            RealCID,
            IsFunded,
            FirstTimeFunded,
            Global_FTD_Date,
            FirstFundedDateID
        FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status
        WHERE DateID >= CONVERT(INT, CONVERT(VARCHAR(8), DATEADD(MONTH, -2, GETDATE()), 112))
          AND IsValidCustomer = 1
    ) AS s
) AS daily_movement_flags
GROUP BY
    Date,
    DateID