select p.*,cast(m.Customer_Unique_ID_CID__c as int) as Customer_Unique_ID_CID__c
from
(
select accountid,interaction,max(LastInteractionDate) as LastInteractionDate
from
(
select accountid,interaction,max(createddate) as LastInteractionDate
from
(select
t.id,
t.whatId,
t.TaskSubtype,
t.subject,
t.ownerid,
t.accountid,
t.createddate,
case
when TaskSubtype = 'Call' and subject in ('Call','Outgoing - Effective Answered Call','Incoming - Answered Call','Outgoing - Answered Call','Outgoing - Effective Answered Call') then 'PhoneContacted'
when TaskSubtype = 'Call' and subject in ('Incoming - Failed Call','Outgoing - Failed Call') then 'PhoneAttempt'
when TaskSubtype in ('Email','ListEmail') then 'Email/Whatsapp'
end as interaction
from main.crm.silver_crm_task t
where whatid not like '500%' and t.CreatedDate>>= now() - INTERVAL '12 months') a
where a.interaction is not null and accountid is not null
group by accountid,interaction
union
(select
account__c as accountid,'Email/Whatsapp' as interaction,max(CreatedDate) as LastInteractionDate
from main.crm.silver_crm_messagingsession
where AgentType in ('BotToAgent','Agent')
group by account__c)
) b
group by accountid,interaction
having accountid is not null
order by b.accountid,b.interaction
) p
join crm.silver_crm_accountidmappingtable m
on p.accountid = m.id