USE CATALOG dwh_daily_process;
USE SCHEMA migration_tables;



CREATE OR REPLACE PROCEDURE dwh_daily_process.migration_tables.SP_Dim_Channel(
)
LANGUAGE SQL
SQL SECURITY INVOKER
MODIFIES SQL DATA
AS

BEGIN



DECLARE V_Table STRING
;
DECLARE V_body STRING;

		--SET @Table = CAST(( 
		--SELECT a.[Channel] AS "td",'',
		--	   a.[SubChannelID] AS "td",'',
		--	   a.[SubChannel] AS "td"
		--FROM #TMP_Channel a
		--LEFT JOIN [DWH_dbo].[Dim_Channel] b
		--ON a.SubChannelID=b.SubChannelID
		--WHERE b.SubChannelID IS null
		-- --FOR XML PATH('tr')
		-- --, ELEMENTS ) 
		-- )AS NVARCHAR(MAX))


	    

DECLARE V_copy_to STRING;
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

DROP VIEW IF EXISTS TEMP_TABLE_TMP_Channel_a;
DROP VIEW IF EXISTS TEMP_TABLE_TMP_Channel;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_TMP_Channel_a AS
SELECT DISTINCT SubChannelID
			   ,Channel
               ,SubChannel
			   ,current_timestamp() AS InsertDate
			   ,current_timestamp() AS UpdateDate

FROM dwh_daily_process.migration_tables.Ext_Dim_SubChannel_UnifyCode


;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_TMP_Channel AS
SELECT SubChannelID, 
	Channel, 
	SubChannel, 
	CASE
		WHEN Channel IN ('Friend Referral', 'Direct', 'SEO') THEN 'Organic'
		WHEN SubChannel = 'Google Brand' THEN 'Organic'
		ELSE 'Paid'
		END AS `Organic/Paid`,

	InsertDate, 
	UpdateDate 

FROM TEMP_TABLE_TMP_Channel_a;



--select * From #TMP_Channel
--- insert exiting data
DROP VIEW IF EXISTS TEMP_TABLE_InsertData;

CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_InsertData AS
SELECT a.*

FROM TEMP_TABLE_TMP_Channel a
LEFT join  dwh_daily_process.migration_tables.Dim_Channel b
ON a.SubChannelID=b.SubChannelID
WHERE a.SubChannelID  <> 0;
--select * from #TMP_Channel order by 2 
--select * from #InsertData
TRUNCATE table dwh_daily_process.migration_tables.Dim_Channel

;
INSERT INTO dwh_daily_process.migration_tables.Dim_Channel
           (`Channel`
           ,`SubChannelID`
           ,`SubChannel`
           ,`Organic/Paid`
           ,`InsertDate`
           ,`UpdateDate`)
SELECT 
`Channel`
           ,`SubChannelID`
           ,`SubChannel`
           ,`Organic/Paid`
           ,`InsertDate`
           ,`UpdateDate`
FROM TEMP_TABLE_InsertData 

;
IF (select count(*) FROM TEMP_TABLE_TMP_Channel a
	LEFT JOIN dwh_daily_process.migration_tables.Dim_Channel b
	ON a.SubChannelID=b.SubChannelID
	WHERE b.SubChannelID IS null) > 0

	THEN
SET V_Table = (
SELECT
ARRAY_JOIN(COLLECT_LIST(CONCAT('<tr>',
'<td>', a.`Channel` , '</td>',
'<td>',  a.`SubChannelID`  , '</td>',
'<td>',  a.`SubChannel`   , '</td>', 
'</tr>')), '') FROM TEMP_TABLE_TMP_Channel a
		LEFT JOIN dwh_daily_process.migration_tables.Dim_Channel b
		ON a.SubChannelID=b.SubChannelID
		WHERE b.SubChannelID IS null


		 LIMIT 1);
SET V_body =
		'<html><body><H2>New Channels in Affwizz - Need mapping ASAP</H2>
		<table border = 1 > 
		<th> Channel </th> 
		<th> SubChannelID </th> 
		<th> SubChannel </th> 
		</tr>'    

		;
SET V_body = V_body + V_Table ||'</table></body></html>'

		;
SET V_copy_to = 'bi-datasolutions@etoro.com'+';'+'BIAnalysisTeam@etoro.com';
--EXEC msdb.dbo.sp_send_dbmail
--@profile_name = 'AZR-WE-DWH-01',
--@body = @body,
--@body_format ="HTML",
--@from_address = 'bi-datasolutions@etoro.com',
--@recipients = @copy_to,
--@subject = 'New Channels in Affwizz'

END IF;

-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_InsertData;
DROP VIEW IF EXISTS TEMP_TABLE_TMP_Channel;
DROP VIEW IF EXISTS TEMP_TABLE_TMP_Channel_a;
END;
