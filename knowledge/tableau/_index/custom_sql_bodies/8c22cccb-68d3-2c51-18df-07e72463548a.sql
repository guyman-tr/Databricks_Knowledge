select * 
from
 (
    select accountid
    , CASE WHEN a.accountid  is not null then a.pi_potential
    else c.pi_potential__c end pi_potential
    , b.cid, a.CreatedDate  --a.*, b.CID 
    from main.crm.gold_crm_idmaptopology b 
    left join 
           (
               select accountid, row_number() over (partition by b.CID ORDER BY createddate desc) RN, newvalue pi_potential, cid, a.CreatedDate  --a.*, b.CID 
                from main.crm.gold_crm_idmaptopology b
                left join  main.crm.silver_crm_accounthistory a
                on a.AccountId = b.SF_ID
                where Field = 'PI_Potential__c'

             ) a 
      on a.AccountId = b.SF_ID
      and a.rn = 1
      left join main.crm.baselines_piaccountbaseline_20240208 c
      on b.SF_ID = c.ID
  ) vv
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cd
on cd.realCID =vv.cid
where  cd.gurustatusid> 0