SELECT              sysusers.name as username,
                    sysusers.email,
                    sysusers.friendly_name as Name,
                    case when licensing.licensing_role_name='Tier_Author' then 'Craetor'
                         when licensing.licensing_role_name='Tier_Basic' then  'Viewer'
                         when licensing.licensing_role_name='Tier_Interactor' then  'Explorer' 
                         else licensing.licensing_role_name end as LicenseType ,
                    users.login_at as LastLogin,
                    users.created_at as UserCreateDate,
                    count(groups.name) countgroups
            FROM system_users   sysusers
            join 
            group_users groupusers on sysusers.id=groupusers.user_id
            join  groups groups on groupusers.group_id=groups.id
            join users users on users.id=sysusers.id
            join _users licensing on licensing.id=sysusers.id
            where sysusers.name not in ('RahavBA' ,'guest')
            group by sysusers.name , sysusers.email,sysusers.friendly_name,users.login_at,users.created_at,
            case when licensing.licensing_role_name='Tier_Author' then 'Craetor'
                         when licensing.licensing_role_name='Tier_Basic' then  'Viewer'
                         when licensing.licensing_role_name='Tier_Interactor' then  'Explorer' 
                         else licensing.licensing_role_name end