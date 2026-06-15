--This subquery obtains the users granted Server Admin privileges the entire Tableau Server instance and returns all of their usernames in the "server_admins_string" field
	--This is used for row-level security
SELECT
    1 AS dummy_join_field ,
    ';' || string_agg(DISTINCT su.name || ';', '') AS server_admins_string
FROM users u
    INNER JOIN system_users su
        ON u.system_user_id = su.id
WHERE su.admin_level = 10