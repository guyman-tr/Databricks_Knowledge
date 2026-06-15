-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.crm_user_v
-- Captured: 2026-05-19T15:05:44Z
-- ==========================================================================

WITH RECURSIVE hierarchy AS (
  -- Base level: start from each user
  SELECT
    u.Id            AS UserId,
    u.Id            AS CurrentId,
    u.ManagerId     AS NextManagerId,
    0               AS lvl,
    array(u.Id)     AS path
  FROM main.crm.silver_crm_user u

  UNION ALL

  -- Recursive step: traverse up the management chain
  SELECT
    h.UserId        AS UserId,
    m.Id            AS CurrentId,
    m.ManagerId     AS NextManagerId,
    h.lvl + 1       AS lvl,
    array_union(h.path, array(m.Id)) AS path
  FROM hierarchy h
  JOIN main.crm.silver_crm_user m
    ON h.NextManagerId = m.Id
  WHERE
    h.NextManagerId IS NOT NULL
    AND h.lvl < 20
    AND NOT array_contains(h.path, m.Id)
),

rm_choice AS (
  -- Select the closest Regional Manager (RM) in each user's hierarchy
  SELECT
    h.UserId,
    rm.Id AS RM_UserId,
    concat(rm.FirstName, ' ', rm.LastName) AS RM_FullName,
    row_number() OVER (
      PARTITION BY h.UserId
      ORDER BY h.lvl
    ) AS rn
  FROM hierarchy h
  JOIN main.crm.silver_crm_user rm
    ON h.CurrentId = rm.Id
  WHERE rm.Position__c = 'RM'
)

SELECT
  u.Id                                      AS UserId,
  u.BO_User_ID__c                           AS BO_User_ID,
  concat(u.FirstName, ' ', u.LastName)      AS FullName,
  u.Department                              AS Department,
  u.Title                                   AS Title,
  u.Position__c                             AS Position,
  u.Desk__c                                 AS Desk,
  u.Team__c                                 AS Team,
  u.IsActive                                AS IsActive,
  u.ManagerId                               AS ManagerId,
  CASE
    WHEN u.ManagerId IN ('0050800000EE0zOAAT', '0050800000GyOLrAAN', '0050800000DArh6AAD')
      THEN 'Australia/Sydney'
    ELSE u.TimeZoneSidKey
  END                                       AS TimeZoneSidKeys,
  m.BO_User_ID__c                           AS Manager_BO_User_ID,
  concat(m.FirstName, ' ', m.LastName)      AS Manager_FullName,
  m.Department                              AS Manager_Department,
  m.Title                                   AS Manager_Title,
  m.Position__c                             AS Manager_Position,
  m.Desk__c                                 AS Manager_Desk,
  m.Team__c                                 AS Manager_Team,
  m.IsActive                                AS Manager_IsActive,
  rc.RM_UserId                              AS RM_UserId,
  rc.RM_FullName                            AS RM_FullName
FROM main.crm.silver_crm_user u
LEFT JOIN main.crm.silver_crm_user m
  ON u.ManagerId = m.Id
LEFT JOIN rm_choice rc
  ON u.Id = rc.UserId
 AND rc.rn = 1
