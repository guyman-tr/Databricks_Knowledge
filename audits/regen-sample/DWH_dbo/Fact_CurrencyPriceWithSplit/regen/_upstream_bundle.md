# Pre-Resolved Upstream Bundle for `DWH_dbo.Fact_CurrencyPriceWithSplit`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Fact_CurrencyPriceWithSplit.sql`

```sql
CREATE TABLE [DWH_dbo].[Fact_CurrencyPriceWithSplit]
(
	[ProviderID] [int] NULL,
	[InstrumentID] [int] NULL,
	[Occurred] [datetime] NULL,
	[OccurredDate] [date] NULL,
	[OccurredDateID] [int] NULL,
	[isvalid] [int] NULL,
	[AskSpreaded] [numeric](36, 12) NULL,
	[BidSpreaded] [numeric](36, 12) NULL,
	[RateLastEx] [numeric](36, 12) NULL,
	[Ask] [numeric](36, 12) NULL,
	[Bid] [numeric](36, 12) NULL,
	[UpdateDate] [datetime] NOT NULL,
	[ConvertRateIsBuy_1] [numeric](18, 4) NULL,
	[ConvertRateIsBuy_0] [numeric](18, 4) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [InstrumentID] ),
	CLUSTERED COLUMNSTORE INDEX
)

GO
CREATE NONCLUSTERED INDEX [IX_Fact_CurrencyPriceWithSplit] ON [DWH_dbo].[Fact_CurrencyPriceWithSplit]
(
	[OccurredDateID] ASC
)WITH (DROP_EXISTING = OFF)
GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse] @dt [Date] AS
BEGIN

-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse] '20211201'

--DATE          NAME                    CHANGE DETAILES 

--2022-04-27     Inbal BML & Adi F       replace  [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView] with [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInsHistory]
--2023-02-26	 MeravHu				 Add ConvertRateIsBuy_1 , ConvertRateIsBuy_0
--2023-03-09	 MeravHu				 Bugfix	
-- =============================================
--DECLARE @dt [Date] = '2021-12-10'
DECLARE @DateID int = cast(CONVERT(varchar(10),cast(@dt as date),112) as INT) 
DECLARE @CountRowsSplit as int

DELETE from [DWH_dbo].[Fact_CurrencyPriceWithSplit]
where
OccurredDateID = @DateID



INSERT INTO [DWH_dbo].[Fact_CurrencyPriceWithSplit]
           ([ProviderID]
           ,[InstrumentID]
           ,[Occurred]
           ,[OccurredDate]
           ,[OccurredDateID]
           ,[isvalid]
           ,[AskSpreaded]
           ,[BidSpreaded]
           ,[RateLastEx]
           ,[Ask]
           ,[Bid]
           ,[UpdateDate]
      )
SELECT
[ProviderID]
      ,[InstrumentID]
      ,[Occurred]
      ,[OccurredDate]
      ,[OccurredDateID]
      ,[isvalid]
      ,[AskSpreaded]
      ,[BidSpreaded]
      ,[RateLastEx]
      ,[Ask]
      ,[Bid]
,getdate() as UpdateDate
FROM [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView]


TRUNCATE TABLE [DWH_dbo].[Ext_FCPWS_History_SplitRatio]

INSERT INTO [DWH_dbo].[Ext_FCPWS_History_SplitRatio]
           ([InstrumentID]
           ,[MinDate]
           ,[MaxDate]
           ,[PriceRatio]
           ,[AmountRatio])
select InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio
from [DWH_staging].[etoro_History_SplitRatio] with(NOLOCK) 
where MinDate>= @dt and MinDate <  dateadd(day,1, @dt)


Select @CountRowsSplit = count(*)
from [DWH_dbo].[Ext_FCPWS_History_SplitRatio]

IF  @CountRowsSplit> 0
	BEGIN

		if object_id ('tempdb..#SplitInstrument') is not null drop table  #SplitInstrument
		
		select Distinct InstrumentID 
		Into #SplitInstrument
		from [DWH_dbo].[Ext_FCPWS_History_SplitRatio]


		if object_id ('tempdb..#ConvertRateIsBuy') is not null drop table  #ConvertRateIsBuy
		if object_id ('tempdb..#ConvertRateIsBuy_all') is not null drop table  #ConvertRateIsBuy_all
		
	
			select distinct a.InstrumentID, a.OccurredDateID, a.ConvertRateIsBuy_1 , a.ConvertRateIsBuy_0
			,ROW_NUMBER() OVER(PARTITION BY a.OccurredDateID ORDER BY a.ConvertRateIsBuy_1 desc ) RowNumber
			into #ConvertRateIsBuy_all 
			from [DWH_dbo].[Fact_CurrencyPriceWithSplit]  a 
			join #SplitInstrument b on a.InstrumentID=b.InstrumentID 
		
			select  a.InstrumentID, a.OccurredDateID, a.ConvertRateIsBuy_1 , a.ConvertRateIsBuy_0
			into  #ConvertRateIsBuy
			from #ConvertRateIsBuy_all a
			where RowNumber=1
		
		
		delete [DWH_dbo].[Fact_CurrencyPriceWithSplit] 
		where InstrumentID in 
		(select  InstrumentID from #SplitInstrument)
		
		INSERT INTO [DWH_dbo].[Fact_CurrencyPriceWithSplit]
		           ([ProviderID]
		           ,[InstrumentID]
		           ,[Occurred]
		           ,[OccurredDate]
		           ,[OccurredDateID]
		           ,[isvalid]
		           ,[AskSpreaded]
		           ,[BidSpreaded]
		           ,[RateLastEx]
		           ,[Ask]
		           ,[Bid]
		           ,ConvertRateIsBuy_1 
				   ,ConvertRateIsBuy_0
				   ,[UpdateDate]
				 
				   
		)
		SELECT distinct
		[ProviderID]
		      ,a.InstrumentID
		      ,[Occurred]
		      ,[OccurredDate]
		      ,a.OccurredDateID
		      ,[isvalid]
		      ,[AskSpreaded]
		      ,[BidSpreaded]
		      ,[RateLastEx]
		      ,[Ask]
		      ,[Bid]
			  ,ConvertRateIsBuy_1
			  ,ConvertRateIsBuy_0
		,getdate() as UpdateDate
		FROM [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory] a
		left join #ConvertRateIsBuy b  on a.InstrumentID=b.InstrumentID and a.OccurredDateID=b.OccurredDateID
		--[DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView]
		where a.InstrumentID in 
		(
		select Distinct InstrumentID
		from [DWH_staging].[etoro_History_SplitRatio] with(NOLOCK) 
		where MinDate>=@dt and MinDate <  dateadd(day,1,@dt)
		
		--select InstrumentID from #SplitInstrument
		)
	
	END

TRUNCATE TABLE [DWH_dbo].[Ext_FCPWS_Instrument]


INSERT INTO [DWH_dbo].[Ext_FCPWS_Instrument]
           ([InstrumentID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID])
SELECT
b.InstrumentID,
b.BuyCurrencyID,
b.SellCurrencyID
FROM
[DWH_staging].[etoro_Trade_GetInstrument] b

UPDATE a
SET 
ConvertRateIsBuy_1 = 
cast(
CASE
WHEN Pair.SellCurrencyID = 1
THEN 1.00
WHEN Pair.BuyCurrencyID = 1
THEN (1.00 / a.Bid )-- IsBuy = 1
WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
THEN coalesce(1.00 /I2Price.Bid , I3Price.Bid , 1.00)-- IsBuy = 1
END
AS MONEY) 
,
ConvertRateIsBuy_0 = 
cast(
CASE
WHEN Pair.SellCurrencyID = 1
THEN 1.00
WHEN Pair.BuyCurrencyID = 1
THEN (1.00 / a.Ask )-- IsBuy = 0
WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
THEN coalesce(1.00 /I2Price.Ask , I3Price.Ask , 1.00)-- IsBuy = 0
END
AS MONEY) 

FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] a
JOIN [DWH_dbo].[Ext_FCPWS_Instrument] Pair
ON a.InstrumentID = Pair.InstrumentID
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] PairPrice WITH (NOLOCK)
ON Pair.InstrumentID = PairPrice.InstrumentID 
AND PairPrice.OccurredDateID=@DateID
LEFT JOIN [DWH_dbo].[Ext_FCPWS_Instrument] I2 WITH (NOLOCK)
ON I2.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
AND I2.SellCurrencyID = Pair.SellCurrencyID AND I2.BuyCurrencyID = 1 -- USD
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] I2Price WITH (NOLOCK)
ON I2Price.InstrumentID = I2.InstrumentID 
AND I2Price.OccurredDateID=@DateID
LEFT JOIN [DWH_dbo].[Ext_FCPWS_Instrument] I3 WITH (NOLOCK)
ON I3.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
AND I3.BuyCurrencyID = Pair.SellCurrencyID AND I3.SellCurrencyID = 1 -- USD
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] I3Price WITH (NOLOCK)
ON I3Price.InstrumentID = I3.InstrumentID 
AND I3Price.OccurredDateID=@DateID
WHERE
a.OccurredDateID=@DateID



END

GO

```

### SP `DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER] @dt [Date] AS
BEGIN

-- =============================================
-- Author:     <Adi  Ferber>
-- Create Date: 2021-10-12
-- Description: SP intended to transfer data from DataLake to synapse
-- exec [DWH_dbo].[SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse] '20211201'

--DATE          NAME                    CHANGE DETAILES 

--2022-04-27     Inbal BML & Adi F       replace  [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView] with [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInsHistory]

-- =============================================
--DECLARE @dt [Date] = '20211210'
DECLARE @DateID int = cast(CONVERT(varchar(10),cast(@dt as date),112) as INT) 
DECLARE @CountRowsSplit as int

DELETE from [DWH_dbo].[Fact_CurrencyPriceWithSplit]
where
OccurredDateID = @DateID


INSERT INTO [DWH_dbo].[Fact_CurrencyPriceWithSplit]
           ([ProviderID]
           ,[InstrumentID]
           ,[Occurred]
           ,[OccurredDate]
           ,[OccurredDateID]
           ,[isvalid]
           ,[AskSpreaded]
           ,[BidSpreaded]
           ,[RateLastEx]
           ,[Ask]
           ,[Bid]
           ,[UpdateDate]
      )
SELECT
[ProviderID]
      ,[InstrumentID]
      ,[Occurred]
      ,[OccurredDate]
      ,[OccurredDateID]
      ,[isvalid]
      ,[AskSpreaded]
      ,[BidSpreaded]
      ,[RateLastEx]
      ,[Ask]
      ,[Bid]
,getdate() as UpdateDate
FROM [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView]


TRUNCATE TABLE [DWH_dbo].[Ext_FCPWS_History_SplitRatio]

INSERT INTO [DWH_dbo].[Ext_FCPWS_History_SplitRatio]
           ([InstrumentID]
           ,[MinDate]
           ,[MaxDate]
           ,[PriceRatio]
           ,[AmountRatio])
select InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio
from [DWH_staging].[etoro_History_SplitRatio] with(NOLOCK) 
where MinDate>= @dt and MinDate <  dateadd(day,1, @dt)


Select @CountRowsSplit = count(*)
from [DWH_dbo].[Ext_FCPWS_History_SplitRatio]

IF  @CountRowsSplit> 0
BEGIN
delete [DWH_dbo].[Fact_CurrencyPriceWithSplit] 
where InstrumentID in 
(select Distinct InstrumentID from [DWH_dbo].[Ext_FCPWS_History_SplitRatio])

INSERT INTO [DWH_dbo].[Fact_CurrencyPriceWithSplit]
           ([ProviderID]
           ,[InstrumentID]
           ,[Occurred]
           ,[OccurredDate]
           ,[OccurredDateID]
           ,[isvalid]
           ,[AskSpreaded]
           ,[BidSpreaded]
           ,[RateLastEx]
           ,[Ask]
           ,[Bid]
           ,[UpdateDate]
	       -- ,ConvertRateIsBuy_1	 adi 
		---	,ConvertRateIsBuy_0 adi

)
SELECT
[ProviderID]
      ,[InstrumentID]
      ,[Occurred]
      ,[OccurredDate]
      ,[OccurredDateID]
      ,[isvalid]
      ,[AskSpreaded]
      ,[BidSpreaded]
      ,[RateLastEx]
      ,[Ask]
      ,[Bid]
,getdate() as UpdateDate
--ConvertRateIsBuy_1	, adi 
--ConvertRateIsBuy_0 adi

FROM [DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory]
--[DWH_staging].[PriceLog_Candles_CurrencyPriceMaxDateWithSplitView]
where [InstrumentID] in 
(
select Distinct InstrumentID
from [DWH_staging].[etoro_History_SplitRatio] with(NOLOCK) 
where MinDate>=@dt and MinDate <  dateadd(day,1,@dt)
)

END

TRUNCATE TABLE [DWH_dbo].[Ext_FCPWS_Instrument]


INSERT INTO [DWH_dbo].[Ext_FCPWS_Instrument]
           ([InstrumentID]
           ,[BuyCurrencyID]
           ,[SellCurrencyID])
SELECT
b.InstrumentID,
b.BuyCurrencyID,
b.SellCurrencyID
FROM
[DWH_staging].[etoro_Trade_GetInstrument] b

UPDATE a
SET 
ConvertRateIsBuy_1 = 
cast(
CASE
WHEN Pair.SellCurrencyID = 1
THEN 1.00
WHEN Pair.BuyCurrencyID = 1
THEN (1.00 / a.Bid )-- IsBuy = 1
WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
THEN coalesce(1.00 /I2Price.Bid , I3Price.Bid , 1.00)-- IsBuy = 1
END
AS MONEY) 
,
ConvertRateIsBuy_0 = 
cast(
CASE
WHEN Pair.SellCurrencyID = 1
THEN 1.00
WHEN Pair.BuyCurrencyID = 1
THEN (1.00 / a.Ask )-- IsBuy = 0
WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
THEN coalesce(1.00 /I2Price.Ask , I3Price.Ask , 1.00)-- IsBuy = 0
END
AS MONEY) 

FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] a
JOIN [DWH_dbo].[Ext_FCPWS_Instrument] Pair
ON a.InstrumentID = Pair.InstrumentID
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] PairPrice WITH (NOLOCK)
ON Pair.InstrumentID = PairPrice.InstrumentID 
AND PairPrice.OccurredDateID=@DateID
LEFT JOIN [DWH_dbo].[Ext_FCPWS_Instrument] I2 WITH (NOLOCK)
ON I2.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
AND I2.SellCurrencyID = Pair.SellCurrencyID AND I2.BuyCurrencyID = 1 -- USD
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] I2Price WITH (NOLOCK)
ON I2Price.InstrumentID = I2.InstrumentID 
AND I2Price.OccurredDateID=@DateID
LEFT JOIN [DWH_dbo].[Ext_FCPWS_Instrument] I3 WITH (NOLOCK)
ON I3.InstrumentID <> Pair.InstrumentID -- This is so I won't get doubled records.
AND I3.BuyCurrencyID = Pair.SellCurrencyID AND I3.SellCurrencyID = 1 -- USD
LEFT JOIN [DWH_dbo].[Fact_CurrencyPriceWithSplit] I3Price WITH (NOLOCK)
ON I3Price.InstrumentID = I3.InstrumentID 
AND I3Price.OccurredDateID=@DateID
WHERE
a.OccurredDateID=@DateID



END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit | `—` |
| `DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse.sql` |
| `DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER` | synapse_sp | DWH_dbo | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER.sql` |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` | unresolved | DWH_staging | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | `—` |
| `DWH_staging.etoro_History_SplitRatio` | unresolved | DWH_staging | etoro_History_SplitRatio | `—` |
| `DWH_dbo.Ext_FCPWS_History_SplitRatio` | unresolved | DWH_dbo | Ext_FCPWS_History_SplitRatio | `—` |
| `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory` | unresolved | DWH_staging | PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory | `—` |
| `DWH_staging.etoro_Trade_GetInstrument` | unresolved | DWH_staging | etoro_Trade_GetInstrument | `—` |
| `DWH_dbo.Ext_FCPWS_Instrument` | unresolved | DWH_dbo | Ext_FCPWS_Instrument | `—` |
