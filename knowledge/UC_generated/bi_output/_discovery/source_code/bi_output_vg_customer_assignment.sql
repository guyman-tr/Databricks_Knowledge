-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_customer_assignment
-- Captured: 2026-06-19T14:30:22Z
-- ==========================================================================

SELECT
  dcu.RealCID,
  am.AccountId            AS SalesForceAccountID,
  u.BO_User_ID          AS AM_CID,
  am.OwnerId              AS AM_ID,
  u.FullName              AS AM_FullName,
  u.Department            AS AM_Department,
  u.Position              AS AM_Position,
  am.CreatedDate          AS AssignmentCreatedDate,
  am.__START_AT           AS AssignmentStartAt,
  am.__END_AT             AS AssignmentEndAt,
  CASE
    WHEN am.__END_AT IS NULL  THEN 1
    ELSE 0
  END AS IsCurrentAssignment
FROM main.crm.gold_crm_accountsmanager am
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dcu
  ON am.AccountId = dcu.SalesForceAccountID
JOIN main.bi_output.bi_output_vg_crm_user u
  ON am.OwnerId = u.UserId
  where dcu.IsValidCustomer=1
