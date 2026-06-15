--- yesterday

SELECT 
	'Yesterday' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

--- This Month

UNION all 

-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentMonth' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

--- Last Month

UNION all 


SELECT 
	'PreviousMonthSameTime' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(MONTH,-1,getdate()-1)  AS DATE),'yyyyMMdd') as INT) 
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID BETWEEN CAST(FORMAT(CAST( DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(MONTH,-1,getdate()-1)  AS DATE),'yyyyMMdd') as INT)
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

--- same day 8 weeks 

UNION all 

--DECLARE getdate()-1 DATE = getdate()-1

--SELECT DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0)

SELECT a.[Period]
	 , a.Instrument
	 , a.Metric
	 , avg(a.Amount) AS Amount
FROM 
(
SELECT 
	'SameDay8Weeks' AS [Period],
    Instrument,
	DateID,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
		DateID,
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia -- select @@DATEFIRST -- select CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT)
        WHERE 
            IsValidCustomer = 1
				AND ((DATEPART(WEEKDAY, ia.FullDate) + @@DATEFIRST - 1) % 7) + 1 = ((DATEPART(WEEKDAY, GETDATE() - 1) + @@DATEFIRST - 1) % 7) + 1
				AND DATEDIFF(WEEK, ia.FullDate, GETDATE() - 1) <= 8
				AND DATEDIFF(WEEK, ia.FullDate, GETDATE() - 1) > 0			AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia
				WHERE ((DATEPART(WEEKDAY, ia.FullDate) + @@DATEFIRST - 1) % 7) + 1 = ((DATEPART(WEEKDAY, getdate()-1) + @@DATEFIRST - 1) % 7) + 1 AND DATEDIFF (WEEK, ia.FullDate, getdate()-1) <= 8 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument, Filtered.DateID
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
		VolumeOnClose
    )
) AS unpvt
) a
GROUP BY a.Period, a.Instrument, a.Metric

UNION all 

--DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentYear' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
		DateID,
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
			AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia
				WHERE ia.DateID between CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument, Filtered.DateID
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
		VolumeOnClose
    )
) AS unpvt

UNION all 

SELECT 
	'PreviousYearSameTime' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
		DateID,
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(YEAR,-1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
			AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia
				WHERE ia.DateID between CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(YEAR,-1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument, Filtered.DateID
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
		VolumeOnClose
    )
) AS unpvt

union all 


SELECT 
	'CurrentWeek' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID BETWEEN CAST(FORMAT(CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

union all 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'PreviousWeekSameTime' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(dateadd (WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(dateadd(WEEK, -1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID BETWEEN  CAST(FORMAT(CAST(dateadd (WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(dateadd(WEEK, -1,getdate()-1) AS DATE),'yyyyMMdd') as INT)
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

UNION ALL 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentQuarter' AS [Period],
    Instrument,
    Metric,
    Amount
FROM 
(
    SELECT 
        Instrument,
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(VolumeOnOpen) AS VolumeOnOpen,
        SUM(VolumeOnClose) AS VolumeOnClose
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(qq, DATEDIFF(qq, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
            AND InstrumentID IN (
                SELECT TOP 20 InstrumentID
                FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
                WHERE DateID BETWEEN  CAST(FORMAT(CAST( DATEADD(qq, DATEDIFF(qq, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
                GROUP BY InstrumentID
                ORDER BY SUM(ISNULL(FullCommissions,0) + ISNULL(RollOverFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0) + ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0)) DESC
            )
    ) AS Filtered
    GROUP BY Instrument
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
		VolumeOnClose
    )
) AS unpvt

--- Last Month