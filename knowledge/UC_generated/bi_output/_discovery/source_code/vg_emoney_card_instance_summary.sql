-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_emoney_card_instance_summary
-- Captured: 2026-05-19T14:54:51Z
-- ==========================================================================

select CID, DWH_CardInstanceId as Customer_Card_ID, InstanceStatus as Customer_Card_Status,
 InstanceCreatedDate as Customer_Card_Order_Date,
 InstanceActivationDate as Customer_Card_Activation_Date
 , InstanceExpirationDate as Customer_Card_Expiration_Date
  from 
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary
