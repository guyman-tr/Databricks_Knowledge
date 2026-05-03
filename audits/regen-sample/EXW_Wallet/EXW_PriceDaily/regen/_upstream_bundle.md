# Pre-Resolved Upstream Bundle for `EXW_Wallet.EXW_PriceDaily`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.EXW_PriceDaily.sql`

```sql
CREATE TABLE [EXW_Wallet].[EXW_PriceDaily]
(
	[InstrumentID] [int] NULL,
	[eToroInstrumentID] [int] NULL,
	[CryptoID] [int] NULL,
	[CryptoName] [varchar](50) NULL,
	[AvgPrice] [decimal](38, 8) NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [varchar](50) NULL,
	[FullDate] [date] NULL,
	[FullDateID] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CryptoID] ),
	CLUSTERED INDEX
	(
		[FullDateID] ASC,
		[CryptoID] ASC
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


### SP `EXW_Wallet.SP_Prices`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_Prices.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [EXW_Wallet].[SP_Prices] @dt [DATE] AS

BEGIN
/***************map wallet instrument to etoro instrument and cryptoid***************************/
--SELECT MAX(FullDate) FROM EXW_Wallet.EXW_PriceDaily  2023-11-30


--DECLARE @dt DATE = '20231130'
IF OBJECT_ID('tempdb..#mapping') IS NOT NULL    DROP TABLE #mapping
CREATE TABLE #mapping
(
             InstrumentID   INT NULL
			,eToroInstrumentID  INT NULL
			,CryptoId  INT NULL
			,CryptoName   NVARCHAR(128) Null
			,BlockchainCryptoId  INT NULL
			,BlockchainCryptoName   NVARCHAR(128) Null
)

INSERT INTO #mapping
 
SELECT DISTINCT 
             i.Id AS InstrumentID
			,dct.InstrumentId AS eToroInstrumentID
			,cmrm.CryptoId
			,cmrm.MarketRatesCurrencySymbol AS CryptoName
			,dct.BlockchainCryptoId
			,ct1.Name AS BlockchainCryptoName
FROM  [EXW_Currency].[Instruments]  i 
    JOIN [EXW_Currency].[Currencies]  cb ON cb.Id = i.BuyCurrencyId
    JOIN [EXW_Currency].[Currencies]  cs ON cs.Id = i.SellCurrencyId
LEFT JOIN 
	(
	SELECT DISTINCT Id, CryptoId, MarketRatesCurrencySymbol FROM 
	[EXW_Wallet].[CryptoMarketRatesMappings] WITH (NOLOCK)
	) cmrm
	ON cb.Symbol = cmrm.MarketRatesCurrencySymbol
LEFT JOIN [EXW_Wallet].[CryptoTypes] dct WITH (NOLOCK)
	ON cmrm.CryptoId = dct.CryptoID
LEFT JOIN  [EXW_Wallet].[CryptoTypes] ct1  
		ON dct.BlockchainCryptoId = ct1.CryptoID
WHERE 1=1
AND cmrm.CryptoId IS NOT NULL
AND cs.Symbol = 'USD'

--select * from #mapping   order by 1

IF OBJECT_ID('tempdb..#rates') IS NOT NULL  DROP TABLE #rates
CREATE TABLE #rates(
	[InstrumentID] [int] NULL,
	[eToroInstrumentID] [int] NULL,
	[CryptoId] [int] NULL,
	[CryptoName] [varchar](20) NULL,
	[AskLast] [numeric](36, 18) NULL,
	[LastBid] [numeric](36, 18) NULL,
	[AvgPrice] [numeric](38, 19) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[BlockchainCryptoId] [int] NULL,
	[BlockchainCryptoName] [nvarchar](500) NULL,
	[FullDate] [date] NULL,
	[FullDateID] [int] NULL);

INSERT INTO #rates
SELECT irh.InstrumentID
			 ,m.eToroInstrumentID
			,m.CryptoId
			,m.CryptoName
			,irh.AskRateAvg AS AskLast
			,irh.BidRateAvg AS LastBid
			,(irh.BidRateAvg + irh.AskRateAvg) / 2 AS AvgPrice
			,irh.DateHour AS DateFrom
			,DATEADD(HOUR, 1, irh.DateHour) AS DateTo
			,m.BlockchainCryptoId
			,m.BlockchainCryptoName
			,CAST(irh.DateHour AS DATE) AS FullDate
			,CONVERT(VARCHAR(8),irh.DateHour,112) AS FullDateID
FROM EXW_Wallet.ETL_InstrumentRates_ByHour  irh WITH (NOLOCK)
JOIN #mapping m ON irh.InstrumentID = m.InstrumentID
WHERE 1=1
AND DateHour >= @dt AND DateHour < DATEADD(D,1,@dt)

IF OBJECT_ID ('tempdb..#price') IS NOT NULL DROP TABLE #price
CREATE TABLE #price WITH(HEAP, DISTRIBUTION = HASH(CryptoId))
AS

SELECT CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID
									ELSE CryptoId
									END AS InstrumentID
	,CASE WHEN eToroInstrumentID >= 100000 THEN eToroInstrumentID
									ELSE CryptoId
									END AS ETL_InstrumentID
	,eToroInstrumentID
	,CryptoId
	,CryptoName
	,AskLast
	,LastBid
	,AvgPrice
	,DateFrom
	,DateTo
	,BlockchainCryptoId
	,BlockchainCryptoName
	,FullDate
	,FullDateID
FROM #rates 
--select * from #price
-------- completing hourly prices (estimated with last price) when there are missing prices from MarketRates -----------

--- create table of full hours since yesterday with no holes -----



IF OBJECT_ID('tempdb..#inst') IS NOT NULL    DROP TABLE #inst
CREATE TABLE #inst     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

AS 
SELECT 
  a.InstrumentID 
, a.eToroInstrumentID
, a.CryptoId
, a.CryptoName
, a.BlockchainCryptoId
, a.BlockchainCryptoName
, a.FullDate
, a.FullDateID
--, ROW_NUMBER() OVER (ORDER BY a.InstrumentID) AS RN
FROM (
          SELECT DISTINCT InstrumentID
		  , eToroInstrumentID
		  , CryptoId
		  , CryptoName
		  , BlockchainCryptoId
		  , BlockchainCryptoName
          , FullDate
		  , FullDateID
		FROM #price
       WHERE FullDate = @dt
		) a
		--select * from #inst
------- populate with datefrom and dateto -----


---create hours table --------------------
 --declare @dt date= '20231127'
IF OBJECT_ID('tempdb..#24hours') IS NOT NULL    DROP TABLE #24hours
CREATE TABLE #24hours
(
 
 FullDate DATE
,FullDateID INT 
,DateFrom DATETIME NULL 
,DateTo DATETIME NULL 
)
 

DECLARE  @dt_i INT = CAST(CONVERT (VARCHAR(8) , @dt, 112 ) AS INT)
DECLARE @date2 DATEtime = @dt
DECLARE @maxdate DATETIME
DECLARE @rn INT = 1
	IF @dt = CAST(GETDATE() AS DATE)
	BEGIN
		SET @maxdate = DATEADD(hour,-1,GETDATE())
	END 
	ELSE 
		BEGIN 
			SET @maxdate = DATEADD(hour,-1,DATEADD(D,1,CAST(@dt AS DATETIME)))

		END  

	-----------------------------------------

INSERT INTO #24hours
 SELECT 
				  @dt
                 ,@dt_i 
                 ,@date2  
                 ,DATEADD(HOUR,1,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,1,@date2)  
                 ,DATEADD(HOUR,2,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,2,@date2)  
                 ,DATEADD(HOUR,3,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,3,@date2)  
                 ,DATEADD(HOUR,4,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,4,@date2)  
                 ,DATEADD(HOUR,5,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,5,@date2)  
                 ,DATEADD(HOUR,6,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,6,@date2)  
                 ,DATEADD(HOUR,7,@date2)  
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,7,@date2)  
                 ,DATEADD(HOUR,8,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,8,@date2)  
                 ,DATEADD(HOUR,9,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,9,@date2)  
                 ,DATEADD(HOUR,10,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,10,@date2)  
                 ,DATEADD(HOUR,11,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,11,@date2)  
                 ,DATEADD(HOUR,12,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,12,@date2)  
                 ,DATEADD(HOUR,13,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,13,@date2)  
                 ,DATEADD(HOUR,14,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,14,@date2)  
                 ,DATEADD(HOUR,15,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,15,@date2)  
                 ,DATEADD(HOUR,16,@date2) 
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,16,@date2)  
                 ,DATEADD(HOUR,17,@date2)  
 UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,17,@date2)  
                 ,DATEADD(HOUR,18,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,18,@date2)  
                 ,DATEADD(HOUR,19,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,19,@date2)  
                 ,DATEADD(HOUR,20,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,20,@date2)  
                 ,DATEADD(HOUR,21,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,21,@date2)  
                 ,DATEADD(HOUR,22,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,22,@date2)  
                 ,DATEADD(HOUR,23,@date2)  
UNION ALL 
				SELECT 
				  @dt
                 ,@dt_i 
                 ,DATEADD(HOUR,23,@date2)  
                 ,DATEADD(HOUR,24,@date2)  

WHERE  @date2 <= @maxdate

---cross hours table with instruments


IF OBJECT_ID('tempdb..#allhours') IS NOT NULL    DROP TABLE #allhours
CREATE TABLE #allhours
(
 InstrumentID INT 
,eToroInstrumentID INT
,CryptoId INT
,CryptoName VARCHAR (255)
,BlockchainCryptoId INT  
,BlockchainCryptoName VARCHAR(255)
,FullDate DATE
,FullDateID INT 
,DateFrom DATETIME NULL 
,DateTo DATETIME NULL 
)
 	INSERT INTO #allhours 
                           (
                            InstrumentID  
                           ,eToroInstrumentID 
                           ,CryptoId 
                           ,CryptoName  
                           ,BlockchainCryptoId  
                           ,BlockchainCryptoName 
                           ,FullDate 
                           ,FullDateID 
                           ,DateFrom 
                           ,DateTo
                           )
SELECT
DISTINCT 
 a.InstrumentID 
,a.eToroInstrumentID 
,a.CryptoId 
,a.CryptoName  
,a.BlockchainCryptoId  
,a.BlockchainCryptoName 
,a.FullDate 
,a.FullDateID 
,h.DateFrom
,h.DateTo
FROM #inst a, #24hours h
WHERE a.FullDateID =h.FullDateID

---select * from #allhours
--apply prices to correlated hours ---------
IF OBJECT_ID('tempdb..#pricesprep') IS NOT NULL    DROP TABLE #pricesprep
CREATE TABLE #pricesprep     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
SELECT  
     a.InstrumentID	
	,a.eToroInstrumentID
	,a.CryptoId
	,a.CryptoName
	,AskLast
	,LastBid
	,AvgPrice
	,a.DateFrom
	,a.DateTo
	,a.BlockchainCryptoId
	,a.BlockchainCryptoName
	,a.FullDate
	,a.FullDateID
FROM  #allhours a 
LEFT JOIN #price b ON a.InstrumentID = b.InstrumentID	 AND a.DateFrom = b.DateFrom AND b.DateTo = b.DateTo



IF OBJECT_ID('tempdb..#prices') IS NOT NULL    DROP TABLE #prices
CREATE TABLE #prices     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
SELECT
   a.CryptoId
   ,a.CryptoName
  ,a.InstrumentID
  ,a.eToroInstrumentID
  ,a.BlockchainCryptoId
  ,a.BlockchainCryptoName
  ,a.FullDate
  ,a.FullDateID
  ,a.DateFrom
  ,a.DateTo
  ,a.LastBid  orBid
  ,a.AskLast  orAsk
  ,a.AvgPrice  orAVG
  ,f.AvgPrice
  ,s.AskLast
  ,z.LastBid  
  ,ROW_NUMBER() OVER (PARTITION BY a.CryptoId  ORDER BY DateFrom DESC)Rn
  FROM
    #pricesprep  a
OUTER APPLY
	( SELECT TOP 1 p.AvgPrice
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.AvgPrice IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS f
OUTER APPLY   
	( SELECT TOP 1 p.AskLast
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.AskLast IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS s
OUTER APPLY   
	( SELECT TOP 1 p.LastBid
        FROM
            #pricesprep p
        WHERE
                a.CryptoId = p.CryptoId
           AND p.DateFrom<=a.DateFrom
            AND p.LastBid IS NOT NULL
        ORDER BY
           DateFrom DESC)  AS z
 

---- update missing price from previous values for each InstrumentID ------
IF OBJECT_ID('tempdb..#missing_previous_prices') IS NOT NULL    DROP TABLE #missing_previous_prices
CREATE TABLE #missing_previous_prices     WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS 
	SELECT a.InstrumentID , max(b.DateFrom) DateFrom
		INTO #missing_previous_prices
		FROM #prices a
		JOIN  EXW_Wallet.EXW_Price b
			ON a.InstrumentID = b.InstrumentID
			AND b.DateFrom < CAST(@dt as date)
		WHERE a.AskLast IS NULL
		group by a.InstrumentID



		UPDATE a
		SET AskLast = b.AskLast
		,LastBid = b.BidLast
		,AvgPrice = b.AvgPrice
		FROM #prices a
		JOIN #missing_previous_prices m
			ON m.InstrumentID = a.InstrumentID
		JOIN EXW_Wallet.EXW_Price b
			ON m.InstrumentID = b.InstrumentID
		AND m.DateFrom = b.DateFrom			 
		WHERE a.AskLast IS NULL

---- update price daily ------
--SELECT COUNT(*) , CryptoID  FROM EXW_Wallet.EXW_Price  where  [FullDateID] =20231130 GROUP BY CryptoID HAVING COUNT(*) >24

DELETE FROM EXW_Wallet.EXW_Price
WHERE DateFrom >= @dt AND DateFrom < DATEADD(D,1,@dt)

INSERT INTO EXW_Wallet.EXW_Price ( [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoID]
      ,[CryptoName]
      ,[AskLast]
      ,BidLast
      ,[AvgPrice]
      ,[DateFrom]
      ,[DateTo]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
      ,[UpdateDate])

SELECT [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoId]
      ,CryptoName
      ,[AskLast]
      ,[LastBid]
      ,[AvgPrice]
      ,[DateFrom]
      ,[DateTo]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
	  ,GETDATE()
FROM #prices


----- update price daily -------

DELETE FROM EXW_Wallet.EXW_PriceDaily
WHERE FullDate = @dt

INSERT INTO EXW_Wallet.EXW_PriceDaily ([InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoID]
      ,[CryptoName]
      ,[AvgPrice]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
      ,[UpdateDate])

   SELECT [InstrumentID]
      ,[eToroInstrumentID]
      ,[CryptoId]
      ,[CryptoName]
      ,[AvgPrice]
      ,[BlockchainCryptoId]
      ,[BlockchainCryptoName]
      ,[FullDate]
      ,[FullDateID]
	  ,GETDATE()
FROM  #prices
		WHERE FullDate = @dt
	AND  Rn = 1


END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `EXW_Wallet.SP_Prices` | synapse_sp | EXW_Wallet | SP_Prices | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\EXW_Wallet\Stored Procedures\EXW_Wallet.SP_Prices.sql` |
| `EXW_Currency.Instruments` | unresolved | EXW_Currency | Instruments | `—` |
| `EXW_Currency.Currencies` | unresolved | EXW_Currency | Currencies | `—` |
| `EXW_Wallet.CryptoMarketRatesMappings` | unresolved | EXW_Wallet | CryptoMarketRatesMappings | `—` |
| `EXW_Wallet.CryptoTypes` | unresolved | EXW_Wallet | CryptoTypes | `—` |
| `EXW_Wallet.ETL_InstrumentRates_ByHour` | unresolved | EXW_Wallet | ETL_InstrumentRates_ByHour | `—` |
| `EXW_Wallet.EXW_Price` | unresolved | EXW_Wallet | EXW_Price | `—` |
