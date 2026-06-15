select
CASE 
WHEN dcc.Region IN ('ROE','Eastern Europe','North Europe') THEN 'Europe' 
WHEN dcc.Region IN ('Africa','ROW','Israel','Russian') THEN 'ROW' 
WHEN dcc.Region IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
WHEN dcc.Region IN ('China','Other Asia') THEN 'China & Other Asia'
WHEN dcc.Region IN ('Spain') THEN 'Spanish' 
WHEN dcc.Region IN ('South & Central America') THEN 'LATAM' ELSE dcc.Region END as Region
,dcc.CountryID
from DWH.dbo.Dim_Country dcc