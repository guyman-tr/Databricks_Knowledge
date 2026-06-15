--- yesterday

SELECT 
	'Yesterday' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID = CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT)
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

--- This Month

UNION all 

-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentMonth' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(month, DATEDIFF(month, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

--- Last Month

UNION all 


SELECT 
	'PreviousMonthSameTime' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(month, DATEDIFF(month, 0, getdate()-1) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(MONTH,-1,getdate()-1)  AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt


UNION all 

--DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentYear' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

UNION all 

SELECT 
	'PreviousYearSameTime' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        sum(Commissions) AS Commissions,
        sum(FullCommissions) AS FullCommissions,
        sum(RollOverFee) AS RollOverFee,
        sum(TicketFee) AS TicketFee,
        sum(TicketFeeByPercent) AS TicketFeeByPercent,
        sum(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT ia.*
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg ia -- select @@DATEFIRST
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) - 1, 0) AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(dateadd(YEAR,-1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

union all 


SELECT 
	'CurrentWeek' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

union all 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'PreviousWeekSameTime' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST(dateadd (WEEK, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, getdate()-1), getdate()-1)) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(dateadd(WEEK, -1,getdate()-1) AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

UNION ALL 



-- DECLARE getdate()-1 DATE = getdate()-1

SELECT 
	'CurrentQuarter' AS [Period],
	InstrumentType,
	IsSettled,
	Region,
	Club,
	[FTD Year],
    Metric,
    Amount
FROM 
(
    SELECT 
		InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year],
        SUM(Commissions) AS Commissions,
        SUM(FullCommissions) AS FullCommissions,
        SUM(RollOverFee) AS RollOverFee,
        SUM(TicketFee) AS TicketFee,
        SUM(TicketFeeByPercent) AS TicketFeeByPercent,
        SUM(AdminFee) AS AdminFee,
        SUM(SpotAdjustFee) AS SpotAdjustFee,
        SUM(ISNULL(VolumeOnOpen,0) + ISNULL(VolumeOnClose,0)) AS Volume,
		sum(Filtered.InvestedAmountOpen) AS InvestedAmountOpen
    FROM 
    (
        SELECT *
        FROM BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
        WHERE 
            IsValidCustomer = 1
            AND DateID BETWEEN CAST(FORMAT(CAST( DATEADD(qq, DATEDIFF(qq, 0, getdate()-1), 0) AS DATE),'yyyyMMdd') as INT)  AND CAST(FORMAT(CAST(getdate()-1 AS DATE),'yyyyMMdd') as INT) 
    ) AS Filtered
    GROUP BY InstrumentType,
		IsSettled,
		Region,
		Club,
		[FTD Year]
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
		Volume,
		Aggregated.InvestedAmountOpen
    )
) AS unpvt

--- Last Month8