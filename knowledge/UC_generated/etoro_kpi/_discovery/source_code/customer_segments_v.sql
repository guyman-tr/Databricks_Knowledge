-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.customer_segments_v
-- Captured: 2026-05-19T15:06:28Z
-- ==========================================================================

select
  cf.GCID,
  cf.CID,
  cf.Club,
  cf.Channel,
  cf.Country,
  cf.registered,
  Case
    when cf.FirstDepositDate = '1900-01-01T00:00:00.000+00:00' Then NULL
    ELSE cf.FirstDepositDate
  End as FirstDepositDate,
  cf.FirstCashoutDate,
  cf.FirstMenualPosOpenDate as FirstOpenPositionDate,
  cf.CommunicationLanguage,
  ca.Age as CustomerAge,
  CASE WHEN LSD IN('Churn 14-30 days' , 'Churn 31-60 days', 'Churn over 60 days' ) Then True else False End  Is_Churn_over_14 ,
  CASE WHEN LSD IN('Churn 31-60 days', 'Churn over 60 days' ) Then True else False End  Is_Churn_over_30 ,
  CASE WHEN LSD IN('Churn over 60 days' ) Then True else False End  Is_Churn_over_60 ,
  CASE 
  WHEN aum.EquityGlobal >= 10000 Then 'High' 
  WHEN aum.EquityGlobal Between 150 and 10000  Then 'Medium' 
  WHEN aum.EquityGlobal Between 0.5 and 150  Then 'Low'
  Else 'No Equity' End as EquityScore 
from
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cf
    LEFT JOIN bi_dealing.bi_output_dealing_cidage_data ca ON (ca.RealCID = cf.CID)
    LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_lifestagedefinition lsd ON(lsd.ToDateID =99991231 and lsd.RealCID = cf.CID)
    LEFT JOIN main.etoro_kpi.ddr_aum_v aum on(aum.RealCID = cf.CID and aum.DateID = CAST(date_format(date_add(current_date(), -1), 'yyyyMMdd') AS INT))
