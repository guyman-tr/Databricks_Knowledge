select bdsmu.AccountManagerID
        ,bdsmu.Position
        ,bdsmu.Team
        ,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) Name
        ,bdsmu.ID
        ,count(*) CIDs
from bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc
on CAST(bdsmu.AccountManagerID AS INT) = cc.AccountManagerID
and IsValidCustomer = 1
WHERE bdsmu.ToDate = '9999-12-31T00:00:00.000Z'
and bdsmu.IsActive = 'true'
and bdsmu.Position in ('Sales','RM','Account Manager','Team leader','Senior Account Manager')
group by bdsmu.AccountManagerID
        ,bdsmu.Position
        ,bdsmu.Team
        ,CONCAT(bdsmu.FirstName, ' ', bdsmu.LastName) 
        ,bdsmu.ID