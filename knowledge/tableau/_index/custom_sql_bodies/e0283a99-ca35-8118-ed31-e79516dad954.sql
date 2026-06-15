SELECT a.RoutingDate, a.Field,
       a.OldValue, a.NewValue AS Group,
       a.Current_ClubLevel as ClubLevel,
       a.Status, a.Current_Regualtion as Regulation, a.CaseNumber,
       a.Current_PlayerStatus as CustomerStatus
FROM (
    SELECT cc.*,
           CAST(ch.CreatedDate AS DATE) AS RoutingDate,
           ch.Field, ch.OldValue, ch.NewValue, ch.DataType,
           dr.Name AS Current_Regualtion,
           dps.Name AS Current_PlayerStatus,
           dpl.Name AS Current_ClubLevel,
           ROW_NUMBER() OVER (PARTITION BY cc.CaseNumber ORDER BY ch.CreatedDate DESC) AS RN
    FROM bi_output.bi_output_customer_customer_support_case cc
    JOIN crm.silver_crm_casehistory ch ON ch.CaseId = cc.CaseId
    JOIN (SELECT CaseNumber, Case_Id_18__c FROM crm.silver_crm_case) c ON c.Case_Id_18__c = ch.CaseId
    JOIN main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer dc ON dc.RealCID = cc.CID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr ON dr.DWHRegulationID = dc.RegulationID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl ON dc.PlayerLevelID = dpl.PlayerLevelID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
    WHERE ch.Field = 'Owner'
      AND ch.DataType = 'Text'
) a
WHERE a.NewValue IN (
    'AML ADGM', 'AML Australia', 'AML Cyprus', 'AML Seychelles',
    'AML UK', 'Compliance CY', 'eToro Money FinCrime','AML USA', 'eToro X AML'

)
AND a.RN = 1