with am as (
SELECT AccountId, OwnerId
FROM crm.gold_crm_accountsmanager am
WHERE (AccountId, CreatedDate) IN (
    SELECT AccountId, MAX(CreatedDate)
    FROM crm.gold_crm_accountsmanager
    GROUP BY AccountId
)
)
select
    am.accountid as customerSFid,
    cast(m.Customer_Unique_ID_CID__c as int) as Customer_Unique_ID_CID__c,
    m.GCID__c,
    concat(u.FirstName,' ',u.lastname) as AM_name,
    u.Email as am_email,
    u.managerid,
    u.Team__c,
    m_m1.email as m1_email,
    concat(m_m1.firstname,' ',m_m1.lastname) as m1_fullname,
    m_m2.email as m2_email,
    concat(m_m2.firstname,' ',m_m2.lastname) as m2_fullname,
    m_m3.email as m3_email,
    concat(m_m3.firstname,' ',m_m3.lastname) as m3_fullname,
    m_m4.email as m4_email,
    concat(m_m4.firstname,' ',m_m4.lastname) as m4_fullname,
    m_m5.email as m5_email,
    concat(m_m5.firstname,' ',m_m5.lastname) as m5_fullname,
    m_m6.email as m6_email,
    concat(m_m6.firstname,' ',m_m6.lastname) as m6_fullname
from crm.silver_crm_accountidmappingtable m
join am
    on m.id = am.AccountId
join main.crm.silver_crm_user u
    on am.OwnerId = u.id
left join crm.silver_crm_user m_m1
    on m_m1.id = u.managerid
left join crm.silver_crm_user m_m2
    on m_m2.id = m_m1.managerid
left join crm.silver_crm_user m_m3
    on m_m3.id = m_m2.managerid
left join crm.silver_crm_user m_m4
    on m_m4.id = m_m3.managerid
left join crm.silver_crm_user m_m5
    on m_m5.id = m_m4.managerid
left join crm.silver_crm_user m_m6
    on m_m6.id = m_m5.managerid