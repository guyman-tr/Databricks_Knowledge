-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_cf_crm_contact
-- Captured: 2026-05-19T14:47:18Z
-- ==========================================================================

SELECT
  tfcrm.*,
  -- Derived date key
  CAST(date_format(tfcrm.CreatedDate, 'yyyyMMdd') AS INT) AS CreatedDateId,

  -- AM enrichment
  amu.BO_User_ID  AS AM_BO_User_ID,
  amu.FullName    AS AM_FullName,
  amu.Department  AS AM_Department,
  amu.Title       AS AM_Title,
  amu.Position    AS AM_Position,
  amu.Desk        AS AM_Desk,
  amu.Team        AS AM_Team,
  amu.IsActive    AS AM_IsActive,
  amu.TimeZoneSidKeys AS AM_TimeZoneSidKeys,

  -- AM manager hierarchy
  amu.Manager_FullName,
  amu.Manager_Department,
  amu.Manager_Title,
  amu.Manager_Position,
  amu.Manager_Desk,
  amu.Manager_Team,

  -- Owner enrichment 
  owneru.BO_User_ID  AS Owner_BO_User_ID,
  owneru.FullName    AS Owner_FullName,
  owneru.Department  AS Owner_Department,
  owneru.Title       AS Owner_Title,
  owneru.Position    AS Owner_Position,
  owneru.Desk        AS Owner_Desk,
  owneru.Team        AS Owner_Team,
  owneru.IsActive    AS Owner_IsActive,
  owneru.TimeZoneSidKeys AS Owner_TimeZoneSidKeys

FROM main.bi_output_stg.tf_crm_contact_user(
       CAST(date_trunc('month', add_months(current_date(), -12)) AS DATE),
       date_sub(current_date(), 1)
     ) tfcrm
JOIN main.bi_output.bi_output_vg_crm_user amu
  ON tfcrm.AccountManagerId = amu.UserId
LEFT JOIN main.bi_output.bi_output_vg_crm_user owneru
  ON tfcrm.OwnerId = owneru.UserId
WHERE owneru.Department IN ('CF','Retention, CF')
  AND owneru.Position IN ('Senior Account Manager','Account Manager','Team leader','Sales')
