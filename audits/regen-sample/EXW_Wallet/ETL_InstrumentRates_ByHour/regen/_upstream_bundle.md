# Pre-Resolved Upstream Bundle for `EXW_Wallet.ETL_InstrumentRates_ByHour`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.ETL_InstrumentRates_ByHour.sql`

```sql
CREATE TABLE [EXW_Wallet].[ETL_InstrumentRates_ByHour]
(
	[InstrumentID] [int] NULL,
	[AskRateAvg] [numeric](36, 18) NULL,
	[BidRateAvg] [numeric](36, 18) NULL,
	[DateHour] [datetime] NULL,
	[Date] [date] NULL,
	[DateID] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateID] ASC,
		[InstrumentID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `EXW_Wallet.SP_ETL_InstrumentRates_ByHour`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_ETL_InstrumentRates_ByHour.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [EXW_Wallet].[SP_ETL_InstrumentRates_ByHour] @date [DATE] AS 
/********************************************************************************************
	Author:      KatyF	
	Date:        2020-01-27	
	Description: InstrumentRates Daily Aggregation

	**************************
	** Change History
	**************************
	Date        Author			Description 
	2021-01-26	Daniel			Create a ETL_InstrumentRates_Daily_Last_Value table to calculate a last daily rates			

	2023-05-02  Inessa Converted to Synapse
	exec EXW_Wallet.[SP_ETL_InstrumentRates_ByHour] '2026-04-10';
	2026-04-13 Inessa Updated Group by case to suit the condition as it was cousing dupses in rare cases
	( when we have entry suit also for prev date and for current date)

	----------    ----------   ------------------------------------*/

BEGIN

--DECLARE @date DATE = '2026-04-10'
DECLARE @prevdate  DATE = DATEADD(dd, -1, @date)  
DECLARE @dateid AS INTEGER = CAST(CONVERT(VARCHAR(8),@date, 112) AS INT)
DECLARE @prevdateid AS INTEGER = CAST(CONVERT(VARCHAR(8),@prevdate, 112) AS INT)

DELETE FROM EXW_Wallet.ETL_InstrumentRates_ByHour
WHERE [DateID]  >= @prevdateid

INSERT INTO EXW_Wallet.ETL_InstrumentRates_ByHour
   ([InstrumentID]
	,[AskRateAvg] 
	,[BidRateAvg]
	,[DateHour]
	,[Date] 
	,[DateID]
	,UpdateDate
	)

SELECT [InstrumentId] 
	,AVG(AskRate) AS AskRateAvg
	,AVG(BidRate) AS BidRateAvg
	,CASE WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(D,1,@prevdate) 
				THEN DATEADD(HOUR, DATEPART(HOUR,DateFrom),CAST(CONVERT(VARCHAR(20),DateFrom,112) AS DATETIME))
			ELSE  @prevdate
			END AS DateHour
	,CASE WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(D,1,@prevdate)  
			THEN CAST(DateFrom AS DATE)
			ELSE CAST(@prevdate AS DATE) 
			END AS [Date]
	,CASE WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(D,1,@prevdate)  
		THEN CONVERT(VARCHAR(8),CAST(DateFrom AS DATE), 112) 
		ELSE CONVERT(VARCHAR(8),CAST(@prevdate AS DATE), 112) 
		END AS DateID
	,GETDATE() AS UpdateDate
FROM [EXW_Currency].[vInstrumentRatesForWeek]
WHERE NOT (CAST(DateFrom AS DATE) = DATEADD(D,-1,@prevdate) AND CAST(DateTo AS DATE) = @prevdate)    
	AND DateFrom < DATEADD(D,1,@prevdate) AND DateTo > @prevdate

GROUP BY
    [InstrumentId],
    CASE
        WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @prevdate)
        THEN DATEADD(HOUR, DATEPART(HOUR, DateFrom), CAST(CONVERT(VARCHAR(20), DateFrom, 112) AS DATETIME))
        ELSE @prevdate
    END,
    CASE
        WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @prevdate)
        THEN CAST(DateFrom AS DATE)
        ELSE CAST(@prevdate AS DATE)
    END,
    CASE
        WHEN CAST(DateFrom AS DATE) >= @prevdate AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @prevdate)
        THEN CONVERT(VARCHAR(8), CAST(DateFrom AS DATE), 112)
        ELSE CONVERT(VARCHAR(8), CAST(@prevdate AS DATE), 112)
    END;



INSERT INTO EXW_Wallet.ETL_InstrumentRates_ByHour
   ([InstrumentID]
	,[AskRateAvg] 
	,[BidRateAvg]
	,[DateHour]
	,[Date] 
	,[DateID]
	,UpdateDate
	)

SELECT [InstrumentId] 
	,AVG(AskRate) AS AskRateAvg
	,AVG(BidRate) AS BidRateAvg
	,CASE WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(D,1,@date) 
				THEN DATEADD(HOUR, DATEPART(HOUR,DateFrom),CAST(CONVERT(VARCHAR(20),DateFrom,112) AS DATETIME))
			ELSE  @date
			END AS DateHour
	,CASE WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(D,1,@date)  
			THEN CAST(DateFrom AS DATE)
			ELSE CAST(@date AS DATE) 
			END AS [Date]
	,CASE WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(D,1,@date)  
		THEN CONVERT(VARCHAR(8),CAST(DateFrom AS DATE), 112) 
		ELSE CONVERT(VARCHAR(8),CAST(@date AS DATE), 112) 
		END AS DateID
	,GETDATE() AS UpdateDate
FROM [EXW_Currency].[vInstrumentRatesForWeek]
WHERE NOT (CAST(DateFrom AS DATE) = DATEADD(D,-1,@date) AND CAST(DateTo AS DATE) = @date)    
	AND DateFrom < DATEADD(D,1,@date) AND DateTo > @date

/*GROUP BY InstrumentId
		,CAST(DateFrom AS DATE) 
		,DATEADD(HOUR, DATEPART(HOUR,DateFrom),CAST(CONVERT(VARCHAR(20),DateFrom,112) AS DATETIME))
		
*/
GROUP BY
    [InstrumentId],
    CASE
        WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @date)
        THEN DATEADD(HOUR, DATEPART(HOUR, DateFrom), CAST(CONVERT(VARCHAR(20), DateFrom, 112) AS DATETIME))
        ELSE @date
    END,
    CASE
        WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @date)
        THEN CAST(DateFrom AS DATE)
        ELSE CAST(@date AS DATE)
    END,
    CASE
        WHEN CAST(DateFrom AS DATE) >= @date AND CAST(DateFrom AS DATE) < DATEADD(DAY, 1, @date)
        THEN CONVERT(VARCHAR(8), CAST(DateFrom AS DATE), 112)
        ELSE CONVERT(VARCHAR(8), CAST(@date AS DATE), 112)
    END;

END


 --SELECT * INTO #ETL_InstrumentRates_ByHour 
 --FROM EXW_Wallet.ETL_InstrumentRates_ByHour WHERE DateID >20260408
  
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `EXW_Wallet.SP_ETL_InstrumentRates_ByHour` | synapse_sp | EXW_Wallet | SP_ETL_InstrumentRates_ByHour | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_ETL_InstrumentRates_ByHour.sql` |
