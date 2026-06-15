select distinct 
cast(c.CreatedDate as date) as CreatedDate,
c.CaseNumber,
c.CID,
c.Country,
c.Status,
c.ClubLevel,
c.Type,
c.Sub_Type,
c.TechnicalRefund,
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
c.Duplicate,
CASE WHEN e.CID>0 THEN 1 ELSE 0 END AS HasEtoroMoney,
CONCAT_WS(' ', u.FirstName, u.LastName)  as CaseOwner,
c.GoodwillGesture,
SubRole
from main.bi_output.bi_output_customer_customer_support_case c  
left join   main.crm.silver_crm_case sc on c.CaseNumber=sc.Case_Number__c and sc.Reference_Id__c is not null
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked m on m.RealCID=c.CID 
left join bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account e on e.CID=c.CID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID=m.RegulationID
left join main.bi_output.bi_output_customer_customer_support_agent_user u on u.ID=c.OwnerId AND YEAR(ToDate)='9999'

where Cast(c.CreatedDate as date)>='2022-05-25'
and  EscalationDate is not null