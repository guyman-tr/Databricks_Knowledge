--This subquery obtains the users granted Site Admin privileges the entire Tableau Server Site and returns all of their usernames in the "site_admins_string" field
	--This is used for row-level security
SELECT
    u.site_id ,
    ';' || string_agg(DISTINCT su.name || ';', '') AS site_admins_string
FROM users u
    INNER JOIN system_users su
        ON u.system_user_id = su.id
    INNER JOIN site_roles sr
        ON u.site_role_id = sr.id
WHERE sr.name LIKE '%SiteAdmin%'
GROUP BY u.site_id