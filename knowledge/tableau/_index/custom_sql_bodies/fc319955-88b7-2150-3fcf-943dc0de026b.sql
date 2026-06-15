--- yesterday

SELECT 
	'Yesterday' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0)) AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

--- This Month

UNION all 

-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentMonth' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

--- Last Month

UNION all 


SELECT 
	'PreviousMonthSameTime' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(MONTH,-1,getdate()-1)  AS DATE),'yyyyMMdd') as INT) 
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID BETWEEN CAST(FORMAT(CAST( DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(MONTH,-1,getdate()-1)  AS DATE),'yyyyMMdd') as INT)
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

--- same day 8 weeks 


UNION all 

--DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentYear' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
			AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport ia
				WHERE ia.DateID between CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

UNION all 

SELECT 
	'PreviousYearSameTime' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(YEAR,-1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
			AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport ia
				WHERE ia.DateID between CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(YEAR,-1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

union all 


SELECT 
	'CurrentWeek' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID BETWEEN CAST(FORMAT(CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

union all 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'PreviousWeekSameTime' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(dateadd (WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(dateadd(WEEK, -1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID BETWEEN  CAST(FORMAT(CAST(dateadd (WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(dateadd(WEEK, -1,getdate()-1) AS DATE),'yyyyMMdd') as INT)
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

UNION ALL 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentQuarter' AS [Period],
    RealCID,
	UserName,
	Region,
	Manager,
	Regulation,
	Mifid,
    Metric,
    Amount
FROM 
(
    SELECT 
        RealCID,
		Filtered.UserName,
		Filtered.Region,
		Filtered.Manager,
		Filtered.Regulation,
		Filtered.Mifid,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose,
		SUM(ISNULL(FullCommissions,0)) + SUM(ISNULL(RollOverFee,0)) + SUM(ISNULL(TicketFee,0)) + SUM(ISNULL(TicketFeeByPercent,0)) + SUM(ISNULL(AdminFee,0)) + SUM(ISNULL(SpotAdjustFee,0))  AS TotalTradingRevenue
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(qq, DATEDIFF(qq, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND RealCID IN (
                SELECT TOP 20 RealCID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport
                WHERE DateID BETWEEN  CAST(FORMAT(CAST( DATEADD(qq, DATEDIFF(qq, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY RealCID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY RealCID,		
				UserName,
				Region,
				Manager,
				Regulation,
				Mifid
) AS Aggregated
UNPIVOT
(
    Amount FOR Metric IN (
        Commissions,
        FullCommissions,
        RollOverFee,
        TicketFee,
        TicketFeeByPercent,
        AdminFee,
        SpotAdjustFee,
		VolumeOnOpen,
		VolumeOnClose,
		TotalTradingRevenue
    )
) AS unpvt

--- Last Month