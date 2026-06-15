select 

        Table_Name   ,
        Filter_Condition   ,
        DateID,
        CONVERT(date,CONVERT(datetime, CAST(DateID AS CHAR(8))), 101) as Date ,
        --CAST(CAST( as datetime) as Date) Date ,
        Field_Name ,
	DWH_Value  ,
	Synapse_Value ,
        Diff ,
        CASE 
            WHEN Diff <> 0 THEN 'not equal' 
            ELSE 'equal' 
        END AS Diff_Ind

FROM [AZR-WE-DWH-02].[DWH_DEV].[dbo].[DWH_Compare_Results_Diff_View] 
WHERE Diff = 0