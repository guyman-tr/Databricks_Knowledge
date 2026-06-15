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
c.Sub_Type,
case  
       WHEN c.CaseSkills LIKE '%US%' THEN 'US'
            WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '5.Islamic/GDPR'
    WHEN c.CaseSkills LIKE '%Club Issues%' THEN '6.Club Issues'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '7.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '8.Technical'

end as Skills,
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
where Cast(c.CreatedDate as date)>='2024-05-25'
and  (GoodwillGesture>0 OR TechnicalRefund>0 OR com.GoodWill>0)