-- This query grabs project information, along with parent project hierarchy information


WITH RECURSIVE project_hierarchy AS (
    SELECT
        p.name                                          AS project_name ,
        p.id                                            AS project_id ,
        p.luid                                          AS project_luid ,
        p.site_id                                       AS project_site_id ,
        su.friendly_name                                AS project_owner_friendly_name ,
        su.name                                         AS project_owner_system_name ,
        su.email                                        AS project_owner_email ,
        pc.project_id                                   AS parent_project_id ,
        CAST(NULL as varchar)                           AS parent_project_name ,
        CAST(NULL as varchar)                           AS parent_project_owner_friendly_name ,
        CAST(NULL as varchar)                           AS parent_project_owner_system_name ,
        CAST(NULL as varchar)                           AS parent_project_owner_email ,
        0                                               AS project_level ,
        p.name                                          AS top_level_project_name ,
        CAST(p.name AS VARCHAR(255))                    AS project_path ,
        p.controlled_permissions_enabled ,
        p.controlling_permissions_project_id ,
        p.nested_projects_permissions_included
    FROM projects p
        LEFT JOIN projects_contents pc
            ON p.id = pc.content_id
                AND p.site_id = pc.site_id
                AND pc.content_type = 'project'
        LEFT JOIN users u
            ON p.owner_id = u.id
        LEFT JOIN system_users su
            ON u.system_user_id = su.id
    WHERE pc.project_id IS NULL
    UNION ALL
    SELECT
        p.name                                          AS project_name ,
        p.id                                            AS project_id ,
        p.luid                                          AS project_luid ,
        p.site_id                                       AS project_site_id ,
        su.friendly_name                                AS project_owner_friendly_name ,
        su.name                                         AS project_owner_system_name ,
        su.email                                        AS project_owner_email ,
        p.parent_project_id ,
        ph.project_name                                 AS parent_project_name ,
        CAST(ph.project_owner_friendly_name as varchar)
                                                        AS parent_project_owner_friendly_name ,
        CAST(ph.project_owner_system_name as varchar)
                                                        AS parent_project_owner_system_name ,
        CAST(ph.project_owner_email as varchar)
                                                        AS parent_project_owner_email ,
        ph.project_level + 1                            AS project_level ,
        ph.top_level_project_name                       AS top_level_project_name ,
        CAST((ph.project_path || '/' || p.name) AS VARCHAR(255))
                                                        AS project_path ,
        p.controlled_permissions_enabled ,
        p.controlling_permissions_project_id ,
        p.nested_projects_permissions_included
    FROM projects p
        LEFT JOIN projects_contents pc
            ON p.id = pc.content_id
                AND p.site_id = pc.site_id
                AND pc.content_type = 'project'
        LEFT JOIN users u
            ON p.owner_id = u.id
        LEFT JOIN system_users su
            ON u.system_user_id = su.id
        INNER JOIN project_hierarchy ph
            ON ph.project_id = pc.project_id
)

SELECT *
FROM project_hierarchy