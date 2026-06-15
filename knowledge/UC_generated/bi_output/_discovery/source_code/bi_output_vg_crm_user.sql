-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_crm_user
-- Captured: 2026-05-19T14:48:04Z
-- ==========================================================================

WITH RECURSIVE hierarchy AS (

  -- Base level (level 0):
  -- Start the hierarchy from each user.
  -- CurrentId represents the current node in the hierarchy traversal.
  SELECT
    u.Id            AS UserId,            -- The original user we are resolving hierarchy for
    u.Id            AS CurrentId,         -- Current node in the hierarchy
    u.ManagerId     AS NextManagerId,     -- Next manager to traverse to
    0               AS lvl,               -- Hierarchy level (0 = the user itself)
    array(u.Id)     AS path               -- Track visited nodes to prevent cycles
  FROM main.crm.silver_crm_user u

  UNION ALL

  -- Recursive step:
  -- Traverse up the management hierarchy by joining on the manager.
  SELECT
    h.UserId        AS UserId,            -- Keep the original user constant
    m.Id            AS CurrentId,         -- Move to the manager
    m.ManagerId     AS NextManagerId,     -- Prepare for the next level up
    h.lvl + 1       AS lvl,               -- Increment hierarchy level
    array_union(h.path, array(m.Id)) AS path
  FROM hierarchy h
  JOIN main.crm.silver_crm_user m
    ON h.NextManagerId = m.Id
  WHERE
    h.NextManagerId IS NOT NULL            -- Stop if there is no manager
    AND h.lvl < 20                         -- Safety limit to prevent infinite recursion
    AND NOT array_contains(h.path, m.Id)  -- Prevent circular references
),

rm_choice AS (
  -- Select the first RM found in the hierarchy for each user.
  -- The closest RM in the chain (lowest level) is chosen.
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

  -- Override timezone for specific managers, otherwise use the user's timezone
  CASE
    WHEN u.ManagerId IN ('0050800000EE0zOAAT', '0050800000GyOLrAAN', '0050800000DArh6AAD')
      THEN 'Australia/Sydney'
    ELSE u.TimeZoneSidKey
  END                                       AS TimeZoneSidKeys,

  -- Direct manager details (level 1)
  m.BO_User_ID__c                           AS Manager_BO_User_ID,
  concat(m.FirstName, ' ', m.LastName)      AS Manager_FullName,
  m.Department                              AS Manager_Department,
  m.Title                                   AS Manager_Title,
  m.Position__c                             AS Manager_Position,
  m.Desk__c                                 AS Manager_Desk,
  m.Team__c                                 AS Manager_Team,
  m.IsActive                                AS Manager_IsActive,

  -- Resolved Regional Manager (RM) from the hierarchy
  rc.RM_UserId                              AS RM_UserId,
  rc.RM_FullName                            AS RM_FullName

FROM main.crm.silver_crm_user u
LEFT JOIN main.crm.silver_crm_user m
  ON u.ManagerId = m.Id
LEFT JOIN rm_choice rc
  ON u.Id = rc.UserId
 AND rc.rn = 1
