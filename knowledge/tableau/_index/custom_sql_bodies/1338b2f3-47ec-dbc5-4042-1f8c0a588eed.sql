--This subquery obtains the users granted Project Leader permissions for each project and returns all of their usernames in the "project_leaders_string" field
	--      This is used for row-level security
SELECT
    project_permissions.project_id              AS project_id ,
    ';' || string_agg(DISTINCT su.name || ';', '')
                                                AS project_leaders_string
FROM public.system_users su
    INNER JOIN public.users u
        ON su.id = u.system_user_id
    INNER JOIN
        (
        -- users granted project leader rights via individual assignment
        SELECT
                ngp.grantee_id              AS user_id ,
                ngp.authorizable_id         AS project_id
        FROM public.users u
            INNER JOIN public.next_gen_permissions ngp
                ON u.id = ngp.grantee_id
                    AND ngp.capability_id = 19 -- Project Leader permissions
                    AND ngp.grantee_type = 'User'
                    AND ngp.permission = 3 -- Granted to user
                    AND ngp.authorizable_type = 'Project'
        UNION
        -- users granted project leader rights via group membership
        SELECT
                gu.user_id                  AS user_id ,
                ngp.authorizable_id         AS project_id
        FROM public.group_users gu
            INNER JOIN public.groups g
                ON gu.group_id = g.id
            INNER JOIN public.next_gen_permissions ngp
                ON gu.group_id = ngp.grantee_id
                    AND ngp.capability_id = 19 -- Project Leader permissions
                    AND ngp.grantee_type = 'Group'
                    AND ngp.permission = 1 -- Granted to group
                    AND ngp.authorizable_type = 'Project'
        ) AS project_permissions
            ON u.id = project_permissions.user_id
    INNER JOIN public.projects p
        ON project_permissions.project_id = p.id
GROUP BY
    project_permissions.project_id
ORDER BY project_permissions.project_id