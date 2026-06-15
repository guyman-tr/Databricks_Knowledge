with escalations as (
select distinct 
cast(c.CreatedDate as date) as CreatedDate,
c.CaseNumber,
c.CID,
c.Country,
c.Status,
c.ClubLevel,
c.FullResolutionTime,
c.ClosedDate,
c.Type,
c.Origin,
c.Sub_Type,
case when c.RecordTypeId ='0121p000001138oAAA' then 'Customer'
when c.RecordTypeId ='0121p000001138jAAA' then 'Affiliate'
when c.RecordTypeId ='0121p000000oYwbAAE' then 'eToro Money'
when c.RecordTypeId='01208000000gYqpAAE'  then 'Popular Investor'
when c.RecordTypeId='0121p000000TiVlAAK' then ' eToroX Customer'
when c.RecordTypeId ='0121p000000oYwgAAE' then 'Wallet'
end as RecordType,
sc.Reference_Id__c as ReferenceID, 
CAST(c.EscalationDate AS DATE) as DateofEscalation,
c.Phase as CurrentPhase,
r.Name as Regulation,
PositionID,
c.ElapsedTimeFromEscalation,
c.FinalEscalationResponseDate,
GoodwillGesture,TechnicalRefund,
c.Duplicate,
sc2.Case_Summary__c,
CASE WHEN e.CID>0 THEN 1 ELSE 0 END AS HasEtoroMoney,
CONCAT_WS(' ', u.FirstName, u.LastName)  as CaseOwner,
SubRole,
com.GoodWill as SatisfactionCredit
,com.Description as SatisfactionReason
from main.bi_output.bi_output_customer_customer_support_case c  
left join   main.crm.silver_crm_case sc on c.CaseNumber=sc.Case_Number__c and sc.Reference_Id__c is not null
left join  (SELECT 
    Case_Number__c,
    Case_Summary__c,
    LastModifiedDate
FROM (
    SELECT 
        Case_Number__c,
        Case_Summary__c,
        LastModifiedDate,
        ROW_NUMBER() OVER (PARTITION BY Case_Number__c ORDER BY LastModifiedDate DESC) AS row_num
    FROM 
        main.crm.silver_crm_case
) ranked_cases
WHERE row_num = 1) sc2 on c.CaseNumber=sc2.Case_Number__c and sc2.Case_Summary__c is not null
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked m on m.RealCID=c.CID 
left join bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account e on e.CID=c.CID
left join (select CreditID,CID,Credit as GoodWill,Description,Occurred FROM main.general.bronze_etoro_history_credit
WHERE CompensationReasonID in (26,125,126)) com on com.CID=c.CID AND cast(com.Occurred as date) between c.CreatedDate and c.ClosedDate
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID=m.RegulationID
left join main.bi_output.bi_output_customer_customer_support_agent_user u on u.ID=c.OwnerId AND YEAR(ToDate)='9999'
where Cast(c.CreatedDate as date)>='2022-05-25'
and  EscalationDate is not null),
pop AS (
 
  SELECT 
      fsc.RealCID AS CID,
      fsc.PlayerStatusID,
      dps.Name AS PlayerStatus,
      psr.Name AS PlayerStatusReason,
      psssr.PlayerStatusSubReasonName AS PlayerStatusSubReason,
      TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date
  FROM 
      dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
  INNER JOIN 
      main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr 
        ON fsc.DateRangeID = dr.DateRangeID
  INNER JOIN 
      dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps 
        ON fsc.PlayerStatusID = dps.PlayerStatusID
        INNER JOIN 
      dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr
        ON fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID
           INNER JOIN 
      dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons psssr
        ON fsc.PlayerStatusSubReasonID = psssr.PlayerStatusSubReasonID
  WHERE 
      fsc.IsValidCustomer = 1
      AND fsc.RealCID IN (SELECT DISTINCT CID FROM escalations)

)
select e.*,  p.PlayerStatus as PlayerStatus_TOE,
        p.PlayerStatusReason AS PlayerStatusReason_TOE,p.PlayerStatusSubReason AS PlayerStatusSubReason_TOE
     from escalations e
LEFT JOIN LATERAL (
    SELECT 
        PlayerStatus,
        p.PlayerStatusReason,p.PlayerStatusSubReason,
        Change_Date
    FROM pop p
    WHERE p.CID = e.CID
      AND p.Change_Date <= e.CreatedDate
    ORDER BY p.Change_Date DESC
    LIMIT 1
) p ON TRUE