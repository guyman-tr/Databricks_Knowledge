SELECT *
FROM [dbo].[DWH_Compare_Results_new_compare_Diff_View] comapre
	left join   [SYNAPSE-DWH-PROD].[sql_dp_prod_we].[DE_dbo].[ObjectsStatus]  config
	   ON replace (  config.TableName,left(  config.TableName,charindex('.',   config.TableName)),'') =   comapre.Table_Name COLLATE Latin1_General_CI_AS
	WHERE 	comapre.System_Code=2  -- compare indication
			  and config.MigartionStatusID in (3,4)-- side by side or compare mode
	AND NOT EXISTS 
	(
		SELECT
			NULL
		FROM DWH_Compare_Ignore_Field b
		WHERE
			comapre.Table_Name=b.TableName
			AND comapre.Field_Name=b.FieldName
	)
and comapre.DateID = CAST(CONVERT(VARCHAR(8), <[Parameters].[Parameter 1]>, 112) AS INT)
AND comapre.Table_Name = <[Parameters].[Parameter 2]>