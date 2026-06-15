select 
CAST(GETDATE() AS DATE) as Date,
'ISR' as Server,
'DWH Data' as Type,
ISNULL(MAX(CASE WHEN DWH_Status = 2 THEN 'Updated' ELSE 'Outdated' END),'Outdated') Data,
ISNULL(MAX(CASE WHEN DWH_Status = 2 THEN 1 ELSE 0 END),0) DataCode

from 

DWH.dbo.DWH_Status
where UpdateDate >= cast(getdate() as date)
UNION ALL


select 
CAST(GETDATE() AS DATE) as Date,
'ISR' as Server,
'OLAP Data' as Type,
ISNULL(MAX(CASE WHEN DWH_Status = 1 THEN 'Updated' 
                  WHEN DWH_Status = 0 and Comments like '%Cube Processing Issues: No%' THEN 'Updated' 
		          ELSE 'Outdated' END),'Outdated') Data,
ISNULL(MAX(CASE WHEN DWH_Status = 1 THEN 1
                WHEN DWH_Status = 0 and Comments like '%Cube Processing Issues: No%' THEN 1 
			    ELSE 0 END),0) DataCode

from 

DWH.dbo.DWH_Status
where UpdateDate >= cast(getdate() as date)