select  id,case when name='Tier_Author' then 'Creator'
            when  name='Tier_Basic' then  'Viewer'
            when  name='Tier_Interactor' then  'Explorer' 
            else name end as LicenseType 
,roles.licensing_roles_count NumberOfLicenses
,'Budget' as Description 
from public.licensing_roles roles 

where roles.licensing_roles_count>0 and name!='Guest'
order by 1