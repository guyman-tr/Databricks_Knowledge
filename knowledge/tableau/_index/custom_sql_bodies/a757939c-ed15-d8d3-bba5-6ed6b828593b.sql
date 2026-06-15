SELECT 
    case  
        when CaseSkills like '%Cashout%' then 'Cashouts' 
    end as Type
    ,count(CaseNumber) as Backlog 
    ,cast(c.CreatedDate  as date) as CreatedDate
    ,case 
        when c.Status in ('In Routing') then 'Backlog' 
        else 'Resolved'
     end as Status
    ,dc.VerificationLevelID
     ,case 
	    when Year(dc.FirstDepositDate) = 1900 then 'No'
	    else 'Yes'
      end as IsFTD
from 
    bi_output.bi_output_customer_customer_support_case c
LEFT JOIN
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = c.CID
where
     --Status in ('In Routing','Open','New')  and 
     (CaseSkills like '%Cashout%')
     and cast(c.CreatedDate as date) >= '2024-01-01'
group by
    case  
        when CaseSkills like '%Cashout%' then 'Cashouts' 
    end
    ,cast(c.CreatedDate as date) 
    ,case 
        when c.Status in ('In Routing') then 'Backlog' 
        else 'Resolved' 
    end
    ,dc.VerificationLevelID
    ,case 
	    when Year(dc.FirstDepositDate) = 1900 then 'No'
	    else 'Yes'
      end