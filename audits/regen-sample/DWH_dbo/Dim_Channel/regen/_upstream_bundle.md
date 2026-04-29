# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_Channel`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_Channel.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_Channel]
(
	[SubChannelID] [int] NOT NULL,
	[Channel] [nvarchar](50) NOT NULL,
	[SubChannel] [varchar](100) NOT NULL,
	[Organic/Paid] [varchar](7) NULL,
	[InsertDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[SubChannelID] ASC
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


### SP `DWH_dbo.SP_Dim_Channel`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Channel.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Dim_Channel] AS
BEGIN

/********************************************************************************************
Author:      Boris Slutski
Date:        2019-01-13
Description: Update table Dim_Channel
 
**************************
** Change History
**************************
Date             Author        Description   
----------     ----------      ------------------------------------
2021-05-02     Chen Avraham    Update Channels & SubChannels classification logic. 
2022-03-27     Jan Iablunovskey  New channels created :Media Programmatic,Media Performance,Content Partnerships,TV,Social Organic
2022-11-22     Adi Ferber		update subchannel script semandad by Eti Rozilio
2023-02-15     Adi Ferber       reffer script to use subchannel unifycode
*********************************************************************************************/

IF OBJECT_ID(N'tempdb..#TMP_Channel_a') IS NOT NULL 
	DROP TABLE #TMP_Channel_a


IF OBJECT_ID(N'tempdb..#TMP_Channel') IS NOT NULL 
	DROP TABLE #TMP_Channel
SELECT DISTINCT SubChannelID
			   ,Channel
               ,SubChannel
			   ,GETDATE() AS InsertDate
			   ,GETDATE() AS UpdateDate
INTO #TMP_Channel_a
FROM [DWH_dbo].Ext_Dim_SubChannel_UnifyCode



SELECT SubChannelID, 
	Channel, 
	SubChannel, 
	CASE
		WHEN Channel IN ('Friend Referral', 'Direct', 'SEO') THEN 'Organic'
		WHEN SubChannel = 'Google Brand' THEN 'Organic'
		ELSE 'Paid'
		END AS 'Organic/Paid',

	InsertDate, 
	UpdateDate 
INTO #TMP_Channel
FROM #TMP_Channel_a



--select * From #TMP_Channel
--- insert exiting data

IF OBJECT_ID(N'tempdb..#InsertData') IS NOT NULL 
	DROP TABLE #InsertData

SELECT a.*
INTO #InsertData
FROM #TMP_Channel a
LEFT join  [DWH_dbo].[Dim_Channel] b
ON a.SubChannelID=b.SubChannelID
WHERE a.SubChannelID  != 0
--select * from #TMP_Channel order by 2 
--select * from #InsertData

truncate table [DWH_dbo].[Dim_Channel]

INSERT INTO [DWH_dbo].[Dim_Channel]
           ([Channel]
           ,[SubChannelID]
           ,[SubChannel]
           ,[Organic/Paid]
           ,[InsertDate]
           ,[UpdateDate])
SELECT 
[Channel]
           ,[SubChannelID]
           ,[SubChannel]
           ,[Organic/Paid]
           ,[InsertDate]
           ,[UpdateDate]
FROM #InsertData 

if (select count(*) FROM #TMP_Channel a
	LEFT JOIN [DWH_dbo].[Dim_Channel] b
	ON a.SubChannelID=b.SubChannelID
	WHERE b.SubChannelID IS null) > 0

	BEGIN

		DECLARE @Table NVARCHAR(MAX)
		DECLARE @body NVARCHAR(MAX)

		--SET @Table = CAST(( 
		--SELECT a.[Channel] AS 'td','',
		--	   a.[SubChannelID] AS 'td','',
		--	   a.[SubChannel] AS 'td'
		--FROM #TMP_Channel a
		--LEFT JOIN [DWH_dbo].[Dim_Channel] b
		--ON a.SubChannelID=b.SubChannelID
		--WHERE b.SubChannelID IS null
		-- --FOR XML PATH('tr')
		-- --, ELEMENTS ) 
		-- )AS NVARCHAR(MAX))


	    SELECT  @Table = STRING_AGG( CONCAT('<tr>',
		                 '<td>', a.[Channel] , '</td>',
						 '<td>',  a.[SubChannelID]  , '</td>',
						 '<td>',  a.[SubChannel]   , '</td>', 
						  '</tr>'),'')
		FROM #TMP_Channel a
		LEFT JOIN [DWH_dbo].[Dim_Channel] b
		ON a.SubChannelID=b.SubChannelID
		WHERE b.SubChannelID IS null


		SET @body =
		'<html><body><H2>New Channels in Affwizz - Need mapping ASAP</H2>
		<table border = 1 > 
		<th> Channel </th> 
		<th> SubChannelID </th> 
		<th> SubChannel </th> 
		</tr>'    

		SET @body = @body + @Table +'</table></body></html>'

		DECLARE @copy_to varchar(max)= 'bi-datasolutions@etoro.com'+';'+'BIAnalysisTeam@etoro.com'
		--EXEC msdb.dbo.sp_send_dbmail

		--@profile_name = 'AZR-WE-DWH-01',
		--@body = @body,
		--@body_format ="HTML",
		--@from_address = 'bi-datasolutions@etoro.com',
		--@recipients = @copy_to,
		--@subject = 'New Channels in Affwizz'

	END

END



GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `DWH_staging.fiktivo_dbo_tblaff_Affiliates` | unresolved | DWH_staging | fiktivo_dbo_tblaff_Affiliates | `—` |
| `DWH_dbo.Ext_Dim_SubChannel_UnifyCode` | unresolved | DWH_dbo | Ext_Dim_SubChannel_UnifyCode | `—` |
| `DWH_dbo.SP_Dim_Channel` | synapse_sp | DWH_dbo | SP_Dim_Channel | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Dim_Channel.sql` |
